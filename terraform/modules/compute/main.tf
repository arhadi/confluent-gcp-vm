resource "google_compute_instance" "this" {
  name         = var.vm_name
  zone         = var.zone
  machine_type = var.machine_type
  tags = var.tags
  labels = var.labels

  boot_disk {
    initialize_params {
      image = var.image
      size  = var.disk_size
    }
  }

  network_interface {
    network    = var.network
    subnetwork = var.subnetwork
    network_ip = var.internal_ip
    dynamic "access_config" {
      for_each = var.assign_public_ip ? [1] : []
      content {}
    }
  }

  metadata = {
    ssh-keys = "${var.ssh_user}:${file(pathexpand(var.public_key_file))}"
  }
}
