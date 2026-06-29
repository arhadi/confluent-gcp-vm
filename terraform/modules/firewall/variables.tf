variable "network_name" {
  type = string
}

variable "firewall_name" {
  type = string
}

variable "source_ranges" {
  type = list(string)
}

variable "target_tags" {
  type = list(string)
  default = []
}

variable "tcp_ports" {
  type = list(string)
  default = []
}

variable "udp_ports" {
  type = list(string)
  default = []
}

variable "allow_icmp" {
  type    = bool
  default = true
}

variable "description" {
  type    = string
  default = ""
}
