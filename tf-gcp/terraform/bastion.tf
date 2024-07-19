resource "google_compute_address" "static" {
  name = "ipv4-address"
}

# creating a bastion host instance with a static ipv4 IP to SSH into private jenkins instances
resource "google_compute_instance" "bastion" {
  project      = var.project
  name         = "bastion"
  machine_type = var.bastion_machine_type
  zone         = var.zone
  tags         = ["bastion"]

  boot_disk {
    initialize_params {
      image = var.bastion_machine_image
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.public_subnet[0].self_link

    access_config {
      nat_ip = google_compute_address.static.address
    }
  }

  metadata = {
    ssh_keys = "${var.ssh_user}:${file(var.ssh_public_key)}"
  }
}

resource "google_compute_firewall" "allow_ssh_to_bastion" {
  project = var.project
  name    = "allow-ssh-to-bastion"
  network = google_compute_network.management.self_link

	# allow inbound traffic on port 22 from anywhere
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  source_tags   = ["bastion"]
}