resource "google_service_account" "database" {
  account_id   = "database"
  display_name = "Custom SA for the database VM Instance"
}

resource "google_project_iam_member" "database" {
  for_each = toset([
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
  ])
  project = var.project_id
  member  = google_service_account.database.member
  role    = each.value
}

resource "google_compute_instance" "database" {
  name                = "database"
  machine_type        = "n2-standard-4"
  project             = var.project_id
  zone                = var.zone
  can_ip_forward      = false
  deletion_protection = false
  enable_display      = false
  tags                = ["database"]

  boot_disk {
    auto_delete = true
    mode        = "READ_WRITE"
    initialize_params {
      image = "debian-cloud/debian-12"
      size  = 10
      type  = "pd-balanced"
    }
  }

  network_interface {
    stack_type = "IPV4_ONLY"
    subnetwork = google_compute_subnetwork.subnets["backend-main"].id
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

NAME=$(curl -H "Metadata-Flavor: Google" "http://metadata.google.internal/computeMetadata/v1/instance/hostname")
IP=$(curl -H "Metadata-Flavor: Google" "http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/ip")
METADATA=$(curl -f -H "Metadata-Flavor: Google" "http://metadata.google.internal/computeMetadata/v1/instance/attributes/?recursive=True" | jq 'del(.["startup-script"])')

cat <<EOF > /var/www/html/index.html
<pre>
Name: $NAME
IP: $IP
Metadata: $METADATA
</pre>
EOF
EOT

  service_account {
    email  = google_service_account.database.email
    scopes = ["cloud-platform"]
  }

  # This is not recommended for production workloads
  depends_on = [
    # Make sure we have internet access
    google_compute_router_nat.internet,
    google_compute_instance.appliance,
  ]
}
