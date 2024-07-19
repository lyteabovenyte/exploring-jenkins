resource "google_compute_network" "management" {
    name = var.network_name
    auto_create_subnetworks = false
    routing_mode = "REGIONAL" # "GLOBAL" --> jenkins instance across multiple cloud providers
}

resource "google_compute_subnetwork" "public_subnet" {
    count = var.public_subnets_count
    name = "public-10-0-${count.index * 2 + 1}-0"
    ip_cidr_range = "10.0.${count.index * 2 + 1}.0/24"
    region = var.region
    network = google_compute_network.management.self_link
}

resource "google_cloud_subnetwork" "private_subnet" {
    count = var.private_subnets_count
    name = "private-10-0-${count.index * 2}-0"
    ip_cidr_range = "10.0.${count.index * 2}.0/24"
    region = var.region
    network = google_compute_network.management.self_link
    private_ip_google_access = true
}