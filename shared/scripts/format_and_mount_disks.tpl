#!/bin/bash

DISKS="${disks}"

for disk in $DISKS; do
  IFS=',' read -ra DISK_INFO <<< "$${disk}"
  DISK_DEVICE_NAME="$${DISK_INFO[0]}"
  DISK_MOUNT_POINT="$${DISK_INFO[1]}"

  # Format disk
  sudo mkfs -t xfs $DISK_DEVICE_NAME

  # Mount disk
  sudo mkdir -p $DISK_MOUNT_POINT
  sudo mount -o discard,defaults $DISK_DEVICE_NAME $DISK_MOUNT_POINT

  # Add entry to /etc/fstab to mount disk at boot
  echo UUID=`sudo blkid -s UUID -o value $DISK_DEVICE_NAME` $DISK_MOUNT_POINT xfs discard,defaults,nofail 0 2 | sudo tee -a /etc/fstab
done
