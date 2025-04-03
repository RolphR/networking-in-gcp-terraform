resource "google_service_account" "appliance" {
  account_id   = "appliance"
  display_name = "Custom SA for the appliance VM Instance"
}

resource "google_compute_instance" "appliance" {
  name                = "appliance"
  machine_type        = "n2-standard-4"
  project             = var.project_id
  zone                = var.zone
  can_ip_forward      = true
  deletion_protection = false
  enable_display      = false
  tags                = ["appliance"]

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
    subnetwork = google_compute_subnetwork.subnets["internet-appliance"].id
    network_ip = cidrhost(local.subnets["internet-appliance"].cidr, 3)
  }
  network_interface {
    stack_type = "IPV4_ONLY"
    subnetwork = google_compute_subnetwork.subnets["web-appliance"].id
    network_ip = cidrhost(local.subnets["web-appliance"].cidr, 3)
  }
  network_interface {
    stack_type = "IPV4_ONLY"
    subnetwork = google_compute_subnetwork.subnets["backend-appliance"].id
    network_ip = cidrhost(local.subnets["backend-appliance"].cidr, 3)
  }
  network_interface {
    stack_type = "IPV4_ONLY"
    subnetwork = google_compute_subnetwork.subnets["onprem-appliance"].id
    network_ip = cidrhost(local.subnets["onprem-appliance"].cidr, 3)
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
    #!/bin/bash
    # Enable forwarding
    sysctl -w net.ipv4.ip_forward=1

    ip route add default gw ${cidrhost(local.subnets["internet-appliance"].cidr, 1)}
    iptables -A INPUT -j ACCEPT

    ip a add ${cidrhost(local.subnets["internet-appliance"].cidr, 2)}/32 dev ens4:0
    ip route add ${var.networks["internet"]} via ${cidrhost(local.subnets["internet-appliance"].cidr, 1)}
    iptables -t nat -A POSTROUTING -o ens4 -j MASQUERADE --random
    iptables -A FORWARD -i ens4 -o ens5 -m conntrack --ctstate RELATED, ESTABLISHED -j ACCEPT
    iptables -A FORWARD -i ens4 -o ens6 -m conntrack --ctstate RELATED, ESTABLISHED -j ACCEPT
    iptables -A FORWARD -i ens4 -o ens7 -m conntrack --ctstate RELATED, ESTABLISHED -j ACCEPT

    ip a add ${cidrhost(local.subnets["web-appliance"].cidr, 2)}/32 dev ens5:0
    ip route add ${var.networks["web"]} via ${cidrhost(local.subnets["web-appliance"].cidr, 1)}
    iptables -A FORWARD -i ens5 -o ens4 -j ACCEPT
    iptables -A FORWARD -i ens5 -o ens6 -j ACCEPT
    iptables -A FORWARD -i ens5 -o ens7 -j ACCEPT

    ip a add ${cidrhost(local.subnets["backend-appliance"].cidr, 2)}/32 dev ens6:0
    ip route add ${var.networks["backend"]} via ${cidrhost(local.subnets["backend-appliance"].cidr, 1)}
    iptables -A FORWARD -i ens6 -o ens4 -j ACCEPT
    iptables -A FORWARD -i ens6 -o ens5 -j ACCEPT
    iptables -A FORWARD -i ens6 -o ens7 -j ACCEPT

    ip a add ${cidrhost(local.subnets["onprem-appliance"].cidr, 2)}/32 dev ens7:0
    ip route add ${var.networks["onprem"]} via ${cidrhost(local.subnets["onprem-appliance"].cidr, 1)}
    iptables -A FORWARD -i ens7 -o ens4 -j ACCEPT
    iptables -A FORWARD -i ens7 -o ens5 -j ACCEPT
    iptables -A FORWARD -i ens7 -o ens6 -j ACCEPT
  EOT

  service_account {
    email  = google_service_account.appliance.email
    scopes = ["cloud-platform"]
  }

  depends_on = [
    # Make sure we have internet access
    google_compute_router_nat.internet,
  ]
}



resource "google_compute_instance_group" "appliance" {
  name    = "appliance"
  project = var.project_id
  zone    = var.zone
  instances = [
    google_compute_instance.appliance.self_link,
  ]

  depends_on = [
    google_compute_instance.appliance,
  ]
}
