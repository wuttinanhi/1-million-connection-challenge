variable "GOOGLE_CREDENTIAL" {
  type = string
  nullable = false
}

variable "GOOGLE_PROJECT" {
  type = string
  nullable = false

}

variable "GOOGLE_REGION" {
  type = string
  nullable = false
  default = "asia-southeast2"
}

variable "GOOGLE_ZONE" {
  type = string
  nullable = false
  default = "asia-southeast2-c"
}

variable "DOCKER_SWARM_MANAGER_COUNT" {
  type = number
  default = 3
}

variable "DOCKER_SWARM_WORKER_COUNT" {
  type = number
  default = 3
}

terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "4.51.0"
    }
  }
}

provider "google" {
    credentials = file(var.GOOGLE_CREDENTIAL)
    project = var.GOOGLE_PROJECT
    region = var.GOOGLE_REGION
    zone = var.GOOGLE_ZONE
}

resource "google_compute_network" "vpc_network" {
  name                    = "docker-network"
  auto_create_subnetworks = false
  mtu                     = 1460
}

resource "google_compute_subnetwork" "default" {
  name          = "docker-subnetwork"
  ip_cidr_range = "10.0.0.0/24"
  region        =  var.GOOGLE_REGION
  network       = google_compute_network.vpc_network.id
}

resource "google_compute_firewall" "swarm" {
  name    = "docker-firewall"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["22", "2377", "7946", "8080", "80", "443", "3000"]
  }

  allow {
    protocol = "udp"
    ports    = ["7946", "4789"]
  }

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_instance" "managers" {
    machine_type = "n1-standard-2"
    name         = "manager-${count.index + 1}"
    count        = var.DOCKER_SWARM_MANAGER_COUNT
    zone = var.GOOGLE_ZONE
    tags = ["http-server"]


    boot_disk {
        auto_delete = true
        device_name = "manager"

        initialize_params {
            image = "projects/debian-cloud/global/images/debian-11-bullseye-v20231115"
            size  = 100
            type  = "pd-standard"
        }

      mode = "READ_WRITE"
    }

    network_interface {
        access_config {
            network_tier = "STANDARD"
        }

        subnetwork = google_compute_subnetwork.default.id
    }

    scheduling {
        automatic_restart   = true
        preemptible         = false
        provisioning_model  = "STANDARD"
    }

    shielded_instance_config {
        enable_integrity_monitoring = true
        enable_secure_boot          = true
        enable_vtpm                 = true
    }


    metadata = {
        startup-script = <<EOT
curl -fsSL https://get.docker.com | sh
sudo useradd docker -s /bin/bash -m -g docker
sudo usermod --password $(echo @test12345 | openssl passwd -1 -stdin) docker
sudo sed -i "/^[^#]*PasswordAuthentication[[:space:]]no/c\PasswordAuthentication yes" /etc/ssh/sshd_config
sudo systemctl restart ssh
docker run -it -d -p 8080:8080 -v /var/run/docker.sock:/var/run/docker.sock dockersamples/visualizer
EOT
    }
}

resource "google_compute_instance" "workers" {
    machine_type = "n1-standard-2"
    name         = "worker-${count.index + 1}"
    count        = var.DOCKER_SWARM_WORKER_COUNT
    zone = var.GOOGLE_ZONE
    tags = ["http-server"]

    boot_disk {
        auto_delete = true
        device_name = "worker"

        initialize_params {
            image = "projects/debian-cloud/global/images/debian-11-bullseye-v20231115"
            size  = 100
            type  = "pd-standard"
        }

      mode = "READ_WRITE"
    }

    network_interface {
        access_config {
            network_tier = "STANDARD"
        }

        subnetwork = google_compute_subnetwork.default.id
    }

    scheduling {
        automatic_restart   = true
        preemptible         = false
        provisioning_model  = "STANDARD"
    }

    shielded_instance_config {
        enable_integrity_monitoring = true
        enable_secure_boot          = true
        enable_vtpm                 = true
    }

    metadata = {
        startup-script = <<EOT
curl -fsSL https://get.docker.com | sh
sudo useradd docker -s /bin/bash -m -g docker
sudo usermod --password $(echo @test12345 | openssl passwd -1 -stdin) docker
sudo sed -i "/^[^#]*PasswordAuthentication[[:space:]]no/c\PasswordAuthentication yes" /etc/ssh/sshd_config
sudo systemctl restart ssh
docker run -it -d -p 8080:8080 -v /var/run/docker.sock:/var/run/docker.sock dockersamples/visualizer
EOT
    }
}



output "manager_ip" {
    value = "${google_compute_instance.managers[*].network_interface.0.access_config.0.nat_ip}"
}

output "manager_first_node_private_ip" {
    value = "${google_compute_instance.managers[0].network_interface.0.network_ip}"
}

output "worker_ip" {
    value = "${google_compute_instance.workers[*].network_interface.0.access_config.0.nat_ip}"
}
