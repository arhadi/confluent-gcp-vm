module "network" {
  source      = "./modules/network"
  vpc_name    = var.vpc_name
  subnet_name = var.subnet_name
  region      = var.region
  subnet_cidr = var.subnet_cidr

}

module "fw_ssh" {
  source        = "./modules/firewall"
  firewall_name = "allow-ssh"
  network_name  = module.network.network_name
  source_ranges = [
    "0.0.0.0/0"
  ]

  target_tags = [
    "ssh"
  ]

  tcp_ports = [
    "22"
  ]

  description = "Allow SSH"
}

module "fw_kafka" {
  source        = "./modules/firewall"
  firewall_name = "allow-kafka"
  network_name  = module.network.network_name

  source_ranges = [
    "10.128.0.0/24"
  ]

  target_tags = [
    "kafka"
  ]

  tcp_ports = [
    "9092",
    "9093"
  ]

  description = "Kafka Broker and KRaft"
}

module "fw_jmx" {
  source        = "./modules/firewall"
  firewall_name = "allow-jmx"
  network_name  = module.network.network_name
  source_ranges = [
    "10.128.0.0/24"
  ]

  target_tags = [
    "kafka"
  ]

  tcp_ports = [
    "9101"
  ]
}

module "fw_icmp" {
  source        = "./modules/firewall"
  firewall_name = "allow-icmp"
  network_name  = module.network.network_name

  source_ranges = [
    "10.128.0.0/24"
  ]

  target_tags = [
    "ssh",
    "kafka"
  ]

  allow_icmp = true

}

module "vm" {
  for_each = var.vms

  source = "./modules/compute"

  vm_name         = each.key
  internal_ip     = each.value.ip
  zone            = var.zone
  machine_type    = var.machine_type
  image           = var.image
  disk_size       = var.disk_size
  network         = module.network.network_id
  subnetwork      = module.network.subnet_id
  ssh_user        = var.ssh_user
  public_key_file = var.public_key_file

  tags = each.value.tags

  labels = {
    role        = each.value.role
    environment = "dev"
    managed_by  = "terraform"
  }
}

