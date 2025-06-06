# 🏗️ 환경별 인프라 구조 개선 계획

## 📊 현재 문제점 분석

### 🚨 **주요 이슈**
1. **jumpbox가 test 환경에만 종속**
   - 다른 환경(dev, prod) 접근 시 별도 jumpbox 필요
   - 관리 복잡도 증가 및 비용 낭비

2. **WireGuard가 환경별 중복 설정**
   - 각 환경마다 별도 VPN 설정 필요
   - 클라이언트 설정 파일 관리 복잡

3. **공통 인프라 구성 요소 중복**
   - 네트워크 게이트웨이, 모니터링 등이 환경별 중복
   - 운영 효율성 저하

## 🎯 개선된 아키텍처 설계

### 🌐 **공통 인프라 (Shared Infrastructure)**
```
📦 Common Infrastructure
├── 🖥️ Shared Jump Box
│   ├── WireGuard VPN Server (통합)
│   ├── Ansible Control Node
│   ├── Monitoring Dashboard
│   └── Security Scanning Tools
│
├── 🌐 Shared Management Network
│   ├── VPC: 10.100.0.0/16 (management)
│   ├── VPN CIDR: 10.8.0.0/24
│   └── Admin Access Controls
│
└── 🔐 Shared Security
    ├── KMS Keys (환경별)
    ├── Secret Management
    └── Audit Logging
```

### 🏢 **환경별 인프라 (Environment-Specific)**
```
📦 Environment Infrastructure
├── 🧪 Dev Environment
│   ├── VPC: 10.0.0.0/16
│   ├── Single VM (monolith)
│   └── Development Data
│
├── 🧪 Test Environment  
│   ├── VPC: 10.1.0.0/16
│   ├── 3-Tier Architecture
│   │   ├── Backend VM
│   │   ├── AI VM
│   │   └── Database VM
│   └── Test Data
│
└── 🚀 Prod Environment
    ├── VPC: 10.2.0.0/16
    ├── 3-Tier Architecture (HA)
    │   ├── Backend Cluster
    │   ├── AI Cluster
    │   └── Database Cluster
    └── Production Data
```

## 🔧 구현 방안

### **1단계: 공통 인프라 분리**

#### 1-1. Terraform 구조 개선
```
terraform/
├── shared/                     # 새로 생성
│   ├── management/             # 공통 관리 인프라
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── backend.tf
│   └── security/               # 공통 보안 인프라
│       ├── kms/
│       └── iam/
├── environments/
│   ├── dev/                    # 기존 유지
│   ├── test/                   # jumpbox 제거
│   └── prod/                   # jumpbox 제거
└── modules/
    ├── shared_jumpbox/         # 새로 생성
    ├── environment_network/    # 환경별 네트워크
    └── ... 기존 모듈들
```

#### 1-2. 공통 관리 인프라 설계
```hcl
# terraform/shared/management/main.tf
module "shared_jumpbox" {
  source = "../../modules/shared_jumpbox"
  
  project_name = var.project_name
  machine_type = "e2-small"
  disk_size    = 30
  
  # 모든 환경 접근 가능한 네트워크 설정
  management_vpc_cidr = "10.100.0.0/16"
  wireguard_cidr     = "10.8.0.0/24"
  
  # 환경별 네트워크 피어링 설정
  environment_networks = {
    dev  = "10.0.0.0/16"
    test = "10.1.0.0/16" 
    prod = "10.2.0.0/16"
  }
}

# VPC 피어링으로 환경별 네트워크 연결
module "vpc_peering" {
  source = "../../modules/vpc_peering"
  
  management_vpc = module.shared_jumpbox.vpc_name
  environment_vpcs = {
    dev  = "projects/${var.project_id}/global/networks/moongsan-dev-vpc"
    test = "projects/${var.project_id}/global/networks/moongsan-test-vpc"
    prod = "projects/${var.project_id}/global/networks/moongsan-prod-vpc"
  }
}
```

### **2단계: Ansible 구조 개선**

#### 2-1. 인벤토리 구조 개선
```ini
# ansible/inventory_shared.ini
[shared_infrastructure]
shared-jumpbox ansible_host=34.64.100.100 ansible_user=lsh

[shared_infrastructure:vars]
ansible_ssh_private_key_file=~/.ssh/google_compute_engine
ansible_ssh_common_args='-o StrictHostKeyChecking=no'

# ansible/inventory_all_environments.ini
[jumpbox]
shared-jumpbox ansible_host=34.64.100.100 ansible_user=lsh

[dev_environment]
dev-vm ansible_host=10.0.0.10 ansible_user=lsh

[test_environment]
test-backend ansible_host=10.1.0.3 ansible_user=lsh
test-ai ansible_host=10.1.0.5 ansible_user=lsh
test-database ansible_host=10.1.0.2 ansible_user=lsh

[prod_environment]
prod-backend ansible_host=10.2.0.3 ansible_user=lsh
prod-ai ansible_host=10.2.0.5 ansible_user=lsh
prod-database ansible_host=10.2.0.2 ansible_user=lsh

# 환경별 그룹화
[dev:children]
dev_environment

[test:children]
test_environment

[prod:children]
prod_environment

# 공통 프록시 설정
[dev:vars]
ansible_ssh_common_args='-o StrictHostKeyChecking=no -o ProxyJump=lsh@34.64.100.100'

[test:vars]
ansible_ssh_common_args='-o StrictHostKeyChecking=no -o ProxyJump=lsh@34.64.100.100'

[prod:vars]
ansible_ssh_common_args='-o StrictHostKeyChecking=no -o ProxyJump=lsh@34.64.100.100'
```

