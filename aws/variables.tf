variable "region" {
  description = "aws region to deploy the services to"
  default     = "ap-south-1"
  type        = string
}

variable "zone" {
  description = "aws zone in a given region"
  default     = "ap-south-1a"
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

variable "credentials" {
  description = "iam credentials"
  type        = string
}

variable "vpc" {
  description = "vpc region"
  type        = string
}

variable "subnet" {
  description = "vpc subnet"
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
  default     = "c5d.xlarge"
  type        = string
}

variable "bastion" {
  description = "bastion instance name"
  type        = string
}