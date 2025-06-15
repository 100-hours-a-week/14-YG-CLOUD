# 🚀 IaC 원칙 준수 3-tier 환경 재구현 가이드

## 📋 개요

지금까지의 문제점들을 해결하고 IaC 원칙을 완전히 준수하면서 Terraform과 Ansible을 분리한 완전한 3-tier 환경 구현 가이드입니다.

## 🔍 현재 상황 분석

### ✅ 성공한 부분들
- WireGuard VPN 구축 및 Ansible 자동화
- Backend → MySQL 연결 완전 해결
- SSH 태그 기반 방화벽 규칙 적용
- VPC 내부 네트워크 통신 검증

### ❌ 개선이 필요한 부분들
- startup-script 사용으로 인한 IaC 원칙 위반
- 하드코딩된 설정값들
- Terraform과 Ansible 역할 분리 부족
- 암호화된 변수 관리 복잡성

## 🎯 개선된 구현 방식

### 📊 **역할 분리 원칙**

```
🏗️  TERRAFORM (Infrastructure as Code)
├── 네트워크 구성 (VPC, Subnet, Firewall)
├── 컴퓨팅 리소스 (VM, Disk, Static IP)
├── 로드밸런서 (Backend Service, Health Check)
├── DNS 및 인증서 (Cloud DNS, SSL Certificate)
└── 기본 보안 설정 (Service Account, IAM)

🔧 ANSIBLE (Configuration Management)
├── 운영체제 설정 (Package, User, Service)
├── 애플리케이션 배포 (Docker, Code Deployment)
├── 설정 파일 관리 (Config Templates)
├── 서비스 상태 관리 (Start, Stop, Restart)
└── 모니터링 및 로그 설정
```

## 🛠️ **단계별 재구현 방법**

### 1단계: 클린한 Terraform 구성

#### **VM 설정 개선**
```hcl
# terraform/modules/compute/main.tf
resource "google_compute_instance" "vm" {
  name         = "${var.project_name}-${var.env}-${var.vm_name}"
  machine_type = var.machine_type
  zone         = var.zone

  # IaC 원칙: startup-script 완전 제거
  # 모든 애플리케이션 설정은 Ansible에서 관리

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = var.disk_size
      type  = "pd-standard"
    }
  }

  network_interface {
    network    = var.network_name
    subnetwork = var.subnet_name
    network_ip = var.network_ip
    
    dynamic "access_config" {
      for_each = var.assign_external_ip ? [1] : []
      content {
        nat_ip = var.external_ip_address
      }
    }
  }

  # SSH 키만 설정 (애플리케이션 설정 제외)
  metadata = {
    ssh-keys = "${var.ssh_user}:${file(var.ssh_public_key_path)}"
  }

  # 방화벽 태그 명확화
  tags = var.network_tags  # ["internal", "ssh", var.vm_role]

  service_account {
    email  = var.service_account_email
    scopes = ["cloud-platform"]
  }

  labels = {
    environment = var.env
    tier        = var.tier
    role        = var.vm_role
    managed_by  = "terraform"
  }
}
```

#### **방화벽 규칙 체계화**
```hcl
# terraform/modules/network/firewall.tf
# SSH 접근 (관리용)
resource "google_compute_firewall" "allow_ssh" {
  name    = "${var.project_name}-${var.env}-allow-ssh"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = var.ssh_source_ranges
  target_tags   = ["ssh"]
}

# 애플리케이션 포트 (Ansible에서 관리되는 서비스용)
resource "google_compute_firewall" "allow_app_ports" {
  name    = "${var.project_name}-${var.env}-allow-app-ports"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["8080", "8100", "3000", "3306", "6379", "27017"]
  }

  source_ranges = [var.subnet_cidr, var.wireguard_cidr]
  target_tags   = ["internal"]
}

# WireGuard VPN
resource "google_compute_firewall" "allow_wireguard" {
  name    = "${var.project_name}-${var.env}-allow-wireguard"
  network = google_compute_network.vpc.name

  allow {
    protocol = "udp"
    ports    = ["51820"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["wireguard-server"]
}
```

### 2단계: Ansible 변수 체계화

#### **암호화되지 않은 기본 변수**
```yaml
# ansible/group_vars/test/main.yml
---
# 환경 정보
env: "test"
project_name: "moongsan"
service_name: "moongsan"

# 네트워크 정보
vpc_cidr: "10.0.0.0/24"
wireguard_cidr: "10.8.0.0/24"

# VM 정보
database_ip: "10.0.0.2"
backend_ip: "10.0.0.3"
ai_ip: "10.0.0.4"

# 애플리케이션 포트
app_ports:
  backend: 8080
  ai: 8100
  frontend: 3000
  mysql: 3306
  redis: 6379

# 사용자 정보
ssh_user: "ubuntu"
app_user: "appuser"

# Docker 설정
docker_network: "moongsan_network"
```

#### **암호화된 민감한 변수**
```yaml
# ansible/group_vars/test/vault.yml (암호화됨)
---
# 데이터베이스 인증 정보
db:
  root_user: "root"
  root_password: "moongsan_root_2024!"
  app_user: "app_user"
  app_password: "app_password_2024!"
  database_name: "moongsan_app"

# 애플리케이션 시크릿
app_secrets:
  jwt_secret: "your-jwt-secret-key"
  api_key: "your-api-key"
  session_secret: "your-session-secret"

# WireGuard 키
wireguard:
  server_private_key: "UCgKHj5sZjIo4l9sX5ql2vR1ES/IsnaM7jjdlS9m+1s="
  server_public_key: "3OwuX076UsQyDDQVmvdI73Rsz1RzXYoGQdeVhZS/ui4="
```

