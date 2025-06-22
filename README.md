# 🏗️ 14-YG-CLOUD

> **GCP에서 구현한 최적화된 3-Tier 클라우드 인프라** - 비용 효율성과 보안을 동시에 달성

## 🎯 프로젝트 개요

단일 VM에서 **3-Tier 아키텍처로 마이그레이션**하여 **18% 비용 절약**과 확장성, 보안성을 확보한 엔터프라이즈급 클라우드 인프라

### 📊 달성 결과
- ✅ **18% 비용 절감**: $277.99 → $227.77/월
- ✅ **보안 강화**: Private Network + VPN 접근
- ✅ **확장성 확보**: 계층별 독립적 스케일링
- ✅ **운영 자동화**: IaC + Configuration Management

### 🏗️ 현재 아키텍처
```
Internet
  │
  ▼
🌐 Load Balancer (Global)
  │  ├── /api/* → Backend API (8080)
  │  └── /generation/* → AI Service (8100)
  │
  ▼
🔒 Private VPC (10.0.0.0/16)
  │
  ├── 📱 Frontend: GCS + CDN
  ├── 🖥️ Jump Box: VPN Gateway (e2-small)
  ├── ⚙️ Backend API: Spring Boot (e2-standard-2)
  ├── 🤖 AI Service: FastAPI (e2-highmem-2)
  └── 🗄️ Database: MySQL + Redis (e2-standard-2)
```

### 💰 비용 구조
| 구성요소 | 사양 | 월 비용 |
|----------|------|---------|
| Jump Box | e2-small (0.5 vCPU, 2GB) | $13.84 |
| Backend API | e2-standard-2 (2 vCPU, 8GB) | $53.54 |
| AI Service | e2-highmem-2 (2 vCPU, 16GB) | $80.96 |
| Database | e2-standard-2 (2 vCPU, 8GB) | $53.54 |
| 디스크 & 네트워크 | - | $25.89 |
| **총 비용** | - | **$227.77/월** |

## 🚀 빠른 시작

### 🆕 신규 사용자라면?
**처음 이 프로젝트를 사용하시나요?** 다음 문서들을 순서대로 확인하세요:

1. **📋 [신규 사용자 체크리스트](CHECKLIST-NEW-USER.md)** - 필수 준비사항 단계별 체크
2. **🔧 [환경 설정 스크립트](scripts/setup-new-user.sh)** - 자동 환경 설정 및 연결 테스트
3. **❓ [자주 묻는 질문](FAQ-NEW-USER.md)** - 설정 및 배포 관련 FAQ
4. **📚 [완전 재배포 가이드](COMPLETE-REDEPLOY-GUIDE.md)** - 전체 배포 프로세스

### 📋 사전 요구사항
- GCP 프로젝트 및 서비스 계정 키
- Terraform >= 1.5
- Ansible >= 2.12
- WireGuard VPN 클라이언트
- SSH 키 (GCP 등록 필요)
- Ansible Vault 패스워드

### ⚡ 즉시 시작 (경험자용)
```bash
# 1. Repository clone
git clone [repository-url]
cd 14-YG-CLOUD

# 2. 환경 설정 체크 (신규 사용자)
./scripts/setup-new-user.sh

# 3. 인프라 배포
cd terraform/environments/test
terraform init && terraform apply

# 4. 서비스 배포
cd ../../../ansible
ansible-playbook -i test.ini playbooks/main.yml
```

### ⚡ 5분 배포
```bash
# 1. 저장소 클론
git clone <repository-url>
cd 14-YG-CLOUD

### 📖 자세한 배포 가이드

#### 1️⃣ 처음 배포 (신규 사용자)
```bash
# 환경 설정 확인 (필수!)
./scripts/setup-new-user.sh

# 인프라 생성
cd terraform/environments/test
terraform init
terraform plan  # 리소스 확인
terraform apply

