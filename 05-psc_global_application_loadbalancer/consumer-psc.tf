resource "google_compute_region_network_endpoint_group" "consumer" {
  for_each = var.consumer_subnets
  name     = "consumer-${each.key}"
  project  = var.project_id
  region   = each.key

  network_endpoint_type = "PRIVATE_SERVICE_CONNECT"
  psc_target_service    = google_compute_service_attachment.producer[each.key].self_link
  psc_data {
    producer_port = "80"
  }
  network    = module.vpc_consumer.vpc.self_link
  subnetwork = google_compute_subnetwork.consumer[each.key].self_link
}
