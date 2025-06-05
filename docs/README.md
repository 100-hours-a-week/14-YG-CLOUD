# 14-YG-CLOUD 프로젝트 문서

이 디렉토리는 14-YG-CLOUD 프로젝트의 모든 기술 문서를 포함합니다.

## 📚 문서 목록

### 🚀 실행 가이드 (우선 참조)
- **⭐ [terraform-deployment-manual.md](./terraform-deployment-manual.md)** - **[최우선 참조]**
  - **완전한 Terraform 중심 배포 메뉴얼**
  - 환경별 단계적 배포 가이드
  - gcloud 명령어 대신 Terraform 명령어 중심
  - 트러블슈팅 및 고급 운영 포함

- **⚡ [deployment-workflow.md](./deployment-workflow.md)** - **[신규 추가]**
  - **Terraform → Ansible 자동화 배포 워크플로우**
  - 스크립트 기반 원클릭 배포
  - startup_script vs Ansible 역할 분담
  - 배포 단계별 상세 가이드

### 🔧 구조 분석 및 최적화
- **[terraform-structure-analysis.md](./terraform-structure-analysis.md)** - **[신규 추가]**
  - metadata_startup_script 중복 문제 해결
  - Terraform 모듈 구조 최적화 분석
  - startup_script → Ansible 마이그레이션 방안

### 🔒 보안 & Git 관리
- **[security-git-guide.md](./security-git-guide.md)** - **[신규 추가]**
  - **민감한 정보 보호 가이드**
  - .gitignore 설정 및 보안 체크리스트
  - Git 커밋 전 보안 검증 방법

### 🏗️ 아키텍처 & 설계
- **[architecture-communication-flow.md](./architecture-communication-flow.md)**
  - Dev와 Test 환경 아키텍처 비교 분석
  - 네트워크 통신 흐름 상세 설명
  - 보안 고려사항 및 트러블슈팅 가이드

### 🔐 보안 및 네트워크
- **[wireguard-vs-jumpbox-analysis.md](./wireguard-vs-jumpbox-analysis.md)** - **⭐ 접근 방식 비교 분석**
- **[wireguard-simple-guide.md](./wireguard-simple-guide.md)** - 초보자용 WireGuard 설명서
- **[wireguard-setup.md](./wireguard-setup.md)** - 상세한 VPN 설정 가이드
- **[security-git-guide.md](./security-git-guide.md)** - 민감한 정보 보호 가이드

### 🌐 호스팅 & 배포
- **[gcs-cdn-setup.md](./gcs-cdn-setup.md)**
  - GCS + CDN Frontend 호스팅 구성
  - Terraform 자동화 및 성능 최적화
  - CI/CD 파이프라인 연동 방법

### 📋 프로젝트 관리
- **[project-status-summary.md](./project-status-summary.md)**
  - 전체 프로젝트 진행 현황 요약
  - 완료/진행/예정 작업 현황
  - 리소스 관리 및 다음 단계 계획

- **[work-session-log.md](./work-session-log.md)**
  - 세션별 상세 작업 기록
  - 수행된 분석 및 인프라 작업
  - 사용된 도구와 명령어 히스토리

### 🚀 배포 및 운영
- **[Scripts 실행 흐름 가이드](./scripts-execution-flow.md)** - **⭐ 스크립트 사용법 완전 가이드**
- **[배포 워크플로우](./deployment-workflow.md)** - Terraform과 Ansible 통합 배포 가이드
- **[Terraform 배포 매뉴얼](./terraform-deployment-manual.md)** - 단계별 배포 가이드
- **[GCS + CDN 설정](./gcs-cdn-setup.md)** - Frontend 정적 호스팅 가이드

## 🗂️ 문서 구조

