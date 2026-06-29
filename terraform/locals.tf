locals {
  common_labels = {
    owner       = "platform"
    environment = "lab"
    managed_by  = "terraform"
    project     = "confluent"
  }

  common_tags = [
    "ssh"
  ]
}
