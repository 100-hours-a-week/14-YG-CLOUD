# Compute 모듈 - VM 인스턴스 관리

# VM 인스턴스 생성
resource "google_compute_instance" "vm" {
  name         = "${var.project_name}-${var.env}-${var.vm_name}"
  machine_type = var.machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = var.image
      size  = var.disk_size
      type  = var.disk_type
    }
  }

  network_interface {
    network    = var.network_name
    subnetwork = var.subnet_name
    
    # 외부 IP 할당 여부 (Jump Box만 외부 IP 필요)
    dynamic "access_config" {
      for_each = var.assign_external_ip ? [1] : []
      content {
        nat_ip = var.external_ip_address
      }
    }
  }

  metadata = {
    ssh-keys = "${var.ssh_user}:${file(var.ssh_public_key_path)}"
    # startup-script는 필요한 경우만 사용 (WireGuard 등 인프라 설정용)
    startup-script = var.startup_script != "" ? var.startup_script : null
  }

  tags = var.network_tags

  service_account {
    email  = var.service_account_email
    scopes = var.service_account_scopes
  }

  # metadata_startup_script 제거 - 중복 방지 및 서버 초기화 이슈 해결

  labels = {
    environment = var.env
    tier        = var.tier
    role        = var.vm_role
  }
}
