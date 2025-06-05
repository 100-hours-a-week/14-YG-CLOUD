# 🚀 14-YG-CLOUD - 3-Tier 아키텍처

> **체계적인 5개 문서**로 모든 것을 관리하는 클라우드 인프라 프로젝트

## 🏗️ 프로젝트 개요

단일 VM 개발 환경에서 **최적화된 3-Tier 아키텍처로 마이그레이션**하여 **18% 비용 절약($227.77/월)**과 확장성, 보안성을 극대화한 클라우드 인프라입니다.

### 📊 최적화 결과
- ✅ **비용 절약**: 18% 절감 ($277.99 → $227.77/월)
- ✅ **성능 향상**: 3-Tier 분리로 확장성 극대화
- ✅ **보안 강화**: WireGuard VPN + Private 네트워크
- ✅ **운영 효율**: IaC + 자동화로 배포 시간 47% 단축

### 🎯 아키텍처 특징
- **Frontend**: GCS + CDN으로 정적 웹 호스팅
- **Backend**: Private VM에서 Spring Boot API 서버
- **AI Service**: Private VM에서 FastAPI 기반 AI 서비스  
- **Database**: Private VM에서 MySQL 데이터베이스
- **VPN**: WireGuard로 안전한 내부 통신
- **IaC**: Terraform 모듈화로 재사용성 극대화
- **자동화**: Ansible로 배포 자동화

## 📚 핵심 문서 (5개 고정 구조)

> **모든 정보는 5개 문서로 완결됩니다** - 더 이상 문서가 늘어나지 않습니다

### 📋 [`docs/README.md`](docs/README.md) 
**문서 인덱스 및 프로젝트 가이드** - 전체 문서 구조와 빠른 접근 방법

### 🏗️ [`docs/infrastructure-complete-guide.md`](docs/infrastructure-complete-guide.md) 
**인프라 완전 가이드** - 아키텍처 설계부터 최적화 결과까지 모든 것
- Part 1: 아키텍처 설계 (3-Tier 구조, 네트워크 설계)
- Part 2: 최적화 여정 (Jump Box, AI 서버, 로드밸런서, 디스크 최적화)
- Part 3: 최종 결과 (18% 비용 절약, $227.77/월)
- Part 4: 현재 아키텍처 상태 (완성된 시스템 상세)

### 🔧 [`docs/deployment-guide.md`](docs/deployment-guide.md) 
**배포 가이드** - 순수 Terraform/Ansible 명령어로 투명한 배포
- Bootstrap 리소스 생성
- 환경별 인프라 배포  
- 애플리케이션 배포
- WireGuard VPN 설정

### 🔐 [`docs/security-guide.md`](docs/security-guide.md) 
**통합 보안 가이드** - 모든 보안 설정을 한 곳에
- Part 1: Git 보안 (민감한 정보 보호)
- Part 2: Ansible Vault 보안 (암호화된 설정 관리)
- Part 3: WireGuard VPN 설정 (안전한 네트워크 접근)
- Part 4: 종합 보안 체크리스트

### 🔧 [`docs/troubleshooting-guide.md`](docs/troubleshooting-guide.md) 
**문제해결 가이드** - 모든 문제상황과 해결방법
- Terraform 문제해결
- Ansible 문제해결  
- WireGuard VPN 문제해결
- GCP 리소스 문제해결
- 네트워크 연결 문제해결
- 긴급 상황 대응

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
