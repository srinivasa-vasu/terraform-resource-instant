locals {
  disks_count = (var.disks * var.instances)
  ingress     = "${chomp(data.http.localip.body)}/32"
  dev_ids     = ["b", "c"]
}

provider "aws" {
  region                  = var.region
  shared_credentials_file = var.credentials
}

# Workstation public ip to allow access to. It identies the IP where this gets executed and adds it to the 
# firewall rule in the firewall block
data "http" "localip" {
  url = "http://ipv4.icanhazip.com"
}

data "aws_vpc" "vpc" {
  # id = var.vpc
  filter {
    name   = "tag:Name"
    values = ["${var.vpc}"]
  }
}

data "aws_subnet" "subnet" {
  vpc_id = data.aws_vpc.vpc.id
  # id     = var.subnet
  filter {
    name   = "tag:Name"
    values = ["${var.subnet}"]
  }
}

data "aws_availability_zones" "zones" {
  state = "available"
}

data "aws_instance" "bastion" {
  # instance_id = "yb-bastion"
  filter {
    name   = "tag:Name"
    values = ["${var.bastion}"]
  }
  filter {
    name   = "availability-zone"
    values = ["${var.zone}"]
  }
}

data "aws_ami" "ami" {
  most_recent = true
  owners      = ["aws-marketplace"]

  filter {
    name = "name"
    values = [
      "CentOS Linux 7 x86_64 HVM EBS *",
    ]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

data "aws_security_groups" "sg" {
  filter {
    name   = "group-name"
    values = ["${var.identifier}*"]
  }

  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.vpc.id]
  }

  filter {
    name   = "tag:kind"
    values = ["intra"]
  }
}

resource "aws_instance" "instances" {
  count = var.instances
  ami   = data.aws_ami.ami.id
  # associate_public_ip_address = var.associate_public_ip_address
  instance_type          = var.instance_type
  key_name               = var.ssh_keypair
  availability_zone      = var.zone != "" ? var.zone : element(data.aws_availability_zones.zones.names, count.index)
  subnet_id              = data.aws_subnet.subnet.id
  vpc_security_group_ids = data.aws_security_groups.sg.ids
  root_block_device {
    volume_size = 50
  }
  tags = {
    Name = "${var.identifier}-n${format("%d", count.index + 1)}"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "null_resource" "format_attached_disks" {
  count = var.instances
  depends_on = [
    aws_volume_attachment.attach_disks
  ]
  connection {
    bastion_host        = data.aws_instance.bastion.public_ip
    bastion_private_key = file(var.ssh_private_key)
    bastion_user        = var.bastion_ssh_user
    host                = aws_instance.instances[count.index].private_ip
    type                = "ssh"
    user                = var.ssh_user
    private_key         = file(var.ssh_private_key)
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mkfs -t xfs /dev/nvme2n1",
      "sudo mkfs -t xfs /dev/nvme3n1",
      "sudo mkdir -p /disks/ssd0",
      "sudo mkdir -p /disks/ssd1",
      "sudo mount /dev/nvme2n1 /disks/ssd0",
      "sudo mount /dev/nvme3n1 /disks/ssd1",
      "sudo cp /etc/fstab /etc/fstab.orig",
      "disk0_uuid=$(sudo blkid | grep -i \"/dev/nvme2n1\" | awk '{print $2}' | tr -d '\"')",
      "disk1_uuid=$(sudo blkid | grep -i \"/dev/nvme3n1\" | awk '{print $2}' | tr -d '\"')",
      "echo $disk0_uuid /disks/ssd0  xfs  defaults,nofail  0  2 | sudo tee -a /etc/fstab",
      "echo $disk1_uuid /disks/ssd1  xfs  defaults,nofail  0  2 | sudo tee -a /etc/fstab"
    ]
  }
}

resource "aws_volume_attachment" "attach_disks" {
  device_name = "/dev/sd${local.dev_ids[count.index]}"
  volume_id   = aws_ebs_volume.disks[count.index].id
  instance_id = aws_instance.instances[floor(count.index / var.disks)].id
  count       = local.disks_count
}

resource "aws_ebs_volume" "disks" {
  count             = local.disks_count
  availability_zone = var.zone != "" ? var.zone : element(data.aws_availability_zones.zones.names, count.index)
  size              = 50
  # provisioned_iops = 100000
  tags = {
    Name = "${var.identifier}-n${format("%d", count.index + 1)}"
  }
}
