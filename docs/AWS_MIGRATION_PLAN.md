# 멀티 클라우드 전환 계획서 (GCP Dev & AWS Prod)

> **문서 목표**: GCP vCPU 리소스 부족 문제를 해결하고, 인프라 확장성 및 안정성을 확보하기 위해 `dev` 환경은 GCP를 유지하고 `prod` 환경은 AWS로 전환하는 멀티 클라우드 전략을 명확하게 정의합니다.

## 1. 최종 목표 (End-Goal)

- **인프라 전환**: `dev` 환경은 GCP에 유지하고, `prod` 환경의 모든 애플리케이션(BE, FE, AI) 및 공유 서비스(DB 등)를 AWS로 이전합니다.
- **CI/CD 고도화**: AWS에 새로 구축한 Jenkins를 기반으로 `dev` 환경은 CD(지속적 배포), `prod` 환경은 CI(지속적 통합)가 적용된 파이프라인을 구축합니다.
- **비용 최적화**: GCP `dev` 환경은 무료 크레딧을 최대한 활용하고, AWS `prod` 환경은 효율적인 리소스 관리를 통해 비용을 최적화합니다.
- **다운타임 최소화**: 프로덕션 환경 이전 시, 계획된 최소한의 시간 내에 작업을 완료하여 서비스 중단을 최소화합니다.

## 2. 마이그레이션 단계별 로드맵

### Phase 1: CI/CD 기반 구축 (현재 진행 중)

- **목표**: AWS 환경에 Jenkins를 구축하고, `dev` 및 `prod` 환경 자동화된 배포 파이프라인의 토대를 마련합니다.
- **완료된 작업**:
    - [x] Terraform을 사용한 AWS 공유 VPC 및 Jenkins EC2 인프라 프로비저닝
    - [x] Ansible을 사용한 Jenkins 서버 초기 설치 및 설정
    - [x] Jenkins 서버 연결 확인 및 SSH 키 구성 완료
    - [x] Jenkins Credential 등록 완료:
        - [x] GitHub Personal Access Token (PAT) - ID: `github-pat-credentials`
        - [x] Docker Hub Credential - ID: `dockerhub-credentials`
    - [x] `deployment-guide.md`에 Jenkins 설정 내용 문서화
- **남은 작업**:
    - [ ] **Jenkins 플러그인 설치**: Docker, Ansible, Git 관련 플러그인 설치
    - [ ] **WireGuard 터널링 설정**: AWS Jenkins 서버와 GCP `dev` 환경 간의 WireGuard 연결 구성
    - [ ] 각 서비스(BE, FE, AI)별 `Jenkinsfile` 작성하여 파이프라인 코드화
    - [ ] `dev` 환경(develop 브랜치): Build → Test → Push → Deploy 자동화 (GCP `dev` 환경 대상)
    - [ ] `prod` 환경(main 브랜치): Build → Test 까지만 자동화 (배포는 수동 승인)

### Phase 1 완료 기준
- **Jenkins 서비스 상태**: ✅ 실행 중 (AWS EC2: 3.38.150.190)
- **Ansible 연결**: ✅ 정상 (SSH 키 구성 완료)
- **Credentials 설정**: ✅ 완료 (GitHub PAT + Docker Hub)
- **다음 단계**: Jenkins 플러그인 설치 및 파이프라인 구성

### Phase 2: 프로덕션(`prod`) 환경 인프라 AWS 이전

- **목표**: `prod` 환경의 모든 애플리케이션 서버를 AWS에 구축합니다.
- **주요 작업**:
    - [ ] **Terraform**: `prod` 환경용 EC2 인스턴스, 보안 그룹, 네트워크 설정 등 AWS 리소스 정의
    - [ ] **Ansible**: `prod.ini` 인벤토리 파일에 새로 생성된 AWS 서버 정보 업데이트
    - [ ] **WireGuard**: 신규 AWS `prod` 서버와 기존 인프라 간의 VPN 터널링 설정 및 연결 확인 (필요시)

### Phase 3: 프로덕션(`prod`) 환경 배포 및 검증

- **목표**: Phase 1에서 구축한 Jenkins 파이프라인을 통해 `prod` 애플리케이션을 AWS에 배포하고 안정성을 검증합니다.
- **주요 작업**:
    - [ ] Jenkins 파이프라인을 실행하여 `prod` 서버(BE, FE, AI)에 애플리케이션 배포
    - [ ] 배포된 `prod` 환경의 기능 및 성능 통합 테스트 수행
    - [ ] 내부 DNS 또는 서비스 디스커버리 설정 변경 (필요시)

### Phase 4: 프로덕션(`prod`) 환경 트래픽 전환

- **목표**: `prod` 환경의 안정적인 AWS 운영을 확인한 후, 실제 사용자 트래픽을 AWS로 전환합니다.
- **주요 작업**:
    - [ ] 사전 공지를 통해 점검 시간 확보
    - [ ] DNS 레코드(Load Balancer 주소 등)를 신규 AWS `prod` 환경으로 변경
    - [ ] 전환 후 즉시 모니터링을 통해 서비스 안정성 집중 확인

### Phase 5: GCP 프로덕션 리소스 정리 (Decommissioning)

- **목표**: AWS `prod` 환경이 완전히 안정화된 것을 확인한 후, 불필요한 GCP `prod` 리소스를 제거하여 비용을 최적화합니다.
- **주요 작업**:
    - [ ] 최소 1-2주간 AWS `prod` 환경 모니터링 후 롤백 계획이 불필요하다고 판단
    - [ ] Terraform `destroy` 명령을 사용하여 `prod` 환경의 GCP 리소스 제거
    - [ ] (선택 사항) GCP `dev` 환경의 리소스는 무료 크레딧 범위 내에서 유지 관리

---

## 현재 진행 상황 (2024년 7월 14일 기준)

### ✅ 완료된 인프라 현황

| 환경 | 플랫폼 | 상태 | 주요 서비스 | 연결 테스트 |
|------|--------|------|-------------|-------------|
| **Dev** | GCP | 🟢 운영 중 | moongsan-dev-vm (34.64.59.25) | ✅ 정상 |
| **Prod** | GCP | 🟢 운영 중 | backend, ai, database (내부 IP) | ✅ 정상 |
| **Shared** | GCP | 🟢 운영 중 | jumpbox, elk 서버 | ✅ 정상 |
| **Jenkins** | AWS | 🟢 운영 중 | aws-shared-jenkins (3.38.150.190) | ✅ 정상 |

### 🔧 Jenkins 설정 현황

- **서버 위치**: AWS EC2 (3.38.150.190)
- **서비스 상태**: 실행 중
- **Ansible 연결**: SSH 키 구성 완료
- **Credentials 구성**:
  - `github-pat-credentials`: GitHub 저장소 접근용
  - `dockerhub-credentials`: Docker 이미지 push용

### 🎯 다음 우선 작업

1. **Jenkins 플러그인 설치** (Docker, Ansible, Git)
2. **첫 번째 파이프라인 구성** (Backend 서비스 우선)
3. **Cross-cloud 네트워킹 설정** (AWS ↔ GCP 연결)

---
> 이 문서는 멀티 클라우드 전략에 따라 지속적으로 업데이트되어야 합니다.
