resource "google_compute_firewall" "this" {
  name        = var.firewall_name
  network     = var.network_name
  description = var.description
  source_ranges = var.source_ranges
  target_tags = var.target_tags

  dynamic "allow" {
    for_each = length(var.tcp_ports) > 0 ? [1] : []
    content {
      protocol = "tcp"
      ports = var.tcp_ports
    }
  }

  dynamic "allow" {
    for_each = length(var.udp_ports) > 0 ? [1] : []
    content {
      protocol = "udp"
      ports = var.udp_ports
    }
  }

  dynamic "allow" {
    for_each = var.allow_icmp ? [1] : []
    content {
      protocol = "icmp"
    }
  }
}
