resource "google_compute_route" "default_backend_appliance" {
  name         = "backend-default"
  dest_range   = "0.0.0.0/0"
  network      = module.vpc["backend"].vpc.name
  next_hop_ilb = google_compute_forwarding_rule.appliance_backend.id
  priority     = 1000
}

resource "google_compute_address" "appliance_lb_backend" {
  name         = "appliance-lb-backend"
  project      = var.project_id
  region       = var.region
  subnetwork   = google_compute_subnetwork.subnets["backend-appliance"].id
  address_type = "INTERNAL"
  address      = cidrhost(local.subnets["backend-appliance"].cidr, 2)
}

resource "google_compute_forwarding_rule" "appliance_backend" {
  name                  = "appliance-backend"
  project               = var.project_id
  region                = var.region
  network               = module.vpc["backend"].vpc.name
  subnetwork            = google_compute_subnetwork.subnets["backend-appliance"].name
  load_balancing_scheme = "INTERNAL"
  ip_protocol           = "TCP"
  backend_service       = google_compute_region_backend_service.appliance_backend.id
  all_ports             = true
  ip_address            = google_compute_address.appliance_lb_backend.address
}

resource "google_compute_region_backend_service" "appliance_backend" {
  name                  = "backend-appliance"
  region                = var.region
  network               = module.vpc["backend"].vpc.name
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
