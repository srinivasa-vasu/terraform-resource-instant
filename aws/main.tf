locals {
  disks_count = (var.disks * var.instances)
  subnet      = var.subnet != "" ? var.subnet : "${var.subnet_prefix}*" # if subnet is not provided, use the prefix
  # dev_ids     = ["b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z"]
  dev_ids = ["e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z"]
  # ingress     = "${chomp(data.http.localip.body)}/32"

  disks_mounts = [for index in range(var.disks) : [
    "${var.disks_mount_points[0].device_name}${index + 1}${var.disks_mount_points[0].device_suffix}", "${var.disks_mount_points[0].mount_point}${index}"
  ]]

  ami_list = [
    {
      "type" = "ubuntu18"
      "path" = "ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-*"
      "user" = "ubuntu"
    },
    {
      "type" = "ubuntu20"
      "path" = "ubuntu/images/hvm-ssd/ubuntu-focal-20.04-*"
      "user" = "ubuntu"
    },
    {
      "type" = "ubuntu22"
      "path" = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-*"
      "user" = "ubuntu"
    },
    {
      "type" = "centos7"
      "path" = "centos/7/images/CentOS-7-x86_64-GenericCloud-*"
      "user" = ""
    },
    {
      "type" = "almalinux8"
      "path" = "AlmaLinux OS 8*"
      "user" = ""
    },
    {
      "type" = "almalinux9"
      "path" = "AlmaLinux OS 9*"
      "user" = ""
    },
    {
      "type" = "rhel8"
      "path" = "RHEL-8*"
      "user" = ""
    },
    {
      "type" = "rhel9"
      "path" = "RHEL-9*"
      "user" = ""
    },
    {
      "type" = "amazonlinux2"
      "path" = "amzn2-ami-hvm-2.0.*-x86_64-gp2"
      "user" = ""
    }
  ]

  selected_ami = lookup({ for val in local.ami_list :
    0 => val if val.type == var.ami_type }, 0,
    {
      "type" = "almalinux8"
      "path" = "AlmaLinux OS 8*"
  })

  post_create = templatefile("../shared/scripts/instance_ops.tpl", {
    disks    = join(" ", [for disk in local.disks_mounts : join(",", disk)])
    os_image = var.ami_type
  })
}

provider "aws" {
  region  = var.region
  profile = var.profile
}

# Workstation public ip to allow access to. It identies the IP where this gets executed and adds it to the
# firewall rule in the firewall block
data "http" "localip" {
  url = "http://ipv4.icanhazip.com"
}

data "aws_vpc" "vpc" {
  filter {
    name   = "tag:Name"
    values = [var.vpc]
  }
}

data "aws_availability_zones" "zones" {
  state = "available"
}

data "aws_subnets" "subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.vpc.id]
  }

  filter {
    name   = "tag:Name"
    values = [local.subnet]
  }
}

data "aws_instance" "bastion" {
  count = var.bastion_on ? 1 : 0
  filter {
    name   = "tag:Name"
    values = [var.bastion]
  }
  filter {
    name   = "availability-zone"
    values = [var.zone]
  }
}

data "aws_ami" "ami" {
  most_recent = true
  owners      = ["aws-marketplace", "amazon"]

  filter {
    name   = "name"
    values = [local.selected_ami.path]
  }

  filter {
    name   = "architecture"
    values = ["${var.architecture}"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

data "aws_security_group" "sg" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.vpc.id]
  }

  filter {
    name   = "tag:Name"
    values = [var.security_group]
  }
}

resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  key_name   = var.ssh_keypair
  public_key = tls_private_key.ssh_key.public_key_openssh
}

resource "aws_instance" "instances" {
  count = var.instances
  ami   = var.ami_id != "" ? var.ami_id : data.aws_ami.ami.id
  # associate_public_ip_address = var.associate_public_ip_address
  instance_type          = var.instance_type
  key_name               = aws_key_pair.generated_key.key_name
  availability_zone      = var.zone != "" ? var.zone : element(data.aws_availability_zones.zones.names, count.index)
  subnet_id              = var.subnet != "" ? data.aws_subnets.subnets.ids[0] : element(data.aws_subnets.subnets.ids, count.index)
  vpc_security_group_ids = [data.aws_security_group.sg.id]
  root_block_device {
    volume_size = 50
    tags        = var.labels
  }

  tags = (merge(
    var.labels,
    {
      "Name" = "${var.identifier}-n${format("%d", count.index + 1)}"
    }
  ))

  lifecycle {
    create_before_destroy = true
  }
}

resource "null_resource" "format_attached_disks_bastion_on" {
  count = var.bastion_on ? ((var.disks > 0) ? var.instances : 0) : 0
  depends_on = [
    aws_volume_attachment.attach_disks
  ]
  connection {
    bastion_host        = data.aws_instance.bastion[*].public_ip
    bastion_private_key = file(var.ssh_private_key)
    bastion_user        = var.bastion_ssh_user
    host                = aws_instance.instances[count.index].private_ip
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
  count = var.bastion_on ? 0 : ((var.disks > 0) ? var.instances : 0)
  depends_on = [
    aws_volume_attachment.attach_disks
  ]
  connection {
    host        = aws_instance.instances[count.index].private_ip
    type        = "ssh"
    user        = local.selected_ami.user != "" ? local.selected_ami.user : var.ssh_user
    private_key = tls_private_key.ssh_key.private_key_pem
  }

  provisioner "remote-exec" {
    inline = [
      local.post_create
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
  availability_zone = var.zone != "" ? var.zone : element(data.aws_availability_zones.zones.names, floor(count.index / var.disks))
  size              = var.disk_size
  type              = var.disk_type
  # provisioned_iops = 100000
  tags = (merge(
    var.labels,
    {
      "Name" = "${var.identifier}-n${format("%d", count.index + 1)}"
    }
  ))
}
