# 고정 IP 생성
resource "google_compute_address" "static_ip" {
  name = "moongsan-${var.env}-ip"
}

# VM 생성
resource "google_compute_instance" "vm" {
  name         = "moongsan-${var.env}-vm"
  machine_type = var.vm_machine_type
  zone         = "asia-northeast3-a"

  boot_disk {
    initialize_params {
      image = var.ubuntu_image
      size  = 50
    }
  }

  network_interface {
    network = "default"
    access_config {
      nat_ip = google_compute_address.static_ip.address
    }
  }

  metadata = {
    ssh-keys = "${var.ssh_user}:${file(var.ssh_public_key_path)}"
  }

  tags = [var.env]
}

# 방화벽 설정
resource "google_compute_firewall" "allow-web-traffic" {
  name    = "${var.env}-allow-web-traffic"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["22", "80", "443", "8080", "8100", "3000", "3100", "6379", "9090", "9100"]
  }

  source_ranges = ["0.0.0.0/0"]

  target_tags = [var.env]
}
