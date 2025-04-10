resource "google_service_account" "producer" {
  account_id   = "producer"
  display_name = "Custom SA for the producer VM Instance"
}

resource "google_project_iam_member" "producer" {
  for_each = toset([
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
  ])
  project = var.project_id
  member  = google_service_account.producer.member
  role    = each.value
}

resource "google_compute_region_instance_group_manager" "producer" {
  for_each           = var.producer_subnets
  name               = "producer-${each.key}"
  base_instance_name = "producer-${each.key}"
  region             = each.key
  target_size        = 3
  version {
    instance_template = google_compute_region_instance_template.producer[each.key].self_link
    name              = "producer-${each.key}"
  }
  auto_healing_policies {
    health_check      = google_compute_health_check.default.id
    initial_delay_sec = 300
  }
}

resource "google_compute_region_instance_template" "producer" {
  for_each             = var.producer_subnets
  name                 = "producer-${each.key}-${var.producer_template_version}"
  project              = var.project_id
  region               = each.key
  instance_description = "Producer vm in ${each.key}"
  machine_type         = "f1-micro"
  can_ip_forward       = false
  tags                 = ["producer"]

  disk {
    source_image = "debian-cloud/debian-12"
    auto_delete  = true
    boot         = true
    mode         = "READ_WRITE"
    disk_size_gb = 10
    type         = "PERSISTENT"
  }

  network_interface {
    stack_type = "IPV4_ONLY"
    subnetwork = google_compute_subnetwork.producer[each.key].id
  }

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
    preemptible         = false
    provisioning_model  = "STANDARD"
  }
  shielded_instance_config {
    enable_integrity_monitoring = true
    enable_secure_boot          = false
    enable_vtpm                 = true
  }

  metadata = {
    enable-osconfig = "TRUE"
  }
  metadata_startup_script = <<EOT
#! /bin/bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y nginx-light jq

NAME=$(curl -H "Metadata-Flavor: Google" "http://metadata.google.internal/computeMetadata/v1/instance/name")
IP=$(curl -H "Metadata-Flavor: Google" "http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/ip")
ZONE=$(curl -s -H "Metadata-Flavor: Google" "http://metadata.google.internal/computeMetadata/v1/instance/zone" | cut -d / -f 4)

cat <<EOF > /var/www/html/index.html
<pre>
Name: $NAME
IP: $IP
Zone: $ZONE
</pre>
EOF
EOT

  service_account {
    email  = google_service_account.producer.email
    scopes = ["cloud-platform"]
  }
  lifecycle {
    create_before_destroy = true
  }
}
