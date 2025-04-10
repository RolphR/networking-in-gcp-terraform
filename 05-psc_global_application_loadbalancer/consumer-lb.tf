resource "google_compute_global_address" "loadbalancer" {
  name         = "loadbalancer"
  project      = var.project_id
  ip_version   = "IPV4"
  address_type = "EXTERNAL"
}

locals {
  # Ensure the domain name does NOT have a trailing dot
  domain_name = trimsuffix("${google_compute_global_address.loadbalancer.address}.nip.io", ".")
  regional_domains = {
    for region, cidr in var.producer_subnets :
    region => "${region}.${local.domain_name}"
  }
}

resource "google_compute_global_forwarding_rule" "loadbalancer" {
  name                  = "loadbalancer"
  project               = var.project_id
  target                = google_compute_target_https_proxy.loadbalancer.id
  port_range            = 443
  ip_address            = google_compute_global_address.loadbalancer.id
  load_balancing_scheme = "EXTERNAL"
}

resource "google_compute_managed_ssl_certificate" "loadbalancer" {
  name    = "loadbalancer"
  project = var.project_id

  managed {
    # Ensure there is a trailing dot behind each certificate
    domains = formatlist("%s.", sort(flatten([
      local.domain_name,
      values(local.regional_domains)
    ])))
  }
}

resource "google_compute_target_https_proxy" "loadbalancer" {
  name    = "loadbalancer"
  project = var.project_id
  url_map = google_compute_url_map.loadbalancer.id
  ssl_certificates = [
    google_compute_managed_ssl_certificate.loadbalancer.id
  ]
}

resource "google_compute_url_map" "loadbalancer" {
  name    = "loadbalancer"
  project = var.project_id

  default_service = google_compute_backend_service.global.id

  host_rule {
    hosts        = [local.domain_name]
    path_matcher = "global"
  }
  # Expose regional endpoints for each region we host producers in
  dynamic "host_rule" {
    for_each = var.consumer_subnets
    iterator = region
    content {
      hosts        = [local.regional_domains[region.key]]
      path_matcher = "regional-${region.key}"
    }
  }

  path_matcher {
    name            = "global"
    default_service = google_compute_backend_service.global.id
  }

  dynamic "path_matcher" {
    for_each = var.consumer_subnets
    iterator = region
    content {
      name            = "regional-${region.key}"
      default_service = google_compute_backend_service.consumer[region.key].id
    }
  }
}

resource "google_compute_backend_service" "global" {
  name        = "consumer-global"
  project     = var.project_id
  port_name   = "http"
  protocol    = "HTTP"
  timeout_sec = 10
  # Add each regional NEG to the global backend service
  dynamic "backend" {
    for_each = var.consumer_subnets
    content {
      group = google_compute_region_network_endpoint_group.consumer[backend.key].id
    }
  }
}

resource "google_compute_backend_service" "consumer" {
  for_each              = var.psc_subnets
  name                  = "consumer-${each.key}"
  project               = var.project_id
  load_balancing_scheme = "EXTERNAL_MANAGED"
  port_name             = "http"
  protocol              = "HTTP"
  timeout_sec           = 10
  backend {
    group = google_compute_region_network_endpoint_group.consumer[each.key].id
  }
}
