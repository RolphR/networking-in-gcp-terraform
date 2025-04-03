resource "google_project_service" "services" {
  for_each = toset([
    "networkmanagement.googleapis.com",
  ])
  project            = var.project_id
  service            = each.value
  disable_on_destroy = false
}
