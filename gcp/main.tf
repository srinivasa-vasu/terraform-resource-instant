locals {
  disks_count = (var.disks * var.instances)
  # dev_id_prefix = strcontains(var.disk_type, "pd") ? "sd" : "nvme0n"
  # dev_id_prefix = strcontains(var.instance_type, "c3") ? "nvme0n" : "sd"
  # dev_ids       = strcontains(var.instance_type, "c3") ? var.numbers : var.letters

  # disks_mounts = [for index in range(var.disks) : [
  #   "${var.disks_mount_points[0].device_name}${local.dev_id_prefix}${local.dev_ids[index]}", "${var.disks_mount_points[0].mount_point}${index}"
  # ]]


  image_list = [
    {
      "type" = "almalinux8"
      "path" = "almalinux-cloud/almalinux-8"
    },
    {
      "type" = "ubuntu18"
      "path" = "ubuntu-os-cloud/ubuntu-1804-lts"
    },
    {
      "type" = "ubuntu20"
      "path" = "ubuntu-os-cloud/ubuntu-2004-lts"
    },
    {
      "type" = "ubuntu22"
      "path" = "ubuntu-os-cloud/ubuntu-2204-lts"
    },
    {
      "type" = "centos7"
      "path" = "centos-cloud/centos-7"
    },
    {
      "type" = "almalinux9"
      "path" = "almalinux-cloud/almalinux-9"
    },
    {
      "type" = "rhel8"
      "path" = "rhel-cloud/rhel-8"
    },
    {
      "type" = "rhel9"
      "path" = "rhel-cloud/rhel-9"
    },
    {
      "type" = "cos"
      "path" = "cos-cloud/cos-stable"
    }
  ]
  selected_image = lookup({ for val in local.image_list :
  0 => val if val.type == var.image_type }, 0, local.image_list[0])

  post_create = templatefile("../shared/scripts/instance_ops_v2.tpl", {
    # disks    = join(" ", [for disk in local.disks_mounts : join(",", disk)])
    os_image       = var.image_type
    mnt            = "${var.disks_mount_points[0].mount_point}"
    cloud_provider = "gcp"
  })

}

provider "google" {
  project     = var.project
  region      = var.region
  credentials = file(var.credentials)
}

provider "google-beta" {
  project     = var.project
  region      = var.region
  credentials = file(var.credentials)
}

data "google_compute_network" "vpc" {
  name = var.vpc
}

data "google_compute_subnetwork" "subnet" {
  name = var.subnet
}

data "google_compute_zones" "zones" {
  region = var.region
}

data "google_compute_instance" "bastion" {
  count = var.bastion_on ? 1 : 0
  name  = var.bastion
  zone  = "asia-south1-a"
}

resource "google_compute_instance" "instances" {
  count                     = var.instances
  name                      = "${var.identifier}-n${format("%d", count.index + 1)}"
  machine_type              = var.instance_type
  allow_stopping_for_update = true
  zone                      = var.zone != "" ? var.zone : element(data.google_compute_zones.zones.names, count.index)
  tags                      = var.tags

  boot_disk {
    initialize_params {
      image  = local.selected_image.path
      size   = 50
      type   = var.disk_type
      labels = var.labels
    }
  }

  network_interface {
    subnetwork = data.google_compute_subnetwork.subnet.self_link
    # access_config {
    # }
  }

  labels = var.labels

  metadata = {
    sshKeys = "${var.ssh_user}:${file(var.ssh_public_key)}"
  }

  lifecycle {
    ignore_changes = [attached_disk]
  }

}

resource "null_resource" "format_attached_disks_bastion_on" {
  count = var.bastion_on ? var.instances : 0
  depends_on = [
    google_compute_attached_disk.attach_disks
  ]

  triggers = {
    instance_id = google_compute_instance.instances[count.index].id
    disk_ids    = join(",", [for disk in google_compute_attached_disk.attach_disks : disk.id if disk.instance == google_compute_instance.instances[count.index].id])
  }

  connection {
    bastion_host        = data.google_compute_instance.bastion[0].network_interface.0.access_config.0.nat_ip
    bastion_private_key = file(var.bastion_ssh_private_key)
    bastion_user        = var.ssh_user
    host                = google_compute_instance.instances[count.index].network_interface.0.network_ip
    type                = "ssh"
    user                = var.ssh_user
    private_key         = file(var.ssh_private_key)
  }

  provisioner "remote-exec" {
    inline = [
      local.post_create
    ]
  }

}

resource "null_resource" "format_attached_disks_bastion_off" {
  count = var.bastion_on ? 0 : var.instances
  depends_on = [
    google_compute_attached_disk.attach_disks
  ]

  triggers = {
    instance_id = google_compute_instance.instances[count.index].id
    disk_ids    = join(",", [for disk in google_compute_attached_disk.attach_disks : disk.id if disk.instance == google_compute_instance.instances[count.index].id])
  }

  connection {
    host        = google_compute_instance.instances[count.index].network_interface.0.network_ip
    type        = "ssh"
    user        = var.ssh_user
    private_key = file(var.ssh_private_key)
  }

  provisioner "remote-exec" {
    inline = [
      local.post_create
    ]
  }
}

resource "google_compute_attached_disk" "attach_disks" {
  disk     = google_compute_disk.disks[count.index].id
  instance = google_compute_instance.instances[floor(count.index / var.disks)].id
  count    = local.disks_count
}

resource "google_compute_disk" "disks" {
  count  = local.disks_count
  name   = "${var.identifier}-nw-n${format("%d", count.index + 1)}"
  type   = var.disk_type
  zone   = var.zone != "" ? var.zone : element(data.google_compute_zones.zones.names, floor(count.index / var.disks))
  size   = var.disk_size
  labels = var.labels
  # provisioned_iops = 100000
}
