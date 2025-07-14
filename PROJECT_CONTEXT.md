# 🧠 프로젝트 컨텍스트 & 메모리 문서

> **목적**: AI 어시스턴트가 프로젝트 상황을 빠르게 파악할 수 있도록 핵심 정보를 정리한 문서

## 📅 최종 업데이트
- **날짜**: 2024년 7월 14일
- **브랜치**: `feat/3tier`
- **상태**: Jenkins AWS 마이그레이션 진행 중

## 🌟 프로젝트 개요

### 목표
- **최종 목표**: 여러 문서를 종합하여 하나의 포트폴리오 문서 작성
- **현재 단계**: GCP에서 AWS로 점진적 마이그레이션 진행 중

### 아키텍처 전략 (Multi-Cloud → AWS 중심)
```
┌─────────────────┬─────────────────────────────────┬──────────────┐
│   환경          │   현재 위치                      │   최종 목표  │
├─────────────────┼─────────────────────────────────┼──────────────┤
│   dev           │   GCP (free credits 활용)      │   GCP 유지   │
│   prod          │   GCP → AWS 이전 예정           │   AWS        │
│   shared        │   GCP → AWS 이전 진행 중        │   AWS        │
└─────────────────┴─────────────────────────────────┴──────────────┘
```

**마이그레이션 전략**:
- **Dev 환경**: GCP 유지 (free credits 최대 활용)
- **Prod + Shared 환경**: AWS로 완전 이전
- **이유**: GCP vCPU 할당량 문제 해결 및 운영 환경 통합

## 🔄 현재 마이그레이션 상황

### ✅ 완료된 작업
- [x] GCP 3tier 아키텍처 구성 (Terraform)
- [x] Ansible 배포 자동화 구성
- [x] 기본 인프라 문서화

### 🔄 진행 중인 작업
- [ ] **Shared 환경 AWS 마이그레이션** (최우선)
  - **배경**: GCP vCPU 할당량 문제
  - **대상**: shared VPC의 모든 리소스 (Jenkins 포함)
  - **상태**: Jenkins 우선 이전 → 전체 shared 환경 이전
- [ ] **Prod 환경 AWS 마이그레이션** (후속)
  - **대상**: 운영 환경 전체
  - **전략**: Shared 환경 이전 완료 후 진행

### ⏳ 예정 작업
- [ ] Jenkins CI/CD 파이프라인 구성
- [ ] 기존 Ansible 역할 통합 (`ai_deploy`, `be_deploy`, `fe_deploy`)
- [ ] Shared 환경 전체 AWS 이전 완료
- [ ] Prod 환경 AWS 마이그레이션 계획 수립
- [ ] 포트폴리오 문서 통합 작성

## 🚀 CI/CD 전략

### Dev 환경 (GCP)
- **플랫폼**: Google Cloud Platform
- **CI/CD**: 완전 자동화 (CI + CD)
- **트리거**: `develop` 브랜치 push 시
- **배포**: 자동 배포까지 완료

### Prod 환경 (AWS)
- **플랫폼**: Amazon Web Services  
- **CI/CD**: CI만 자동화
- **트리거**: `main` 브랜치 push 시
- **배포**: 수동 트리거 (안정성 확보)

### Jenkins 위치
- **현재**: AWS로 마이그레이션 중 (Shared 환경의 일부)
- **역할**: 모든 환경의 CI/CD 허브
- **사용 도구**: 기존 Ansible 역할 활용
- **최종 구성**: AWS 기반 Shared 환경에서 dev(GCP) + prod(AWS) 관리

## 📋 중요한 규칙 & 컨벤션

### 작업 방식 및 역할 분담 (중요!)

#### 🤖 **AI 어시스턴트 담당 영역**
- **GCP 인프라**: Terraform/Ansible을 통한 모든 자동화 작업
- **Ansible 플레이북**: 모든 환경의 배포 및 구성 관리
- **문서 작성**: 가이드 및 진행 상황 문서화
- **AWS 정보 제공**: CLI 명령어를 통한 상태 확인 및 가이드 제공

#### 👨‍💻 **사용자 직접 작업 영역**
- **AWS 콘솔 작업**: EC2, VPC, 보안 그룹 등 모든 AWS 리소스 직접 구성
- **AWS 실습 학습**: 콘솔을 통한 AWS 서비스 이해도 향상
- **설정 검증**: 본인이 생성한 AWS 리소스 확인

#### 🤝 **협업 원칙**
- AI는 AWS CLI로 현재 상태만 확인하고 가이드 제공
- 사용자가 AWS 콘솔에서 모든 리소스 직접 생성
- AI가 생성된 AWS 리소스에 Ansible로 애플리케이션 배포

### 커밋 메시지 형식 (필수)
```bash
feat(<브랜치명>): <제목>

# 예시:
feat(3tier): Jenkins AWS 마이그레이션 완료
fix(cicd): Ansible 배포 스크립트 수정
docs(portfolio): 프로젝트 컨텍스트 문서 추가
```

