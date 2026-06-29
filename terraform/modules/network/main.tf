resource "google_compute_network" "this" {
  name                    = var.vpc_name
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "this" {
  name          = var.subnet_name
  region        = var.region
  ip_cidr_range = var.subnet_cidr
  network       = google_compute_network.this.id
}
