resource "google_compute_route" "default_internet" {
  name             = "producer-default"
  dest_range       = "0.0.0.0/0"
  network          = module.vpc_producer.vpc.name
  next_hop_gateway = "default-internet-gateway"
  priority         = 1000
}

resource "google_compute_router" "nat" {
  for_each = var.producer_subnets
  name     = "nat-${each.key}"
  project  = var.project_id
  region   = each.key
  network  = module.vpc_producer.vpc.id

  bgp {
    asn = 64514
  }
}

resource "google_compute_router_nat" "nat" {
  for_each                           = var.producer_subnets
  name                               = "nat-${each.key}"
  project                            = var.project_id
  router                             = google_compute_router.nat[each.key].name
  region                             = each.key
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}