### 커밋 주기 (중요!)
- **원칙**: 하나의 작업이 끝나면 수시로 커밋
- **세분화**: 큰 작업을 작은 단위로 나누어 자주 커밋
- **예시**:
  ```bash
  # 설정 파일 추가 시
  feat(3tier): Jenkins Dockerfile 추가
  
  # 구성 변경 시  
  feat(3tier): Jenkins AWS 보안 그룹 설정
  
  # 테스트 완료 시
  feat(3tier): Jenkins 연결 테스트 완료
  
  # 문서 업데이트 시
  docs(3tier): Jenkins 설치 가이드 추가
  ```

### 언어 사용 규칙
- **메시지 내용**: 한국어 우선, 영어 혼용 허용
- **문서**: 한국어 기본, 기술 용어는 영어 혼용

### 파일 정리 사항
- `portfolio-draft.md`: 삭제 예정 (최종 통합 문서로 대체)

## 🛠️ 기술 스택

### Infrastructure as Code
- **Terraform**: 인프라 프로비저닝
- **Ansible**: 애플리케이션 배포 및 구성 관리

### CI/CD Pipeline
- **Jenkins**: 빌드 및 배포 오케스트레이션
- **Docker**: 컨테이너화
- **Docker Hub**: 이미지 레지스트리

### Monitoring & Security
- **ELK Stack**: 로깅 및 모니터링
- **WireGuard**: VPN 연결

## 📁 프로젝트 구조 핵심

```
14-YG-CLOUD/
├── terraform/           # 인프라 프로비저닝
│   ├── bootstrap/      # Backend 설정
│   └── environments/   # 환경별 구성
├── ansible/            # 배포 자동화
│   ├── roles/         # 재사용 가능한 역할들
│   └── playbooks/     # 배포 시나리오
├── docs/              # 프로젝트 문서
└── PROJECT_CONTEXT.md # 이 파일!
```

## 🎯 다음 우선순위 작업

1. **Shared 환경 AWS 마이그레이션 완료**
   - Jenkins 설치 및 구성
   - 기타 Shared 리소스 이전
2. **기존 Ansible 역할과 Jenkins 연동**
3. **dev 환경 CI/CD 파이프라인 구성** (GCP)
4. **prod 환경 AWS 마이그레이션 계획**
5. **prod 환경 CI 파이프라인 구성** (AWS)
6. **통합 포트폴리오 문서 작성**

## 🚨 주의사항

### 클라우드 비용 관리
- **GCP**: free credits 최대 활용 (dev 환경만 유지)
- **AWS**: Shared + Prod 환경 통합 운영으로 비용 최적화

### 마이그레이션 고려사항
- **단계적 이전**: Shared → Prod 순서로 진행
- **네트워크 연결**: Cross-cloud 통신 (GCP dev ↔ AWS shared/prod)
- **데이터 이전**: 기존 GCP 데이터의 안전한 마이그레이션
- **Downtime 최소화**: 무중단 서비스 전환 전략 필요

### 보안 고려사항
- **Cross-cloud 연결**: GCP dev ↔ AWS shared/prod 간 보안 네트워킹
- **Jenkins 마이그레이션**: AWS 이전 시 모든 credentials 재설정 필요
- **VPN 설정**: WireGuard를 통한 안전한 클라우드 간 연결

### 데이터 일관성
- **상태 관리**: Terraform state 백업 및 동기화
- **설정 관리**: Ansible 인벤토리 환경별 분리

---

## 💬 AI 어시스턴트 가이드

### 대화 시작 시 체크리스트
- [ ] 현재 브랜치 확인: `feat/3tier`
- [ ] Shared 환경 AWS 마이그레이션 진행 상황 확인
- [ ] 작업 중인 환경 (dev/shared/prod) 확인
- [ ] 마이그레이션 단계 (Shared → Prod) 확인
- [ ] **AWS 작업 방식 확인**: 사용자가 콘솔에서 직접 작업할지 확인
- [ ] 커밋 메시지 형식 준수 여부 확인
- [ ] 작업 완료 시 즉시 커밋 여부 확인

### 자주 참조할 파일들
- `docs/deployment-guide.md`: 배포 가이드
- `ansible/playbooks/main.yml`: 통합 배포 플레이북
- `terraform/environments/`: 환경별 인프라 설정

### 작업 우선순위 기억
1. **Shared 환경 AWS 마이그레이션** (진행 중)
2. **Prod 환경 AWS 마이그레이션** (후속)
3. **Cross-cloud CI/CD 파이프라인 구성**
4. **포트폴리오 문서 통합**

---

📝 **작성자**: GitHub Copilot  
🔄 **업데이트 주기**: 주요 마일스톤 완료 시마다 업데이트