# 서비스 배포
cd ../../../ansible
ansible-playbook -i test.ini playbooks/main.yml
```

#### 2️⃣ 재배포 (기존 사용자)
```bash
# 완전 재배포
cd terraform/environments/test
terraform destroy  # 기존 인프라 삭제
terraform apply     # 새로 생성

cd ../../../ansible
ansible-playbook -i test.ini playbooks/main.yml
```

#### 3️⃣ 부분 배포 (코드 변경)
```bash
# 백엔드만 재배포
ansible-playbook -i test.ini playbooks/main.yml --tags be_deploy

# 프론트엔드만 재배포  
ansible-playbook -i test.ini playbooks/main.yml --tags fe_deploy
```
```

### 🔍 상태 확인
```bash
# 인프라 상태
gcloud compute instances list

# 서비스 상태
curl -s http://your-domain.com/api/health
curl -s http://your-domain.com/generation/health
```

## 📚 문서 구조

### 🚀 **운영 중심 문서**


#### [`docs/README.md`](docs/README.md) 📖
**프로젝트 개요 및 문서 네비게이션** - 시작점

#### [`docs/operations-guide.md`](docs/operations-guide.md) ⭐
**일상 운영 가이드** - 시스템 운영의 모든 것

#### [`docs/infrastructure-architecture.md`](docs/infrastructure-architecture.md) 🏗️
**시스템 아키텍처** - 현재 구조와 동작 원리

### 🔧 **배포 및 관리 문서**

#### [`docs/deployment-guide.md`](docs/deployment-guide.md)
**배포 실행 가이드** - 환경 구축 및 배포 절차

#### [`docs/security-guide.md`](docs/security-guide.md)
**보안 설정 가이드** - VPN, 인증, 방화벽 설정

### 📚 **참고 및 히스토리**

#### [`docs/infrastructure-complete-guide.md`](docs/infrastructure-complete-guide.md)
**인프라 히스토리** - 설계 과정과 최적화 여정

#### [`docs/troubleshooting-guide.md`](docs/troubleshooting-guide.md)
**문제해결 레퍼런스** - 상황별 해결 방법

## 📁 프로젝트 구조

```
14-YG-CLOUD/
├── 📚 docs/                 # 모든 문서 (구조화됨)
├── 🏗️ terraform/            # 인프라 as Code
│   ├── bootstrap/          # 초기 리소스
│   ├── modules/            # 재사용 모듈
│   └── environments/       # 환경별 설정
├── ⚙️ ansible/              # 설정 관리
│   ├── inventories/        # 환경별 인벤토리
│   ├── playbooks/         # 작업 스크립트
│   └── roles/             # 역할별 설정
└── 🛠️ scripts/              # 유틸리티 도구
```

## 🎯 역할별 가이드

| 역할 | 시작 문서 | 주요 작업 |
|------|-----------|----------|
| **시스템 운영자** | [operations-guide.md](docs/operations-guide.md) | 모니터링, 백업, 장애 대응 |
| **개발자/배포자** | [deployment-guide.md](docs/deployment-guide.md) | 코드 배포, 환경 설정 |
| **인프라 관리자** | [infrastructure-architecture.md](docs/infrastructure-architecture.md) | 아키텍처 이해, 확장 계획 |
| **보안 관리자** | [security-guide.md](docs/security-guide.md) | 보안 설정, VPN 관리 |

## 🔧 주요 명령어

### 일상 운영
```bash
# 시스템 상태 확인
gcloud compute instances list
curl -s http://your-domain.com/api/health

# VPN 연결
sudo wg-quick up wg0

# 서비스 재시작
ansible -i inventories/test.ini backend -m service -a "name=backend-api state=restarted"
```

### 배포 작업
```bash
# 인프라 변경
cd terraform/environments/test
terraform plan && terraform apply

# 애플리케이션 배포
cd ../../ansible
ansible-playbook -i inventories/test.ini main.yml -e "env=test"
```

### 모니터링
```bash
# 리소스 사용량
ansible -i inventories/test.ini all -m shell -a "free -h && df -h"

# 로그 확인
ansible -i inventories/test.ini backend -m shell -a "journalctl -u backend-api -n 20"
```

