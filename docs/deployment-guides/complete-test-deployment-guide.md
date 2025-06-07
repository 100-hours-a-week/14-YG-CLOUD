# 🚀 14-YG-CLOUD Test 환경 완전한 배포 가이드

> **작성일**: 2025년 6월 5일  
> **목적**: Test 환경 3-tier 아키텍처 완전 배포 (GCS+CDN 프론트엔드 + Route53 도메인 포함)  
> **기술스택**: Terraform + Ansible + GCS + Cloud CDN + Route53

## 📋 목차

1. [배포 개요](#-배포-개요)
2. [사전 준비사항](#-사전-준비사항)
3. [1단계: Bootstrap 인프라 준비](#1단계-bootstrap-인프라-준비)
4. [2단계: Terraform 인프라 배포](#2단계-terraform-인프라-배포)
5. [3단계: Ansible 애플리케이션 배포](#3단계-ansible-애플리케이션-배포)
6. [4단계: Frontend GCS+CDN 배포](#4단계-frontend-gcscdn-배포)
7. [5단계: Route53 도메인 설정](#5단계-route53-도메인-설정)
8. [6단계: 통합 테스트](#6단계-통합-테스트)
9. [트러블슈팅](#-트러블슈팅)

---

## 🎯 배포 개요

### 전체 아키텍처
```
┌─────────────────────────────────────────────────────────┐
│                     인터넷                              │
└─────────────────────┬───────────────────────────────────┘
                      │
              ┌───────▼───────┐
              │    Route53    │ ← test.moongsan.com
              │  DNS 관리     │
              └───────┬───────┘
                      │
              ┌───────▼───────┐
              │Global Load    │ ← HTTPS 종료 + SSL
              │Balancer       │
              │34.8.174.93    │
              └───────┬───────┘
                      │
              ┌───────▼───────┐
              │  Cloud CDN    │ ← 캐시 레이어
              │ (Edge Servers)│
              └───────┬───────┘
                      │
              ┌───────▼───────┐
              │   GCS 버킷    │ ← React 빌드 파일
              │moongsan-test- │
              │  frontend     │
              └───────────────┘
```

### 3-Tier 백엔드 구조
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  Jump Box       │    │  Backend        │    │  Database       │
│  (Bastion)      │    │  (Spring Boot)  │    │  (MySQL)        │
│  10.8.0.1       │    │  10.0.0.3       │    │  10.0.0.2       │
│  WireGuard VPN  │    │  Docker         │    │  Direct Install │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                │
                       ┌─────────────────┐
                       │  AI Server      │
                       │  (FastAPI)      │
                       │  10.0.0.5       │
                       │  Docker         │
                       └─────────────────┘
```

---

## 🛠️ 사전 준비사항

### 1. 필수 도구 설치
```bash
# Terraform 설치 확인
terraform --version  # >= 1.0

# Ansible 설치 확인
ansible --version    # >= 2.9

# Google Cloud SDK 설치 확인
gcloud --version

# kubectl 설치 확인 (선택사항)
kubectl version --client
```

### 2. GCP 인증 설정
```bash
# GCP 로그인
gcloud auth login

# 프로젝트 설정
gcloud config set project ktb-2-moongsan

# Application Default Credentials 설정
gcloud auth application-default login
```

### 3. SSH 키 준비
```bash
# SSH 키 확인
ls -la ~/.ssh/lsh-study-key*

# 없다면 생성
ssh-keygen -t rsa -b 4096 -f ~/.ssh/lsh-study-key -C "your-email@example.com"
```

### 4. 프로젝트 저장소 준비
```bash
# 프로젝트 디렉토리로 이동
cd /Users/lsh/Documents/local/3tier-moongsan/14-YG-CLOUD

# 최신 코드 확인
git status
git pull origin main
```

---

## 1단계: Bootstrap 인프라 준비

> **목적**: GCS 백엔드와 KMS 암호화 키 생성

### 1.1 Bootstrap 디렉토리로 이동
```bash
cd terraform/bootstrap
```

### 1.2 변수 설정
```bash
# terraform.tfvars 파일 생성
cat > terraform.tfvars << EOF
project_id = "ktb-2-moongsan"
region     = "asia-northeast3"
EOF
```

### 1.3 Terraform 초기화
```bash
terraform init
```

### 1.4 배포 계획 확인
```bash
terraform plan
```

### 1.5 Bootstrap 리소스 생성
```bash
terraform apply -auto-approve
```

### 1.6 Bootstrap 결과 확인
```bash
# 생성된 GCS 버킷 확인
gsutil ls | grep terraform-state

# KMS 키 확인
gcloud kms keys list --location=asia-northeast3 --keyring=terraform-state

echo "✅ Bootstrap 완료!"
```

---

## 2단계: Terraform 인프라 배포

> **목적**: Test 환경 3-tier 인프라 생성

### 2.1 Test 환경 디렉토리로 이동
```bash
cd ../environments/test
```

### 2.2 Backend 설정 활성화
```bash
# backend.tf 파일에서 주석 해제
sed -i '' 's/^# //' backend.tf
```

### 2.3 변수 설정
```bash
# terraform.tfvars 파일 생성
cat > terraform.tfvars << EOF
# 프로젝트 정보
project_id   = "ktb-2-moongsan"
project_name = "moongsan"
env          = "test"
region       = "asia-northeast3"
zone         = "asia-northeast3-a"

# 도메인 설정
domain_name = "test.moongsan.com"

# 네트워크 설정
subnet_cidr    = "10.0.0.0/24"
wireguard_cidr = "10.8.0.0/24"

# SSH 설정
ssh_public_key_path = "~/.ssh/lsh-study-key.pub"
ssh_source_ranges   = ["0.0.0.0/0"]

# WireGuard 키 설정 (실제 키로 교체)
wireguard_private_key = "YOUR_WIREGUARD_PRIVATE_KEY"
wireguard_public_key  = "YOUR_WIREGUARD_PUBLIC_KEY"

# WireGuard 클라이언트 설정
wireguard_clients = []
EOF
```

### 2.4 Terraform 초기화
```bash
terraform init
```

### 2.5 단계별 배포

#### 2.5.1 네트워크 인프라 배포
```bash
# VPC, 서브넷, 방화벽 생성
terraform apply -target=module.network -auto-approve
```

#### 2.5.2 고정 IP 배포
```bash
# 고정 IP 주소 생성
terraform apply -target=module.jumpbox_ip -auto-approve
terraform apply -target=module.backend_ip -auto-approve
terraform apply -target=module.ai_ip -auto-approve
terraform apply -target=module.database_ip -auto-approve
```

#### 2.5.3 VM 인스턴스 배포
```bash
# Jump Box 생성
terraform apply -target=module.jumpbox -auto-approve

# Backend VM 생성
terraform apply -target=module.backend -auto-approve

# AI VM 생성
terraform apply -target=module.ai -auto-approve

# Database VM 생성
terraform apply -target=module.database -auto-approve
```

#### 2.5.4 Frontend GCS+CDN 배포
```bash
# GCS 버킷과 CDN 생성
terraform apply -target=module.frontend_hosting -auto-approve
```

### 2.6 배포 결과 확인
```bash
# 전체 인프라 상태 확인
terraform show

# 중요한 출력값 확인
terraform output jumpbox_public_ip
terraform output backend_internal_ip
terraform output ai_internal_ip
terraform output database_internal_ip
terraform output frontend_cdn_ip
terraform output frontend_url

echo "✅ Terraform 인프라 배포 완료!"
```

---

## 3단계: Ansible 애플리케이션 배포

> **목적**: 3-tier 서버에 애플리케이션 설치 및 설정

### 3.1 Ansible 디렉토리로 이동
```bash
cd ../../ansible
```

### 3.2 연결 테스트
```bash
# 모든 서버 연결 확인
ansible -i inventories/test.ini all -m ping
```

### 3.3 단계별 배포 (최적화된 base_system role 사용)

#### 3.3.1 기본 시스템 설정
```bash
# 기본 패키지 설치 (조건별 설치 적용)
ansible-playbook -i inventories/test.ini playbooks/main.yml \
  -e "env=test" \
  --tags base_system

# 배포 결과 확인
ansible -i inventories/test.ini backend -m shell -a "which docker"
ansible -i inventories/test.ini ai -m shell -a "which python3"
ansible -i inventories/test.ini database -m shell -a "which mysql"
```

#### 3.3.2 데이터베이스 설정
```bash
# MySQL 설치 및 설정
ansible-playbook -i inventories/test.ini playbooks/main.yml \
  -e "env=test" \
  --tags database \
  --limit database

# 데이터베이스 상태 확인
ansible -i inventories/test.ini database -m shell -a "sudo systemctl status mysql"
```

#### 3.3.3 백엔드 배포
```bash
# Spring Boot 애플리케이션 배포
ansible-playbook -i inventories/test.ini playbooks/main.yml \
  -e "env=test" \
  --tags be_deploy \
  --limit backend

# 백엔드 상태 확인
ansible -i inventories/test.ini backend -m shell -a "docker ps | grep be_moongsan"
```

#### 3.3.4 AI 서비스 배포
```bash
# FastAPI 애플리케이션 배포
ansible-playbook -i inventories/test.ini playbooks/main.yml \
  -e "env=test" \
  --tags ai_deploy \
  --limit ai

# AI 서비스 상태 확인
ansible -i inventories/test.ini ai -m shell -a "docker ps | grep ai_moongsan"
```

### 3.4 서비스 통합 테스트
```bash
# 백엔드 API 테스트
curl -I http://$(terraform output -raw backend_internal_ip):8080/health

# AI 서비스 테스트
curl -I http://$(terraform output -raw ai_internal_ip):8100/health

echo "✅ Ansible 애플리케이션 배포 완료!"
```

---

## 4단계: Frontend GCS+CDN 배포

> **목적**: React 앱을 GCS+CDN에 배포

### 4.1 Frontend 빌드 준비
```bash
# Frontend 프로젝트로 이동 (프로젝트 구조에 따라 경로 조정)
cd ../14-YG-FE

# 의존성 설치
npm install

# Test 환경용 빌드
npm run build
```

### 4.2 GCS 버킷 정보 확인
```bash
# Terraform에서 생성된 버킷 정보 확인
cd ../14-YG-CLOUD/terraform/environments/test
BUCKET_NAME=$(terraform output -raw frontend_hosting | jq -r '.bucket_name')
CDN_IP=$(terraform output -raw frontend_hosting | jq -r '.cdn_ip_address')

echo "버킷 이름: $BUCKET_NAME"
echo "CDN IP: $CDN_IP"
```

### 4.3 Frontend 파일 업로드
```bash
# 기존 파일 삭제 (선택사항)
gsutil -m rm gs://$BUCKET_NAME/** || true

# 새 빌드 파일 업로드
gsutil -m cp -r ../../../14-YG-FE/dist/* gs://$BUCKET_NAME/

# 업로드 확인
gsutil ls -la gs://$BUCKET_NAME/
```

### 4.4 CDN 캐시 무효화
```bash
# CDN 캐시 무효화 (즉시 반영)
gcloud compute url-maps invalidate-cdn-cache moongsan-test-frontend-urlmap \
  --path "/*" \
  --global

# 무효화 상태 확인
gcloud compute operations list --global --filter="operationType:invalidateCache"
```

### 4.5 배포 확인
```bash
# HTTP 응답 확인
curl -I https://$CDN_IP/

# 예상 출력:
# HTTP/2 200
# content-type: text/html
# cache-control: public, max-age=3600
# server: gws

echo "✅ Frontend GCS+CDN 배포 완료!"
```

---

## 5단계: Route53 도메인 설정

> **목적**: test.moongsan.com 도메인을 CDN에 연결

### 5.1 DNS Zone 생성 (이미 있다면 건너뛰기)
```bash
# DNS Zone 확인
gcloud dns managed-zones list | grep moongsan-zone

# 없다면 생성
gcloud dns managed-zones create moongsan-zone \
  --dns-name=moongsan.com \
  --description="Moongsan domain zone"
```

### 5.2 Test 서브도메인 A 레코드 추가
```bash
# CDN IP 주소 확인
CDN_IP=$(terraform output -raw frontend_hosting | jq -r '.cdn_ip_address')
echo "CDN IP: $CDN_IP"

# DNS 레코드 트랜잭션 시작
gcloud dns record-sets transaction start --zone=moongsan-zone

# Test 서브도메인 A 레코드 추가
gcloud dns record-sets transaction add \
  --name=test.moongsan.com \
  --ttl=300 \
  --type=A \
  --zone=moongsan-zone \
  $CDN_IP

# 트랜잭션 실행
gcloud dns record-sets transaction execute --zone=moongsan-zone
```

### 5.3 SSL 인증서 자동 발급
```bash
# 관리형 SSL 인증서 생성
gcloud compute ssl-certificates create moongsan-test-ssl-cert \
  --domains=test.moongsan.com \
  --global

# 인증서 상태 확인 (발급까지 최대 30분 소요)
gcloud compute ssl-certificates describe moongsan-test-ssl-cert \
  --global \
  --format="value(managed.status)"
```

### 5.4 DNS 전파 확인
```bash
# DNS 전파 확인 (5-10분 소요)
nslookup test.moongsan.com
dig test.moongsan.com

# 전파 완료까지 대기
echo "DNS 전파 대기 중... (5-10분)"
while ! nslookup test.moongsan.com | grep -q "$CDN_IP"; do
  sleep 30
  echo "DNS 전파 확인 중..."
done
echo "✅ DNS 전파 완료!"
```

---

## 6단계: 통합 테스트

> **목적**: 전체 시스템 동작 확인

### 6.1 Frontend 접근 테스트
```bash
# HTTPS 접근 테스트
curl -I https://test.moongsan.com/

# 브라우저에서 접근 (macOS)
open https://test.moongsan.com

# 브라우저에서 접근 (Linux)
xdg-open https://test.moongsan.com
```

### 6.2 Backend API 테스트
```bash
# VPN 연결 후 Backend API 테스트
# (실제 API 엔드포인트는 애플리케이션에 따라 조정)
curl -X GET https://test.moongsan.com/api/health

# 또는 내부 IP로 직접 테스트 (VPN 연결 필요)
curl -X GET http://10.0.0.3:8080/health
```

### 6.3 AI 서비스 테스트
```bash
# AI 서비스 API 테스트
curl -X GET http://10.0.0.5:8100/health
```

### 6.4 데이터베이스 연결 테스트
```bash
# 데이터베이스 연결 테스트 (Jump Box를 통해)
gcloud compute ssh moongsan-test-jumpbox --zone=asia-northeast3-a \
  --command="mysql -h 10.0.0.2 -u moongsan_admin -p -e 'SHOW DATABASES;'"
```

### 6.5 성능 테스트
```bash
# CDN 캐시 성능 테스트
for i in {1..5}; do
  echo "Test $i:"
  curl -w "Time: %{time_total}s\n" -s -o /dev/null https://test.moongsan.com/
done
```

---

## 🛠️ 트러블슈팅

### 자주 발생하는 문제와 해결책

#### 1. Terraform 배포 실패
```bash
# 상태 확인
terraform show

# 특정 리소스 재생성
terraform taint module.jumpbox.google_compute_instance.vm
terraform apply

# 전체 재배포
terraform destroy -auto-approve
terraform apply -auto-approve
```

#### 2. Ansible 연결 실패
```bash
# SSH 연결 테스트
ssh -i ~/.ssh/lsh-study-key ubuntu@$(terraform output -raw jumpbox_public_ip)

# 인벤토리 파일 확인
cat inventories/test.ini

# VPN 연결 확인
sudo wg show
```

#### 3. Frontend 403 Forbidden 오류
```bash
# 버킷 권한 확인
gsutil iam get gs://moongsan-test-frontend

# 퍼블릭 읽기 권한 설정
gsutil iam ch allUsers:objectViewer gs://moongsan-test-frontend
```

#### 4. SSL 인증서 발급 실패
```bash
# DNS 설정 확인
nslookup test.moongsan.com

# SSL 인증서 상태 확인
gcloud compute ssl-certificates describe moongsan-test-ssl-cert --global

# 재발급
gcloud compute ssl-certificates delete moongsan-test-ssl-cert --global
# 위의 5.3 단계 재실행
```

#### 5. CDN 캐시 문제
```bash
# 캐시 무효화
gcloud compute url-maps invalidate-cdn-cache moongsan-test-frontend-urlmap \
  --path "/*" --global

# 브라우저 강제 새로고침
# Ctrl+F5 (Windows) 또는 Cmd+Shift+R (Mac)
```

### 디버깅 명령어 모음

#### 인프라 상태 확인
```bash
# VM 인스턴스 상태
gcloud compute instances list --filter="name:moongsan-test-*"

# 방화벽 규칙 확인
gcloud compute firewall-rules list --filter="name:moongsan-test-*"

# GCS 버킷 확인
gsutil ls -la gs://moongsan-test-frontend/

# CDN 상태 확인
gcloud compute backend-buckets describe moongsan-test-frontend-backend
```

#### 네트워크 디버깅
```bash
# DNS 전파 확인
dig test.moongsan.com @8.8.8.8

# SSL 인증서 확인
openssl s_client -connect test.moongsan.com:443 -servername test.moongsan.com

# CDN 응답 헤더 확인
curl -I https://test.moongsan.com/ -H "Cache-Control: no-cache"
```

---

## 📊 배포 완료 체크리스트

- [ ] **Bootstrap 인프라**: GCS 백엔드, KMS 키 생성
- [ ] **네트워크 인프라**: VPC, 서브넷, 방화벽 생성
- [ ] **VM 인스턴스**: Jump Box, Backend, AI, Database 생성
- [ ] **GCS+CDN**: Frontend 호스팅 인프라 생성
- [ ] **Base System**: 최적화된 패키지 설치 (조건별)
- [ ] **Database**: MySQL 설치 및 설정
- [ ] **Backend**: Spring Boot 애플리케이션 배포
- [ ] **AI Service**: FastAPI 애플리케이션 배포
- [ ] **Frontend**: React 앱 GCS+CDN 배포
- [ ] **DNS**: Route53 도메인 설정
- [ ] **SSL**: 자동 SSL 인증서 발급
- [ ] **통합 테스트**: 전체 시스템 동작 확인

---

## 🎉 배포 완료!

축하합니다! Test 환경의 완전한 3-tier 아키텍처가 성공적으로 배포되었습니다.

### 접근 URL
- **Frontend**: https://test.moongsan.com
- **Backend API**: http://10.0.0.3:8080 (VPN 연결 필요)
- **AI Service**: http://10.0.0.5:8100 (VPN 연결 필요)

### 관리 접속
- **Jump Box**: `gcloud compute ssh moongsan-test-jumpbox --zone=asia-northeast3-a`
- **VPN 연결**: WireGuard 클라이언트 설정 파일 사용

### 다음 단계
1. **모니터링 설정**: Prometheus, Grafana 설정
2. **로그 관리**: ELK Stack 구성
3. **백업 전략**: 정기 백업 스케줄 설정
4. **성능 최적화**: CDN 캐시 정책 세부 조정

---

**문서 마지막 업데이트**: 2025년 6월 5일  
**작성자**: DevOps Team  
**관련 문서**: [GCS+CDN 설정](./gcs-cdn-setup.md), [WireGuard VPN 설정](../security-guides/wireguard-setup.md)
