# 14-YG-CLOUD - 최적화된 3-Tier 아키텍처

## 🏗️ 프로젝트 개요

단일 VM 개발 환경에서 **최적화된 3-Tier 아키텍처로 마이그레이션**하여 확장성, 보안성, 비용 효율성을 극대화한 클라우드 인프라입니다.

### 주요 특징
- ✅ **Frontend**: GCS + CDN으로 정적 웹 호스팅
- ✅ **Backend**: Private VM에서 Spring Boot API 서버
- ✅ **AI Service**: Private VM에서 FastAPI 기반 AI 서비스  
- ✅ **Database**: Private VM에서 MySQL 데이터베이스
- ✅ **VPN**: WireGuard로 보안 통신
- ✅ **IaC**: Terraform 모듈화
- ✅ **자동화**: Ansible 배포 자동화

## 📁 프로젝트 구조

```
14-YG-CLOUD/
├── terraform/                 # Infrastructure as Code
│   ├── modules/              # 재사용 가능한 Terraform 모듈
│   │   ├── network/         # VPC, 서브넷, 방화벽
│   │   ├── compute/         # VM 인스턴스 관리
│   │   ├── gcs_cdn/         # Frontend 정적 호스팅
│   │   ├── wireguard/       # VPN 서버/클라이언트 설정
│   │   └── static_ip/       # 고정 IP 관리
│   └── environments/        # 환경별 설정
│       ├── dev/            # 기존 단일 VM 환경
│       ├── test/           # 새 3-Tier 환경
│       └── prod/           # 프로덕션 환경
├── ansible/                  # 배포 자동화
│   ├── roles/              # Ansible 역할 정의
│   └── playbooks/          # 배포 플레이북
└── scripts/                  # 필수 도구들 (2개)
    ├── cleanup-resources.sh     # 개선된 리소스 정리 도구 ⭐
    ├── generate-wireguard-keys.sh # VPN 키 생성 유틸리티 ⭐
    └── archive/                 # 아카이브된 기존 스크립트들
        ├── bootstrap.sh         # → Script-Free 가이드로 대체
        ├── deploy.sh           # → 수동 배포 가이드로 대체
        ├── deploy-frontend.sh  # → GCS 업로드 명령어로 대체
        ├── setup-terraform-backend.sh # → Bootstrap 가이드로 대체
        └── cleanup-all.sh      # → cleanup-resources.sh로 개선
```

## 🚀 빠른 시작

### 1. 메뉴얼 선택 (우선순위)

1. **🎯 [스크립트 없는 순수 Terraform 배포 가이드](docs/script-free-deployment-guide.md)** ⭐ **[최고 권장]**
   - **완전한 스크립트 의존성 제거**
   - **순수 Terraform/Ansible 명령어** 사용
   - **투명하고 안정적인 배포** 방식
   - **학습 및 디버깅에 최적화**

2. **📖 [Terraform 수동 배포 가이드](docs/terraform-manual-deployment.md)**
   - 기존 수동 배포 가이드 (스크립트 의존성 최소화)
   - 환경별(Dev/Test/Prod) 단계별 배포

3. **⚡ [스크립트 기반 자동 배포](docs/deployment-workflow.md)** 
   - Terraform → Ansible 자동화 배포 (기존 방식)
   - 스크립트 기반 원클릭 배포 (고급 사용자용)

4. **🔧 [구조 분석 문서](docs/terraform-structure-analysis.md)**
   - Terraform 구조 최적화 분석
   - startup_script → Ansible 마이그레이션

### 2. 수동 배포 (권장 방법)

#### Step 1: Bootstrap 리소스 생성
```bash
cd terraform/bootstrap
terraform init
terraform apply -var="project_id=your-project-id"
```

#### Step 2: 환경별 인프라 배포
```bash
cd ../environments/test
# backend.tf 설정 활성화 (Bootstrap 출력값 사용)
terraform init
terraform apply
```

#### Step 3: 애플리케이션 배포
```bash
cd ../../ansible
ansible-playbook -i inventory_test.ini playbooks/site.yml
```

### 3. 필수 유틸리티만 사용 (권장)

> ✅ **권장**: 복잡한 스크립트 의존성을 제거하고 필요한 유틸리티만 사용합니다.

```bash
# WireGuard VPN 키 생성 (최초 1회)
./scripts/generate-wireguard-keys.sh

# 리소스 정리 (필요시)
./scripts/cleanup-resources.sh test --help

# 주요 배포는 순수 Terraform/Ansible 명령어 사용
cd terraform/environments/test
terraform init && terraform apply
cd ../../../ansible  
ansible-playbook -i inventory_test.ini playbooks/site.yml
```

### 4. 배포 확인
```bash
# 인프라 상태 확인
cd terraform/environments/test
terraform output

# VPN 연결 테스트 (WireGuard 설정 후)
ping 10.8.0.1

# 서비스 접속 테스트
curl https://$(terraform output -raw frontend_cdn_url)
```

### 5. 리소스 정리
```bash
# 환경 리소스만 정리
./scripts/cleanup-resources.sh test --env-only

# 모든 리소스 완전 정리 (Bootstrap 포함)
./scripts/cleanup-resources.sh test

# 정리 계획 확인 (Dry Run)
./scripts/cleanup-resources.sh test --dry-run
```

