resource "google_compute_route" "default_onprem_appliance" {
  name         = "onprem-default"
  dest_range   = "0.0.0.0/0"
  network      = module.vpc["onprem"].vpc.name
  next_hop_ilb = google_compute_forwarding_rule.appliance_onprem.id
  priority     = 1000
}

resource "google_compute_address" "appliance_lb_onprem" {
  name         = "appliance-lb-onprem"
  project      = var.project_id
  region       = var.region
  subnetwork   = google_compute_subnetwork.subnets["onprem-appliance"].id
  address_type = "INTERNAL"
  address      = cidrhost(local.subnets["onprem-appliance"].cidr, 2)
}

resource "google_compute_forwarding_rule" "appliance_onprem" {
  name                  = "appliance-onprem"
  project               = var.project_id
  region                = var.region
  network               = module.vpc["onprem"].vpc.name
  subnetwork            = google_compute_subnetwork.subnets["onprem-appliance"].name
  load_balancing_scheme = "INTERNAL"
  ip_protocol           = "TCP"
  backend_service       = google_compute_region_backend_service.appliance_onprem.id
  all_ports             = true
  ip_address            = google_compute_address.appliance_lb_onprem.address
}

resource "google_compute_region_backend_service" "appliance_onprem" {
  name                  = "appliance-onprem"
  region                = var.region
  network               = module.vpc["onprem"].vpc.name
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

resource "google_compute_firewall" "allow_http_from_webserver_to_onprem" {
  name      = "onprem-allow-http-from-webserver-to-onprem"
  project   = var.project_id
  direction = "INGRESS"
  network   = module.vpc["onprem"].vpc.name
  source_ranges = [
    "${google_compute_instance.webserver.network_interface[0].network_ip}/32",
  ]
  target_service_accounts = [
    google_service_account.onprem.email,
  ]
  allow {
    protocol = "tcp"
    ports = [
      "80"
    ]
  }
}
