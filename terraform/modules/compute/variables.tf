variable "vm_name" {
  type = string
}

variable "zone" {
  type = string
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

variable "network" {
  type = string
}

variable "subnetwork" {
  type = string
}

variable "internal_ip" {
  type = string
}

variable "assign_public_ip" {
  type    = bool
  default = true
}

variable "ssh_user" {
  type = string
}

variable "public_key_file" {
  type = string
}

variable "tags" {
  type    = list(string)
  default = []
}

variable "labels" {
  type    = map(string)
  default = {}
}