## 🌐 아키텍처 다이어그램

```
Internet ──> CDN ──> GCS (Frontend)
                │
                └──> Users

Admin ──> Jump Box (VPN) ──> Private Network
                              │
                    ┌─────────┼─────────┐
                    │         │         │
                Backend ──> AI ──> Database
               (Spring)  (FastAPI) (MySQL)
```

## 💰 비용 최적화 결과

| 구성요소 | 기존 | 최적화 | 절약 효과 |
|---------|------|--------|----------|
| Frontend | VM (24/7) | GCS+CDN | ~70% 절약 |
| Backend | Monolith VM | 분리된 VMs | 확장성 향상 |
| 네트워크 | Public | Private+VPN | 보안 강화 |
| 관리 | 수동 | IaC+자동화 | 운영비 절약 |

## 🛡️ 보안 강화

- **네트워크 분리**: Public/Private 네트워크 완전 분리
- **VPN 암호화**: WireGuard로 내부 통신 보호
- **Jump Box**: 중앙집중식 접근 관리
- **최소 권한**: 필요한 포트만 개방
- **SSL 인증서**: 자동 관리되는 HTTPS

### 🔒 보안 관리 및 Git 보호

⚠️ **중요**: 민감한 정보 보호를 위해 [보안 가이드](docs/security-git-guide.md)와 [Ansible Vault 가이드](docs/ansible-vault-security-guide.md)를 반드시 확인하세요.

```bash
# 민감한 정보 검색 (커밋 전 확인)
grep -r "AKIA\|sk-" . --exclude-dir=.git --exclude-dir=terraform/.terraform

# Ansible Vault 파일 상태 확인
cd ansible
ansible-vault view group_vars/dev/all.yml  # 암호화 상태 확인

# 안전한 설정 파일 생성
cp terraform/environments/test/terraform.tfvars.example \
   terraform/environments/test/terraform.tfvars
```

**보안 강화 사항:**
- ✅ **Ansible Vault**: 모든 민감 정보 암호화
- ✅ **Git 보호**: `.gitignore`로 민감 파일 자동 제외
- ✅ **Vault 변수**: AWS 키, API 키 등 안전한 관리
- ✅ **암호화된 설정**: 환경별 설정 파일 완전 암호화

**자동으로 제외되는 파일들:**
- `*.tfvars` (Terraform 변수)
- `*.json` (GCP 서비스 계정 키)
- `wireguard-keys/` (VPN 키)
- `.env*` (환경 변수)
- `*.tfstate*` (Terraform 상태)
- `.vault_pass.txt` (Ansible Vault 패스워드)
- 하드코딩된 API 키, AWS 액세스 키 등

## 📊 모니터링 & 관리

현재 구성된 모니터링 스택:
- **Prometheus**: 메트릭 수집
- **Grafana**: 시각화 대시보드  
- **K6**: 성능 테스트
- **로그 수집**: 중앙집중식 로깅

## 🔧 개발 환경

### 요구사항
- Terraform >= 1.0
- Ansible >= 2.9
- gcloud CLI
- WireGuard (VPN 클라이언트)

### 환경 변수
```bash
export GOOGLE_APPLICATION_CREDENTIALS="path/to/service-account.json"
export TF_VAR_project_id="your-gcp-project"
```

## 📚 상세 문서

### 🚀 실행 가이드
- **[Terraform 배포 메뉴얼](docs/terraform-deployment-manual.md)** - 완전한 Terraform 중심 배포 가이드
- [Test 환경 가이드](terraform/environments/test/README.md) - 3-Tier 아키텍처 설명
- [Ansible 플레이북 가이드](ansible/README.md) - 애플리케이션 배포 자동화

### 🏗️ 아키텍처 & 설정
- [아키텍처 통신 흐름](docs/architecture-communication-flow.md) - 환경별 네트워크 분석
- [WireGuard VPN 설정](docs/wireguard-setup.md) - VPN 설정 및 관리
- [GCS+CDN 호스팅](docs/gcs-cdn-setup.md) - Frontend 호스팅 가이드

### 📋 프로젝트 관리
- **[프로젝트 정리 완료 보고서](docs/project-cleanup-completion-report.md)** - 최신 정리 작업 결과 ⭐
- [프로젝트 현황 요약](docs/project-status-summary.md) - 전체 진행 상황
- [작업 세션 로그](docs/work-session-log.md) - 상세 작업 기록
- [문서 인덱스](docs/README.md) - 모든 문서 가이드

## 🤝 기여 가이드

1. 새 기능은 별도 브랜치에서 개발
2. Terraform 계획 확인 후 PR 생성
3. 코드 리뷰 후 메인 브랜치에 병합

## 📝 변경 이력

### v2.0 - 최적화된 3-Tier 아키텍처
- Frontend를 GCS + CDN으로 마이그레이션
- WireGuard VPN으로 보안 강화
- Terraform 모듈화로 재사용성 증대
- 비용 최적화 및 성능 향상

### v1.0 - 기존 단일 VM 환경
- Monolithic 구조의 단일 VM 배포
- 기본적인 Ansible 자동화
