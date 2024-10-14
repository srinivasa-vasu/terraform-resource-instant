variable "region" {
  description = "aws region to deploy the services to"
  type        = string
  default     = ""
}

variable "zone" {
  description = "aws zone in a given region"
  type        = string
  default     = ""
}

variable "ssh_private_key" {
  description = "private key to connect to the instance"
  type        = string
  default     = ""
}

variable "bastion_ssh_private_key" {
  description = "private key to connect to the bastion instance"
  type        = string
  default     = ""
}

variable "ssh_keypair" {
  description = "key pair name managed by aws"
  type        = string
}

variable "ssh_user" {
  description = "user name to connect to instance"
  type        = string
  default     = "centos"
}

variable "bastion_ssh_user" {
  description = "user name to connect to instance"
  type        = string
  default     = "ubuntu"
}

variable "vpc" {
  description = "vpc region"
  type        = string
}

variable "subnet" {
  description = "vpc subnet"
  type        = string
  default     = ""
}

variable "subnet_prefix" {
  description = "vpc subnet prefix"
  type        = string
}

variable "instances" {
  description = "instance count"
  type        = number
}

variable "disks" {
  description = "disks/instance count"
  type        = number
}

variable "instance_type" {
  description = "instance types to create"
  default     = "c5d.xlarge"
  type        = string
}

variable "bastion" {
  description = "bastion instance name"
  type        = string
  default     = ""
}

variable "config" {
  description = "shared config file path"
  type        = string
}

variable "profile" {
  description = "aws profile name"
  type        = string
}

variable "labels" {
  description = "labels to be added to the resources"
  type        = map(string)
}

variable "ami_type" {
  description = "ami os distribution to use"
  type        = string
  default     = "almalinux8"
}

variable "disk_size" {
  description = "disk size to use in GB"
  type        = number
  default     = 50
}

variable "disk_type" {
  description = "disk type to use"
  type        = string
  default     = "gp3"
}

variable "disks_mount_points" {
  type = list(object({
    device_name   = string
    mount_point   = string
    device_suffix = string
  }))
  default = [
    {
      device_name   = "/dev/nvme"
      mount_point   = "/mnt/d"
      device_suffix = "n1"
    }
  ]
}

variable "security_group" {
  description = "security group to use"
  type        = string
}

variable "bastion_on" {
  description = "enable/disable bastion"
  type        = bool
  default     = false
}

variable "architecture" {
  description = "architecture to use"
  type        = string
  default     = "x86_64"
}

variable "ami_id" {
  description = "ami id to use"
  type        = string
  default     = ""
}

variable "identifier" {
  description = "identifier to use"
  type        = string
  default     = "sv"
}
