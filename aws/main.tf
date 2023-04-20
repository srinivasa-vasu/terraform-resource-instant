locals {
  disks_count = (var.disks * var.instances)
  ingress     = "${chomp(data.http.localip.body)}/32"

  disks_mounts = [for index in range(var.disks) : [
    "${var.disks_mount_points[0].device_name}${index + 2}${var.disks_mount_points[0].device_suffix}", "${var.disks_mount_points[0].mount_point}${index}"
  ]]

  ami_list = [
    {
      "type" = "ubuntu18"
      "path" = "ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"
    },
    {
      "type" = "ubuntu20"
      "path" = "ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"
    },
    {
      "type" = "ubuntu22"
      "path" = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-daily-*"
    },
    {
      "type" = "centos7"
      "path" = "centos/7/images/CentOS-7-x86_64-GenericCloud-*"
    },
    {
      "type" = "almalinux8"
      "path" = "AlmaLinux OS 8*"
    },
    {
      "type" = "almalinux9"
      "path" = "AlmaLinux OS 9*"
    },
    {
      "type" = "rhel8"
      "path" = "RHEL-8*"
    },
    {
      "type" = "amazonlinux2"
      "path" = "amzn2-ami-hvm-2.0.*-x86_64-gp2"
    }
  ]

  selected_ami = lookup({ for val in local.ami_list :
    0 => val if val.type == var.ami_type }, 0,
    {
      "type" = "almalinux8"
      "path" = "AlmaLinux OS 8*"
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
    values = ["${var.vpc}"]
  }
}

data "aws_availability_zones" "zones" {
  state = "available"
}

data "aws_subnets" "selected" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.vpc.id]
  }
  filter {
    name   = "tag:Name"
    values = ["*pvt*"]
  }
}

data "aws_instance" "bastion" {
  count = var.bastion_on ? 1 : 0
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
    name   = "name"
    values = [local.selected_ami.path]
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
    name   = "vpc-id"
    values = [data.aws_vpc.vpc.id]
  }

  filter {
    name   = "tag:Name"
    values = [var.security_group]
  }
}

data "template_file" "post_create" {
  template = file("../shared/scripts/instance_ops.tpl")

  vars = {
    disks = join(" ", [for disk in local.disks_mounts : join(",", disk)])
    os_image = var.ami_type
  }
}

resource "aws_instance" "instances" {
  count = var.instances
  ami   = data.aws_ami.ami.id
  # associate_public_ip_address = var.associate_public_ip_address
  instance_type          = var.instance_type
  key_name               = var.ssh_keypair
  availability_zone      = var.zone != "" ? var.zone : element(data.aws_availability_zones.zones.names, count.index)
  subnet_id              = var.subnet != "" ? var.subnet : element(data.aws_subnets.selected.ids, count.index)
  vpc_security_group_ids = data.aws_security_groups.sg.ids
  root_block_device {
    volume_size = 50
    tags        = var.labels
  }

  tags = var.labels

  lifecycle {
    create_before_destroy = true
  }
}

resource "null_resource" "format_attached_disks_bastion_on" {
  count = var.bastion_on ? var.instances : 0
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
      data.template_file.post_create.rendered
    ]
  }
}

resource "null_resource" "format_attached_disks_bastion_off" {
  count = var.bastion_on ? 0 : var.instances
  depends_on = [
    aws_volume_attachment.attach_disks
  ]
  connection {
    host        = aws_instance.instances[count.index].private_ip
    type        = "ssh"
    user        = var.ssh_user
    private_key = file(var.ssh_private_key)
  }

  provisioner "remote-exec" {
    inline = [
      data.template_file.post_create.rendered
    ]
  }
}

resource "aws_volume_attachment" "attach_disks" {
  device_name = local.disks_mounts[count.index].device_name
  volume_id   = aws_ebs_volume.disks[count.index].id
  instance_id = aws_instance.instances[floor(count.index / var.disks)].id
  count       = local.disks_count
}

resource "aws_ebs_volume" "disks" {
  count             = local.disks_count
  availability_zone = var.zone != "" ? var.zone : element(data.aws_availability_zones.zones.names, floor(count.index / var.disks))
  size              = var.disk_size
  tags              = var.labels
  type              = var.disk_type
  # provisioned_iops = 100000
  # tags = {
  #   Name = "${var.identifier}-n${format("%d", count.index + 1)}"
  # }
}
