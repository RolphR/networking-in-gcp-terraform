module "vpc_producer" {
  source     = "../modules/vpc"
  project_id = var.project_id
  name       = "producer"
}

resource "google_compute_subnetwork" "producer_psc" {
  for_each      = var.psc_subnets
  name          = "producer-psc-${each.key}"
  project       = var.project_id
  region        = each.key
  ip_cidr_range = each.value
  network       = module.vpc_producer.vpc.id
  purpose       = "PRIVATE_SERVICE_CONNECT"
}

resource "google_compute_subnetwork" "producer" {
  for_each      = var.producer_subnets
  name          = "producer-main-${each.key}"
  project       = var.project_id
  region        = each.key
  ip_cidr_range = each.value
  network       = module.vpc_producer.vpc.id
}

resource "google_compute_subnetwork" "producer_proxy" {
  for_each      = var.proxy_subnets
  name          = "producer-proxy-${each.key}"
  project       = var.project_id
  region        = each.key
  ip_cidr_range = each.value
  network       = module.vpc_producer.vpc.id
  purpose       = "REGIONAL_MANAGED_PROXY"
  role          = "ACTIVE"
}

# An internal http (application) loadbalancer uses a proxy subnet.
# Allow instances in these regional proxy subnets to connect to all instances
resource "google_compute_firewall" "producer_allow_proxy_http" {
  name          = "producer-allow-proxy-http"
  project       = var.project_id
  direction     = "INGRESS"
  network       = module.vpc_producer.vpc.id
  source_ranges = sort(values(var.proxy_subnets))
  allow {
    protocol = "tcp"
    ports = [
      "80",
    ]
  }
}
