module "vpc_a" {
  source     = "../modules/vpc"
  project_id = var.project_id
  name       = "vpc-a"
}

resource "google_compute_subnetwork" "subnet_a" {
  name                     = "subnet-a"
  ip_cidr_range            = var.subnet_a
  region                   = var.region
  network                  = module.vpc_a.vpc.id
  private_ip_google_access = true
}


module "vpc_b" {
  source     = "../modules/vpc"
  project_id = var.project_id
  name       = "vpc-b"
}

resource "google_compute_subnetwork" "subnet_b" {
  name                     = "subnet-b"
  ip_cidr_range            = var.subnet_b
  region                   = var.region
  network                  = module.vpc_b.vpc.id
  private_ip_google_access = true
}

module "vpc_c" {
  source     = "../modules/vpc"
  project_id = var.project_id
  name       = "vpc-c"
}

resource "google_compute_subnetwork" "subnet_c" {
  name                     = "subnet-c"
  ip_cidr_range            = var.subnet_c
  region                   = var.region
  network                  = module.vpc_c.vpc.id
  private_ip_google_access = true
}

resource "google_compute_firewall" "healthchecks_ssh_vpc_a" {
  name          = "vpc-a-allow-hc"
  project       = var.project_id
  direction     = "INGRESS"
  network       = module.vpc_a.vpc.id
  source_ranges = ["130.211.0.0/22", "35.191.0.0/16", "35.235.240.0/20"]
  allow {
    protocol = "tcp"
    ports = [
      "22",
    ]
  }
}

resource "google_compute_firewall" "healthchecks_ssh_vpc_b" {
  name          = "vpc-ballow-hc"
  project       = var.project_id
  direction     = "INGRESS"
  network       = module.vpc_b.vpc.id
  source_ranges = ["130.211.0.0/22", "35.191.0.0/16", "35.235.240.0/20"]
  allow {
    protocol = "tcp"
    ports = [
      "22",
    ]
  }
}

resource "google_compute_firewall" "healthchecks_ssh_vpc_c" {
  name          = "vpc-c-allow-hc"
  project       = var.project_id
  direction     = "INGRESS"
  network       = module.vpc_c.vpc.id
  source_ranges = ["130.211.0.0/22", "35.191.0.0/16", "35.235.240.0/20"]
  allow {
    protocol = "tcp"
    ports = [
      "22",
    ]
  }
}

resource "google_compute_firewall" "ping_vpc_a" {
  name          = "vpc-a-allow-ping"
  project       = var.project_id
  direction     = "INGRESS"
  network       = module.vpc_a.vpc.id
  source_ranges = ["0.0.0.0/0"]
  allow {
    protocol = "icmp"
  }
}

resource "google_compute_firewall" "ping_vpc_b" {
  name          = "vpc-b-allow-ping"
  project       = var.project_id
  direction     = "INGRESS"
  network       = module.vpc_b.vpc.id
  source_ranges = ["0.0.0.0/0"]
  allow {
    protocol = "icmp"
  }
}

resource "google_compute_firewall" "ping_vpc_c" {
  name          = "vpc-c-allow-ping"
  project       = var.project_id
  direction     = "INGRESS"
  network       = module.vpc_c.vpc.id
  source_ranges = ["0.0.0.0/0"]
  allow {
    protocol = "icmp"
  }
}
