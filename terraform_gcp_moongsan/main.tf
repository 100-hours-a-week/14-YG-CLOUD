# 고정 IP 생성
resource "google_compute_address" "prod_static_ip" {
  name = "moongsan-prod-ip"
}

# prod VM 생성
resource "google_compute_instance" "prod_vm" {
  name         = "moongsan-prod-vm"
  machine_type = var.vm_machine_type
  zone         = "asia-northeast3-a"

  # allow_stopping_for_update = true  # 이 줄 추가!

  boot_disk {
    initialize_params {
      image = var.ubuntu_image
      size  = 50
    }
  }

  network_interface {
    network = "default"
    access_config {
      nat_ip = google_compute_address.prod_static_ip.address
    }
  }

  metadata = {
    ssh-keys = "${var.ssh_user}:${file(var.ssh_public_key_path)}"
    # google-logging-enabled = "true"
    # google-monitoring-enabled = "true"
  }

  # metadata_startup_script = <<-EOT
  #   #!/bin/bash
  #   apt-get update -y
  #   apt-get install -y nginx mysql-server python3-pip openjdk-17-jdk
  #   curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
  #   apt-get install -y nodejs
  #   pip3 install fastapi uvicorn
  # EOT

  tags = ["prod"]
}

# 방화벽 설정
resource "google_compute_firewall" "allow-web-traffic" {
  name    = "allow-web-traffic"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["22", "80", "443", "8080", "8100", "3000", "3100", "9090", "9100"]
  }

  source_ranges = ["0.0.0.0/0"]

  target_tags = ["prod"]
  # target_tags = ["prod", "dev"]
}
