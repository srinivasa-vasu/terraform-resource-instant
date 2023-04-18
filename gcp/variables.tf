variable "project" {
  description = "gcp project name"
  type        = string
}

variable "region" {
  description = "gcp region to deploy the services to"
  default     = "asia-south1"
  type        = string
}

variable "zone" {
  description = "gcp zone in a given region"
  default     = ""
  type        = string
}

variable "ssh_private_key" {
  description = "private key to connect to the instance"
  type        = string
}

variable "bastion_ssh_private_key" {
  description = "private key to connect to the bastion instance"
  type        = string
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
  default     = "c2d-standard-32"
  type        = string
}

variable "labels" {
  description = "labels to be added to the resources"
  type        = map(string)
}
