variable "project" {
  description = "gcp project name"
  type        = string
}

variable "region" {
  description = "gcp region to deploy the services to"
  type        = string
  default     = ""
}

variable "zone" {
  description = "gcp zone in a given region"
  type        = string
  default     = ""
}

variable "ssh_private_key" {
  description = "private key to connect to the instance"
  type        = string
}

variable "bastion_ssh_private_key" {
  description = "private key to connect to the bastion instance"
  type        = string
  default     = ""
}

variable "ssh_public_key" {
  description = "public key to be added to the authorized_keys file"
  type        = string
}

variable "ssh_user" {
  description = "user name to connect to instance"
  type        = string
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

variable "disk_type" {
  description = "disk type"
  type        = string
  default     = "pd-balanced"
}

variable "disk_size" {
  description = "value in GB"
  type        = number
  default     = 50
}

variable "instance_type" {
  description = "instance types to create"
  default     = "n2-standard-4"
  type        = string
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
      device_name = "/dev/"
      mount_point = "/mnt/d"
    }
  ]
}

variable "letters" {
  type    = list(string)
  default = ["b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z"]
}

variable "numbers" {
  type    = list(string)
  default = ["2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12", "13", "14", "15", "16", "17", "18", "19", "20", "21", "22", "23", "24", "25", "26", "27"]
}

variable "bastion" {
  description = "bastion instance name"
  type        = string
  default     = ""
}

variable "bastion_on" {
  description = "enable/disable bastion"
  type        = bool
  default     = false
}

variable "image_type" {
  description = "os distribution to use"
  type        = string
  default     = "almalinux8"
}

variable "tags" {
  description = "tags to be added to the resources"
  type        = list(string)
  default     = []
}
