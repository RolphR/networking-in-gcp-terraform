resource "google_compute_address" "producer_ilb" {
  for_each     = var.producer_subnets
  name         = "producer-ilb-${each.key}"
  project      = var.project_id
  region       = each.key
  subnetwork   = google_compute_subnetwork.producer[each.key].id
  address_type = "INTERNAL"
  address      = cidrhost(each.value, 2)
}

resource "google_compute_forwarding_rule" "producer" {
  for_each = var.producer_subnets
  name     = "producer-${each.key}"
  project  = var.project_id
  region   = each.key

  load_balancing_scheme = "INTERNAL_MANAGED"
  allow_global_access   = true # Required for cross-regional and global access of this PSC attachment
  no_automate_dns_zone  = true
  target                = google_compute_region_target_http_proxy.producer[each.key].id
  port_range            = "80"
  network               = module.vpc_producer.vpc.name
  subnetwork            = google_compute_subnetwork.producer[each.key].name

  # There is an implicit dependency on INTERNAL_MANAGED forwarding_rules and the REGIONAL_MANAGED_PROXY subnet (in the same region) with state ACTIVE
  depends_on = [
    google_compute_subnetwork.producer_proxy,
  ]
}

resource "google_compute_region_target_http_proxy" "producer" {
  for_each = var.producer_subnets
  name     = "producer-${each.key}"
  project  = var.project_id
  region   = each.key
  url_map  = google_compute_region_url_map.producer[each.key].id
}

resource "google_compute_region_url_map" "producer" {
  for_each        = var.producer_subnets
  name            = "producer-${each.key}"
  project         = var.project_id
  region          = each.key
  default_service = google_compute_region_backend_service.producer[each.key].id
}

resource "google_compute_region_backend_service" "producer" {
  for_each              = var.psc_subnets
  name                  = "producer-${each.key}"
  project               = var.project_id
  region                = each.key
  load_balancing_scheme = "INTERNAL_MANAGED"
  port_name             = "http"
  protocol              = "HTTP"
  timeout_sec           = 10
  health_checks         = [google_compute_health_check.default.id]
  backend {
    group           = google_compute_region_instance_group_manager.producer[each.key].instance_group
    balancing_mode  = "UTILIZATION"
    max_utilization = 0.8
    capacity_scaler = 1
  }
}

resource "google_compute_health_check" "default" {
  name               = "http-health-check"
  project            = var.project_id
  timeout_sec        = 1
  check_interval_sec = 1

  http_health_check {
    port         = 80
    request_path = "/"
  }
}
