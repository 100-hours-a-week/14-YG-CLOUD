# 🏗️ 14-YG-CLOUD 프로젝트

> **GCP에서 구현한 최적화된 3-Tier 클라우드 인프라** - 비용 효율성과 보안을 동시에 달성한 엔터프라이즈급 아키텍처

## 🎯 프로젝트 현황

### 📊 시스템 상태
- **운영 환경**: Test, Production (Private Network)
- **개발 환경**: Dev (Public Network)
- **월 운영비**: $227.77 (18% 최적화 달성)
- **보안**: VPN 접근 + Private Network
- **자동화**: Terraform + Ansible IaC

### 🏗️ 아키텍처 개요
```
Internet → Load Balancer → Private VPC (10.0.0.0/16)
                              │
                              ├── Frontend (GCS + CDN)
                              ├── Jump Box (VPN Gateway)
                              ├── Backend API (Spring Boot)
                              ├── AI Service (FastAPI)
                              └── Database (MySQL + Redis)
```

## 📚 문서 구조

### 🚀 **운영자를 위한 문서**

#### [`operations-guide.md`](./operations-guide.md) ⭐
**일상 운영 가이드** - 시스템 운영의 모든 것
- 일상 점검 및 모니터링
- 배포 및 롤백 절차
- 백업 및 복구 방법
- 비상 상황 대응

#### [`infrastructure-architecture.md`](./infrastructure-architecture.md)
**현재 아키텍처 상태** - 시스템 구조와 동작 원리
- 네트워크 구조 및 보안 모델
- 각 계층별 구성 요소
- 통신 흐름 및 포트 매핑
- 리소스 사양 및 비용

### 🔧 **배포자를 위한 문서**

#### [`deployment-guide.md`](./deployment-guide.md)
**배포 실행 가이드** - 환경 구축 및 배포
- Terraform 인프라 생성
- Ansible 애플리케이션 배포
- 환경별 설정 관리

#### [`security-guide.md`](./security-guide.md)
**보안 설정 가이드** - 보안 구성 및 관리
- VPN 설정 및 인증서 관리
- Ansible Vault 암호화
- 방화벽 및 네트워크 보안

### 📋 **관리자를 위한 문서**

#### [`infrastructure-complete-guide.md`](./infrastructure-complete-guide.md)
**인프라 히스토리** - 설계 과정과 최적화 여정
- 아키텍처 설계 배경
- 비용 최적화 과정 (18% 절약)
- 의사결정 히스토리

#### [`troubleshooting-guide.md`](./troubleshooting-guide.md)
**문제해결 레퍼런스** - 상황별 해결 방법
- Terraform/Ansible 오류 해결
- 시스템 장애 대응
- 네트워크 문제 진단


## 🚀 빠른 시작

### 👀 시스템 상태 확인
```bash
# 인프라 상태 점검
gcloud compute instances list --project=your-project-id

# 서비스 헬스체크
curl -s http://your-domain.com/api/health
curl -s http://your-domain.com/generation/health
```

### 🔧 일상 운영 작업
```bash
# VPN 연결
sudo wg-quick up wg0

# Jump Box 접속
ssh -i ~/.ssh/gcp_key ubuntu@jump-box-ip

# 서비스 재시작
sudo systemctl restart backend-api
```

### 📦 새 버전 배포
```bash
# 1. 코드 업데이트
git pull origin main

# 2. 배포 실행
cd ansible
ansible-playbook -i inventories/test.ini main.yml -e "env=test"

# 3. 검증
curl -s http://your-domain.com/api/health
```

## 💡 주요 특징

### ✅ **비용 최적화**
- **18% 비용 절감**: $227.77/월 달성
- **Right-sizing**: 서버별 적정 사양 적용
- **Frontend 분리**: GCS + CDN으로 VM 비용 절약

### 🔒 **보안 강화**
- **Private Network**: 모든 서버가 내부 네트워크에 위치
- **VPN 게이트웨이**: WireGuard 기반 안전한 접근
- **방화벽 규칙**: 최소 권한 원칙 적용

### 🔄 **운영 자동화**
- **IaC**: Terraform으로 인프라 관리
- **Configuration Management**: Ansible로 설정 자동화
- **Environment Parity**: 환경별 일관성 보장

### 📈 **확장성**
- **독립적 스케일링**: 계층별 독립적 확장 가능
- **로드밸런서**: 트래픽 분산 및 고가용성
- **마이크로서비스 준비**: 3-Tier 기반 서비스 분리

## 📁 프로젝트 구조

```
14-YG-CLOUD/
├── docs/                    # 📚 모든 문서
│   ├── README.md           # 👈 현재 문서
│   ├── operations-guide.md # 🚀 일상 운영 가이드
│   ├── infrastructure-architecture.md # 🏗️ 시스템 구조
│   └── archive/            # 📦 과거 분석 자료
├── terraform/              # 🏗️ 인프라 구성
│   ├── bootstrap/          # 부트스트랩 리소스
│   ├── modules/            # 재사용 가능한 모듈
│   └── environments/       # 환경별 설정
├── ansible/                # ⚙️ 애플리케이션 배포
│   ├── inventories/        # 환경별 인벤토리
│   ├── playbooks/         # 플레이북 모음
│   └── roles/             # 역할별 설정
└── scripts/               # 🛠️ 유틸리티 스크립트
```

## 🎯 사용자별 시작점

| 역할 | 시작 문서 | 목적 |
|------|-----------|------|
| **운영자** | [`operations-guide.md`](./operations-guide.md) | 일상 운영, 모니터링, 장애 대응 |
| **배포자** | [`deployment-guide.md`](./deployment-guide.md) | 환경 구축, 애플리케이션 배포 |
| **아키텍트** | [`infrastructure-architecture.md`](./infrastructure-architecture.md) | 시스템 구조, 설계 이해 |
| **관리자** | [`infrastructure-complete-guide.md`](./infrastructure-complete-guide.md) | 프로젝트 히스토리, 의사결정 |

## 📞 지원 및 문의

- **문서 이슈**: GitHub Issues
- **긴급 상황**: operations-guide.md의 에스컬레이션 절차 참조
- **아키텍처 질문**: infrastructure-architecture.md 참조

---

*이 문서는 14-YG-CLOUD 프로젝트의 현재 상태를 반영하며, 시스템 변경시 함께 업데이트됩니다.*

## 🚀 빠른 시작 가이드

### **1. 처음 사용하는 경우**
1. [`infrastructure-complete-guide.md`](./infrastructure-complete-guide.md) - 전체 이해
2. [`deployment-guide.md`](./deployment-guide.md) - 실제 배포
3. [`security-guide.md`](./security-guide.md) - 보안 설정

### **2. 문제가 발생한 경우**  
1. [`troubleshooting-guide.md`](./troubleshooting-guide.md) - 문제해결
2. 해당 영역별 가이드 참고

### **3. 상세 분석이 필요한 경우**
1. [`archive/`](./archive/) 폴더의 세부 분석 문서들 참고

## 💡 문서 특징

- ✅ **5개 고정 구조**: 더 이상 문서가 늘어나지 않음
- ✅ **내용 손실 없음**: 모든 과거 분석 내용이 보존됨  
- ✅ **쉬운 접근**: 필요한 정보를 빠르게 찾을 수 있음
- ✅ **체계적 정리**: 주제별로 논리적으로 구성됨

---

> 💬 **사용 팁**: 각 문서는 독립적으로 읽을 수 있지만, 전체적인 이해를 위해서는 `infrastructure-complete-guide.md`부터 시작하는 것을 추천합니다.