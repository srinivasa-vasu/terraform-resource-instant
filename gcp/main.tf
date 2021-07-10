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

resource "google_compute_instance" "instances" {
  count        = var.replicas
  name         = "${var.identifier}-n${format("%d", count.index + 1)}"
  machine_type = "n1-standard-4"
  zone         = element(data.google_compute_zones.zones.names, count.index)

  boot_disk {
    initialize_params {
      image = "centos-cloud/centos-7"
      size  = 50
      type  = "pd-ssd"
    }
  }

  network_interface {
    subnetwork = data.google_compute_subnetwork.subnet.self_link
    access_config {
    }
  }

  metadata = {
    sshKeys = "${var.ssh_user}:${file(var.ssh_public_key)}"
  }
  
  connection {
    type        = "ssh"
    user        = var.ssh_user
    private_key = file(var.ssh_private_key)
    host        = self.network_interface.0.access_config.0.nat_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mkdir -p /storage"
    ]
  }

}
