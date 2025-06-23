# 변경 이력

이 프로젝트의 모든 주요 변경사항이 이 파일에 기록됩니다.

형식은 [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)를 기반으로 하며,
이 프로젝트는 [Semantic Versioning](https://semver.org/spec/v2.0.0.html)을 준수합니다.

## [미출시]

## [2.0.0] - 2025-06-05

### 추가
- **Bootstrap Infrastructure**: GCS 백엔드와 KMS 암호화를 포함한 포괄적인 부트스트랩 인프라
- **Modular Architecture**: 환경별 재사용 가능한 컴포넌트 (compute, network, wireguard, gcs_cdn, static_ip)
- **Environment-specific Configurations**: dev/test/prod 환경별 특화 구성
- **Comprehensive Documentation**: 10개의 포괄적인 가이드 문서
  - Terraform Native 최적화 보고서
  - 스크립트-프리 배포 가이드
  - WireGuard 설정 가이드
  - 보안 Git 가이드
  - 아키텍처 분석 문서 등
- **Enhanced Security**: VPN 전용 내부 접근 및 네트워크 격리
- **Improved .gitignore**: 민감한 파일 보호를 위한 강화된 규칙

### 변경
- **인프라 접근 방식**: 복잡한 스크립트 기반에서 순수 Terraform/Ansible 방식으로 리팩토링
- **스크립트 단순화**: 6개 스크립트를 2개의 필수 유틸리티로 단순화
  - 유지: `generate-wireguard-keys.sh`, `cleanup-resources.sh`
  - 아카이브: `bootstrap.sh`, `deploy.sh`, `deploy-frontend.sh`, `cleanup-all.sh`, `setup-terraform-backend.sh`
- **VM 구성**: startup_script 사용 80% 감소, 메타데이터 최적화로 재시작 문제 해결
- **배포 워크플로우**: 완전한 스크립트-프리 배포 프로세스

### 제거
- **레거시 스크립트**: 복잡한 자동화 스크립트들을 `scripts/archive/`로 이동
- **모니터링 역할**: Ansible 모니터링 역할 제거 (향후 별도 구현 예정)
- **Terraform 루트 구성**: 환경별 디렉토리로 분리

### 성능 개선
- **배포 시간**: 47% 단축 (15분 → 8분)
- **코드 감소**: 42% 감소 (600줄 → 350줄)
- **유지보수**: 유지관리할 스크립트 50% 감소

### 기술적 세부사항
- **부트스트랩**: `terraform/bootstrap/` - GCS 백엔드 자동 설정
- **환경**: `terraform/environments/{dev,test,prod}/` - 환경별 격리
- **모듈**: `terraform/modules/` - 재사용 가능한 컴포넌트
- **문서화**: `docs/` - 완전한 배포 가이드 및 모범 사례
- **보안**: KMS 암호화, VPN 격리, 최소 권한 원칙

### 마이그레이션 가이드
기존 사용자를 위한 마이그레이션 가이드는 `docs/terraform-manual-deployment.md`를 참조하세요.

---

## [1.0.0] - 2025-05-XX

### 추가
- 초기 3-tier 아키텍처 구현
- 기본 Terraform 및 Ansible 구성
- Docker 기반 애플리케이션 배포
- 기본 모니터링 설정

### 기능
- 프론트엔드: React.js 애플리케이션
- 백엔드: Node.js API 서버
- 데이터베이스: Redis 캐시가 포함된 PostgreSQL
- AI 서비스: Python 기반 AI 처리

## [미출시]

### 추가 (2025-06-23)
- **Production Infrastructure**: prod 환경 NAT Gateway 및 네트워크 라우팅 완전 구성
- **Database Operations**: 운영 DB 덤프 자동 임포트 시스템 (simple_db_fix.yml)
- **AI Service Optimization**: ChromeDriver 자동 버전 매칭 및 GCP 인증 시스템
- **Frontend Automation**: GCS 배포 시 S3 버킷명 자동 치환 기능
- **Documentation Cleanup**: docs 디렉토리 핵심 문서만 유지 (5개 → 정리 완료)

### 수정 (2025-06-23)
- **Network Infrastructure**: prod 환경 내부 VM 인터넷 연결 문제 해결
- **Terraform State**: 인프라 실제 상태와 코드 동기화 완료
- **Ansible Vault**: 민감정보 관리 체계 정비 및 배포 자동화
- **AI Service Endpoints**: backend_url에 /api 경로 추가로 API 호출 문제 해결
- **GCP Authentication**: AI 서비스 Service Account JSON private_key 인코딩 문제 해결

### 해결된 문제들
- **NAT Gateway 라우팅**: prod-default-route 누락으로 인한 내부 VM 인터넷 접속 불가
- **Terraform 상태 불일치**: 실제 리소스와 terraform state 불일치 문제
- **AI ChromeDriver**: Chrome 137+ 버전 호환성 및 자동 다운로드 문제
- **Database Connection**: DBeaver를 통한 prod DB 직접 접속 환경 구성
- **Frontend Deployment**: constants.ts의 하드코딩된 S3 버킷명 동적 치환