```
docs/
├── README.md                           # 이 파일 (문서 인덱스)
├── terraform-deployment-manual.md      # 🆕 Terraform 중심 완전 배포 가이드
├── architecture-communication-flow.md  # 아키텍처 통신 흐름 가이드
├── wireguard-setup.md                 # WireGuard VPN 설정 가이드
├── gcs-cdn-setup.md                   # GCS+CDN 호스팅 가이드
├── project-status-summary.md          # 프로젝트 현황 요약
└── work-session-log.md                # 작업 세션 로그
```

## 🎯 문서 사용 가이드

### 새로운 팀원을 위한 순서
1. **[terraform-deployment-manual.md](./terraform-deployment-manual.md)** - 실행 메뉴얼 (필수)
2. **[project-status-summary.md](./project-status-summary.md)** - 프로젝트 전체 개요 파악
3. **[architecture-communication-flow.md](./architecture-communication-flow.md)** - 아키텍처 이해
4. **[wireguard-setup.md](./wireguard-setup.md)** - VPN 접속 설정

### 운영자를 위한 순서
1. **[terraform-deployment-manual.md](./terraform-deployment-manual.md)** - 운영 명령어 (필수)
2. **[work-session-log.md](./work-session-log.md)** - 최근 작업 내역 확인
3. **[architecture-communication-flow.md](./architecture-communication-flow.md)** - 트러블슈팅 가이드
4. **[project-status-summary.md](./project-status-summary.md)** - 다음 작업 계획

### 개발자를 위한 순서
1. **[terraform-deployment-manual.md](./terraform-deployment-manual.md)** - 개발 환경 구축 (필수)
2. **[architecture-communication-flow.md](./architecture-communication-flow.md)** - 시스템 아키텍처 이해
3. **[wireguard-setup.md](./wireguard-setup.md)** - 개발 환경 접속
4. **[gcs-cdn-setup.md](./gcs-cdn-setup.md)** - 배포 프로세스 이해

## 🔄 문서 업데이트 정책

### 업데이트 주기
- **project-status-summary.md**: 주요 마일스톤 달성 시
- **work-session-log.md**: 매 작업 세션 후
- **기술 가이드들**: 설정 변경 또는 새로운 발견 사항 시

### 버전 관리
- 모든 문서는 Git으로 버전 관리
- 주요 변경사항은 커밋 메시지에 명시
- 브랜치별 환경 차이사항 반영

## 🔍 빠른 참조

### 환경별 정보
| 환경 | VPC CIDR | 인스턴스 수 | 상태 |
|------|----------|-------------|------|
| Dev | 10.0.0.0/24 | 1개 | RUNNING |
| Test | 10.1.0.0/24 | 4개 | TERMINATED |
| Prod | 미정 | 미정 | 미구성 |

### 주요 포트
| 서비스 | 포트 | 프로토콜 | 접근 |
|--------|------|----------|-------|
| Frontend | 3000 | HTTP | 외부 |
| Backend API | 8000 | HTTP | 내부 |
| Database | 5432 | TCP | 내부 |
| SSH | 22 | TCP | VPN |
| WireGuard | 51820 | UDP | 외부 |

### 유용한 명령어
```bash
# VM 상태 확인
gcloud compute instances list --filter="name~moongsan"

# VPN 연결 상태
sudo wg show

# 방화벽 규칙 조회
gcloud compute firewall-rules list --filter="name~moongsan"

# Terraform 상태 확인
terraform state list
```

## 🆘 도움이 필요한 경우

1. **기술적 문제**: 해당 기술 가이드의 트러블슈팅 섹션 참조
2. **인프라 이슈**: [work-session-log.md](./work-session-log.md)에서 유사 사례 검색
3. **프로젝트 방향**: [project-status-summary.md](./project-status-summary.md)의 다음 단계 확인

## 📞 연락처
- **담당자**: LSH
- **프로젝트 리포지토리**: 현재 디렉토리
- **마지막 업데이트**: 2024-12-19

---

> 💡 **팁**: 각 문서는 독립적으로 읽을 수 있지만, 전체적인 이해를 위해서는 위에서 제안한 순서대로 읽는 것을 권장합니다.
