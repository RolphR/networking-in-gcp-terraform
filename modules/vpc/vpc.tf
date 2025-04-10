variable "project_id" {
  type        = string
  description = "Project in which to place this subnet"
}

variable "name" {
  type        = string
  description = "Name of the vpc"
}

variable "mtu" {
  type        = number
  description = "MTU of the network"
  default     = 1500
}

variable "enable_global_routing" {
  type        = bool
  description = "Enable global routing"
  default     = true
}

variable "googleapis" {
  type        = map(string)
  description = "Map of allowed googleapi.com ranges"
  default = {
    "all"        = "34.126.0.0/18"
    "private"    = "199.36.153.8/30"
    "restricted" = "199.36.153.4/30"
  }
}

variable "router_service_accounts" {
  type        = set(string)
  description = "Set of router service accounts"
  default     = []
}


resource "google_compute_network" "vpc" {
  project                         = var.project_id
  name                            = var.name
  auto_create_subnetworks         = false
  mtu                             = 1500
  routing_mode                    = var.enable_global_routing ? "GLOBAL" : "REGIONAL"
  bgp_best_path_selection_mode    = "STANDARD"
  bgp_always_compare_med          = true
  bgp_inter_region_cost           = "ADD_COST_TO_MED"
  delete_default_routes_on_create = true
}

# Route all googleapis to the default internet gateway
resource "google_compute_route" "googleapis" {
  for_each         = var.googleapis
  name             = "${var.name}-internet-googleapis-${each.key}"
  dest_range       = each.value
  network          = google_compute_network.vpc.id
  next_hop_gateway = "default-internet-gateway"
  priority         = 100
}

# Allow everyone to invoke googleapis
resource "google_compute_firewall" "allow_googleapis" {
  name               = "${var.name}-allow-googleapis"
  project            = var.project_id
  direction          = "INGRESS"
  network            = google_compute_network.vpc.id
  source_ranges      = ["0.0.0.0/0"]
  destination_ranges = sort(values(var.googleapis))
  allow {
    protocol = "tcp"
    ports = [
      "443",
    ]
  }
}

# Allow healthchecks to always check the ssh port
resource "google_compute_firewall" "allow_healthchecks_ssh" {
  name          = "${var.name}-allow-hc"
  project       = var.project_id
  direction     = "INGRESS"
  network       = google_compute_network.vpc.id
  source_ranges = ["130.211.0.0/22", "35.191.0.0/16", "35.235.240.0/20"]
  allow {
    protocol = "tcp"
    ports = [
      "22",
      "80",
      "443",
    ]
  }
}

# Allow appliance to connect to everything
resource "google_compute_firewall" "allow_all_from_router" {
  for_each  = var.router_service_accounts
  name      = "${var.name}-allow-all-from-${split("@", each.value)[0]}"
  project   = var.project_id
  direction = "INGRESS"
  network   = google_compute_network.vpc.id
  source_service_accounts = [
    each.value,
  ]
  destination_ranges = [
    "0.0.0.0/0"
  ]
  allow {
    protocol = "all"
  }
}

# Allow everything to connect to the appliance
resource "google_compute_firewall" "allow_all_to_router" {
  for_each  = var.router_service_accounts
  name      = "${var.name}-allow-all-to-${split("@", each.value)[0]}"
  project   = var.project_id
  direction = "INGRESS"
  network   = google_compute_network.vpc.id
  source_ranges = [
    "0.0.0.0/0"
  ]
  target_service_accounts = [
    each.value,
  ]
  allow {
    protocol = "all"
  }
}

resource "google_compute_firewall" "allow_ping" {
  for_each  = var.router_service_accounts
  name      = "${var.name}-allow-all-ping"
  project   = var.project_id
  direction = "INGRESS"
  network   = google_compute_network.vpc.id
  source_ranges = [
    "0.0.0.0/0"
  ]
  allow {
    protocol = "icmp"
  }
}

resource "google_compute_firewall" "deny_and_log" {
  name      = "${var.name}-deny-all"
  project   = var.project_id
  direction = "INGRESS"
  network   = google_compute_network.vpc.id
  priority  = 65534
  source_ranges = [
    "0.0.0.0/0"
  ]
  deny {
    protocol = "all"
  }
  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}


output "vpc" {
  value       = google_compute_network.vpc
  description = "Attributes of the network"
  depends_on = [
    google_compute_network.vpc,
  ]
}
