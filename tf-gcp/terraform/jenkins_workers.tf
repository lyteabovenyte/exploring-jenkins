resource "google_compute_instance_template" "jenkins-worker-template" {
  name_prefix = "jenkins-worker"
  description = "jenkins worker instance template"
  region      = var.region

  tags         = ["jenkins-worker"]
  machine_type = var.jenkins_worker_machine_type

  metadata_startup_script = data.template_file.jenkins_worker_startup_script.rendered

  disk {
    source_image = var.jenkins_worker_machine_image
    disk_size_gb = 50
  }

  network_interface {
    network    = google_compute_network.management.self_link
    subnetwork = google_compute_subnetwork.private_subnet[0].self_link
  }

  metadata = {
    ssh_keys = "${var.ssh_user}:${file(var.ssh_public_key)}"
  }
}

data "template_file" "jenkins_worker_startup_script" {
  template = file("scripts/join-cluster.tpl")

  vars = {
    jenkins_url            = "http://${google_compute_forwardin_rule.jenkins_master_forwarding_rule.ip_address}"
    jenkins_username       = var.jenkins_username
    jenkins_password       = var.jenkins_password
    jenkins_credentials_id = var.jenkins_credentials_id
  }
}

resource "google_compute_firewall" "allow-ssh-to-worker" {
    project = var.project
    name = "allow-ssh-to-worker"
    network = google_compute_network.management.self_link

    # allow inbound traffic on port 22, both from bastion and jenkins-master
    allow {
        protocol = "tcp"
        ports = ["22"]
    }

    source_tags = ["bastion", "jenkins-ssh", "jenkins-worker"]
}

resource "google_compute_instance_group_manager" "jenkins-workers-group" {
    provider = google-beta
    name = "jenkins-workers"
    base_instance_name = "jenkins-worker"
    zone = var.zone

    version {
        instance_template = google_compute_instance_template.jenkins-worker-template.self_link
    }

    target_pools = [google_compute_target_pool.jenkins-workers-pool.id]
    target_size = 2
}

resource "google_compute_target_pool" "jenkins-workers-pool" {
    provider = google-beta
    name = "jenkins-workers-pool"
}

# scale-out based on CPU utilization
resource "google_compute_autoscaler" "jenkins-workers-autoscaler" {
    name = "jenkins-workers-autoscaler"
    zone = var.zone
    target = google_compute_instance_group_manager.jenkins-workers-group.id

    autoscaling_policy {
      max_replicas = 6
      min_replicas = 2
      cooldown_period = 60

      cpu_utilization {
        target = 0.8
      }
    }
}