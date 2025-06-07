# 🏗️ 3-Tier 클라우드 인프라 아키텍처

## 📋 목차
- [시스템 개요](#시스템-개요)
- [네트워크 아키텍처](#네트워크-아키텍처)
- [컴포넌트 구조](#컴포넌트-구조)
- [통신 흐름](#통신-흐름)
- [보안 모델](#보안-모델)
- [배포 전략](#배포-전략)

---

## 🎯 시스템 개요

### 아키텍처 특징
- **3-Tier Architecture**: Frontend(GCS) + Backend/AI(Compute) + Database(Compute)
- **Hybrid VPN**: WireGuard를 통한 안전한 내부 네트워크 접근
- **환경 분리**: dev, test, prod 환경별 독립 네트워크
- **공유 관리**: 통합 Jumpbox를 통한 효율적인 운영

### 기술 스택
```yaml
Infrastructure: Google Cloud Platform
IaC: Terraform (모듈화)
Configuration: Ansible (역할 기반)
VPN: WireGuard (현대적 VPN)
Frontend: GCS + CDN + Global Load Balancer
Backend: Spring Boot on Compute Engine
AI: FastAPI/Django on Compute Engine  
Database: MySQL on Compute Engine
```

---

## 🌐 네트워크 아키텍처

### IP 할당 체계
```
📡 Management VPC (10.100.0.0/16)
├── Shared Jumpbox: 10.100.0.10
└── WireGuard Server: 10.8.0.1

🧪 Test Environment (10.0.0.0/24)
├── Jumpbox: 10.0.0.10 → 34.64.123.40 (External)
├── Backend: 10.0.0.20 (Private)
├── AI: 10.0.0.30 (Private)
└── Database: 10.0.0.40 (Private)

🔧 Dev Environment (10.1.0.0/16) 
└── Single VM: 10.1.0.10 → External IP

🚀 Prod Environment (10.2.0.0/16)
└── [구성 예정]

📱 VPN Network (10.8.0.0/24)
├── Server: 10.8.0.1
├── Admin: 10.8.0.2
├── Developers: 10.8.0.3-10
└── Automation: 10.8.0.11-20
```

### 네트워크 구조
```
                 Internet
                    │
        ┌───────────┼───────────┐
        │           │           │
   Load Balancer  CDN      Jumpbox
   (Backend/AI)  (Frontend)    │
        │           │           │
        └───── Private Network ─┘
                    │
       ┌────────────┼────────────┐
       │            │            │
   Backend VM    AI VM     Database VM
   :8080         :8100       :3306
   (Spring)     (FastAPI)    (MySQL)
```

---

## 🧩 컴포넌트 구조

### 1. Frontend Layer (Static Hosting)
```yaml
Service: Google Cloud Storage + CDN
Domain: Custom Domain with SSL
Components:
  - GCS Bucket: 정적 파일 저장
  - Global Load Balancer: HTTPS 종료점
  - Managed SSL Certificate: 자동 갱신
  - CDN: 전역 캐싱
```

### 2. Application Layer (Compute Engine)
```yaml
Backend Service:
  Instance: e2-standard-2 (2 vCPU, 8GB RAM)
  Disk: 30GB SSD
  Network: Private (10.0.0.20)
  Services: Spring Boot (Port 8080)

AI Service:
  Instance: e2-highmem-2 (2 vCPU, 16GB RAM) 
  Disk: 40GB SSD
  Network: Private (10.0.0.30)
  Services: FastAPI/Django (Port 8100)
```

### 3. Data Layer (Database)
```yaml
Database Service:
  Instance: e2-standard-2 (2 vCPU, 8GB RAM)
  Disk: 100GB SSD (확장 가능)
  Network: Private (10.0.0.40)
  Services: MySQL 8.0 (Port 3306)
  Backup: 자동 백업 스케줄링
```

### 4. Management Layer (Jumpbox)
```yaml
Shared Jumpbox:
  Instance: e2-small (1 vCPU, 2GB RAM)
  Network: Management VPC (10.100.0.10)
  Services: 
    - WireGuard VPN Server (Port 51820)
    - SSH Gateway (Port 22)
    - Terraform/Ansible 도구
```

---

## 🔄 통신 흐름

### 1. 사용자 트래픽 흐름
```
Client Request → Global Load Balancer → CDN → GCS Bucket
     ↓
API Request → Load Balancer → Backend VM (Spring Boot)
     ↓
Database Query → Private Network → Database VM (MySQL)
     ↓
AI Request → Internal Network → AI VM (FastAPI)
```

### 2. 개발자 접근 흐름
```
Developer → WireGuard VPN → Management VPC → Environment VPC
    ↓
SSH Access → Jumpbox → Private VMs (Backend/AI/Database)
    ↓
Ansible Deployment → Configuration Management
```

### 3. 서비스 간 통신
```yaml
Frontend ↔ Backend:
  Protocol: HTTPS
  Path: /api/*
  Load Balancer: Global HTTP(S)

Backend ↔ Database:
  Protocol: TCP (MySQL Protocol)
  Port: 3306
  Network: Private (10.0.0.0/24)

Backend ↔ AI:
  Protocol: HTTP/HTTPS
  Port: 8100
  Path: /generation/*
  Network: Private (10.0.0.0/24)
```

---

## 🔒 보안 모델

### 네트워크 보안
```yaml
Public Access:
  - Frontend CDN: 인터넷 전체 (443/80)
  - Jumpbox SSH: 특정 IP만 (22)
  - WireGuard: 인터넷 전체 (51820/UDP)

Private Network:
  - Backend/AI/Database: VPN을 통해서만 접근
  - 내부 통신: Private IP만 사용
  - NAT Gateway: 아웃바운드 인터넷 접근
```

### 방화벽 규칙
```yaml
SSH Access:
  Source: 0.0.0.0/0 (Jumpbox only)
  Target: ssh tag
  Ports: 22

Web Traffic:
  Source: 0.0.0.0/0
  Target: web tag  
  Ports: 80, 443

Internal Communication:
  Source: VPN CIDR (10.8.0.0/24)
  Target: internal tag
  Ports: 3306, 8080, 8100, 9090, 6379

WireGuard VPN:
  Source: 0.0.0.0/0
  Target: wireguard-server tag
  Ports: 51820/UDP
```

### 인증 및 권한
```yaml
SSH Access:
  - Key-based Authentication
  - No Password Login
  - Individual User Keys

VPN Access:
  - WireGuard Public/Private Keys
  - Per-user Configuration
  - IP-based Access Control

GCP IAM:
  - Service Account for Compute
  - Minimal Required Permissions
  - Environment-based Role Separation
```

---

## 🚀 배포 전략

### Terraform 모듈 구조
```
terraform/
├── bootstrap/           # GCS Backend + KMS
├── environments/        # 환경별 설정
│   ├── dev/            # 개발 환경
│   ├── test/           # 테스트 환경
│   ├── prod/           # 운영 환경  
│   └── shared/         # 공유 관리 인프라
└── modules/            # 재사용 가능한 모듈
    ├── network/        # VPC, 서브넷, 방화벽
    ├── compute/        # VM 인스턴스
    ├── gcs_cdn/        # Frontend 호스팅
    ├── load_balancer/  # HTTP(S) 로드밸런서
    ├── shared_jumpbox/ # 관리 서버
    ├── static_ip/      # 고정 IP 관리
    └── vpc_peering/    # VPC 피어링
```

### Ansible 구조
```
ansible/
├── inventories/        # 환경별 인벤토리
│   ├── dev.ini
│   ├── test.ini
│   ├── prod.ini
│   └── shared.ini
├── playbooks/          # 통합 플레이북
│   ├── main.yml        # 메인 배포 플레이북
│   ├── deploy_shared.yml # 공유 인프라
│   └── dev_db_fix.yml    # 개발 전용
├── roles/              # 기능별 역할
│   ├── base_system/    # 기본 시스템 설정
│   ├── docker_net/     # Docker 환경
│   ├── be_deploy/      # Backend 배포
│   ├── ai_deploy/      # AI 서비스 배포
│   ├── database/       # MySQL 설정
│   ├── nginx_conf/     # Nginx 프록시
│   └── wireguard_setup/ # VPN 설정
└── group_vars/         # 환경별 변수
    ├── all/           # 공통 변수
    ├── dev/           # 개발 환경 변수
    ├── test/          # 테스트 환경 변수
    └── prod/          # 운영 환경 변수
```

### 배포 명령어
```bash
# 인프라 배포
terraform -chdir=terraform/environments/test apply

# 애플리케이션 배포  
ansible-playbook -i inventories/test.ini main.yml -e "env=test"

# 특정 서비스만 배포
ansible-playbook -i inventories/test.ini main.yml -e "env=test" --tags backend

# 전체 태그 시스템
# base, database, backend, ai, frontend, nginx, monitoring, backup
```

---

## 📊 리소스 사양

### 컴퓨팅 리소스
| 컴포넌트 | 인스턴스 타입 | vCPU | 메모리 | 디스크 | 용도 |
|---------|-------------|------|--------|--------|------|
| Jumpbox | e2-small | 1 | 2GB | 20GB | 관리/VPN |
| Backend | e2-standard-2 | 2 | 8GB | 30GB | Spring Boot |
| AI | e2-highmem-2 | 2 | 16GB | 40GB | ML/AI 모델 |
| Database | e2-standard-2 | 2 | 8GB | 100GB | MySQL |

### 네트워크 리소스
- **VPC**: 환경별 독립 네트워크
- **Static IP**: Jumpbox용 고정 외부 IP
- **Load Balancer**: Global HTTP(S) LB
- **CDN**: 전역 캐싱 네트워크
- **VPN**: WireGuard 터널

### 예상 비용 (월간, 서울 리전)
```yaml
Test Environment:
  - Compute: ~$150/월 (4 VMs)
  - Network: ~$10/월 (LB, IP)
  - Storage: ~$20/월 (GCS, Disk)
  Total: ~$180/월

Production (추정):
  - Compute: ~$300/월 (고사양, 중복화)
  - Network: ~$30/월 (트래픽 증가)
  - Storage: ~$50/월 (백업, 로그)
  Total: ~$380/월
```

---

> 💡 **핵심 특징**: 이 아키텍처는 비용 효율성과 보안성을 동시에 달성하며, WireGuard VPN을 통해 전통적인 Jump Box의 한계를 극복한 현대적인 클라우드 인프라입니다.