#### 2-2. WireGuard 설정 통합 관리
```yaml
# ansible/group_vars/shared_infrastructure/wireguard.yml
wireguard:
  server:
    interface: wg0
    port: 51820
    ip: "10.8.0.1/24"
    
  # 환경별 라우팅 설정
  environment_routes:
    dev:  "10.0.0.0/16"
    test: "10.1.0.0/16"
    prod: "10.2.0.0/16"
    
  # 통합 클라이언트 관리
  clients:
    admin:
      address: "10.8.0.10/32"
      public_key: "{{ vault_admin_public_key }}"
      private_key: "{{ vault_admin_private_key }}"
      allowed_environments: ["dev", "test", "prod"]
      
    developer1:
      address: "10.8.0.20/32"
      public_key: "{{ vault_dev1_public_key }}"
      private_key: "{{ vault_dev1_private_key }}"
      allowed_environments: ["dev", "test"]
      
    developer2:
      address: "10.8.0.21/32"
      public_key: "{{ vault_dev2_public_key }}"
      private_key: "{{ vault_dev2_private_key }}"
      allowed_environments: ["dev", "test"]
```

### **3단계: 네트워크 아키텍처 개선**

#### 3-1. VPC 피어링을 통한 환경 연결
```
📡 Shared Management VPC (10.100.0.0/16)
     │
     ├── 🖥️ Shared Jump Box (10.100.0.10)
     │   └── WireGuard Server (10.8.0.1)
     │
     ┌─────────VPC Peering─────────┐
     │                           │
     ▼                           ▼
🧪 Dev VPC          🧪 Test VPC         🚀 Prod VPC
(10.0.0.0/16)      (10.1.0.0/16)      (10.2.0.0/16)
     │                   │                   │
     └── Dev VM          ├── Backend VM      ├── Backend Cluster
                         ├── AI VM           ├── AI Cluster  
                         └── Database VM     └── Database Cluster
```

#### 3-2. 보안 및 접근 제어
```yaml
# 환경별 접근 제어 규칙
firewall_rules:
  shared_to_dev:
    source_ranges: ["10.100.0.0/16"]
    target_ranges: ["10.0.0.0/16"]
    allowed_ports: ["22", "8080", "3306"]
    
  shared_to_test:
    source_ranges: ["10.100.0.0/16"]
    target_ranges: ["10.1.0.0/16"]
    allowed_ports: ["22", "8080", "8100", "3306"]
    
  shared_to_prod:
    source_ranges: ["10.100.0.0/16"]
    target_ranges: ["10.2.0.0/16"]
    allowed_ports: ["22", "8080", "8100", "3306"]
    # prod는 추가 보안 제어
```

## 💰 비용 영향 분석

### 현재 vs 개선안 비용 비교

#### **현재 구조 (test 환경만 jumpbox)**
```
Test 환경:
- Jump Box: $10.70/월 (e2-small)
- 다른 환경은 jumpbox 없음 (접근 불편)

총 관리 비용: $10.70/월
```

#### **개선안 (공통 jumpbox)**
```
Shared Infrastructure:
- Shared Jump Box: $15.50/월 (e2-small + 30GB)
- Management VPC: 무료
- VPC Peering: 무료 (같은 리전)

각 환경:
- jumpbox 제거로 $10.70/월 절약
- 네트워크 최적화

총 관리 비용: $15.50/월
절약 효과: 환경이 늘어날수록 큰 절약
```

### 운영 효율성 향상
1. **단일 진입점**: 하나의 jumpbox로 모든 환경 관리
2. **통합 VPN**: 하나의 클라이언트 설정으로 모든 환경 접근
3. **중앙집중 모니터링**: 모든 환경을 한 곳에서 모니터링
4. **보안 강화**: 통합 보안 정책 및 감사

## 🚀 실행 계획

### **Phase 1: 공통 인프라 구축 (1주)**
1. shared/management Terraform 모듈 생성
2. 공통 jumpbox 배포
3. WireGuard 통합 설정

### **Phase 2: 네트워크 피어링 (1주)**
1. VPC 피어링 설정
2. 라우팅 테이블 구성
3. 방화벽 규칙 적용

### **Phase 3: Ansible 구조 개선 (1주)**
1. 통합 인벤토리 구성
2. 환경별 변수 재구성
3. 배포 프로세스 개선

### **Phase 4: 기존 환경 마이그레이션 (1주)**
1. test 환경에서 jumpbox 제거
2. 공통 jumpbox로 접근 전환
3. 검증 및 문서화

## 🎯 기대 효과

### 📈 **운영 효율성**
- **통합 관리**: 단일 진입점으로 모든 환경 관리
- **비용 절약**: 환경 증가 시 jumpbox 비용 절약
- **보안 강화**: 중앙집중식 보안 관리

### 🔧 **개발자 경험**
- **간편한 접근**: 하나의 VPN 설정으로 모든 환경 접근
- **일관된 경험**: 환경별 동일한 접근 방식
- **빠른 환경 전환**: 네트워크 재연결 없이 환경 변경

### 🚀 **확장성**
- **새 환경 추가**: prod 환경 추가 시 jumpbox 비용 없음
- **멀티 리전**: 리전별 공통 인프라 확장 가능
- **팀 확장**: 새 개발자 추가 시 통합 관리

이 계획을 통해 현재의 비효율적인 환경별 중복을 해결하고, 확장 가능하며 비용 효율적인 인프라 구조를 구축할 수 있습니다.
