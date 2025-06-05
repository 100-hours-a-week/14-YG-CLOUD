# 🏗️ Terraform 구조 개선 분석 및 제안

## 📊 현재 구조 분석

### ✅ 잘 구성된 부분

1. **모듈화 아키텍처**
   ```
   terraform/
   ├── modules/
   │   ├── network/      # VPC, 서브넷, 방화벽 규칙
   │   ├── compute/      # VM 인스턴스 관리
   │   ├── gcs_cdn/      # Frontend 정적 호스팅
   │   ├── wireguard/    # VPN 설정
   │   └── static_ip/    # 고정 IP 관리
   └── environments/
       ├── dev/          # 개발 환경
       ├── test/         # 테스트 환경
       └── prod/         # 운영 환경
   ```

2. **환경별 분리**: 각 환경마다 독립적인 상태 관리
3. **보안 설계**: Private 네트워크 + VPN 접근 제어
4. **재사용성**: 모듈 기반으로 코드 재사용

### ⚠️ 개선이 필요한 문제점

#### 1. **metadata_startup_script 중복 및 이슈**

**현재 문제:**
```terraform
# compute/main.tf에서 중복 정의
metadata = {
  startup-script = var.startup_script
}
# ... 
metadata_startup_script = var.startup_script  # 중복!
```

**문제점:**
- VM 재시작 시 startup script 재실행
- Terraform 변경 시 서버 초기화 위험
- 애플리케이션 레벨 설정이 인프라 코드에 혼재

#### 2. **startup_script의 부적절한 사용**

**현재 startup_script 사용 현황:**
- **Jump Box**: WireGuard 설치 (적절함)
- **Backend**: 애플리케이션 설치 (부적절함)
- **AI**: 파이썬 환경 설정 (부적절함)  
- **Database**: MySQL 설치 및 설정 (부적절함)

## 🎯 개선된 구조 제안

### 1. **Terraform 역할 재정의**

**Terraform이 담당할 것:**
- ✅ 인프라 리소스 (VM, 네트워크, 스토리지)
- ✅ 기본 OS 설정 (최소한의 패키지만)
- ✅ 보안 설정 (방화벽, VPN)

**Ansible이 담당할 것:**
- ✅ 애플리케이션 설치 및 설정
- ✅ 서비스 구성 및 시작
- ✅ 운영 중 설정 변경

### 2. **개선된 compute 모듈**

```terraform
# modules/compute/main.tf (개선안)
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
    
    dynamic "access_config" {
      for_each = var.assign_external_ip ? [1] : []
      content {
        nat_ip = var.external_ip_address
      }
    }
  }

  metadata = {
    ssh-keys = "${var.ssh_user}:${file(var.ssh_public_key_path)}"
    # startup-script만 필요한 경우만 사용 (WireGuard 등)
    startup-script = var.startup_script != "" ? var.startup_script : null
  }

  tags = var.network_tags

  service_account {
    email  = var.service_account_email
    scopes = var.service_account_scopes
  }

  # metadata_startup_script 제거 (중복 방지)

  labels = {
    environment = var.env
    tier        = var.tier
    role        = var.vm_role
  }

  # VM 생성 후 Ansible 실행을 위한 준비만
  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y python3 python3-pip",
      "echo 'VM ready for Ansible provisioning'"
    ]
    
    connection {
      type        = "ssh"
      user        = var.ssh_user
      private_key = file(var.ssh_private_key_path)
      host        = self.network_interface[0].access_config[0].nat_ip
    }
  }
}
```

### 3. **startup_script 사용 가이드라인**

#### ✅ **적절한 사용 사례 (유지)**
```terraform
# Jump Box - WireGuard 설정 (네트워크 인프라)
module "jumpbox" {
  source = "../../modules/compute"
  # ...
  startup_script = module.wireguard.startup_script
}
```

#### ❌ **부적절한 사용 사례 (Ansible로 이전)**
```terraform
# Backend, AI, Database - 애플리케이션 설정 제거
module "backend" {
  source = "../../modules/compute"
  # ...
  startup_script = ""  # 빈 문자열 또는 제거
}
```

### 4. **Ansible 역할 강화**

#### 기본 시스템 설정 역할 추가
```yaml
# roles/base_system/tasks/main.yml
- name: Update system packages
  apt:
    update_cache: yes
    upgrade: dist

- name: Install basic packages
  apt:
    name:
      - curl
      - wget
      - git
      - htop
      - python3
      - python3-pip
    state: present

- name: Configure timezone
  timezone:
    name: Asia/Seoul
```

#### 애플리케이션별 역할 개선
```yaml
# roles/backend_setup/tasks/main.yml
- name: Install Java 17
  apt:
    name: openjdk-17-jdk
    state: present

- name: Create application user
  user:
    name: appuser
    shell: /bin/bash
    create_home: yes

- name: Configure Spring Boot service
  template:
    src: spring-boot.service.j2
    dest: /etc/systemd/system/backend.service
  notify: restart backend
```

### 5. **배포 워크플로우 개선**

#### Phase 1: Terraform (인프라)
```bash
cd terraform/environments/test
terraform init
terraform apply
```

#### Phase 2: Ansible (애플리케이션)
```bash
cd ansible
# 기본 시스템 설정
ansible-playbook -i inventory_test.ini playbooks/base_system.yml

# 애플리케이션 배포
ansible-playbook -i inventory_test.ini playbooks/site.yml
```

## 📋 마이그레이션 계획

### Step 1: Compute 모듈 수정
- metadata_startup_script 중복 제거
- startup_script를 필수가 아닌 선택사항으로 변경
- 기본 provisioner로 Python 설치만 수행

### Step 2: startup_script 정리
- Jump Box: WireGuard 설정만 유지
- Backend/AI/Database: startup_script 제거

### Step 3: Ansible 역할 추가
- base_system 역할 생성
- 기존 역할들 개선

### Step 4: 배포 스크립트 개선
- Terraform → Ansible 순서로 실행
- 에러 처리 및 롤백 로직 추가

## 🎯 최종 목표 구조

```
배포 흐름:
1. Terraform: 순수 인프라 (VM, 네트워크, 스토리지)
2. Ansible: 시스템 설정 + 애플리케이션 배포
3. 운영: Ansible로 지속적 관리

장점:
✅ 인프라와 애플리케이션 관심사 분리
✅ VM 재시작 시 설정 유지
✅ 무중단 배포 가능
✅ 설정 변경의 안전성 향상
✅ 디버깅 및 트러블슈팅 용이
```

## 🚀 실행 계획

이 개선안을 단계적으로 적용하여:
1. **안정성 향상**: 서버 초기화 위험 제거
2. **운영 편의성**: 애플리케이션 배포/업데이트 분리
3. **확장성**: 새로운 서비스 추가 용이
4. **유지보수성**: 코드 가독성 및 관리 효율성 향상
