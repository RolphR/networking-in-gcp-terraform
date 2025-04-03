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


output "vpc" {
  value       = google_compute_network.vpc
  description = "Attributes of the network"
  depends_on = [
    google_compute_network.vpc,
  ]
}
