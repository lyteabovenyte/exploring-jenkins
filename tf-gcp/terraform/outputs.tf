output "bastion" {
    value = "${google_compute_instance.bastion.network_interface.0.access_conig.0.nat_ip}"
}