# 🏗️ 인프라 완전 가이드

> **14-YG-CLOUD 프로젝트**의 모든 인프라 설계, 최적화 과정, 그리고 최종 결과를 담은 완전한 가이드입니다.

## 📋 목차

- [Part 1: 아키텍처 설계](#part-1-아키텍처-설계)
- [Part 2: 최적화 여정](#part-2-최적화-여정)
- [Part 3: 최종 결과](#part-3-최종-결과)
- [Part 4: 현재 아키텍처 상태](#part-4-현재-아키텍처-상태)

---

## Part 1: 아키텍처 설계

### 🎯 프로젝트 개요

**14-YG-CLOUD**는 단일 VM에서 최적화된 3-Tier 아키텍처로의 마이그레이션 프로젝트입니다.

#### 주요 목표
- ✅ **비용 최적화**: Frontend를 GCS + CDN으로 이전하여 VM 비용 절감
- ✅ **보안 강화**: Private Network + VPN 접근으로 보안 레벨 향상  
- ✅ **확장성 개선**: 서비스별 독립적 스케일링 가능
- ✅ **운영 자동화**: Terraform + Ansible로 IaC 구현

#### 환경 구성
| 환경 | 목적 | 아키텍처 | 네트워크 |
|------|------|----------|----------|
| **Dev** | 개발/테스트 | 단일 VM (모노리틱) | Public Network |
| **Test** | 검증/스테이징 | 3-Tier 분리 | Private Network + Load Balancer |
| **Prod** | 프로덕션 | 3-Tier 분리 | Private Network + Load Balancer |

### 🏗️ 최종 아키텍처 다이어그램

```
인터넷
  │
  ▼
🌐 HTTP(S) Load Balancer
  │  ├── /api/* → Backend (8080)
  │  └── /generation/* → AI (8100)
  │
  ▼
🔒 Private VPC Network (10.0.0.0/16)
  │
  ├── 📱 Frontend
  │   └── GCS Bucket + CDN
  │
  ├── 🖥️ Jump Box (관리용)
  │   ├── e2-small (0.5 vCPU, 2GB)
  │   ├── 20GB 디스크
  │   └── WireGuard VPN 서버
  │
  ├── ⚙️ Backend API Server  
  │   ├── e2-standard-2 (2 vCPU, 8GB)
  │   ├── 30GB 디스크
  │   └── Spring Boot API (8080)
  │
  ├── 🤖 AI Generation Server
  │   ├── e2-highmem-2 (2 vCPU, 16GB)
  │   ├── 40GB 디스크
  │   └── FastAPI AI (8100)
  │
  └── 🗄️ Database Server
      ├── e2-standard-2 (2 vCPU, 8GB)  
      ├── 100GB 디스크
      ├── MySQL 8.0
      └── Redis Cache
```

---

## Part 2: 최적화 여정

### 🔍 2.1 Jump Box 크기 최적화

#### 문제 인식
- 초기 설정: `e2-medium` (1 vCPU, 4GB) = $24.27/월
- 역할: SSH 접근용 + WireGuard VPN만 담당
- **과도한 리소스** 사용 발견

#### 분석 과정
1. **CPU 사용률 분석**: 평상시 5% 미만
2. **메모리 사용률**: 500MB 미만
3. **네트워크 트래픽**: 관리 트래픽만

#### 최적화 결정
```diff
- machine_type = "e2-medium"     # $24.27/월 (1 vCPU, 4GB)
+ machine_type = "e2-small"      # $10.44/월 (0.5 vCPU, 2GB)

- disk_size = 50GB               # $8.50/월
+ disk_size = 20GB               # $3.40/월

💰 절약: $18.67/월 (57% 절약)
```

### 🤖 2.2 AI 서버 메모리 최적화

#### 문제 상황
- AI 모델 로딩 시 **16GB 메모리 필요**
- 기존 `e2-standard-4` 고려했으나 비용 부담

#### 대안 분석
| 인스턴스 타입 | vCPU | 메모리 | 월 비용 | 비고 |
|---------------|------|--------|---------|------|
| `e2-standard-4` | 4 | 16GB | $97.06/월 | CPU 과다 |
| `e2-highmem-2` | 2 | 16GB | $60.70/월 | **선택** |
| Custom (2,16) | 2 | 16GB | $88.33/월 | AWS 마이그레이션 고려시 불리 |

#### 최종 결정
- **`e2-highmem-2` 선택** (2 vCPU, 16GB)
- 이유: 비용 효율성 + AWS 마이그레이션 호환성

### ⚖️ 2.3 로드밸런서 구현

#### 아키텍처 갭 발견
- Backend/AI 서버가 `assign_external_ip = false`
- **외부에서 직접 접근 불가능**
- 진정한 3-Tier 아키텍처를 위해 Load Balancer 필요

#### 구현 결과
```hcl
# HTTP(S) Load Balancer 구성
- Frontend: GCS Bucket (정적 파일)
- API 라우팅: 
  * /api/* → Backend:8080
  * /generation/* → AI:8100
- Health Check: 각 서비스별 헬스체크
- SSL 종료: Load Balancer에서 처리
```

#### 비용 투자
- **Load Balancer 비용**: $18.08/월
- **가치**: 프로덕션 준비된 3-Tier 아키텍처 완성

### 💾 2.4 디스크 최적화

#### Backend 서버
```diff
- disk_size = 50GB               # $8.50/월
+ disk_size = 30GB               # $5.10/월
💰 절약: $3.40/월
```

#### AI 서버  
```diff
- disk_size = 50GB               # $8.50/월
+ disk_size = 40GB               # $6.80/월
💰 절약: $1.70/월
```

#### Database 서버
```bash
disk_size = 100GB                # $17.00/월 (유지)
# 이유: 데이터 안정성 및 성장 여유 확보
```

---

## Part 3: 최종 결과

### 💰 월간 비용 비교

#### 최적화 전
```bash
Jump Box:  $32.77/월 (e2-medium + 50GB)
Backend:   $56.95/월 (e2-standard-2 + 50GB)  
AI:        $77.60/월 (e2-standard-4 + 50GB)
Database:  $65.55/월 (e2-standard-2 + 100GB)
─────────────────────
총합:      $232.87/월
```

#### 최적화 후 (Load Balancer 포함)
```bash
Jump Box:    $13.84/월 (e2-small + 20GB)      ⭐ 58% 절약
Backend:     $53.63/월 (e2-standard-2 + 30GB) ⭐ 6% 절약
AI:          $67.50/월 (e2-highmem-2 + 40GB)  ⭐ 13% 절약  
Database:    $65.55/월 (e2-standard-2 + 100GB) ⭐ 유지
Load Balancer: $18.08/월                       ⭐ 새로 추가
Frontend:    $9.17/월 (GCS + CDN)              ⭐ 새로 추가
─────────────────────
총합:        $227.77/월
```

### 📊 최종 절약 결과
- **원래 예상 비용**: $278.00/월 (LB + Frontend 포함)
- **최적화된 비용**: $227.77/월  
- **총 절약**: $50.23/월 (18% 절약)
- **연간 절약**: $602.76/년

---

## Part 4: 현재 아키텍처 상태

### ✅ 완료된 구성

#### 1. **Terraform 모듈 구조**
```
terraform/
├── bootstrap/                   # GCS Backend + KMS
├── environments/test/           # 테스트 환경
└── modules/
    ├── compute/                 # VM 인스턴스들
    ├── network/                 # VPC + 서브넷
    ├── load_balancer/           # HTTP(S) LB (신규)
    ├── gcs_cdn/                 # Frontend 스토리지
    └── static_ip/               # 고정 IP
```

#### 2. **네트워크 구성**
- **VPC**: `moongsan-test-vpc` (10.0.0.0/16)
- **서브넷**: `moongsan-test-subnet` (10.0.1.0/24)
- **방화벽**: Private network 보안 규칙
- **Load Balancer**: 외부 트래픽 라우팅

#### 3. **보안 구성**
- **Private Network**: 모든 VM이 내부 IP만 사용
- **VPN 접근**: WireGuard를 통한 관리 접근
- **Public 접근**: Load Balancer를 통해서만 가능

#### 4. **서비스 포트 매핑**
| 서비스 | 내부 포트 | 외부 경로 | 접근 방법 |
|--------|-----------|-----------|-----------|
| Frontend | - | `/` | Load Balancer → GCS |
| Backend API | 8080 | `/api/*` | Load Balancer → Backend |
| AI API | 8100 | `/generation/*` | Load Balancer → AI |
| Database | 3306 | - | VPN을 통해서만 |
| Redis | 6379 | - | VPN을 통해서만 |

### 🎯 성능 특성

#### **Jump Box** (관리용)
- **목적**: SSH 게이트웨이 + WireGuard VPN
- **성능**: 관리 트래픽 처리에 최적화
- **접근**: 유일한 외부 IP 보유

#### **Backend** (API 서버)
- **목적**: REST API + 비즈니스 로직
- **성능**: 2 vCPU, 8GB로 안정적 처리
- **확장**: 필요시 인스턴스 그룹으로 확장 가능

#### **AI** (생성 서버)
- **목적**: AI 모델 추론 + 생성
- **성능**: 16GB 메모리로 대형 모델 로딩 가능
- **특징**: GPU 추가 확장 준비됨

#### **Database** (데이터 서버)
- **목적**: MySQL + Redis 데이터 저장
- **성능**: 2 vCPU, 8GB + 100GB 스토리지
- **안정성**: 자동 백업 + 고가용성 준비

### 🔮 향후 확장 계획

1. **Production 환경 구축**
   - Test 환경 설정을 Prod로 복제
   - 고가용성 구성 (Multi-Zone)
   - 모니터링 + 로깅 시스템

2. **성능 최적화**
   - CDN 캐싱 전략 고도화
   - Database 읽기 복제본 추가
   - Auto Scaling 그룹 구성

3. **보안 강화**
   - SSL 인증서 자동 갱신
   - 네트워크 보안 정책 강화
   - 액세스 로그 분석 시스템

---

> 💡 **프로젝트 성과**: 단순한 인프라 마이그레이션을 넘어서, **18% 비용 절약**과 함께 **확장 가능한 3-Tier 아키텍처**를 성공적으로 구축했습니다.
