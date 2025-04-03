resource "google_project_service" "services" {
  for_each = toset([
    "compute.googleapis.com",
    "iam.googleapis.com",
    "networkmanagement.googleapis.com",
  ])
  project            = var.project_id
  service            = each.value
  disable_on_destroy = false
}

resource "terraform_data" "network_setup" {
  depends_on = [
    google_compute_instance.appliance,
    google_compute_route.default_internet,
    google_compute_route.default_backend_appliance,
    google_compute_route.default_web_appliance,
    google_compute_route.default_onprem_appliance,
    google_compute_route.default_appliance_internet,
  ]
}
