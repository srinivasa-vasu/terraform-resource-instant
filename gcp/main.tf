locals {
  disks_count = (var.disks * var.instances)
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
  name = "yb-bastion"
  zone = "asia-south1-a"
}

resource "google_compute_instance" "instances" {
  count = var.instances
  name  = "${var.identifier}-n${format("%d", count.index + 1)}"
  # machine_type = "n1-standard-2"
  machine_type = "n2-highcpu-16"
  zone         = var.zone != "" ? var.zone : element(data.google_compute_zones.zones.names, count.index)

  boot_disk {
    initialize_params {
      image = "centos-cloud/centos-7"
      size  = 50
      type  = "pd-ssd"
    }
  }

  network_interface {
    subnetwork = data.google_compute_subnetwork.subnet.self_link
    # access_config {
    # }
  }

  metadata = {
    sshKeys = "${var.ssh_user}:${file(var.ssh_public_key)}"
  }

  lifecycle {
    ignore_changes = [attached_disk]
  }

}

resource "null_resource" "format_attached_disks" {
  count = var.instances
  depends_on = [
    google_compute_attached_disk.attach_disks
  ]
  connection {
    bastion_host        = data.google_compute_instance.bastion.network_interface.0.access_config.0.nat_ip
    bastion_private_key = file(var.bastion_ssh_private_key)
    bastion_user        = var.ssh_user
    host                = google_compute_instance.instances[count.index].network_interface.0.network_ip
    type                = "ssh"
    user                = var.ssh_user
    private_key         = file(var.ssh_private_key)
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mkfs -t xfs /dev/sdb",
      "sudo mkfs -t xfs /dev/sdc",
      "sudo mkdir -p /disks/ssd0",
      "sudo mkdir -p /disks/ssd1",
      "sudo mount /dev/sdb /disks/ssd0",
      "sudo mount /dev/sdc /disks/ssd1",
      "sudo cp /etc/fstab /etc/fstab.orig",
      "disk0_uuid=$(sudo blkid | grep -i \"/dev/sdb\" | awk '{print $2}' | tr -d '\"')",
      "disk1_uuid=$(sudo blkid | grep -i \"/dev/sdc\" | awk '{print $2}' | tr -d '\"')",
      "echo $disk0_uuid /disks/ssd0  xfs  defaults,nofail  0  2 | sudo tee -a /etc/fstab",
      "echo $disk1_uuid /disks/ssd1  xfs  defaults,nofail  0  2 | sudo tee -a /etc/fstab"
    ]
  }
}

resource "google_compute_attached_disk" "attach_disks" {
  disk     = google_compute_disk.disks[count.index].id
  instance = google_compute_instance.instances[floor(count.index / var.disks)].id
  count    = local.disks_count
}

resource "google_compute_disk" "disks" {
  count = local.disks_count
  name  = "${var.identifier}-nw-n${format("%d", count.index + 1)}"
  type  = "pd-extreme"
  zone  = var.zone != "" ? var.zone : element(data.google_compute_zones.zones.names, count.index)
  # image = "centos-cloud/centos-7"
  size = 50
  # provisioned_iops = 100000
}
