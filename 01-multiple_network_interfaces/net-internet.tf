resource "google_compute_route" "default_internet" {
  name             = "internet-default"
  dest_range       = "0.0.0.0/0"
  network          = module.vpc["internet"].vpc.name
  next_hop_gateway = "default-internet-gateway"
  priority         = 1000
}

resource "google_compute_route" "default_appliance_internet" {
  for_each = toset([
    "10.0.0.0/8",
    "172.16.0.0/12",
    "192.168.0.0/16",
  ])
  name         = "internet-appliance-default-${replace(cidrhost(each.value, 0), ".", "-")}"
  dest_range   = each.value
  network      = module.vpc["internet"].vpc.name
  next_hop_ilb = google_compute_forwarding_rule.appliance_internet.id
  priority     = 1000
}

resource "google_compute_address" "appliance_lb_internet" {
  name         = "appliance-lb-internet"
  project      = var.project_id
  region       = var.region
  subnetwork   = google_compute_subnetwork.subnets["internet-appliance"].id
  address_type = "INTERNAL"
  address      = cidrhost(local.subnets["internet-appliance"].cidr, 2)
}

resource "google_compute_forwarding_rule" "appliance_internet" {
  name                  = "appliance-internet"
  project               = var.project_id
  region                = var.region
  network               = module.vpc["internet"].vpc.name
  subnetwork            = google_compute_subnetwork.subnets["internet-appliance"].name
  load_balancing_scheme = "INTERNAL"
  ip_protocol           = "TCP"
  backend_service       = google_compute_region_backend_service.appliance_internet.id
  all_ports             = true
  ip_address            = google_compute_address.appliance_lb_internet.address
}

resource "google_compute_region_backend_service" "appliance_internet" {
  name                  = "internet-appliance"
  region                = var.region
  network               = module.vpc["internet"].vpc.name
  protocol              = "TCP"
  load_balancing_scheme = "INTERNAL"
  health_checks = [
    google_compute_health_check.ssh.id,
  ]
  backend {
    group          = google_compute_instance_group.appliance.id
    balancing_mode = "CONNECTION"
  }
}

resource "google_compute_router" "internet" {
  name    = "internet"
  project = var.project_id
  region  = var.region
  network = module.vpc["internet"].vpc.id

  bgp {
    asn = 64514
  }
}

resource "google_compute_router_nat" "internet" {
  name                               = "internet"
  project                            = var.project_id
  router                             = google_compute_router.internet.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}