## 🎁 주요 특징

### ✅ **운영 효율성**
- **원클릭 배포**: Ansible Playbook으로 모든 서비스 배포
- **환경 일관성**: Dev, Test, Prod 환경 설정 통일
- **자동화**: 백업, 모니터링, 배포 자동화

### 🔒 **엔터프라이즈 보안**
- **Zero Trust**: 모든 서버가 Private Network
- **VPN 게이트웨이**: WireGuard 기반 안전한 접근
- **암호화**: Ansible Vault로 모든 민감정보 암호화

### 💰 **비용 최적화**
- **Right-sizing**: 워크로드별 최적 사양 선택
- **Frontend 분리**: GCS + CDN으로 VM 비용 절약
- **리소스 효율**: 18% 비용 절감 달성

### 📈 **확장 가능성**
- **모듈화**: Terraform 모듈로 재사용성 극대화
- **마이크로서비스 준비**: 계층별 독립적 스케일링
- **로드밸런서**: 트래픽 증가에 대응 가능

## 📞 지원

- **일반 문의**: [docs/README.md](docs/README.md)
- **운영 문제**: [docs/operations-guide.md](docs/operations-guide.md)
- **기술 문제**: [docs/troubleshooting-guide.md](docs/troubleshooting-guide.md)
- **보안 이슈**: [docs/security-guide.md](docs/security-guide.md)

---

*이 프로젝트는 실제 운영 환경에서 검증된 최적화된 3-Tier 아키텍처입니다.*

## 🚀 빠른 시작

### **1. 처음 사용하는 경우**
1. **[`docs/infrastructure-complete-guide.md`](docs/infrastructure-complete-guide.md)** - 전체 시스템 이해
2. **[`docs/deployment-guide.md`](docs/deployment-guide.md)** - 실제 배포 수행
3. **[`docs/security-guide.md`](docs/security-guide.md)** - 보안 설정 완료

### **2. 문제가 발생한 경우**  
1. **[`docs/troubleshooting-guide.md`](docs/troubleshooting-guide.md)** - 문제해결 방법 확인
2. 해당 영역별 가이드 문서 참고

### **3. 상세 분석이 필요한 경우**
1. **[`docs/archive/`](docs/archive/)** 폴더의 세부 분석 문서들 참고

## 🔧 필수 유틸리티

> ✅ **권장**: 복잡한 스크립트 의존성을 제거하고 필요한 유틸리티만 사용

```bash
# WireGuard VPN 키 생성 (최초 1회)
./scripts/generate-wireguard-keys.sh

# 리소스 정리 (필요시)
./scripts/cleanup-resources.sh test --help

# 주요 배포는 순수 Terraform/Ansible 명령어 사용
# 자세한 방법은 docs/deployment-guide.md 참고
```

## 📁 프로젝트 구조

```
14-YG-CLOUD/
├── docs/                     # 📚 5개 핵심 문서 (고정 구조)
│   ├── README.md            # 문서 인덱스
│   ├── infrastructure-complete-guide.md  # 인프라 완전 가이드
│   ├── deployment-guide.md  # 배포 가이드
│   ├── security-guide.md    # 보안 가이드
│   ├── troubleshooting-guide.md  # 문제해결 가이드
│   └── archive/             # 상세 분석 문서들 (30+ 문서)
├── terraform/               # Infrastructure as Code
│   ├── modules/            # 재사용 가능한 모듈
│   ├── environments/       # 환경별 설정 (dev/test/prod)
│   └── bootstrap/          # 초기 설정 (GCS 백엔드, KMS 등)
├── ansible/                # 배포 자동화
│   ├── roles/              # Ansible 역할 정의
│   └── playbooks/          # 배포 플레이북
└── scripts/                # 필수 도구들 (2개만 유지)
    ├── cleanup-resources.sh      # 리소스 정리 도구
    ├── generate-wireguard-keys.sh # VPN 키 생성 유틸리티
    └── archive/            # 아카이브된 기존 스크립트들
```

