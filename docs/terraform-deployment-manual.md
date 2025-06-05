# 🚀 14-YG-CLOUD Terraform 실행 메뉴얼

이 문서는 **Terraform 명령어 중심**으로 14-YG-CLOUD 프로젝트를 배포하고 관리하는 완전한 가이드입니다.

## 📋 목차

1. [사전 준비](#-사전-준비)
2. [환경별 배포 가이드](#-환경별-배포-가이드)
3. [Terraform 명령어 참조](#-terraform-명령어-참조)
4. [트러블슈팅](#-트러블슈팅)
5. [고급 운영](#-고급-운영)

## 🛠️ 사전 준비

### 1. 필수 도구 설치

```bash
# Terraform 설치 (macOS)
brew tap hashicorp/tap
brew install hashicorp/tap/terraform

# 버전 확인
terraform version
# Terraform v1.9.0 이상 권장

# Ansible 설치
pip3 install ansible

# gcloud CLI 설치 (인증용)
brew install google-cloud-sdk
```

### 2. GCP 인증 설정

```bash
# Service Account 키 파일 설정
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/service-account-key.json"

# 또는 gcloud 인증 (초기 설정시만)
gcloud auth application-default login
gcloud config set project YOUR_PROJECT_ID
```

### 3. SSH 키 준비

```bash
# SSH 키 쌍 생성 (없는 경우)
ssh-keygen -t rsa -b 4096 -f ~/.ssh/gcp-key

# 공개키 경로 확인
ls -la ~/.ssh/gcp-key.pub
```

### 4. WireGuard 키 생성

```bash
# 프로젝트 루트에서 실행
cd /Users/lsh/Documents/local/3tier-moongsan/14-YG-CLOUD
./scripts/generate-wireguard-keys.sh
```

## 🎯 환경별 배포 가이드

### 🔧 Dev 환경 (단일 VM)

#### 1단계: Terraform 초기화
```bash
cd terraform/environments/dev

# Backend 설정 초기화
terraform init

# 설정 파일 준비
cp terraform.tfvars.example terraform.tfvars
```

#### 2단계: 변수 설정
```bash
# terraform.tfvars 편집
cat > terraform.tfvars << EOF
project_id = "your-gcp-project-id"
region = "asia-northeast3"
zone = "asia-northeast3-a"
ssh_public_key_path = "~/.ssh/gcp-key.pub"
environment = "dev"
EOF
```

#### 3단계: 인프라 배포
```bash
# 배포 계획 확인
terraform plan

# 인프라 생성
terraform apply
# yes 입력하여 확인

# 배포 완료 후 출력 확인
terraform output
```

#### 4단계: 애플리케이션 배포
```bash
# Ansible로 애플리케이션 배포
cd ../../../ansible
ansible-playbook -i inventory.ini playbooks/site.yml --limit dev
```

### 🏗️ Test 환경 (3-Tier 아키텍처)

#### 1단계: Terraform 초기화
```bash
cd terraform/environments/test

# Backend 설정 초기화
terraform init

# 설정 파일 준비
cp terraform.tfvars.example terraform.tfvars
```

#### 2단계: WireGuard 설정
```bash
# WireGuard 키가 생성되었는지 확인
cat ../../wireguard-keys/server-keys.txt
cat ../../wireguard-keys/client-keys.txt

# terraform.tfvars에 WireGuard 키 추가
cat >> terraform.tfvars << EOF
# WireGuard VPN 설정
wireguard_server_private_key = "$(cat ../../wireguard-keys/server-keys.txt | grep 'Private Key:' | cut -d' ' -f3)"
wireguard_server_public_key = "$(cat ../../wireguard-keys/server-keys.txt | grep 'Public Key:' | cut -d' ' -f3)"
wireguard_client_public_key = "$(cat ../../wireguard-keys/client-keys.txt | grep 'Public Key:' | cut -d' ' -f3)"
EOF
```

#### 3단계: 네트워크 인프라 배포
```bash
# 1. 네트워크 리소스 먼저 생성
terraform plan -target=module.network
terraform apply -target=module.network

# 2. 고정 IP 생성
terraform plan -target=module.static_ip
terraform apply -target=module.static_ip

# 3. VPN 설정
terraform plan -target=module.wireguard
terraform apply -target=module.wireguard
```

#### 4단계: 컴퓨팅 인프라 배포
```bash
# 4. VM 인스턴스 생성
terraform plan -target=module.compute
terraform apply -target=module.compute

# 5. Frontend CDN 설정
terraform plan -target=module.gcs_cdn
terraform apply -target=module.gcs_cdn

# 또는 전체 한번에 배포
terraform apply
```

#### 5단계: 배포 확인
```bash
# 인프라 상태 확인
terraform show

# 중요한 출력값 확인
terraform output jumpbox_public_ip
terraform output backend_internal_ip
terraform output frontend_cdn_url
```

#### 6단계: VPN 연결 설정
```bash
# 클라이언트 설정 파일 생성
terraform output wireguard_client_config > /tmp/wg0.conf

# WireGuard 연결
sudo cp /tmp/wg0.conf /etc/wireguard/wg0.conf
sudo wg-quick up wg0

# 연결 확인
sudo wg show
ping 10.8.0.1  # Jump box VPN IP
```

#### 7단계: 애플리케이션 배포
```bash
# Ansible로 모든 서비스 배포
cd ../../../ansible
ansible-playbook -i inventory_test.ini playbooks/site.yml

# 개별 서비스 배포
ansible-playbook -i inventory_test.ini playbooks/be_deploy.yml  # Backend만
ansible-playbook -i inventory_test.ini playbooks/ai_deploy.yml  # AI만
ansible-playbook -i inventory_test.ini playbooks/db_fix.yml     # Database만
```

#### 8단계: Frontend 배포
```bash
# GCS에 Frontend 파일 업로드
cd scripts
./deploy-frontend.sh test ../14-YG-FE/dist
```

### 🚀 Prod 환경

#### 1단계: Test 환경 검증 후 진행
```bash
# Test 환경이 정상 동작하는지 확인
cd terraform/environments/test
terraform output
```

#### 2단계: Prod 환경 배포
```bash
cd ../prod

# 초기화
terraform init

# Test 환경 설정 복사 및 수정
cp ../test/terraform.tfvars terraform.tfvars.example
cp terraform.tfvars.example terraform.tfvars

# Prod용 설정 수정
sed -i 's/environment = "test"/environment = "prod"/' terraform.tfvars
sed -i 's/test-/prod-/g' terraform.tfvars
```

#### 3단계: 단계적 배포
```bash
# 네트워크부터 순차 배포
terraform plan
terraform apply
```

## 🔧 Terraform 명령어 참조

### 기본 명령어

```bash
# 초기화 (프로젝트 시작시 1회)
terraform init

# 설정 검증
terraform validate

# 포맷팅
terraform fmt

# 배포 계획 확인
terraform plan

# 인프라 배포
terraform apply

# 특정 리소스만 배포
terraform apply -target=module.network
terraform apply -target=google_compute_instance.backend

# 인프라 삭제
terraform destroy

# 특정 리소스만 삭제
terraform destroy -target=google_compute_instance.backend
```

### 상태 관리

```bash
# 현재 상태 확인
terraform show

# 리소스 목록 확인
terraform state list

# 특정 리소스 상태 확인
terraform state show google_compute_instance.jumpbox

# 리소스 상태에서 제거 (실제 리소스는 유지)
terraform state rm google_compute_instance.old_vm

# 기존 리소스를 Terraform 관리로 가져오기
terraform import google_compute_instance.existing_vm projects/PROJECT_ID/zones/ZONE/instances/INSTANCE_NAME
```

### 출력값 관리

```bash
# 모든 출력값 확인
terraform output

# 특정 출력값만 확인
terraform output jumpbox_public_ip

# JSON 형태로 출력
terraform output -json

# 출력값을 변수로 사용
JUMPBOX_IP=$(terraform output -raw jumpbox_public_ip)
echo "Jump box IP: $JUMPBOX_IP"
```

### 변수 및 설정

```bash
# 변수 파일 사용
terraform plan -var-file="production.tfvars"

# 명령줄에서 변수 설정
terraform plan -var="instance_type=e2-standard-4"

# 환경 변수 사용
export TF_VAR_project_id="my-gcp-project"
terraform plan
```

## 🛠️ 트러블슈팅

### 일반적인 문제 해결

#### 1. 인증 오류
```bash
# 에러: Error: google: could not find default credentials
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/service-account.json"

# 또는 gcloud 재인증
gcloud auth application-default login
```

#### 2. 권한 오류
```bash
# 에러: Error: googleapi: Error 403: Insufficient Permission
# Service Account에 필요한 역할 추가:
# - Compute Admin
# - Storage Admin
# - Cloud CDN Admin
# - VPC Admin
```

#### 3. 상태 파일 충돌
```bash
# 에러: Error: state lock
terraform force-unlock LOCK_ID

# 상태 파일 백업
cp terraform.tfstate terraform.tfstate.backup.$(date +%Y%m%d_%H%M%S)
```

#### 4. 리소스 충돌
```bash
# 에러: Error: resource already exists
# 기존 리소스 가져오기
terraform import google_compute_instance.vm projects/PROJECT/zones/ZONE/instances/NAME

# 또는 기존 리소스 삭제 후 재생성
terraform state rm google_compute_instance.vm
terraform apply
```

#### 5. 네트워크 연결 오류
```bash
# VPN 연결 확인
sudo wg show

# VPN 재연결
sudo wg-quick down wg0
sudo wg-quick up wg0

# Jump box 연결 테스트
ssh ubuntu@$(terraform output -raw jumpbox_public_ip)
```

### 상태 복구

```bash
# 상태 파일 손상시 복구
terraform refresh

# 실제 리소스와 상태 동기화
terraform apply -refresh-only

# 상태 파일 백업에서 복구
cp terraform.tfstate.backup terraform.tfstate
terraform refresh
```

## 🔄 고급 운영

### 1. 롤링 업데이트

```bash
# Backend 서버 무중단 업데이트
# 1. 새 인스턴스 생성
terraform apply -target=google_compute_instance.backend_new

# 2. 로드밸런서에서 기존 인스턴스 제거
# 3. 새 인스턴스 추가
# 4. 기존 인스턴스 삭제
terraform destroy -target=google_compute_instance.backend_old
```

### 2. 환경 복제

```bash
# Test 환경을 Staging으로 복제
cp -r terraform/environments/test terraform/environments/staging

# 설정 파일 수정
cd terraform/environments/staging
sed -i 's/test/staging/g' terraform.tfvars
sed -i 's/test-/staging-/g' *.tf

# 새 환경 배포
terraform init
terraform apply
```

### 3. 비용 최적화

```bash
# 개발 시간 외 VM 중지
terraform apply -var="vm_count=0"  # 저녁

terraform apply -var="vm_count=3"  # 다음날 아침

# 또는 스케줄링 스크립트
cat > stop_dev_vms.sh << 'EOF'
#!/bin/bash
cd terraform/environments/dev
terraform apply -var="auto_shutdown=true" -auto-approve
EOF
```

### 4. 백업 및 복구

```bash
# 상태 파일 백업
aws s3 cp terraform.tfstate s3://backup-bucket/terraform/$(date +%Y%m%d)/

# 데이터베이스 백업 (VM 내에서)
ssh ubuntu@$(terraform output -raw database_ip) \
  "mysqldump -u root -p database_name > /tmp/backup.sql"

# 백업 파일 다운로드
scp ubuntu@$(terraform output -raw database_ip):/tmp/backup.sql ./backup.sql
```

### 5. 모니터링 연동

```bash
# Terraform으로 모니터링 스택 배포
terraform apply -target=module.monitoring

# Prometheus 설정 업데이트
terraform apply -var="prometheus_config=$(cat prometheus.yml | base64)"
```

## 📚 추가 참고 자료

### Terraform 모듈 문서
- [네트워크 모듈](../modules/network/README.md)
- [컴퓨팅 모듈](../modules/compute/README.md)
- [CDN 모듈](../modules/gcs_cdn/README.md)
- [WireGuard 모듈](../modules/wireguard/README.md)

### 관련 문서
- [아키텍처 통신 흐름](../../docs/architecture-communication-flow.md)
- [WireGuard VPN 설정](../../docs/wireguard-setup.md)
- [프로젝트 현황 요약](../../docs/project-status-summary.md)

---

## 🚨 중요 주의사항

1. **상태 파일 보안**: `terraform.tfstate`에는 민감한 정보가 포함되므로 Git에 커밋하지 마세요
2. **백업**: 중요한 변경 전에는 항상 상태 파일을 백업하세요
3. **단계적 배포**: Prod 환경은 반드시 Test 환경 검증 후 배포하세요
4. **리소스 태깅**: 비용 추적을 위해 모든 리소스에 적절한 태그를 설정하세요
5. **접근 제어**: Service Account 키는 안전하게 관리하세요

---

**📞 문의사항이 있으시면 [프로젝트 이슈](https://github.com/your-repo/issues)에 등록해주세요.**
