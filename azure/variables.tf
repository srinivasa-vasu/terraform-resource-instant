variable "rg" {
  description = "resource group"
  type        = string
}

variable "subscription_id" {
  description = "subscription id"
  type        = string
}

variable "tenant_id" {
  description = "tenant id"
  type        = string
}

variable "region" {
  description = "azure region to deploy the services to"
  type        = string
}

variable "zone" {
  description = "azure zone in a given region"
  type        = string
}

variable "ssh_private_key" {
  description = "private key to connect to the instance"
  type        = string
}

# variable "bastion_ssh_private_key" {
#   description = "private key to connect to the bastion instance"
#   type        = string
# }

variable "ssh_public_key" {
  description = "public key to add to the authorized_hosts"
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

variable "vnet" {
  description = "virtual network"
  type        = string
}

variable "subnet" {
  description = "vpc subnet"
  type        = string
}

variable "nsg" {
  description = "network security group name"
  type        = string
}

variable "identifier" {
  description = "run identifier"
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
  default     = "Standard_D2s_v4"
  type        = string
}

variable "bastion" {
  description = "bastion instance public ip"
  type        = string
}

variable "disk_size" {
  description = "disk size to use in GB"
  type        = number
  default     = 50
}

variable "disk_type" {
  description = "disk type to use"
  type        = string
  default     = "Standard_LRS"
}

variable "bastion_on" {
  description = "enable/disable bastion"
  type        = bool
  default     = false
}

variable "labels" {
  description = "labels to be added to the resources"
  type        = map(string)
}

variable "disks_mount_points" {
  type = list(object({
    device_name = string
    mount_point = string
  }))
  default = [
    {
      device_name = "/dev/sd"
      mount_point = "/disks/ssd"
    }
  ]
}
