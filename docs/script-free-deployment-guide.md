# 🎯 스크립트 없는 순수 Terraform 배포 가이드

> **철학**: 스크립트 의존성을 제거하고 순수한 Terraform/Ansible 명령어만 사용하여 투명하고 안정적인 배포를 구현합니다.

## 📋 목차
- [핵심 원칙](#핵심-원칙)
- [사전 준비](#사전-준비)
- [1단계: Bootstrap 리소스 생성](#1단계-bootstrap-리소스-생성)
- [2단계: 환경별 인프라 배포](#2단계-환경별-인프라-배포)
- [3단계: 애플리케이션 배포](#3단계-애플리케이션-배포)
- [4단계: WireGuard 설정](#4단계-wireguard-설정)
- [리소스 정리](#리소스-정리)
- [문제 해결](#문제-해결)

## 🎯 핵심 원칙

### ✅ Script-Free 접근법
- **투명성**: 모든 명령어가 명시적으로 보임
- **안정성**: 스크립트 실행 실패 위험 제거
- **재현성**: 동일한 명령어로 동일한 결과 보장
- **학습성**: Terraform/Ansible 베스트 프랙티스 학습

### ❌ 피해야 할 것들
- 복잡한 bash 스크립트 의존성
- 숨겨진 환경 변수 설정
- 자동화된 키 생성 (수동 검증 필요)
- 블랙박스 배포 프로세스

## 🛠️ 사전 준비

### 필수 도구 설치
```bash
# Terraform 설치 확인
terraform version  # >= 1.0

# Google Cloud CLI 설치 확인
gcloud version

# Ansible 설치 확인
ansible --version  # >= 2.9

# WireGuard 도구 설치 (선택사항)
brew install wireguard-tools  # macOS
```

### GCP 인증 설정
```bash
# 서비스 계정 키 설정
export GOOGLE_APPLICATION_CREDENTIALS="path/to/your-service-account.json"

# 프로젝트 설정
export TF_VAR_project_id="your-gcp-project-id"

# 인증 확인
gcloud auth application-default login
gcloud config set project $TF_VAR_project_id
```

## 1단계: Bootstrap 리소스 생성

Bootstrap은 Terraform Backend (GCS + KMS)를 설정합니다.

```bash
# Bootstrap 디렉토리로 이동
cd terraform/bootstrap

# Terraform 초기화
terraform init

# 계획 확인
terraform plan -var="project_id=${TF_VAR_project_id}"

# Bootstrap 리소스 생성
terraform apply -var="project_id=${TF_VAR_project_id}"

# 출력 값 확인 (중요!)
terraform output
```

**출력 예시:**
```
backend_bucket = "your-project-terraform-state"
kms_key_id = "projects/your-project/locations/global/keyRings/terraform/cryptoKeys/terraform-state"
```

## 2단계: 환경별 인프라 배포

### 2-1. Backend 설정 활성화

Bootstrap 완료 후 환경별 backend 설정을 활성화합니다:

```bash
# test 환경 디렉토리로 이동
cd ../environments/test

# backend.tf 파일 편집
vim backend.tf
```

`backend.tf`에서 주석을 해제하고 Bootstrap 출력값을 입력:
```hcl
terraform {
  backend "gcs" {
    bucket         = "your-project-terraform-state"  # Bootstrap 출력값
    prefix         = "terraform/test"
    encryption_key = "your-kms-key-id"                # Bootstrap 출력값
  }
}
```

### 2-2. 환경 변수 설정

```bash
# terraform.tfvars 파일 생성
cp terraform.tfvars.example terraform.tfvars

# 필요한 값들 설정
vim terraform.tfvars
```

`terraform.tfvars` 예시:
```hcl
project_id = "your-gcp-project-id"
region     = "asia-northeast3"
zone       = "asia-northeast3-a"

# 환경별 설정
environment = "test"
```

### 2-3. 인프라 배포

```bash
# Terraform 초기화 (Backend 연결)
terraform init

# 계획 확인
terraform plan

# 인프라 배포
terraform apply

# 출력값 확인
terraform output
```

**중요한 출력값들:**
- `backend_external_ip`: Backend 서버 외부 IP
- `ai_external_ip`: AI 서버 외부 IP  
- `database_internal_ip`: Database 서버 내부 IP
- `frontend_bucket_url`: Frontend GCS 버킷 URL

## 3단계: 애플리케이션 배포

### 3-1. Ansible 인벤토리 업데이트

Terraform 출력값을 사용하여 Ansible 인벤토리를 업데이트:

```bash
# 인벤토리 파일 편집
cd ../../../ansible
vim inventory_test.ini
```

`inventory_test.ini` 예시:
```ini
[backend]
backend-test ansible_host=34.64.123.45 ansible_user=moongsan

[ai]
ai-test ansible_host=34.64.123.46 ansible_user=moongsan

[database]
database-test ansible_host=10.0.1.4 ansible_user=moongsan

[all:vars]
ansible_ssh_private_key_file=~/.ssh/gcp-key
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
```

### 3-2. Ansible 배포 실행

```bash
# 연결 테스트
ansible all -i inventory_test.ini -m ping

# 전체 배포 실행
ansible-playbook -i inventory_test.ini playbooks/site.yml

# 특정 태그만 실행 (예: 데이터베이스만)
ansible-playbook -i inventory_test.ini playbooks/site.yml --tags database

# 특정 서버만 대상 (예: Backend만)
ansible-playbook -i inventory_test.ini playbooks/site.yml --limit backend
```

## 4단계: WireGuard 설정

### 4-1. WireGuard 키 생성 (수동)

```bash
# 키 생성 디렉토리 생성
mkdir -p wireguard-keys
cd wireguard-keys

# 서버 키 생성
SERVER_PRIVATE_KEY=$(wg genkey)
SERVER_PUBLIC_KEY=$(echo "$SERVER_PRIVATE_KEY" | wg pubkey)

echo "Server Private Key: $SERVER_PRIVATE_KEY" > server-keys.txt
echo "Server Public Key: $SERVER_PUBLIC_KEY" >> server-keys.txt

# 클라이언트 키 생성 (admin용)
ADMIN_PRIVATE_KEY=$(wg genkey)
ADMIN_PUBLIC_KEY=$(echo "$ADMIN_PRIVATE_KEY" | wg pubkey)

echo "Admin Private Key: $ADMIN_PRIVATE_KEY" > admin-keys.txt
echo "Admin Public Key: $ADMIN_PUBLIC_KEY" >> admin-keys.txt

# 키 확인
cat server-keys.txt
cat admin-keys.txt
```

### 4-2. WireGuard 설정 파일 생성

```bash
# 클라이언트 설정 파일 생성
cat > admin-client.conf << EOF
[Interface]
PrivateKey = $ADMIN_PRIVATE_KEY
Address = 10.8.0.2/32
DNS = 8.8.8.8

[Peer]
PublicKey = $SERVER_PUBLIC_KEY
AllowedIPs = 10.0.0.0/16, 10.8.0.0/24
Endpoint = $(terraform -chdir=../terraform/environments/test output -raw backend_external_ip):51820
PersistentKeepalive = 25
EOF
```

## 🧹 리소스 정리

### 환경 리소스만 정리
```bash
cd terraform/environments/test
terraform destroy
```

### Bootstrap 리소스까지 완전 정리

⚠️ **주의**: Bootstrap 리소스를 삭제하면 Terraform 상태가 손실됩니다!

```bash
# 1단계: 모든 환경 리소스 먼저 정리
cd terraform/environments/test
terraform destroy

# 2단계: Bootstrap prevent_destroy 제거
cd ../../bootstrap
vim main.tf  # prevent_destroy = false로 변경

# 3단계: Bootstrap 리소스 정리
terraform destroy -var="project_id=${TF_VAR_project_id}"
```

## 🔧 문제 해결

### Terraform 상태 문제
```bash
# 상태 파일 확인
terraform state list

# 특정 리소스 상태 확인
terraform state show google_compute_instance.backend

# 상태 새로고침
terraform refresh
```

### Ansible 연결 문제
```bash
# SSH 연결 디버깅
ansible all -i inventory_test.ini -m ping -vvv

# 특정 호스트 연결 테스트
ssh -i ~/.ssh/gcp-key moongsan@34.64.123.45
```

### WireGuard 연결 문제
```bash
# WireGuard 상태 확인
sudo wg show

# 설정 파일 적용
sudo wg-quick up admin-client

# 연결 테스트
ping 10.0.1.4  # Database 서버 내부 IP
```

## 📚 참고 자료

- [Terraform Backend 설정](https://developer.hashicorp.com/terraform/language/settings/backends/gcs)
- [Ansible 인벤토리 관리](https://docs.ansible.com/ansible/latest/user_guide/intro_inventory.html)
- [WireGuard 설정 가이드](https://www.wireguard.com/quickstart/)
- [GCP Terraform Provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs)

---

> 💡 **팁**: 이 가이드를 북마크하고 각 단계를 차근차근 따라하세요. 스크립트에 의존하지 않고 직접 명령어를 실행함으로써 인프라에 대한 깊은 이해를 얻을 수 있습니다.
