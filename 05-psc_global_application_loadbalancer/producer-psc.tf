resource "google_compute_service_attachment" "producer" {
  for_each    = var.psc_subnets
  name        = "producer-${each.key}"
  project     = var.project_id
  region      = each.key
  description = "A service attachment in ${each.key}"

  domain_names          = []
  enable_proxy_protocol = false
  connection_preference = "ACCEPT_AUTOMATIC"
  nat_subnets           = [google_compute_subnetwork.producer_psc[each.key].id]
  target_service        = google_compute_forwarding_rule.producer[each.key].id
}
