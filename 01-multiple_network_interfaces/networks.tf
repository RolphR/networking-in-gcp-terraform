module "vpc" {
  for_each   = var.networks
  source     = "../modules/vpc"
  project_id = var.project_id
  name       = each.key
  router_service_accounts = [
    google_service_account.appliance.email,
  ]
}

locals {
  subnets = merge([
    for network, subnets in var.subnets :
    {
      for subnet, cidr in subnets :
      "${network}-${subnet}" => {
        cidr    = cidr
        network = module.vpc[network].vpc.id
      }
    }
  ]...)
}

resource "google_compute_subnetwork" "subnets" {
  for_each                 = local.subnets
  name                     = each.key
  ip_cidr_range            = each.value.cidr
  region                   = var.region
  network                  = each.value.network
  private_ip_google_access = true
}

resource "google_compute_health_check" "ssh" {
  name = "ssh"

  timeout_sec        = 1
  check_interval_sec = 1

  tcp_health_check {
    port = "22"
  }
}

resource "google_network_management_connectivity_test" "ping_webserver_onprem" {
  name       = "ping-webserver-onprem"
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

resource "google_network_management_connectivity_test" "ping_database_onprem" {
  name       = "ping-database-onprem"
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

resource "google_network_management_connectivity_test" "ping_webserver_database" {
  name       = "ping-webserver-database"
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

resource "google_network_management_connectivity_test" "http_webserver_onprem" {
  name       = "http-webserver-onprem"
  protocol   = "tcp"
  round_trip = true
  source {
    instance = google_compute_instance.webserver.id
  }
  destination {
    port     = 80
    instance = google_compute_instance.onprem.id
  }
  depends_on = [
    google_project_service.services,
  ]
}

resource "google_network_management_connectivity_test" "http_webserver_database" {
  name       = "http-webserver-database"
  protocol   = "tcp"
  round_trip = true
  source {
    instance = google_compute_instance.webserver.id
  }
  destination {
    port     = 80
    instance = google_compute_instance.database.id
  }
  depends_on = [
    google_project_service.services,
  ]
}

resource "google_network_management_connectivity_test" "http_onprem_webserver" {
  name       = "http-onprem-webserver"
  protocol   = "tcp"
  round_trip = true
  source {
    instance = google_compute_instance.onprem.id
  }
  destination {
    port     = 80
    instance = google_compute_instance.webserver.id
  }
  depends_on = [
    google_project_service.services,
  ]
}

resource "google_network_management_connectivity_test" "http_onprem_database" {
  name       = "http-onprem-database"
  protocol   = "tcp"
  round_trip = true
  source {
    instance = google_compute_instance.onprem.id
  }
  destination {
    port     = 80
    instance = google_compute_instance.database.id
  }
  depends_on = [
    google_project_service.services,
  ]
}

resource "google_network_management_connectivity_test" "http_database_webserver" {
  name       = "http-database-webserver"
  protocol   = "tcp"
  round_trip = true
  source {
    instance = google_compute_instance.database.id
  }
  destination {
    port     = 80
    instance = google_compute_instance.webserver.id
  }
  depends_on = [
    google_project_service.services,
  ]
}

resource "google_network_management_connectivity_test" "http_database_onprem" {
  name       = "http-database-onprem"
  protocol   = "tcp"
  round_trip = true
  source {
    instance = google_compute_instance.database.id
  }
  destination {
    port     = 80
    instance = google_compute_instance.onprem.id
  }
  depends_on = [
    google_project_service.services,
  ]
}
