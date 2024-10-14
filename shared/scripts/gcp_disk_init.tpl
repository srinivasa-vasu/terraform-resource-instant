#!/bin/bash
set -x

OS_IMAGE="${os_image}"

# Get the boot disk device name
boot_disk_device=$(curl -H "Metadata-Flavor: Google" "http://metadata.google.internal/computeMetadata/v1/instance/disks/0/device-name")

boot_disk="/dev/disk/by-id/google-$${boot_disk_device}"

echo "Boot disk identified as: $boot_disk"

# Get list of all disk devices
devices=$(lsblk -ndo name,type | awk '$2=="disk" {print "/dev/"$1}')

# Function to check if a disk is formatted
is_formatted() {
    local device=$1
    if lsblk -n -o FSTYPE "$${device}" | grep -q .; then
        return 0  # Disk is formatted
    else
        return 1  # Disk is not formatted
    fi
}

# Function to format and mount a disk
format_and_mount() {
    local device=$1
    local mount_point=$2

    # Check if the device is already formatted
    if ! is_formatted "$device"; then
        echo "Formatting $device with XFS..."
        sudo mkfs.xfs -f "$device"
    else
        echo "$device is already formatted."
    fi

    # Check if the device is already mounted
    if ! grep -qs "$mount_point" /proc/mounts; then
        echo "Mounting $device to $mount_point..."
        # Create mount point if it doesn't exist
        sudo mkdir -p "$mount_point"
        # Mount the disk
        sudo mount $device "$mount_point"
        # Add entry to fstab if it doesn't exist
        if ! grep -qs "$device" /etc/fstab; then
            # Add entry to /etc/fstab to mount disk at boot
            # echo UUID=`sudo blkid -s UUID -o value $device` $mount_point xfs discard,defaults,nofail 0 2 | sudo tee -a /etc/fstab
            echo "$device $mount_point xfs defaults,nofail 0 2" | sudo tee -a /etc/fstab
            sudo systemctl daemon-reload
        fi
    else
        echo "$device is already mounted to $mount_point."
    fi
}

# Initialize index counter
index=0

# Iterate through all disk devices
for device in $devices; do
    # Resolve any symlinks to get the actual device path
    actual_device=$(readlink -f "$device")

    # Skip the boot disk
    if [[ "$actual_device" == "$(readlink -f "$boot_disk")" ]]; then
        echo "Skipping boot disk: $actual_device"
        continue
    fi

    # Get device ID
    device_id=$(basename "$actual_device")

    # Mount point
    mount_point="${mnt}$index"
    echo "Mount point for $device_id: $mount_point"

    ((index++))

    # Format and mount the disk
    format_and_mount "$actual_device" "$mount_point"
done

echo "Disk formatting and mounting completed."


# create soft link for python3
sudo ln -s /usr/bin/python3 /usr/bin/python

# Change SELinux to permissive mode
case "$${OS_IMAGE,,}" in
    almalinux[8-9]*|rhel[8-9]*)
        sudo setenforce 0
        ;;
esac
