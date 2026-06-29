project_id      = "lab001-498020"
region          = "asia-southeast1"
zone            = "asia-southeast1-a"
vpc_name        = "confluent-vpc"
subnet_name     = "confluent-subnet"
subnet_cidr     = "10.128.0.0/24"
machine_type    = "e2-medium"
image           = "ubuntu-os-cloud/ubuntu-minimal-2404-lts-amd64"
disk_size       = 30
ssh_user        = "ubuntu"
public_key_file = "~/.ssh/id_ed25519.pub"

vms = {
  ansible = {
    ip          = "10.128.0.20"
    role        = "automation"
    environment = "dev"
    tags        = ["ssh"]
  }

  broker01 = {
    ip          = "10.128.0.21"
    role        = "broker"
    environment = "dev"
    tags        = ["kafka"]
  }

  broker02 = {
    ip          = "10.128.0.22"
    role        = "broker"
    environment = "dev"
    tags        = ["kafka"]
  }

  broker03 = {
    ip          = "10.128.0.23"
    role        = "broker"
    environment = "dev"
    tags        = ["kafka"]
  }
}