### 3단계: 개선된 Ansible 플레이북

#### **메인 배포 플레이북**
```yaml
# ansible/playbooks/deploy_test_environment.yml
---
- name: "Complete Test Environment Deployment"
  hosts: localhost
  gather_facts: false
  tasks:
    - name: "Display deployment information"
      debug:
        msg: |
          🚀 Starting complete test environment deployment
          Environment: {{ env }}
          Target hosts: {{ groups['test'] | length }} servers

- import_playbook: deploy_base_system.yml
- import_playbook: deploy_database.yml
- import_playbook: deploy_backend.yml
- import_playbook: deploy_ai.yml
- import_playbook: verify_connectivity.yml
```

#### **기본 시스템 설정 플레이북**
```yaml
# ansible/playbooks/deploy_base_system.yml
---
- name: "Base System Configuration"
  hosts: test
  become: yes
  roles:
    - role: base_system
      vars:
        packages:
          - curl
          - wget
          - git
          - htop
          - net-tools
          - mysql-client
    - role: docker_setup
    - role: security_hardening
```

### 4단계: 역할(Role) 기반 구조화

#### **데이터베이스 역할**
```yaml
# ansible/roles/database/tasks/main.yml
---
- name: "Create MySQL directories"
  file:
    path: "{{ item }}"
    state: directory
    mode: '0755'
  loop:
    - "/opt/mysql/data"
    - "/opt/mysql/config"
    - "/opt/mysql/backups"

- name: "Deploy MySQL configuration"
  template:
    src: "my.cnf.j2"
    dest: "/opt/mysql/config/my.cnf"
    mode: '0644'
  notify: restart mysql

- name: "Deploy Docker Compose for MySQL"
  template:
    src: "docker-compose.yml.j2"
    dest: "/opt/mysql/docker-compose.yml"
    mode: '0644'
  notify: restart mysql

- name: "Start MySQL container"
  community.docker.docker_compose_v2:
    project_src: "/opt/mysql"
    state: present
    pull: always

- name: "Wait for MySQL to be ready"
  wait_for:
    host: "{{ database_ip }}"
    port: "{{ app_ports.mysql }}"
    timeout: 60

- name: "Create application database"
  mysql_db:
    name: "{{ db.database_name }}"
    state: present
    login_host: "{{ database_ip }}"
    login_user: "{{ db.root_user }}"
    login_password: "{{ db.root_password }}"

- name: "Create application user"
  mysql_user:
    name: "{{ db.app_user }}"
    password: "{{ db.app_password }}"
    host: "%"
    priv: "{{ db.database_name }}.*:ALL"
    state: present
    login_host: "{{ database_ip }}"
    login_user: "{{ db.root_user }}"
    login_password: "{{ db.root_password }}"
```

### 5단계: 연결성 검증 자동화

#### **전체 시스템 검증**
```yaml
# ansible/playbooks/verify_connectivity.yml
---
- name: "Verify 3-tier Connectivity"
  hosts: test
  gather_facts: false
  tasks:
    - name: "Test internal network connectivity"
      shell: "ping -c 2 {{ item }}"
      loop:
        - "{{ database_ip }}"
        - "{{ backend_ip }}"
        - "{{ ai_ip }}"
      when: inventory_hostname != item

    - name: "Test MySQL connectivity from Backend"
      mysql_db:
        name: "{{ db.database_name }}"
        state: present
        login_host: "{{ database_ip }}"
        login_user: "{{ db.app_user }}"
        login_password: "{{ db.app_password }}"
      when: inventory_hostname == "test-backend"

    - name: "Test application ports"
      wait_for:
        host: "{{ item.host }}"
        port: "{{ item.port }}"
        timeout: 10
      loop:
        - { host: "{{ database_ip }}", port: "{{ app_ports.mysql }}" }
        - { host: "{{ backend_ip }}", port: "{{ app_ports.backend }}" }
        - { host: "{{ ai_ip }}", port: "{{ app_ports.ai }}" }
      ignore_errors: yes
```

## 🚀 **실행 계획**

### **Step 1: 기존 환경 백업**
```bash
# 현재 상태 백업
cd /Users/lsh/Documents/local/3tier-moongsan/14-YG-CLOUD
cp -r terraform terraform.backup.$(date +%Y%m%d)
cp -r ansible ansible.backup.$(date +%Y%m%d)
```

### **Step 2: Terraform 정리**
```bash
# startup-script 제거 및 태그 정리
# VM 설정 최소화 (인프라만)
# 변수 체계화
```

### **Step 3: Ansible 구조 개선**
```bash
# 역할 기반 구조 적용
# 변수 암호화 체계 정리
# 플레이북 모듈화
```

### **Step 4: 단계별 배포 테스트**
```bash
# 1. 인프라 배포
terraform apply

# 2. 기본 시스템 설정
ansible-playbook -i inventories/test.ini playbooks/deploy_base_system.yml

# 3. 애플리케이션 배포
ansible-playbook -i inventories/test.ini playbooks/deploy_test_environment.yml

# 4. 연결성 검증
ansible-playbook -i inventories/test.ini playbooks/verify_connectivity.yml
```

## 🎯 **기대 효과**

1. **완전한 IaC 준수**: Terraform은 인프라만, Ansible은 설정만
2. **재현 가능성**: 언제든지 동일한 환경 구축 가능
3. **확장성**: 새로운 환경(dev, prod) 쉽게 추가 가능
4. **유지보수성**: 명확한 역할 분리로 관리 용이
5. **보안성**: 민감한 정보 적절한 암호화

---

**다음 작업**: 위의 계획대로 단계별로 재구현을 진행하시겠습니까?
