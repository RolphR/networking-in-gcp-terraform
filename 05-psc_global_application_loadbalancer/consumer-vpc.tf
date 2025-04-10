module "vpc_consumer" {
  source     = "../modules/vpc"
  project_id = var.project_id
  name       = "consumer"
}

resource "google_compute_subnetwork" "consumer" {
  for_each      = var.consumer_subnets
  name          = "consumer-endpoints-${each.key}"
  project       = var.project_id
  region        = each.key
  ip_cidr_range = each.value
  network       = module.vpc_consumer.vpc.id
}
