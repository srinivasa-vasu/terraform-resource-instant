variable "project" {
  description = "gcp project name"
  type        = string
}

variable "region" {
  description = "gcp region to deploy the services to"
  default     = "us-west1"
  type        = string
}

variable "ssh_private_key" {
  description = "private key to connect to the bastion/replicated instance"
  type        = string
}

variable "ssh_public_key" {
  description = "public key to be use when creating the bastion/replicated instance"
  type        = string
}

variable "ssh_user" {
  description = "user name to connect to bastion/replicated instance"
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

variable "replicas" {
  description = "instance count"
  type        = number
}