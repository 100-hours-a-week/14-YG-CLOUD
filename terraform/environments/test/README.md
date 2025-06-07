# 최적화된 3-Tier 아키텍처 with WireGuard VPN

## 🏗️ 아키텍처 개요

```
┌─────────────────────────────┐    ┌──────────────────────────┐
│     Frontend (GCS + CDN)    │    │     WireGuard VPN        │
│  ┌─────────────────────────┐ │    │  ┌─────────────────────┐ │
│  │  Cloud Storage Bucket   │ │    │  │    Jump Box VM      │ │
│  │  + Global Load Balancer │ │    │  │   (VPN Server)      │ │
│  │  + Managed SSL Cert     │ │    │  │  Public IP: x.x.x.x │ │
│  └─────────────────────────┘ │    │  │  VPN IP: 10.8.0.1   │ │
│                               │    │  └─────────────────────┘ │
│  URL: https://test.domain.com │    │                          │
└─────────────────────────────┘    └──────────────────────────┘
                 │                                │
                 │ HTTPS                         │ WireGuard
                 │ (Global CDN)                  │ (UDP 51820)
                 ▼                               ▼
         ┌──────────────┐              ┌─────────────────────┐
         │    Users     │              │   Private Network   │
         │  (Internet)  │              │   (10.0.0.0/24)     │
         └──────────────┘              └─────────────────────┘
                                                │
                              ┌─────────────────┼─────────────────┐
                              │                 │                 │
                   ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐
                   │   Backend VM    │ │     AI VM       │ │  Database VM    │
                   │ Internal IP     │ │ Internal IP     │ │ Internal IP     │
                   │ WireGuard:      │ │ WireGuard:      │ │ WireGuard:      │
                   │ 10.8.0.20       │ │ 10.8.0.30       │ │ 10.8.0.40       │
                   │                 │ │                 │ │                 │
                   │ Spring Boot     │ │ FastAPI         │ │ MySQL           │
                   │ Port: 8080      │ │ Port: 8100      │ │ Port: 3306      │
                   └─────────────────┘ └─────────────────┘ └─────────────────┘
```

## 🔧 주요 특징

### Frontend (GCS + CDN)
- **Cloud Storage**: React 빌드 파일 호스팅
- **Global Load Balancer**: 전 세계 트래픽 분산
- **Cloud CDN**: 캐싱으로 성능 최적화
- **Managed SSL**: 자동 HTTPS 인증서 관리
- **비용 효율**: VM 없이 정적 웹 호스팅

### Backend Infrastructure (VMs + VPN)
- **Jump Box**: WireGuard VPN 서버, SSH 접근점
- **Private VMs**: Backend, AI, Database 서버
- **WireGuard VPN**: 내부 네트워크 보안 통신
- **방화벽**: 최소 권한 원칙 적용

## 🌐 네트워크 설계

### IP 할당
- **Public Network**: `10.0.0.0/24`
- **VPN Network**: `10.8.0.0/24`
  - Jump Box (VPN Server): `10.8.0.1/24`
  - Backend VM: `10.8.0.20/32`
  - AI VM: `10.8.0.30/32`
  - Database VM: `10.8.0.40/32`

### 보안 규칙
- SSH: Jump Box만 외부 접근 허용
- HTTP/HTTPS: Frontend는 CDN을 통해서만 접근
- Internal APIs: VPN을 통해서만 내부 통신

## 🚀 배포 가이드

### 1. WireGuard 키 생성
```bash
cd scripts
./generate-wireguard-keys.sh
```

### 2. Terraform 설정
```bash
cd terraform/environments/test
cp terraform.tfvars.example terraform.tfvars
# terraform.tfvars에 생성된 키 입력
```

### 3. 인프라 배포
```bash
terraform init
terraform plan
terraform apply
```

### 4. Frontend 배포
```bash
cd ../../../scripts
./deploy-frontend.sh test ../14-YG-FE/dist
```

### 5. Backend 배포 (Ansible)
```bash
cd ansible
ansible-playbook -i inventories/test.ini main.yml -e "env=test"
```

## 💰 비용 최적화

### 기존 아키텍처 vs 최적화된 아키텍처
- **Before**: 5개 VM (Frontend, Backend, AI, Database, Jump Box)
- **After**: 4개 VM + GCS/CDN (Backend, AI, Database, Jump Box)
- **절약**: Frontend VM 비용 제거, CDN으로 성능 향상

### 예상 월 비용 (서울 리전 기준)
- **VM 4대**: ~$150-200/월
- **GCS + CDN**: ~$10-20/월 (트래픽에 따라)
- **네트워킹**: ~$5-10/월
- **총합**: ~$165-230/월

## 🔄 CI/CD 통합

### Frontend 자동 배포
```yaml
# GitHub Actions 예시
- name: Deploy Frontend
  run: |
    npm run build
    gsutil -m rsync -r -d dist/ gs://bucket-name/
```

### Backend 자동 배포
```yaml
# Ansible을 통한 Rolling Deployment
- name: Deploy Backend
  run: |
    ansible-playbook -i inventories/test.ini main.yml -e "env=test" --tags "backend"
```

## 🛡️ 보안 강화

1. **네트워크 분리**: Public과 Private 네트워크 완전 분리
2. **VPN 암호화**: WireGuard로 모든 내부 통신 암호화
3. **최소 권한**: 필요한 포트만 개방
4. **SSL/TLS**: Frontend HTTPS 강제
5. **방화벽**: GCP 방화벽 규칙으로 접근 제어

## 📈 모니터링 & 관리

- **Jump Box**: 중앙집중식 관리 서버
- **VPN 접근**: 개발자는 VPN을 통해서만 내부 서버 접근
- **로그 수집**: 모든 서버 로그 중앙화
- **성능 모니터링**: Prometheus + Grafana
