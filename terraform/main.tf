# VPC Network
resource "google_compute_network" "k8s_network" {
  name                    = "k8s-network"
  auto_create_subnetworks = false
}

# Subnet
resource "google_compute_subnetwork" "k8s_subnet" {
  name          = "k8s-subnet"
  ip_cidr_range = "10.1.0.0/16"
  region        = var.region
  network       = google_compute_network.k8s_network.id
}

# Firewall rules
resource "google_compute_firewall" "k8s_allow_internal" {
  name    = "k8s-allow-internal"
  network = google_compute_network.k8s_network.name

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = ["10.1.0.0/16"]
}

resource "google_compute_firewall" "k8s_allow_nodeport" {
  name    = "k8s-allow-nodeport"
  network = google_compute_network.k8s_network.name

  allow {
    protocol = "tcp"
    ports    = ["30000-32767"] # NodePort range
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["k8s-node"]
}

resource "google_compute_firewall" "k8s_allow_ssh" {
  name    = "k8s-allow-ssh"
  network = google_compute_network.k8s_network.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["k8s-node"]
}

# Control Plane Instance
resource "google_compute_instance" "k8s_control_plane" {
  name         = "k8s-control-plane"
  machine_type = var.machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 20
      type  = "pd-standard"
    }
  }

  network_interface {
    network    = google_compute_network.k8s_network.id
    subnetwork = google_compute_subnetwork.k8s_subnet.id
    access_config {
      # Ephemeral public IP
    }
  }

  metadata = {
    ssh-keys = "student:${file("~/.ssh/id_rsa.pub")}"
  }

  metadata_startup_script = <<-EOT
    #!/bin/bash

    hostnamectl set-hostname cp

    apt-get update
    apt-get upgrade -y

    cd /home/student

    wget https://cm.lf.training/LFD259/LFD259_V2025-05-28_SOLUTIONS.tar.xz --user="${var.lf_training_username}" --password="${var.lf_training_password}"
    tar -xvf LFD259_V2025-05-28_SOLUTIONS.tar.xz
    rm LFD259_V2025-05-28_SOLUTIONS.tar.xz

    echo "Startup script completed at $(date)" >> /var/log/startup-script.log
  EOT

  service_account {
    scopes = ["cloud-platform"]
  }

  tags = ["k8s-node", "k8s-control-plane"]

  allow_stopping_for_update = true
}

# Worker Node Instance
resource "google_compute_instance" "k8s_worker" {
  name         = "k8s-worker-1"
  machine_type = var.machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 20
      type  = "pd-standard"
    }
  }

  network_interface {
    network    = google_compute_network.k8s_network.id
    subnetwork = google_compute_subnetwork.k8s_subnet.id
    access_config {
      # Ephemeral public IP
    }
  }

  metadata = {
    ssh-keys = "student:${file("~/.ssh/id_rsa.pub")}"
  }

  metadata_startup_script = <<-EOT
    #!/bin/bash

    hostnamectl set-hostname worker

    apt-get update
    apt-get upgrade -y

    cd /home/student

    wget https://cm.lf.training/LFD259/LFD259_V2025-05-28_SOLUTIONS.tar.xz --user="${var.lf_training_username}" --password="${var.lf_training_password}"
    tar -xvf LFD259_V2025-05-28_SOLUTIONS.tar.xz
    rm LFD259_V2025-05-28_SOLUTIONS.tar.xz

    echo "Startup script completed at $(date)" >> /var/log/startup-script.log
  EOT

  service_account {
    scopes = ["cloud-platform"]
  }

  tags = ["k8s-node", "k8s-worker"]

  allow_stopping_for_update = true
}

# Outputs
output "control_plane_external_ip" {
  description = "External IP of the control plane"
  value       = google_compute_instance.k8s_control_plane.network_interface[0].access_config[0].nat_ip
}

output "control_plane_internal_ip" {
  description = "Internal IP of the control plane"
  value       = google_compute_instance.k8s_control_plane.network_interface[0].network_ip
}

output "worker_external_ip" {
  description = "External IP of the worker node"
  value       = google_compute_instance.k8s_worker.network_interface[0].access_config[0].nat_ip
}

output "worker_internal_ip" {
  description = "Internal IP of the worker node"
  value       = google_compute_instance.k8s_worker.network_interface[0].network_ip
}

output "ssh_commands" {
  description = "SSH commands to access the nodes"
  value = {
    control_plane = "ssh -i ~/.ssh/id_rsa student@${google_compute_instance.k8s_control_plane.network_interface[0].access_config[0].nat_ip}"
    worker        = "ssh -i ~/.ssh/id_rsa student@${google_compute_instance.k8s_worker.network_interface[0].access_config[0].nat_ip}"
  }
}

output "next_steps" {
  description = "What to do next"
  value       = <<-EOT
    
    Your VMs are ready! Next steps:
    
    1. SSH to control plane: ssh -i ~/.ssh/id_rsa student@${google_compute_instance.k8s_control_plane.network_interface[0].access_config[0].nat_ip}
    2. SSH to worker: ssh -i ~/.ssh/id_rsa student@${google_compute_instance.k8s_worker.network_interface[0].access_config[0].nat_ip}0
    3. Follow your CKAD course instructions to install Docker, Kubernetes, etc.
    4. When done practicing: terraform destroy
    
  EOT
}