## 🌐 아키텍처 다이어그램

```
Internet ──> CDN ──> GCS (Frontend)
                │
                └──> Users

Admin ──> WireGuard VPN ──> Private Network
                              │
                    ┌─────────┼─────────┐
                    │         │         │
                Backend ──> AI ──> Database
               (Spring)  (FastAPI) (MySQL)
```

## 💰 최적화 성과

| 항목 | 개선 결과 |
|------|----------|
| **월 비용** | $277.99 → $227.77 (18% 절약) |
| **배포 시간** | 15분 → 8분 (47% 단축) |
| **코드 라인** | 600줄 → 350줄 (42% 감소) |
| **보안성** | Public → Private + VPN |
| **확장성** | Monolith → 3-Tier 분리 |
| **운영성** | 수동 → IaC + 자동화 |

## 🛡️ 보안 및 요구사항

> ⚠️ **중요**: 모든 보안 설정은 [`docs/security-guide.md`](docs/security-guide.md)에서 확인하세요

### 🔒 보안 강화 사항
- **네트워크 분리**: Public/Private 네트워크 완전 분리
- **VPN 암호화**: WireGuard로 내부 통신 보호
- **Ansible Vault**: 모든 민감 정보 암호화
- **Git 보호**: 민감한 파일 자동 제외
- **최소 권한**: 필요한 포트만 개방

### 🔧 개발 환경 요구사항
- Terraform >= 1.0
- Ansible >= 2.9  
- gcloud CLI
- WireGuard (VPN 클라이언트)

### 🌍 환경 변수
```bash
export GOOGLE_APPLICATION_CREDENTIALS="path/to/service-account.json"
export TF_VAR_project_id="your-gcp-project"
```

## 📚 기술 문서

### 📝 구성요소별 가이드
- **[Terraform 가이드](terraform/README.md)** - IaC 구조 및 사용법
- **[Ansible 가이드](ansible/README.md)** - 배포 자동화 상세
- **[Scripts 가이드](scripts/README.md)** - 필수 유틸리티 사용법

### 🗂️ 과거 분석 자료 (Archive)
- **[`docs/archive/2024-06-optimization/`](docs/archive/2024-06-optimization/)** - 최적화 과정 분석
- **[`docs/archive/deployment-guides/`](docs/archive/deployment-guides/)** - 이전 배포 가이드들
- **[`docs/archive/security-guides/`](docs/archive/security-guides/)** - 개별 보안 가이드들
- **[`docs/archive/project-reports/`](docs/archive/project-reports/)** - 프로젝트 진행 보고서
- **[`docs/archive/legacy-analysis/`](docs/archive/legacy-analysis/)** - 초기 분석 문서들

## 🤝 기여 가이드

1. **변경사항 발생시**: 5개 핵심 문서 구조에 따라 해당 문서 업데이트
2. **새 기능 개발**: 별도 브랜치에서 개발 후 PR 생성
3. **문서 업데이트**: 5개 핵심 문서 구조 유지

## 📝 주요 변경 이력

### **v2.0.0** (2025-06-06) - 5개 문서 구조 완성
- ✅ **문서 정리**: 30+ 문서를 5개 핵심 문서로 통합
- ✅ **고정 구조**: 더 이상 문서가 늘어나지 않는 체계 구축
- ✅ **Archive 시스템**: 과거 분석 자료의 체계적 보관

### **v2.0** - 최적화된 3-Tier 아키텍처
- Frontend를 GCS + CDN으로 마이그레이션 (18% 비용 절약)
- WireGuard VPN으로 보안 강화
- Terraform 모듈화로 재사용성 증대
- Script-Free 배포 방식 도입

### **v1.0** - 기존 단일 VM 환경
- Monolithic 구조의 단일 VM 배포
- 기본적인 Ansible 자동화

---

> 💡 **시작하려면**: [`docs/README.md`](docs/README.md)에서 전체 문서 구조를 확인하고, [`docs/deployment-guide.md`](docs/deployment-guide.md)로 배포를 시작하세요!
