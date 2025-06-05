# Terraform Infrastructure

이 디렉토리는 14-YG-CLOUD 프로젝트의 Infrastructure as Code (IaC) 구성을 포함합니다.

## 📁 구조

```
terraform/
├── bootstrap/              # 초기 설정 (GCS 백엔드, KMS 키 등)
├── environments/           # 환경별 설정
│   ├── dev/               # 개발 환경 (기존 단일 VM)
│   ├── test/              # 테스트 환경 (3-Tier 아키텍처)
│   └── prod/              # 프로덕션 환경
└── modules/               # 재사용 가능한 모듈
    ├── compute/           # VM 인스턴스 관리
    ├── gcs_cdn/          # Frontend 정적 호스팅
    ├── network/          # VPC, 서브넷, 방화벽
    ├── static_ip/        # 고정 IP 관리
    └── wireguard/        # VPN 서버/클라이언트 설정
```

## 🚀 수동 배포 가이드 (권장)

### 1. Bootstrap 배포 (최초 1회)
```bash
# Bootstrap 디렉토리로 이동
cd terraform/bootstrap

# 초기화 및 배포
terraform init
terraform plan
terraform apply
```

### 2. 환경별 인프라 배포
```bash
# Test 환경 배포
cd ../environments/test
terraform init
terraform plan  
terraform apply

# Prod 환경 배포  
cd ../environments/prod
terraform init
terraform plan
terraform apply
```

### 3. 배포 확인
```bash
# 리소스 상태 확인
terraform output

# VM 접속 테스트
ssh -i ~/.ssh/lsh-study-key ubuntu@$(terraform output -raw vm_backend_ip)
```

### 4. 리소스 정리
```bash
# 환경 리소스 정리
terraform destroy

# Bootstrap 리소스 정리 (완전 삭제 시)
cd ../../bootstrap
terraform destroy
```

## 📚 상세 가이드

- **[🎯 Terraform 수동 배포 가이드](../docs/terraform-manual-deployment.md)** ⭐ **[권장]**
  - 스크립트 없는 순수 Terraform 배포 방법
  - 단계별 상세 설명 및 문제 해결 가이드
- [Test 환경 가이드](environments/test/README.md) - 3-Tier 아키텍처 설명  
- [Terraform 배포 메뉴얼](../docs/terraform-deployment-manual.md) - 기존 배포 가이드

## 💡 핵심 원칙

- **Script-Free**: 스크립트 의존성 최소화, 순수 Terraform 명령어 사용
- **투명성**: 모든 과정이 명확하게 보이는 수동 배포
- **안정성**: 예측 가능하고 제어 가능한 배포 프로세스
- **재현성**: 언제든 동일한 결과를 얻을 수 있는 배포