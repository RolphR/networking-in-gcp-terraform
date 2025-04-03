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
    subnetwork = google_compute_subnetwork.subnet_a.id
    network_ip = cidrhost(var.subnet_a, 3)
  }
  network_interface {
    stack_type = "IPV4_ONLY"
    subnetwork = google_compute_subnetwork.subnet_b.id
    network_ip = cidrhost(var.subnet_b, 3)
  }
  network_interface {
    stack_type = "IPV4_ONLY"
    subnetwork = google_compute_subnetwork.subnet_c.id
    network_ip = cidrhost(var.subnet_c, 3)
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
    sysctl -w net.ipv4.ip_forward=1
    route add default gw ${cidrhost(var.subnet_a, 1)}
    iptables -A INPUT -j ACCEPT
    iptables -A FORWARD -i ens4 -o ens5 -j ACCEPT
    iptables -A FORWARD -i ens4 -o ens6 -j ACCEPT
    iptables -A FORWARD -i ens5 -o ens4 -j ACCEPT
    iptables -A FORWARD -i ens5 -o ens6 -j ACCEPT
    iptables -A FORWARD -i ens6 -o ens4 -j ACCEPT
    iptables -A FORWARD -i ens6 -o ens5 -j ACCEPT
  EOT

  service_account {
    email  = google_service_account.appliance.email
    scopes = ["cloud-platform"]
  }
}

resource "google_compute_health_check" "ssh" {
  name = "ssh"

  timeout_sec        = 1
  check_interval_sec = 1

  tcp_health_check {
    port = "22"
  }
}

resource "google_compute_instance_group" "appliance" {
  name    = "appliance"
  project = var.project_id
  zone    = var.zone
  instances = [
    google_compute_instance.appliance.id,
  ]
}

resource "google_compute_region_backend_service" "appliance_vpc_a" {
  name                  = "appliance-vpc-a"
  region                = var.region
  network               = module.vpc_a.vpc.name
  protocol              = "TCP"
  load_balancing_scheme = "INTERNAL"
  health_checks = [
    google_compute_health_check.ssh.id,
  ]
  backend {
    group          = google_compute_instance_group.appliance.id
    balancing_mode = "CONNECTION"
  }
}

resource "google_compute_region_backend_service" "appliance_vpc_b" {
  name                  = "appliance-vpc-b"
  region                = var.region
  network               = module.vpc_b.vpc.name
  protocol              = "TCP"
  load_balancing_scheme = "INTERNAL"
  health_checks = [
    google_compute_health_check.ssh.id,
  ]
  backend {
    group          = google_compute_instance_group.appliance.id
    balancing_mode = "CONNECTION"
  }
}

resource "google_compute_region_backend_service" "appliance_vpc_c" {
  name                  = "appliance-vpc-c"
  region                = var.region
  network               = module.vpc_c.vpc.name
  protocol              = "TCP"
  load_balancing_scheme = "INTERNAL"
  health_checks = [
    google_compute_health_check.ssh.id,
  ]
  backend {
    group          = google_compute_instance_group.appliance.id
    balancing_mode = "CONNECTION"
  }
}

resource "google_compute_address" "appliance_lb_a" {
  name         = "appliance-lb-a"
  project      = var.project_id
  region       = var.region
  subnetwork   = google_compute_subnetwork.subnet_a.id
  address_type = "INTERNAL"
  address      = cidrhost(var.subnet_a, 2)
}

resource "google_compute_address" "appliance_lb_b" {
  name         = "appliance-lb-b"
  project      = var.project_id
  region       = var.region
  subnetwork   = google_compute_subnetwork.subnet_b.id
  address_type = "INTERNAL"
  address      = cidrhost(var.subnet_b, 2)
}

resource "google_compute_address" "appliance_lb_c" {
  name         = "appliance-lb-c"
  project      = var.project_id
  region       = var.region
  subnetwork   = google_compute_subnetwork.subnet_c.id
  address_type = "INTERNAL"
  address      = cidrhost(var.subnet_c, 2)
}

resource "google_compute_forwarding_rule" "appliance_a" {
  name                  = "appliance-a"
  project               = var.project_id
  region                = var.region
  network               = module.vpc_a.vpc.name
  subnetwork            = google_compute_subnetwork.subnet_a.name
  load_balancing_scheme = "INTERNAL"
  ip_protocol           = "TCP"
  backend_service       = google_compute_region_backend_service.appliance_vpc_a.id
  all_ports             = true
  ip_address            = google_compute_address.appliance_lb_a.address
}

resource "google_compute_forwarding_rule" "appliance_b" {
  name                  = "appliance-b"
  project               = var.project_id
  region                = var.region
  network               = module.vpc_b.vpc.name
  subnetwork            = google_compute_subnetwork.subnet_b.name
  load_balancing_scheme = "INTERNAL"
  ip_protocol           = "TCP"
  backend_service       = google_compute_region_backend_service.appliance_vpc_b.id
  all_ports             = true
  ip_address            = google_compute_address.appliance_lb_b.address
}

resource "google_compute_forwarding_rule" "appliance_c" {
  name                  = "appliance-c"
  project               = var.project_id
  region                = var.region
  network               = module.vpc_c.vpc.name
  subnetwork            = google_compute_subnetwork.subnet_c.name
  load_balancing_scheme = "INTERNAL"
  ip_protocol           = "TCP"
  backend_service       = google_compute_region_backend_service.appliance_vpc_c.id
  all_ports             = true
  ip_address            = google_compute_address.appliance_lb_c.address
}

resource "google_compute_route" "default_appliance_a" {
  name         = "default-appliance-a"
  dest_range   = "0.0.0.0/0"
  network      = module.vpc_a.vpc.name
  next_hop_ilb = google_compute_forwarding_rule.appliance_a.id
  priority     = 1000
}

resource "google_compute_route" "default_appliance_b" {
  name         = "default-appliance-b"
  dest_range   = "0.0.0.0/0"
  network      = module.vpc_b.vpc.name
  next_hop_ilb = google_compute_forwarding_rule.appliance_b.id
  priority     = 1000
}

resource "google_compute_route" "default_appliance_c" {
  name         = "default-appliance-c"
  dest_range   = "0.0.0.0/0"
  network      = module.vpc_c.vpc.name
  next_hop_ilb = google_compute_forwarding_rule.appliance_c.id
  priority     = 1000
}
