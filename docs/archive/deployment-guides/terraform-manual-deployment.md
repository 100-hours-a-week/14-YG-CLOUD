# 🚀 Terraform 수동 배포 가이드 (Script-Free)

> **철학**: 스크립트에 의존하지 않고 순수 Terraform 명령어로 배포하는 안정적인 방법

## 📋 목차

1. [사전 준비](#1-사전-준비)
2. [Bootstrap 배포](#2-bootstrap-배포-최초-1회)
3. [환경별 인프라 배포](#3-환경별-인프라-배포)
4. [배포 확인](#4-배포-확인)
5. [문제 해결](#5-문제-해결)
6. [완전한 정리](#6-완전한-정리)

## 1. 사전 준비

### 1.1 GCP 인증 설정

```bash
# GCP 계정 로그인
gcloud auth login

# Application Default Credentials 설정 (Terraform용)
gcloud auth application-default login

# 프로젝트 설정
gcloud config set project ktb-2-moongsan

# 현재 설정 확인
gcloud config list
```

### 1.2 필요한 도구 확인

```bash
# Terraform 버전 확인 (1.0 이상 필요)
terraform version

# gcloud CLI 확인
gcloud version

# SSH 키 확인
ls -la ~/.ssh/lsh-study-key*
```

## 2. Bootstrap 배포 (최초 1회)

> **목적**: GCS 백엔드와 KMS 암호화 키 생성

### 2.1 Bootstrap 디렉토리로 이동

```bash
cd terraform/bootstrap
```

### 2.2 Terraform 초기화

```bash
# 초기화 (Provider 다운로드)
terraform init

# 초기화 확인
ls -la .terraform/
```

### 2.3 배포 계획 확인

```bash
# 계획 확인
terraform plan

# 생성될 리소스 확인:
# - google_storage_bucket.terraform_state
# - google_kms_key_ring.terraform_state
# - google_kms_crypto_key.terraform_state_key
# - google_project_service.apis (6개 API)
```

### 2.4 Bootstrap 리소스 생성

```bash
# 리소스 생성
terraform apply

# 'yes' 입력하여 확인
```

### 2.5 Bootstrap 결과 확인

```bash
# 생성된 리소스 확인
terraform output

# GCS 버킷 확인
gsutil ls gs://ktb-2-moongsan-terraform-state/

# Bootstrap 완료 표시
echo "✅ Bootstrap 완료: GCS 백엔드 준비됨"
```

## 3. 환경별 인프라 배포

### 3.1 Test 환경 설정

```bash
# Test 환경 디렉토리로 이동
cd ../environments/test

# 설정 파일 생성
cp terraform.tfvars.example terraform.tfvars
```

### 3.2 설정 파일 편집 (필요시)

```bash
# 설정 파일 편집
nano terraform.tfvars

# 확인해야 할 주요 설정:
# - project_id = "ktb-2-moongsan"
# - env = "test"
# - region = "asia-northeast3"
# - ssh_public_key_path = "~/.ssh/lsh-study-key.pub"
```

### 3.3 SSH 키 확인

```bash
# SSH 공개키 존재 확인
cat ~/.ssh/lsh-study-key.pub

# 없으면 생성
# ssh-keygen -t rsa -b 4096 -f ~/.ssh/lsh-study-key -N ""
```

### 3.4 Terraform 초기화 (GCS 백엔드 연결)

```bash
# 초기화 (Bootstrap에서 생성한 GCS 백엔드 사용)
terraform init

# 백엔드 연결 확인
cat .terraform/terraform.tfstate | grep "backend"
```

### 3.5 배포 계획 확인

```bash
# 전체 계획 확인
terraform plan

# 생성될 주요 리소스:
# - VPC 네트워크 및 서브넷
# - VM 인스턴스 3개 (backend, ai, database)
# - 고정 IP 주소
# - 방화벽 규칙
# - GCS 버킷 (Frontend)
# - Cloud CDN
```

### 3.6 인프라 생성

```bash
# 인프라 생성
terraform apply

# 'yes' 입력하여 확인
# 완료까지 약 3-5분 소요
```

### 3.7 생성된 리소스 확인

```bash
# 모든 출력값 확인
terraform output

# 주요 출력값:
# - vm_backend_ip
# - vm_ai_ip  
# - vm_database_ip
# - frontend_bucket_name
# - frontend_cdn_url
```

## 4. 배포 확인

### 4.1 VM 인스턴스 접속 테스트

```bash
# Backend VM 접속
ssh -i ~/.ssh/lsh-study-key ubuntu@$(terraform output -raw vm_backend_ip)

# AI VM 접속  
ssh -i ~/.ssh/lsh-study-key ubuntu@$(terraform output -raw vm_ai_ip)

# Database VM 접속
ssh -i ~/.ssh/lsh-study-key ubuntu@$(terraform output -raw vm_database_ip)
```

### 4.2 네트워크 연결 확인

```bash
# VPC 내부 통신 확인 (Backend VM에서)
ping $(terraform output -raw vm_ai_private_ip)
ping $(terraform output -raw vm_database_private_ip)
```

### 4.3 Frontend 확인

```bash
# GCS 버킷 확인
gsutil ls gs://$(terraform output -raw frontend_bucket_name)/

# CDN URL 확인  
curl -I $(terraform output -raw frontend_cdn_url)
```

## 5. 문제 해결

### 5.1 권한 오류

```bash
# 서비스 계정 키 직접 지정
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/service-account.json"

# 현재 인증 상태 확인
gcloud auth list
```

### 5.2 API 활성화 오류

```bash
# 필요한 API 수동 활성화
gcloud services enable compute.googleapis.com
gcloud services enable storage-component.googleapis.com
gcloud services enable dns.googleapis.com
```

### 5.3 백엔드 초기화 오류

```bash
# .terraform 디렉토리 삭제 후 재시도
rm -rf .terraform .terraform.lock.hcl
terraform init
```

### 5.4 리소스 충돌 오류

```bash
# 기존 리소스 가져오기
terraform import google_compute_instance.example projects/PROJECT/zones/ZONE/instances/INSTANCE

# 상태 확인
terraform state list
```

## 6. 완전한 정리

### 6.1 환경 리소스 정리

```bash
# Test 환경 디렉토리에서
cd terraform/environments/test

# 모든 환경 리소스 제거
terraform destroy

# 'yes' 입력하여 확인
```

### 6.2 Bootstrap 리소스 정리

```bash
# Bootstrap 디렉토리로 이동
cd ../../bootstrap

# Bootstrap 리소스 제거
terraform destroy

# 'yes' 입력하여 확인
```

### 6.3 로컬 상태 정리

```bash
# 프로젝트 루트에서
cd ../../..

# 모든 Terraform 상태 파일 제거
find terraform/ -name "*.tfstate*" -delete
find terraform/ -name ".terraform.lock.hcl" -delete
find terraform/ -type d -name ".terraform" -exec rm -rf {} +
```

## 7. 재배포 방법

```bash
# 처음부터 다시 배포
cd terraform/bootstrap
terraform init && terraform apply

cd ../environments/test  
terraform init && terraform apply
```

## 📚 추가 참고사항

- **상태 파일**: GCS에 안전하게 저장됨 (KMS 암호화)
- **롤백**: `terraform destroy`로 언제든 깔끔하게 정리 가능
- **확장**: 동일한 방식으로 prod 환경도 배포 가능
- **모니터링**: Terraform 명령어로 모든 상태 추적 가능
