variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "zone" {
  type = string
}

variable "vpc_name" {
  type = string
}

variable "subnet_name" {
  type = string
}

variable "subnet_cidr" {
  type = string
}

variable "vms" {
  type = map(object({
    ip   = string
    role = string
    tags = list(string)
  }))
}

variable "machine_type" {
  type = string
}

variable "image" {
  type = string
}

variable "disk_size" {
  type = number
}

variable "ssh_user" {
  type = string
}

variable "public_key_file" {
  description = "SSH public key file"
  type        = string
}

