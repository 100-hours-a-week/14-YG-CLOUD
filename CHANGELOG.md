# 변경 이력

이 프로젝트의 모든 주요 변경사항이 이 파일에 기록됩니다.

형식은 [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)를 기반으로 하며,
이 프로젝트는 [Semantic Versioning](https://semver.org/spec/v2.0.0.html)을 준수합니다.

## [2025-07-10] 긴급 장애 복구 - APM 데이터 수집 중단

### 수정
- **🚨 APM 장애 완전 복구**: 7/9 18:47~7/10 02:09 (7시간 22분) APM 데이터 수집 중단 해결
- **🔧 Elasticsearch 인증 오류 해결**: APM Server의 cluster_uuid 조회 401 오류 자동 복구
- **📊 실시간 모니터링 재개**: AI/Backend 서비스 APM 데이터 정상 수집 확인
- **📁 APM 인덱스 정상화**: traces-apm (86,809건), metrics-apm.app.backend_moongsan (7,766건) 등 모든 인덱스 정상 동작

### 상세 내용
- **장애 원인**: Elasticsearch 인증 오류로 APM Server가 cluster_uuid 조회 실패 (`status_code=401`)
- **복구 과정**: APM Server 자동 재시작으로 인증 문제 해결 (2025-07-10 02:09:24 UTC)
- **영향 범위**: 약 7시간 22분간 APM 트랜잭션/에러/메트릭 데이터 누락
- **현재 상태**: AI Service (Python Agent), Backend Service (Java Agent) 모두 정상 APM 데이터 전송 중
- **문서화**: `elk-configs/APM_OUTAGE_RECOVERY_REPORT.md` 상세 장애 보고서 작성

## [미출시]

### 추가
- **로그 메시지 표시 개선 가이드**: AI/Backend 로그 분리 및 실제 로그 내용 표시를 위한 종합 가이드
  - `LOG_MESSAGE_IMPROVEMENT_GUIDE.md`: 테이블에 message.keyword 필드 추가 방법
  - `KIBANA_DASHBOARD_DETAILED_GUIDE.md`: AI/Backend 로그 분리 대시보드 완성 가이드
  - `check-log-structure.sh`: 로그 데이터 구조 확인 스크립트
- **대시보드 관리 스크립트 개선**: 개선된 대시보드 Import/Export 지원
  - `manage-dashboards.sh export`: 기존 및 개선된 대시보드 동시 Export
  - `manage-dashboards.sh import improved`: 개선된 AI/Backend 분리 대시보드 Import
  - 사용법 도움말 업데이트 및 다중 대시보드 지원

### 수정
- **GCP Load Balancer 타임아웃 해결**: `/api/generation/description` 엔드포인트의 30초 타임아웃 문제 해결
  - `prod-backend-service` 타임아웃을 30초에서 120초로 증가
  - AI 생성 관련 API 호출의 안정성 향상
  - URL 경로 라우팅 검증 및 최적화 완료

### 개선
- **Kibana 대시보드 로그 메시지 표시**: 기존 대시보드에서 로그 내용이 보이지 않는 문제 분석
  - 테이블 패널에 `message.keyword` 필드 추가 필요성 확인
  - AI 로그(`service.keyword : "ai"`)와 Backend 로그(`service.keyword : "backend"`) 분리 방법 제시
  - 실시간 로그 내용 모니터링을 위한 구체적인 Kibana UI 설정 가이드 제공

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

### 수정
- **APM 서버 인증 오류 해결**: Elasticsearch 비밀번호 변경 후 APM 서버가 데이터를 전송하지 못하는 문제를 해결. `update-apm-auth.yml` 플레이북을 통해 인증 정보 업데이트를 자동화.
- **Ansible 인벤토리 구조 개선**: `shared.ini` 파일에 `[elk_servers:children]` 그룹을 추가하여 변수 상속 구조를 명확히 함.

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

## [2024-07-08] ELK Stack 대시보드 구축 완료

### 🎯 ELK 대시보드 시스템 구축
- **Kibana Sample Data 설치**: 웹로그, 전자상거래, 항공편 데이터 샘플 자동 설치
- **유명 대시보드 템플릿 적용**: [Logs] Web Traffic, [eCommerce] Revenue Dashboard 등
- **실제 서비스 로그 동기화**: Sample 대시보드를 뭉치면 산다 서비스 로그에 맞게 커스터마이징

### 📊 설치된 대시보드 목록
1. **[Logs] Web Traffic**: 실시간 웹 트래픽 분석
2. **[eCommerce] Revenue Dashboard**: 매출 및 주문 분석  
3. **[Flights] Global Flight Dashboard**: 항공편 데이터 분석

### 🛠️ 인덱스 패턴 구성
- `logs-*`: 뭉치면 산다 서비스 로그
- `filebeat-*`: 파일비트 수집 로그
- `kibana_sample_data_*`: 샘플 데이터 (logs, ecommerce, flights)

### 🚀 자동화 스크립트 작성
- `install-famous-dashboards.sh`: 유명 대시보드 템플릿 자동 설치
- `sync-sample-to-service-logs.sh`: Sample 대시보드와 실제 서비스 로그 동기화
- `check-sample-dashboards.sh`: 설치된 대시보드 확인 및 가이드

### 📖 문서화
- `KIBANA_DASHBOARD_USAGE_GUIDE.md`: 대시보드 활용 가이드 작성
- Sample 대시보드 커스터마이징 방법
- 실전 활용 시나리오 및 베스트 프랙티스

### 🔗 접속 정보
- **URL**: http://elk.moongsan.com:5601/app/dashboards
- **로그인**: moongsan_admin / moongsan123
- **주요 메뉴**: Analytics → Dashboard

### ✅ 완료된 작업
- [x] Kibana Sample Data 설치 및 활성화
- [x] 유명 대시보드 템플릿 Import (NDJSON 포맷 처리)
- [x] 실제 서비스 로그 인덱스 패턴 생성
- [x] Sample 대시보드 커스터마이징 자동화
- [x] 대시보드 활용 가이드 문서 작성

### 🎯 다음 단계
- [ ] 실제 서비스 로그 필드 매핑 최적화
- [ ] 커스텀 비즈니스 메트릭 대시보드 추가 생성
- [ ] 알림 시스템 (Watcher) 구성
- [ ] 자동화된 리포팅 시스템 구축

### 📝 기술적 성과
- **로그 시각화**: Sample Data 기반 전문적인 대시보드 즉시 활용 가능
- **자동화**: 스크립트를 통한 대시보드 설치/동기화 자동화
- **확장성**: 새로운 서비스 로그 추가 시 기존 템플릿 재활용 가능
- **운영 효율성**: 실시간 모니터링 및 분석 환경 구축

## [2024-07-08] 대시보드 코드화 및 관리 시스템 구축

### 🎯 대시보드 코드 관리 시스템 완성
- **실제 대시보드 구축**: 뭉치면 산다 실시간 서비스 모니터링 대시보드 완성
- **코드화 완료**: NDJSON 파일로 Export하여 버전 관리 가능
- **자동화 스크립트**: Import/Export/백업/상태확인 스크립트 구축

### 📊 완성된 대시보드 구성
1. **📈 시간별 로그 수**: Line Chart로 실시간 트렌드 분석
2. **📊 로그 레벨 분포**: Pie Chart로 ERROR/DEBUG 비율 확인
3. **🖥️ 서버별 로그 분포**: Bar Chart로 backend/ai 서버 로그 현황
4. **📋 최근 서비스 로그**: Table로 실시간 로그 목록 표시

### 🛠️ 개발된 관리 도구
- `manage-dashboards.sh`: 대시보드 Import/Export/백업 자동화
- `moongsan-service-monitoring-dashboard.ndjson`: 메인 대시보드 코드
- `DASHBOARD_CODE_MANAGEMENT.md`: 완전한 코드 관리 가이드

### 🔄 개발 워크플로우 확립
1. **UI에서 대시보드 수정** → Kibana 웹 인터페이스
2. **코드로 Export** → `./manage-dashboards.sh export`
3. **Git 버전 관리** → commit/push
4. **다른 환경 배포** → `./manage-dashboards.sh import`

### 📁 파일 구조 정리
```
elk-configs/
├── dashboards/
│   └── moongsan-service-monitoring-dashboard.ndjson
├── scripts/
│   ├── manage-dashboards.sh
│   ├── install-famous-dashboards.sh
│   └── quick-dashboard-setup.sh
├── DASHBOARD_CODE_MANAGEMENT.md
└── KIBANA_DASHBOARD_USAGE_GUIDE.md
```

### ✅ 달성된 목표
- [x] 실제 서비스 로그 기반 대시보드 구축
- [x] 대시보드 코드화 및 버전 관리
- [x] Import/Export 자동화 스크립트
- [x] 완전한 문서화 및 가이드
- [x] CI/CD 연동 준비 완료

### 🎯 기술적 성과
- **시각화 다양성**: Line, Pie, Bar, Table 차트 모두 활용
- **실시간 모니터링**: 30초 자동 새로고침으로 실시간 감시
- **코드 기반 관리**: Infrastructure as Code 방식 적용
- **배포 자동화**: 스크립트를 통한 원클릭 배포

### 🔗 접속 정보
- **대시보드 URL**: http://elk.moongsan.com:5601/app/dashboards
- **대시보드 ID**: ceebc166-d33d-40e7-aad4-91e73c2d6c6e
- **데이터 소스**: logs-* (moongsan-logs-*)