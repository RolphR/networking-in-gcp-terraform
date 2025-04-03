resource "google_network_management_connectivity_test" "webserver_onprem" {
  name       = "webserver-onprem"
  protocol   = "ICMP"
  round_trip = true
  source {
    instance = google_compute_instance.webserver.id
  }
  destination {
    instance = google_compute_instance.onprem.id
  }
  depends_on = [
    google_project_service.services,
  ]
}

resource "google_network_management_connectivity_test" "database_onprem" {
  name       = "database-onprem"
  protocol   = "ICMP"
  round_trip = true
  source {
    instance = google_compute_instance.database.id
  }
  destination {
    instance = google_compute_instance.onprem.id
  }
  depends_on = [
    google_project_service.services,
  ]
}

resource "google_network_management_connectivity_test" "webserver_database" {
  name       = "webserver-database"
  protocol   = "ICMP"
  round_trip = true
  source {
    instance = google_compute_instance.webserver.id
  }
  destination {
    instance = google_compute_instance.database.id
  }
  depends_on = [
    google_project_service.services,
  ]
}
