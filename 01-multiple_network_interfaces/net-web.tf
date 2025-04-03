resource "google_compute_route" "default_web_appliance" {
  name         = "web-default"
  dest_range   = "0.0.0.0/0"
  network      = module.vpc["web"].vpc.name
  next_hop_ilb = google_compute_forwarding_rule.appliance_web.id
  priority     = 1000
}

resource "google_compute_address" "appliance_lb_web" {
  name         = "appliance-lb-web"
  project      = var.project_id
  region       = var.region
  subnetwork   = google_compute_subnetwork.subnets["web-appliance"].id
  address_type = "INTERNAL"
  address      = cidrhost(local.subnets["web-appliance"].cidr, 2)
}

resource "google_compute_forwarding_rule" "appliance_web" {
  name                  = "appliance-web"
  project               = var.project_id
  region                = var.region
  network               = module.vpc["web"].vpc.name
  subnetwork            = google_compute_subnetwork.subnets["web-appliance"].name
  load_balancing_scheme = "INTERNAL"
  ip_protocol           = "TCP"
  backend_service       = google_compute_region_backend_service.appliance_web.id
  all_ports             = true
  ip_address            = google_compute_address.appliance_lb_web.address
}

resource "google_compute_region_backend_service" "appliance_web" {
  name                  = "web-appliance"
  region                = var.region
  network               = module.vpc["web"].vpc.name
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
