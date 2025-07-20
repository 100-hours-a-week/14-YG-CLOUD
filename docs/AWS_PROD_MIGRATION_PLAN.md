# 🚀 AWS Prod 환경 마이그레이션 계획서

> **문서 목표**: GCP에서 운영 중인 Prod 환경을 AWS로 이전하여 통합된 클라우드 환경을 구축합니다.

## 📋 현재 상황 (2025-07-17 기준)

### ✅ 이미 AWS로 이전 완료 (Shared 환경)
- **Jenkins**: `aws-shared-jenkins` (3.38.150.190) - `jenkins.moongsan.com:8080`
- **ELK Stack**: `aws-shared-elk` (43.203.65.98) - `elk.test.moongsan.com`
- **WireGuard**: `aws-shared-wireguard` (3.35.93.111) - 수동 설정 예정

### 🎯 이전 대상 (GCP → AWS)
- **Backend API**: Spring Boot 서버
- **AI Service**: FastAPI 서버  
- **Database**: MySQL + Redis
- **Frontend**: React → S3 + CloudFront
- **네트워킹**: VPC + 보안그룹 구성

## 🏗️ AWS Prod 아키텍처 설계

### 네트워크 아키텍처 설계 방침

#### 3-Tier 아키텍처 옵션 분석

AWS 3-Tier 아키텍처 구현에 대한 세 가지 접근 방식을 비교 분석하여 최적의 솔루션을 선택합니다.

##### Option 1: 완전한 엔터프라이즈 3-Tier 아키텍처 ⭐️⭐️⭐️⭐️⭐️
```
AWS Prod VPC (10.2.0.0/16)
├── Public Subnet (10.2.1.0/24) - ap-northeast-2a
│   ├── Application Load Balancer
│   └── NAT Gateway #1
├── Public Subnet (10.2.4.0/24) - ap-northeast-2c  
│   └── NAT Gateway #2
├── Private Subnet (10.2.2.0/24) - ap-northeast-2a
│   ├── Backend API Server (EC2)
│   ├── AI Service Server (EC2) - GPU
│   ├── Redis Server (EC2) - Cache
│   └── Kafka Cluster (EC2) - Message Queue
├── Private Subnet (10.2.5.0/24) - ap-northeast-2c
│   └── (확장용 Private Subnet)
├── Database Subnet (10.2.3.0/24) - ap-northeast-2a
│   ├── Database Server (EC2) - MySQL
│   └── Vector DB Server (EC2) - PostgreSQL + pgvector
└── Database Subnet (10.2.6.0/24) - ap-northeast-2c
    └── (확장용 Database Subnet)
```

**장점:**
- 완전한 고가용성 (Multi-AZ)
- 단일 장애점 없음 (NAT Gateway 이중화)
- 엔터프라이즈 표준 준수
- 향후 확장성 우수

**단점:**
- 높은 비용 (NAT Gateway 2개: $90/월)
- 복잡한 관리
- 현재 트래픽 대비 과도한 스펙

**예상 비용:** $420-450/월

##### Option 2: 비용 최적화 3-Tier 아키텍처 ⭐️⭐️⭐️⭐️ (🎯 **권장**)
```
AWS Prod VPC (10.2.0.0/16)
├── Public Subnet (10.2.1.0/24) - ap-northeast-2a
│   ├── Application Load Balancer (Multi-AZ 지원)
│   └── NAT Gateway (단일, 공유)
├── Public Subnet (10.2.4.0/24) - ap-northeast-2c
│   └── (ALB용 추가 서브넷, NAT 없음)
├── Private Subnet (10.2.2.0/24) - ap-northeast-2a
│   ├── Backend API Server (EC2)
│   ├── AI Service Server (EC2) - GPU
│   ├── Redis Server (EC2) - Cache
│   └── Kafka Cluster (EC2) - Message Queue
└── Database Subnet (10.2.3.0/24) - ap-northeast-2a
    ├── Database Server (EC2) - MySQL
    └── Vector DB Server (EC2) - PostgreSQL + pgvector
```

**장점:**
- 3-Tier 구조 유지 (업계 표준)
- 적절한 보안 격리
- 합리적인 비용 (NAT Gateway 1개: $45/월)
- ALB Multi-AZ로 웹 계층 고가용성 확보
- DB와 Private 계층 분리로 보안성 확보

**단점:**
- NAT Gateway 단일 장애점 (99.95% 가용성)
- Private/DB 서브넷이 같은 AZ

**예상 비용:** $280-320/월

##### Option 3: 단순화된 2-Tier 아키텍처 ⭐️⭐️⭐️
```
AWS Prod VPC (10.2.0.0/16)
├── Public Subnet (10.2.1.0/24) - ap-northeast-2a
│   ├── Application Load Balancer
│   └── NAT Gateway
└── Private Subnet (10.2.2.0/24) - ap-northeast-2a
    ├── Backend API Server (EC2)
    ├── AI Service Server (EC2) - GPU
    ├── Database Server (EC2) - MySQL
    ├── Vector DB Server (EC2) - PostgreSQL + pgvector
    ├── Redis Server (EC2) - Cache
    └── Kafka Cluster (EC2) - Message Queue
```

**장점:**
- 최소 비용
- 단순한 관리
- 빠른 구축

**단점:**
- 보안 격리 부족 (DB와 App이 같은 서브넷)
- 3-Tier 표준 미준수
- 확장성 제한

**예상 비용:** $250-280/월

#### 🎯 **최종 권장: Option 2 (비용 최적화 3-Tier)**

**선택 이유:**
1. **표준 준수**: 3-Tier 아키텍처 유지로 업계 모범사례 준수
2. **적절한 보안**: DB와 Application 계층 분리
3. **비용 효율성**: 완전한 엔터프라이즈 대비 30% 비용 절감
4. **확장 가능성**: 향후 Multi-AZ 확장 시 쉬운 전환
5. **운영 신뢰성**: ALB Multi-AZ로 웹 계층 고가용성 확보

**위험 완화 방안:**
- NAT Gateway 모니터링 강화 (CloudWatch 알람)
- NAT Instance 백업 계획 수립
- 향후 트래픽 증가 시 NAT Gateway 이중화 검토

### 선택된 네트워크 구성 (Option 2 - 단순화)
```
AWS Prod VPC (10.2.0.0/16)
├── Public Subnet (10.2.1.0/24) - ap-northeast-2a
│   ├── Application Load Balancer
│   └── NAT Gateway (공유)
├── Private Subnet (10.2.2.0/24) - ap-northeast-2a
│   ├── Backend API Server (EC2)
│   ├── AI Model Server (EC2) - GPU (학습/추론)
│   ├── AI Serving Server A (EC2) - FastAPI (기능 A)
│   ├── AI Serving Server B (EC2) - FastAPI (기능 B)
│   ├── Redis Server (EC2) - Cache
│   └── Kafka Cluster (EC2) - Message Queue
└── Database Subnet (10.2.3.0/24) - ap-northeast-2a
    ├── Database Server (EC2) - MySQL
    ├── Vector DB Server (EC2) - PostgreSQL + pgvector
    └── MongoDB Server (EC2) - NoSQL Database
```

**핵심 설계 원칙:**
- **3-Tier 분리**: Web(Public) → App(Private) → DB(Database) 계층 구분
- **보안 격리**: 각 계층별 별도 서브넷 및 보안그룹
- **비용 최적화**: 단일 NAT Gateway로 외부 통신 제공
- **확장성**: 필요시 Multi-AZ 확장 준비된 구조
- **MongoDB 포함**: 모든 데이터베이스를 Database 서브넷에서 통합 관리

### 서비스 매핑 (AI 기능별 분리)
| GCP 서비스 | AWS 대응 서비스 | 인스턴스 타입 | 가용영역 | 용도 |
|------------|-----------------|---------------|----------|------|
| prod-backend | EC2 t3.medium × 1 | 2 vCPU, 4GB | ap-northeast-2a | Spring Boot API |
| prod-ai-model | EC2 g4dn.xlarge × 1 | 4 vCPU, 16GB, GPU | ap-northeast-2a | ML Model Server (학습/추론) |
| prod-ai-serving-a | EC2 t3.medium × 1 | 2 vCPU, 4GB | ap-northeast-2a | FastAPI Serving (기능 A) |
| prod-ai-serving-b | EC2 t3.medium × 1 | 2 vCPU, 4GB | ap-northeast-2a | FastAPI Serving (기능 B) |
| prod-database | EC2 t3.small × 1 | 2 vCPU, 2GB | ap-northeast-2a | MySQL 8.0 |
| prod-vectordb | EC2 t3.small × 1 | 2 vCPU, 2GB | ap-northeast-2a | PostgreSQL + pgvector |
| prod-mongodb | EC2 t3.small × 1 | 2 vCPU, 2GB | ap-northeast-2a | MongoDB NoSQL |
| prod-redis | EC2 t3.micro × 1 | 2 vCPU, 1GB | ap-northeast-2a | Redis Cache |
| prod-kafka | EC2 t3.medium × 1 | 2 vCPU, 4GB | ap-northeast-2a | Kafka 3 + Zookeeper 3 + UI |
| GCS + CDN | S3 + CloudFront | - | Multi-Region | 정적 웹사이트 |

**총 인스턴스**: 9대 (모두 ap-northeast-2a)

#### Kafka 클러스터 구성 상세
```
단일 EC2 인스턴스에서 Docker Compose로 운영:
- Zookeeper 3대: 포트 2181, 2182, 2183
- Kafka 3대: 포트 19092, 19093, 19094 (External)
- Kafka UI: 포트 8089 (관리용)
- 내부 통신: 포트 9092 (Kafka), 2888-3888 (Zookeeper)
- 복제 팩터: 3 (고가용성 보장)
```

## 🚀 마이그레이션 단계별 계획

### Phase 1: AWS 인프라 구성 (수동 + Terraform Export)
**담당**: 사용자 (AWS 콘솔/CLI) + AI (가이드 제공)

#### Step 1.1: VPC 및 네트워크 구성 (상세 가이드)

##### 1-1. VPC 생성
```
AWS 콘솔 → VPC → "VPC 생성" 클릭

기본 설정:
- 생성할 리소스: VPC만
- 이름 태그: aws-prod-vpc
- IPv4 CIDR 블록: 10.2.0.0/16
- IPv6 CIDR 블록: IPv6 CIDR 블록 없음
- 테넌시: 기본값
- 태그: 
  * Environment: prod
  * Project: moongsan
```

##### 1-2. 서브넷 생성 (3개)
```
VPC → 서브넷 → "서브넷 생성" 클릭

서브넷 1 - Public:
- 서브넷 이름: aws-prod-public-subnet
- VPC: aws-prod-vpc 선택
- 가용 영역: ap-northeast-2a
- IPv4 서브넷 CIDR 블록: 10.2.1.0/24
- 태그:
  * Name: aws-prod-public-subnet
  * Type: public
  * Environment: prod

서브넷 2 - Private:
- 서브넷 이름: aws-prod-private-subnet
- VPC: aws-prod-vpc 선택
- 가용 영역: ap-northeast-2a
- IPv4 서브넷 CIDR 블록: 10.2.2.0/24
- 태그:
  * Name: aws-prod-private-subnet
  * Type: private
  * Environment: prod

서브넷 3 - Database:
- 서브넷 이름: aws-prod-database-subnet
- VPC: aws-prod-vpc 선택
- 가용 영역: ap-northeast-2a
- IPv4 서브넷 CIDR 블록: 10.2.3.0/24
- 태그:
  * Name: aws-prod-database-subnet
  * Type: database
  * Environment: prod

주의사항:
- Public 서브넷은 향후 확장시 추가 AZ 구성 가능
- 현재는 단일 AZ로 시작하여 복잡성 최소화
- ALB는 단일 서브넷에서도 정상 동작 (Multi-AZ는 향후 확장시 고려)
```

##### 1-3. Internet Gateway 생성 및 연결
```
VPC → 인터넷 게이트웨이 → "인터넷 게이트웨이 생성"

설정:
- 이름 태그: aws-prod-igw
- 태그:
  * Environment: prod
  * Project: moongsan

생성 후 연결:
1. 생성된 IGW 선택
2. "작업" → "VPC에 연결"
3. VPC: aws-prod-vpc 선택
4. "인터넷 게이트웨이 연결" 클릭
```

##### 1-4. 탄력적 IP 및 NAT Gateway 생성
```
Step 1: 탄력적 IP 할당
EC2 → 네트워크 및 보안 → 탄력적 IP → "탄력적 IP 주소 할당"
- 네트워크 경계 그룹: ap-northeast-2
- 퍼블릭 IPv4 주소 풀: Amazon의 IPv4 주소 풀
- 태그:
  * Name: aws-prod-nat-eip
  * Environment: prod

Step 2: NAT Gateway 생성
VPC → NAT 게이트웨이 → "NAT 게이트웨이 생성"
- 이름: aws-prod-nat-gateway
- 서브넷: aws-prod-public-subnet 선택
- 연결 유형: 퍼블릭
- 탄력적 IP 할당 ID: 위에서 생성한 EIP 선택
- 태그:
  * Name: aws-prod-nat-gateway
  * Environment: prod
```

##### 1-5. 라우팅 테이블 구성 (3개)
```
VPC → 라우팅 테이블 → "라우팅 테이블 생성"

라우팅 테이블 1 - Public:
- 이름: aws-prod-public-rt
- VPC: aws-prod-vpc
- 태그:
  * Name: aws-prod-public-rt
  * Type: public
  * Environment: prod

라우팅 규칙 추가:
- 대상: 0.0.0.0/0
- 타겟: aws-prod-igw (인터넷 게이트웨이)

서브넷 연결:
- "서브넷 연결" 탭 → "서브넷 연결 편집"
- aws-prod-public-subnet 선택

라우팅 테이블 2 - Private:
- 이름: aws-prod-private-rt
- VPC: aws-prod-vpc
- 태그:
  * Name: aws-prod-private-rt
  * Type: private
  * Environment: prod

라우팅 규칙 추가:
- 대상: 0.0.0.0/0
- 타겟: aws-prod-nat-gateway (NAT 게이트웨이)

서브넷 연결:
- aws-prod-private-subnet 선택

라우팅 테이블 3 - Database:
- 이름: aws-prod-database-rt
- VPC: aws-prod-vpc
- 태그:
  * Name: aws-prod-database-rt
  * Type: database
  * Environment: prod

라우팅 규칙 추가:
- 대상: 0.0.0.0/0
- 타겟: aws-prod-nat-gateway (NAT 게이트웨이)

서브넷 연결:
- aws-prod-database-subnet 선택
```

##### 1-6. 서브넷 자동 IP 할당 설정
```
각 서브넷 설정:

Public 서브넷:
- aws-prod-public-subnet 선택
- "작업" → "서브넷 설정 수정"
- "퍼블릭 IPv4 주소 자동 할당 활성화" 체크
- 저장

Private/Database 서브넷:
- 자동 IP 할당 비활성화 (기본값 유지)
```

**자동 IP 할당 활성화의 장점:**
- **편의성**: EC2 인스턴스 생성 시 자동으로 퍼블릭 IP 할당 (인스턴스용)
- **운영 효율성**: Public 서브넷의 EC2 인스턴스가 외부 통신 가능
- **비용 절약**: 탄력적 IP(EIP) 할당 없이도 외부 접근 가능 (단, 인스턴스 재시작 시 IP 변경)
- **자동화**: Auto Scaling 시 새 인스턴스에 자동으로 퍼블릭 IP 부여
- **보안**: Private/Database 서브넷은 비활성화하여 외부 직접 접근 차단

**중요 사항:**
- **ALB는 영향 없음**: ALB는 고정 DNS 이름 사용, Route 53 별칭으로 연결
- **자동 IP 할당**: EC2 인스턴스에만 적용, ALB나 NAT Gateway와 무관
- **DNS 안정성**: api.test.moongsan.com → ALB DNS 별칭 → AWS가 자동 관리

**주의사항:**
- 자동 할당된 퍼블릭 IP는 EC2 인스턴스 중지/시작 시 변경됨
- 고정 IP가 필요한 EC2는 탄력적 IP(EIP) 별도 할당 필요  
- Private/Database 서브넷에서는 보안상 비활성화 권장
- **ALB/NAT Gateway**: 별도의 고정 IP/DNS 사용으로 영향 없음

#### Step 1.2: 보안 그룹 설정 (상세 가이드)

```
EC2 → 네트워크 및 보안 → 보안 그룹 → "보안 그룹 생성"
```

##### SG 1: ALB Security Group
```
기본 정보:
- 보안 그룹 이름: aws-prod-alb-sg
- 설명: Production ALB Security Group
- VPC: aws-prod-vpc

인바운드 규칙:
규칙 1:
- 유형: HTTP
- 프로토콜: TCP
- 포트 범위: 80
- 소스: 0.0.0.0/0 (Anywhere IPv4)
- 설명: Allow HTTP from internet

규칙 2:
- 유형: HTTPS
- 프로토콜: TCP
- 포트 범위: 443
- 소스: 0.0.0.0/0 (Anywhere IPv4)
- 설명: Allow HTTPS from internet

아웃바운드 규칙:
- 기본값 유지 (모든 트래픽 허용)

접속 흐름:
- Internet → ALB (:80, :443)

태그:
- Name: aws-prod-alb-sg
- Environment: prod
- Service: alb
```

##### SG 2: Backend Security Group
```
기본 정보:
- 보안 그룹 이름: aws-prod-backend-sg
- 설명: Production Backend API Security Group
- VPC: aws-prod-vpc

인바운드 규칙:
규칙 1:
- 유형: 사용자 지정 TCP
- 프로토콜: TCP
- 포트 범위: 8080
- 소스: aws-prod-alb-sg (보안 그룹 선택)
- 설명: Allow ALB to Backend API

규칙 2:
- 유형: SSH
- 프로토콜: TCP
- 포트 범위: 22
- 소스: 10.2.0.0/16 (VPC CIDR)
- 설명: SSH from VPC

접속 흐름:
- ALB → Backend (:8080)
- VPC → Backend (:22)

태그:
- Name: aws-prod-backend-sg
- Environment: prod
- Service: backend
```

##### SG 3: AI Model Server Security Group
```
기본 정보:
- 보안 그룹 이름: aws-prod-ai-model-sg
- 설명: Production AI Model Server Security Group (GPU)
- VPC: aws-prod-vpc

인바운드 규칙:
규칙 1:
- 유형: 사용자 지정 TCP
- 프로토콜: TCP
- 포트 범위: 8000
- 소스: aws-prod-ai-serving-sg (보안 그룹 선택)
- 설명: Allow AI Serving to Model Server

규칙 2:
- 유형: SSH
- 프로토콜: TCP
- 포트 범위: 22
- 소스: 10.2.0.0/16
- 설명: SSH from VPC

접속 흐름:
- AI Serving → AI Model (:8000)
- VPC → AI Model (:22)

태그:
- Name: aws-prod-ai-model-sg
- Environment: prod
- Service: ai-model
```

##### SG 4: AI Serving Security Group
```
기본 정보:
- 보안 그룹 이름: aws-prod-ai-serving-sg
- 설명: Production AI Serving API Security Group (기능별)
- VPC: aws-prod-vpc

인바운드 규칙:
규칙 1:
- 유형: 사용자 지정 TCP
- 프로토콜: TCP
- 포트 범위: 8100
- 소스: aws-prod-backend-sg (보안 그룹 선택)
- 설명: Allow Backend to AI Serving A (기능 A)

규칙 2:
- 유형: 사용자 지정 TCP
- 프로토콜: TCP
- 포트 범위: 8101
- 소스: aws-prod-backend-sg (보안 그룹 선택)
- 설명: Allow Backend to AI Serving B (기능 B)

규칙 3:
- 유형: 사용자 지정 TCP
- 프로토콜: TCP
- 포트 범위: 8100
- 소스: aws-prod-alb-sg (보안 그룹 선택)
- 설명: Allow ALB to AI Serving A (직접 접근)

규칙 4:
- 유형: 사용자 지정 TCP
- 프로토콜: TCP
- 포트 범위: 8101
- 소스: aws-prod-alb-sg (보안 그룹 선택)
- 설명: Allow ALB to AI Serving B (직접 접근)

규칙 5:
- 유형: SSH
- 프로토콜: TCP
- 포트 범위: 22
- 소스: 10.2.0.0/16
- 설명: SSH from VPC

접속 흐름:
- Backend → AI Serving (:8100, :8101)
- ALB → AI Serving (:8100, :8101) [직접 접근]
- VPC → AI Serving (:22)

태그:
- Name: aws-prod-ai-serving-sg
- Environment: prod
- Service: ai-serving
```

##### SG 5: Database Security Group
```
기본 정보:
- 보안 그룹 이름: aws-prod-database-sg
- 설명: Production MySQL Database Security Group
- VPC: aws-prod-vpc

인바운드 규칙:
규칙 1:
- 유형: MySQL/Aurora
- 프로토콜: TCP
- 포트 범위: 3306
- 소스: aws-prod-backend-sg
- 설명: Allow Backend to MySQL

규칙 2:
- 유형: MySQL/Aurora
- 프로토콜: TCP
- 포트 범위: 3306
- 소스: aws-prod-ai-serving-sg
- 설명: Allow AI Serving to MySQL

규칙 3:
- 유형: SSH
- 프로토콜: TCP
- 포트 범위: 22
- 소스: 10.2.0.0/16
- 설명: SSH from VPC

접속 흐름:
- Backend → MySQL (:3306)
- AI Serving → MySQL (:3306)
- VPC → MySQL (:22)

태그:
- Name: aws-prod-database-sg
- Environment: prod
- Service: mysql
```

##### SG 6: Vector DB Security Group
```
기본 정보:
- 보안 그룹 이름: aws-prod-vectordb-sg
- 설명: Production PostgreSQL Vector DB Security Group
- VPC: aws-prod-vpc

인바운드 규칙:
규칙 1:
- 유형: PostgreSQL
- 프로토콜: TCP
- 포트 범위: 5432
- 소스: aws-prod-ai-serving-sg
- 설명: Allow AI Serving to Vector DB

규칙 2:
- 유형: SSH
- 프로토콜: TCP
- 포트 범위: 22
- 소스: 10.2.0.0/16
- 설명: SSH from VPC

접속 흐름:
- AI Serving → Vector DB (:5432)
- VPC → Vector DB (:22)

태그:
- Name: aws-prod-vectordb-sg
- Environment: prod
- Service: postgresql
```

##### SG 7: MongoDB Security Group
```
기본 정보:
- 보안 그룹 이름: aws-prod-mongodb-sg
- 설명: Production MongoDB NoSQL Database Security Group
- VPC: aws-prod-vpc

인바운드 규칙:
규칙 1:
- 유형: 사용자 지정 TCP
- 프로토콜: TCP
- 포트 범위: 27017
- 소스: aws-prod-backend-sg
- 설명: Allow Backend to MongoDB

규칙 2:
- 유형: 사용자 지정 TCP
- 프로토콜: TCP
- 포트 범위: 27017
- 소스: aws-prod-ai-serving-sg
- 설명: Allow AI Serving to MongoDB

규칙 3:
- 유형: SSH
- 프로토콜: TCP
- 포트 범위: 22
- 소스: 10.2.0.0/16
- 설명: SSH from VPC

접속 흐름:
- Backend → MongoDB (:27017)
- AI Serving → MongoDB (:27017)
- VPC → MongoDB (:22)

태그:
- Name: aws-prod-mongodb-sg
- Environment: prod
- Service: mongodb
```

##### SG 8: Redis Security Group
```
기본 정보:
- 보안 그룹 이름: aws-prod-redis-sg
- 설명: Production Redis Cache Security Group
- VPC: aws-prod-vpc

인바운드 규칙:
규칙 1:
- 유형: 사용자 지정 TCP
- 프로토콜: TCP
- 포트 범위: 6379
- 소스: aws-prod-backend-sg
- 설명: Allow Backend to Redis

규칙 2:
- 유형: 사용자 지정 TCP
- 프로토콜: TCP
- 포트 범위: 6379
- 소스: aws-prod-ai-serving-sg
- 설명: Allow AI Serving to Redis

규칙 3:
- 유형: SSH
- 프로토콜: TCP
- 포트 범위: 22
- 소스: 10.2.0.0/16
- 설명: SSH from VPC

접속 흐름:
- Backend → Redis (:6379)
- AI Serving → Redis (:6379)
- VPC → Redis (:22)

태그:
- Name: aws-prod-redis-sg
- Environment: prod
- Service: redis
```

##### SG 9: Kafka Security Group
```
기본 정보:
- 보안 그룹 이름: aws-prod-kafka-sg
- 설명: Production Kafka Cluster + Zookeeper Security Group
- VPC: aws-prod-vpc

인바운드 규칙:
규칙 1:
- 유형: 사용자 지정 TCP
- 프로토콜: TCP
- 포트 범위: 9092
- 소스: aws-prod-backend-sg
- 설명: Allow Backend to Kafka (Internal)

규칙 2:
- 유형: 사용자 지정 TCP
- 프로토콜: TCP
- 포트 범위: 9092
- 소스: aws-prod-ai-serving-sg
- 설명: Allow AI Serving to Kafka (Internal)

규칙 3:
- 유형: 사용자 지정 TCP
- 프로토콜: TCP
- 포트 범위: 2181-2183
- 소스: aws-prod-backend-sg
- 설명: Allow Backend to Zookeeper Cluster

규칙 4:
- 유형: 사용자 지정 TCP
- 프로토콜: TCP
- 포트 범위: 2181-2183
- 소스: aws-prod-ai-serving-sg
- 설명: Allow AI Serving to Zookeeper Cluster

규칙 5:
- 유형: 사용자 지정 TCP
- 프로토콜: TCP
- 포트 범위: 19092-19094
- 소스: 10.2.0.0/16
- 설명: Allow VPC to Kafka External Ports

규칙 6:
- 유형: 사용자 지정 TCP
- 프로토콜: TCP
- 포트 범위: 8089
- 소스: 10.2.0.0/16
- 설명: Allow VPC to Kafka UI

규칙 7:
- 유형: SSH
- 프로토콜: TCP
- 포트 범위: 22
- 소스: 10.2.0.0/16
- 설명: SSH from VPC

접속 흐름:
- Backend → Kafka (:9092)
- AI Serving → Kafka (:9092)
- Backend → Zookeeper (:2181-2183)
- AI Serving → Zookeeper (:2181-2183)
- VPC → Kafka External (:19092-19094)
- VPC → Kafka UI (:8089)
- VPC → Kafka (:22)
- 📝 참고: Zookeeper 내부 클러스터링(:2888-3888)은 컨테이너 내부 통신으로 보안그룹 규칙 불필요

태그:
- Name: aws-prod-kafka-sg
- Environment: prod
- Service: kafka-cluster
```

#### Step 1.3: EC2 인스턴스 생성 (상세 가이드)

```
EC2 → 인스턴스 → "인스턴스 시작"
```

##### 인스턴스 1: Backend Server
```
1. AMI 선택:
   - Amazon Linux 2023 AMI (HVM) - Kernel 5.14, SSD Volume Type
   - 64비트 (x86)

2. 인스턴스 유형:
   - t3.medium (2 vCPU, 4 GiB RAM)

3. 키 페어:
   - 새 키 페어 생성 또는 기존 선택
   - 이름: aws-prod-backend-key

4. 네트워크 설정:
   - VPC: aws-prod-vpc
   - 서브넷: aws-prod-private-subnet
   - 퍼블릭 IP 자동 할당: 비활성화
   - 보안 그룹: aws-prod-backend-sg 선택

5. 스토리지 구성:
   - 20 GiB gp3 (루트 볼륨)
   - 암호화 활성화

6. 태그:
   - Name: aws-prod-backend
   - Environment: prod
   - Service: backend
   - Backup: true
```

##### 인스턴스 2: AI Model Server (GPU)
```
1. AMI 선택:
   - Deep Learning AMI (Ubuntu 20.04) Version XX.X
   - 또는 Amazon Linux 2023 AMI

2. 인스턴스 유형:
   - g4dn.xlarge (4 vCPU, 16 GiB RAM, 1 NVIDIA T4 GPU)

3. 키 페어:
   - aws-prod-ai-model-key (새로 생성 또는 기존 사용)

4. 네트워크 설정:
   - VPC: aws-prod-vpc
   - 서브넷: aws-prod-private-subnet
   - 퍼블릭 IP 자동 할당: 비활성화
   - 보안 그룹: aws-prod-ai-model-sg 선택

5. 스토리지 구성:
   - 50 GiB gp3 (루트 볼륨) - AI 모델용 추가 공간
   - 추가 EBS 볼륨: 100 GiB gp3 (모델 저장용)
   - 암호화 활성화

6. 태그:
   - Name: aws-prod-ai-model
   - Environment: prod
   - Service: ai-model
   - Instance-Type: gpu
```

##### 인스턴스 3: AI Serving Server A (기능 A)
```
1. AMI 선택:
   - Amazon Linux 2023 AMI

2. 인스턴스 유형:
   - t3.medium (2 vCPU, 4 GiB RAM)

3. 키 페어:
   - aws-prod-ai-serving-key

4. 네트워크 설정:
   - VPC: aws-prod-vpc
   - 서브넷: aws-prod-private-subnet
   - 퍼블릭 IP 자동 할당: 비활성화
   - 보안 그룹: aws-prod-ai-serving-sg 선택

5. 스토리지 구성:
   - 20 GiB gp3 (루트 볼륨)
   - 암호화 활성화

6. 태그:
   - Name: aws-prod-ai-serving-a
   - Environment: prod
   - Service: ai-serving
   - Function: feature-a
```

##### 인스턴스 4: AI Serving Server B (기능 B)
```
1. AMI 선택:
   - Amazon Linux 2023 AMI

2. 인스턴스 유형:
   - t3.medium (2 vCPU, 4 GiB RAM)

3. 키 페어:
   - aws-prod-ai-serving-key (동일 키 사용)

4. 네트워크 설정:
   - VPC: aws-prod-vpc
   - 서브넷: aws-prod-private-subnet
   - 퍼블릭 IP 자동 할당: 비활성화
   - 보안 그룹: aws-prod-ai-serving-sg 선택

5. 스토리지 구성:
   - 20 GiB gp3 (루트 볼륨)
   - 암호화 활성화

6. 태그:
   - Name: aws-prod-ai-serving-b
   - Environment: prod
   - Service: ai-serving
   - Function: feature-b
```

##### 인스턴스 5: MySQL Database Server
```
1. AMI 선택:
   - Amazon Linux 2023 AMI

2. 인스턴스 유형:
   - t3.small (2 vCPU, 2 GiB RAM)

3. 키 페어:
   - aws-prod-db-key

4. 네트워크 설정:
   - VPC: aws-prod-vpc
   - 서브넷: aws-prod-database-subnet
   - 퍼블릭 IP 자동 할당: 비활성화
   - 보안 그룹: aws-prod-database-sg 선택

5. 스토리지 구성:
   - 30 GiB gp3 (루트 볼륨)
   - 추가 EBS 볼륨: 50 GiB gp3 (/var/lib/mysql 마운트용)
   - 암호화 활성화

6. 태그:
   - Name: aws-prod-database
   - Environment: prod
   - Service: mysql
   - Backup: true
```

##### 인스턴스 6: PostgreSQL Vector DB Server
```
1. AMI 선택:
   - Amazon Linux 2023 AMI

2. 인스턴스 유형:
   - t3.small (2 vCPU, 2 GiB RAM)

3. 키 페어:
   - aws-prod-vectordb-key

4. 네트워크 설정:
   - VPC: aws-prod-vpc
   - 서브넷: aws-prod-database-subnet
   - 퍼블릭 IP 자동 할당: 비활성화
   - 보안 그룹: aws-prod-vectordb-sg 선택

5. 스토리지 구성:
   - 20 GiB gp3 (루트 볼륨)
   - 추가 EBS 볼륨: 30 GiB gp3 (Vector 데이터용)
   - 암호화 활성화

6. 태그:
   - Name: aws-prod-vectordb
   - Environment: prod
   - Service: postgresql
   - Vector-Extension: pgvector
```

##### 인스턴스 7: MongoDB Server
```
1. AMI 선택:
   - Amazon Linux 2023 AMI

2. 인스턴스 유형:
   - t3.small (2 vCPU, 2 GiB RAM)

3. 키 페어:
   - aws-prod-mongodb-key

4. 네트워크 설정:
   - VPC: aws-prod-vpc
   - 서브넷: aws-prod-database-subnet
   - 퍼블릭 IP 자동 할당: 비활성화
   - 보안 그룹: aws-prod-mongodb-sg 선택

5. 스토리지 구성:
   - 20 GiB gp3 (루트 볼륨)
   - 추가 EBS 볼륨: 30 GiB gp3 (MongoDB 데이터용)
   - 암호화 활성화

6. 태그:
   - Name: aws-prod-mongodb
   - Environment: prod
   - Service: mongodb
   - Database-Type: nosql
```

##### 인스턴스 8: Redis Server
```
1. AMI 선택:
   - Amazon Linux 2023 AMI

2. 인스턴스 유형:
   - t3.micro (1 vCPU, 1 GiB RAM)

3. 키 페어:
   - aws-prod-redis-key

4. 네트워크 설정:
   - VPC: aws-prod-vpc
   - 서브넷: aws-prod-private-subnet
   - 퍼블릭 IP 자동 할당: 비활성화
   - 보안 그룹: aws-prod-redis-sg 선택

5. 스토리지 구성:
   - 10 GiB gp3 (루트 볼륨)
   - 암호화 활성화

6. 태그:
   - Name: aws-prod-redis
   - Environment: prod
   - Service: redis
   - Cache: true
```

##### 인스턴스 6: Redis Server
```
1. AMI 선택:
   - Amazon Linux 2023 AMI

2. 인스턴스 유형:
   - t3.micro (1 vCPU, 1 GiB RAM)

3. 키 페어:
   - aws-prod-redis-key

4. 네트워크 설정:
   - VPC: aws-prod-vpc
   - 서브넷: aws-prod-private-subnet
   - 퍼블릭 IP 자동 할당: 비활성화
   - 보안 그룹: aws-prod-redis-sg 선택

5. 스토리지 구성:
   - 10 GiB gp3 (루트 볼륨)
   - 암호화 활성화

6. 태그:
   - Name: aws-prod-redis
   - Environment: prod
   - Service: redis
   - Cache: true
```

##### 인스턴스 9: Kafka Server
```
1. AMI 선택:
   - Amazon Linux 2023 AMI

2. 인스턴스 유형:
   - t3.medium (2 vCPU, 4 GiB RAM)

3. 키 페어:
   - aws-prod-kafka-key

4. 네트워크 설정:
   - VPC: aws-prod-vpc
   - 서브넷: aws-prod-private-subnet
   - 퍼블릭 IP 자동 할당: 비활성화
   - 보안 그룹: aws-prod-kafka-sg 선택

5. 스토리지 구성:
   - 20 GiB gp3 (루트 볼륨)
   - 추가 EBS 볼륨: 50 GiB gp3 (Kafka 로그용)
   - 암호화 활성화

6. 태그:
   - Name: aws-prod-kafka
   - Environment: prod
   - Service: kafka
   - Message-Queue: true
```

##### EC2 인스턴스 생성 후 확인사항:
```
1. 모든 인스턴스가 "running" 상태인지 확인
2. Private IP가 올바른 서브넷 범위에 할당되었는지 확인
3. 보안 그룹이 올바르게 적용되었는지 확인
4. EBS 볼륨이 암호화되어 있는지 확인
5. 태그가 정확히 설정되었는지 확인
```

#### Step 1.4: Application Load Balancer 설정 (상세 가이드)

```
EC2 → 로드 밸런싱 → 로드 밸런서 → "로드 밸런서 생성"
```

##### ALB 기본 구성
```
1. 로드 밸런서 유형 선택:
   - Application Load Balancer 선택

2. 기본 구성:
   - 이름: aws-prod-alb
   - 체계: Internet-facing
   - IP 주소 유형: IPv4

3. 네트워크 매핑:
   - VPC: aws-prod-vpc
   - 가용 영역 및 서브넷:
     - ap-northeast-2a: aws-prod-public-subnet 선택
   
   주의사항:
   - ALB는 최소 2개 AZ 권장하지만, 단일 AZ로도 운영 가능
   - 향후 고가용성 필요시 ap-northeast-2c에 추가 퍼블릭 서브넷 생성

4. 보안 그룹:
   - aws-prod-alb-sg 선택 (기본 제거)

5. 태그:
   - Name: aws-prod-alb
   - Environment: prod
   - Service: load-balancer
```

##### 타겟 그룹 생성 (Blue-Green 배포용)

**Blue 환경 타겟 그룹:**
```
1. 기본 구성:
   - 타겟 유형: 인스턴스
   - 타겟 그룹 이름: aws-prod-backend-blue-tg
   - 프로토콜: HTTP
   - 포트: 8080
   - VPC: aws-prod-vpc

2. 상태 확인:
   - 상태 확인 경로: /health
   - 고급 상태 확인 설정:
     - 포트: 트래픽 포트
     - 정상 임계값: 2
     - 비정상 임계값: 2
     - 제한 시간: 5초
     - 간격: 30초
     - 성공 코드: 200

3. 태그:
   - Name: aws-prod-backend-blue-tg
   - Environment: prod
   - Deployment: blue
```

**Green 환경 타겟 그룹:**
```
1. 기본 구성:
   - 타겟 유형: 인스턴스
   - 타겟 그룹 이름: aws-prod-backend-green-tg
   - 프로토콜: HTTP
   - 포트: 8080
   - VPC: aws-prod-vpc

2. 상태 확인: (Blue와 동일)
   - 상태 확인 경로: /health
   - 고급 상태 확인 설정: (Blue와 동일)

3. 태그:
   - Name: aws-prod-backend-green-tg
   - Environment: prod
   - Deployment: green
```

**AI 서빙 A 타겟 그룹:**
```
1. 기본 구성:
   - 타겟 유형: 인스턴스
   - 타겟 그룹 이름: aws-prod-ai-serving-a-tg
   - 프로토콜: HTTP
   - 포트: 8100
   - VPC: aws-prod-vpc

2. 상태 확인:
   - 상태 확인 경로: /health
   - 고급 상태 확인 설정:
     - 포트: 트래픽 포트
     - 정상 임계값: 2
     - 비정상 임계값: 2
     - 제한 시간: 5초
     - 간격: 30초
     - 성공 코드: 200

3. 태그:
   - Name: aws-prod-ai-serving-a-tg
   - Environment: prod
   - Service: ai-serving-a
```

**AI 서빙 B 타겟 그룹:**
```
1. 기본 구성:
   - 타겟 유형: 인스턴스
   - 타겟 그룹 이름: aws-prod-ai-serving-b-tg
   - 프로토콜: HTTP
   - 포트: 8101
   - VPC: aws-prod-vpc

2. 상태 확인:
   - 상태 확인 경로: /health
   - 고급 상태 확인 설정:
     - 포트: 트래픽 포트
     - 정상 임계값: 2
     - 비정상 임계값: 2
     - 제한 시간: 5초
     - 간격: 30초
     - 성공 코드: 200

3. 태그:
   - Name: aws-prod-ai-serving-b-tg
   - Environment: prod
   - Service: ai-serving-b
```

##### 리스너 및 규칙 구성
```
1. HTTP 리스너 (포트 80):
   - 프로토콜: HTTP
   - 포트: 80
   - 기본 작업: 리디렉션
     - 리디렉션 대상: HTTPS
     - 포트: 443
     - 상태 코드: 301

2. HTTPS 리스너 (포트 443):
   - 프로토콜: HTTPS
   - 포트: 443
   - SSL 인증서: AWS Certificate Manager (ACM)에서 선택
     - *.test.moongsan.com 인증서 사용
   
   기본 작업:
   - 대상 그룹으로 전달: aws-prod-backend-blue-tg
   
   규칙 추가 (우선순위 순):
   - 규칙 1 (우선순위: 1):
     - IF: 경로가 /ai/serving-a/* 와 일치
     - THEN: aws-prod-ai-serving-a-tg로 전달
   
   - 규칙 2 (우선순위: 2):
     - IF: 경로가 /ai/serving-b/* 와 일치
     - THEN: aws-prod-ai-serving-b-tg로 전달
   
   - 규칙 3 (우선순위: 3):
     - IF: 경로가 /api/* 와 일치
     - THEN: aws-prod-backend-blue-tg로 전달
   
   - 기본 규칙:
     - 모든 기타 요청 → aws-prod-backend-blue-tg로 전달
```

##### SSL 인증서 설정 (ACM)
```
Certificate Manager → "인증서 요청"

1. 인증서 요청:
   - 도메인 이름: *.test.moongsan.com
   - 검증 방법: DNS 검증
   - 키 알고리즘: RSA 2048

2. DNS 검증:
   - Route 53에서 CNAME 레코드 자동 생성
   - 검증 완료까지 대기

3. 태그:
   - Name: test-moongsan-wildcard
   - Environment: prod
```

##### Route 53 DNS 설정
```
Route 53 → 호스팅 영역 → test.moongsan.com

A 레코드 생성:
- 레코드 이름: api
- 레코드 유형: A
- 별칭: 예
- 트래픽 라우팅 대상: 
  - Application Load Balancer 및 Classic Load Balancer에 대한 별칭
  - 리전: 아시아 태평양 (서울) ap-northeast-2
  - 로드 밸런서: aws-prod-alb 선택

라우팅 정책: 단순 라우팅

경로 기반 라우팅 구조:
- api.test.moongsan.com/api/*          → Backend API
- api.test.moongsan.com/ai/serving-a/* → AI Serving A (기능 A)
- api.test.moongsan.com/ai/serving-b/* → AI Serving B (기능 B)
- api.test.moongsan.com/*              → Backend (기본값)
```

##### ALB 설정 완료 후 확인사항:
```
1. ALB 상태가 "active"인지 확인
2. 타겟 그룹에서 헬스체크가 정상인지 확인
3. HTTPS 인증서가 올바르게 연결되었는지 확인
4. DNS 레코드가 ALB를 올바르게 가리키는지 확인
5. HTTP → HTTPS 리디렉션이 작동하는지 확인
```

#### Step 1.5: 비용 최적화 - 서버 스케줄링 설정 (상세 가이드)

```
Lambda → 함수 → "함수 생성"
```

##### Lambda 함수 1: 서버 종료 (00:00 KST)
```
1. 함수 생성:
   - 함수 이름: aws-prod-server-stop-scheduler
   - 런타임: Python 3.11
   - 아키텍처: x86_64

2. 실행 역할:
   - 새 역할 생성: aws-prod-scheduler-role
   - 정책 연결:
     - AWSLambdaBasicExecutionRole
     - EC2FullAccess (또는 사용자 지정 EC2 Stop/Start 정책)

3. 함수 코드:
```python
import boto3
import json

def lambda_handler(event, context):
    ec2 = boto3.client('ec2', region_name='ap-northeast-2')
    
    # Prod 환경 인스턴스 태그로 필터링
    instances = ec2.describe_instances(
        Filters=[
            {'Name': 'tag:Environment', 'Values': ['prod']},
            {'Name': 'instance-state-name', 'Values': ['running']}
        ]
    )
    
    instance_ids = []
    for reservation in instances['Reservations']:
        for instance in reservation['Instances']:
            instance_ids.append(instance['InstanceId'])
    
    if instance_ids:
        ec2.stop_instances(InstanceIds=instance_ids)
        print(f"Stopped instances: {instance_ids}")
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': f'Successfully stopped {len(instance_ids)} instances',
                'instances': instance_ids
            })
        }
    else:
        return {
            'statusCode': 200,
            'body': json.dumps({'message': 'No running instances found'})
        }
```

4. 환경 변수:
   - REGION: ap-northeast-2
   - ENVIRONMENT: prod

5. 제한 시간: 5분
```

##### Lambda 함수 2: 서버 시작 (08:00 KST)
```
1. 함수 생성:
   - 함수 이름: aws-prod-server-start-scheduler
   - 런타임: Python 3.11
   - 실행 역할: aws-prod-scheduler-role (기존 사용)

2. 함수 코드:
```python
import boto3
import json

def lambda_handler(event, context):
    ec2 = boto3.client('ec2', region_name='ap-northeast-2')
    
    # Prod 환경 인스턴스 태그로 필터링
    instances = ec2.describe_instances(
        Filters=[
            {'Name': 'tag:Environment', 'Values': ['prod']},
            {'Name': 'instance-state-name', 'Values': ['stopped']}
        ]
    )
    
    instance_ids = []
    for reservation in instances['Reservations']:
        for instance in reservation['Instances']:
            instance_ids.append(instance['InstanceId'])
    
    if instance_ids:
        ec2.start_instances(InstanceIds=instance_ids)
        print(f"Started instances: {instance_ids}")
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': f'Successfully started {len(instance_ids)} instances',
                'instances': instance_ids
            })
        }
    else:
        return {
            'statusCode': 200,
            'body': json.dumps({'message': 'No stopped instances found'})
        }
```
```

##### EventBridge 스케줄 설정
```
EventBridge → 규칙 → "규칙 생성"
```

**규칙 1: 서버 종료 스케줄 (00:00 KST)**
```
1. 규칙 세부 정보:
   - 이름: aws-prod-server-stop-schedule
   - 설명: Stop prod servers at midnight KST
   - 이벤트 버스: default

2. 패턴 정의:
   - 규칙 유형: 일정
   - 일정 표현식: cron(0 15 * * ? *)  # UTC 15:00 = KST 00:00
   - 유연한 시간 창: 사용 안 함

3. 대상 선택:
   - 대상 유형: AWS 서비스
   - 서비스: Lambda 함수
   - 함수: aws-prod-server-stop-scheduler

4. 태그:
   - Name: aws-prod-server-stop-schedule
   - Environment: prod
   - Type: scheduler
```

**규칙 2: 서버 시작 스케줄 (08:00 KST)**
```
1. 규칙 세부 정보:
   - 이름: aws-prod-server-start-schedule
   - 설명: Start prod servers at 8 AM KST
   - 이벤트 버스: default

2. 패턴 정의:
   - 규칙 유형: 일정
   - 일정 표현식: cron(0 23 * * ? *)  # UTC 23:00 = KST 08:00
   - 유연한 시간 창: 사용 안 함

3. 대상 선택:
   - 대상 유형: AWS 서비스
   - 서비스: Lambda 함수
   - 함수: aws-prod-server-start-scheduler
```

##### IAM 정책 세부 설정 (사용자 지정)
```
IAM → 정책 → "정책 생성"

정책 이름: AWS-Prod-EC2-Scheduler-Policy
정책 문서:
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeInstances",
                "ec2:StartInstances",
                "ec2:StopInstances"
            ],
            "Resource": "*",
            "Condition": {
                "StringEquals": {
                    "ec2:ResourceTag/Environment": "prod"
                }
            }
        },
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": "arn:aws:logs:ap-northeast-2:*:*"
        }
    ]
}
```

##### CloudWatch 모니터링 설정
```
CloudWatch → 알람 → "알람 생성"

1. 지표 선택:
   - 네임스페이스: AWS/Lambda
   - 지표 이름: Errors
   - 함수 이름: aws-prod-server-stop-scheduler

2. 조건:
   - 임계값 유형: 정적
   - 조건: 보다 큼
   - 임계값: 0

3. 알림:
   - SNS 주제: 새로 생성 또는 기존 선택
   - 이메일 알림 설정

4. 알람 이름: aws-prod-scheduler-errors
```

##### 스케줄러 설정 완료 후 확인사항:
```
1. Lambda 함수가 올바르게 생성되었는지 확인
2. IAM 역할에 필요한 권한이 있는지 확인
3. EventBridge 규칙이 활성화되었는지 확인
4. 테스트 실행으로 함수 동작 확인
5. CloudWatch 로그에서 실행 결과 확인
6. 예상 비용 절감 효과: 약 40% (16시간 가동 vs 24시간)
```

### Step 1.6: 운영체제(OS) 선정: Amazon Linux 2023

**최종 결정**: **Amazon Linux 2023**

기존 GCP 환경에서는 Ubuntu를 사용해왔으나, AWS로의 완전한 통합과 장기적인 운영 효율성을 극대화하기 위해 AWS 네이티브 OS인 Amazon Linux 2023을 표준 운영체제로 선정합니다.

#### Amazon Linux 선택의 트레이드오프 분석

| 비교 기준 | **Amazon Linux (채택)** | **Ubuntu (기존 방식)** |
| :--- | :--- | :--- |
| **AWS 통합 및 최적화** | **최상**<br>• AWS 서비스와 완벽 통합<br>• 성능 및 보안 최적화<br>• AWS 도구 기본 내장 | **좋음**<br>• AWS에서 완벽히 지원<br>• 대부분의 경우 성능 차이 미미 |
| **유지보수 및 지원** | **AWS에서 직접 지원**<br>• 신속한 보안 패치<br>• 라이브 패칭 등 최신 기능 | **Canonical에서 장기 지원**<br>• 검증된 업데이트 주기<br>• 풍부한 커뮤니티 |
| **Ansible 호환성** | **수정 필요**<br>• `apt` → `yum`/`dnf` 전환<br>• 사용자, 패키지명 변경 | **매우 높음**<br>• 기존 스크립트 재사용 가능<br>• 마이그레이션 속도 빠름 |

#### 선택 이유
- **장기적 이점**: 초기 Ansible 스크립트 수정 비용을 감수하더라도, 장기적으로 AWS 환경에 최적화된 OS를 사용하는 것이 운영 효율성, 보안, 성능 면에서 더 큰 이점을 가져다줄 것으로 판단됩니다.
- **AWS 네이티브**: AWS의 새로운 기능이나 서비스가 출시될 때 가장 빠르고 안정적으로 지원받을 수 있습니다.
- **기술 부채 감소**: 클라우드 환경에 종속적인 기술 스택을 적극적으로 채택하여, 특정 OS나 버전에 얽매이지 않고 유연성을 확보합니다.

#### 후속 조치: Ansible 스크립트 수정 계획
Amazon Linux 환경에 맞춰 기존 Ansible 역할을 수정하는 작업이 필요합니다.

- **담당**: AI (스크립트 분석 및 수정)
- **주요 수정 대상**:
  - `common`, `base_system` 등 공통 역할
  - `nginx_conf`, `jenkins`, `database` 등 서비스별 역할
- **수정 내용**:
  1. **패키지 매니저 변경**: `apt` 모듈을 `yum` 또는 `dnf` 모듈로 교체
  2. **패키지 이름 확인**: `nginx`, `python3-pip` 등 패키지 이름이 Amazon Linux 저장소에 맞게 되어 있는지 확인 및 수정
  3. **사용자 및 그룹 변경**: `ubuntu` 사용자를 `ec2-user`로 변경
  4. **서비스 관리**: `systemctl` 명령어 및 서비스 이름 확인
  5. **경로 수정**: 설정 파일 및 로그 경로 등 OS에 따라 달라질 수 있는 부분 확인

---

### Phase 2: 애플리케이션 배포 (Ansible 자동화)
**담당**: AI (Ansible 플레이북 개발 및 실행)

#### Step 2.1: Database 및 인프라 서비스 설정
- MySQL 8.0 설치 및 설정
- PostgreSQL 15 + pgvector 설치 및 설정 (벡터 데이터베이스)
- Redis 설치 및 설정 (캐시 서버)
- Kafka 클러스터 설치 및 설정 (메시지 큐)
- 기존 데이터 마이그레이션 (덤프/복원)

#### Step 2.2: Backend API 배포
- Java 17 + Spring Boot 환경 구성
- 애플리케이션 배포
- Health Check 설정

#### Step 2.3: AI Service 배포  
- Python 3.9 + FastAPI 환경 구성
- ML 모델 및 의존성 설치
- API 엔드포인트 테스트

#### Step 2.4: 운영 자동화 설정
- **무중단 배포**: Jenkins 기반 Blue-Green 배포 파이프라인 구축
- **스케줄링**: EC2 인스턴스 자동 시작/종료 설정 (00:00-08:00 오프)
- **모니터링**: CloudWatch 알람 및 대시보드 구성
- **백업**: 자동 스냅샷 및 데이터베이스 백업

### Phase 3: Frontend 및 로드밸런서 구성
**담당**: 사용자 (S3/CloudFront) + AI (ALB 설정)

#### Step 3.1: S3 + CloudFront 설정
- S3 버킷 생성 및 정적 웹사이트 호스팅
- CloudFront 배포 설정
- React 빌드 파일 업로드

#### Step 3.2: Application Load Balancer
- ALB 생성 및 Target Group 설정
- Backend/AI 서비스 등록
- SSL 인증서 적용 (Let's Encrypt)

### Phase 4: 테스트 및 DNS 전환
**담당**: 공동 작업

#### Step 4.1: 통합 테스트
- 각 서비스 개별 테스트
- End-to-End 테스트
- 성능 및 부하 테스트

#### Step 4.2: DNS 점진적 전환
1. **테스트 도메인**: `api.test.moongsan.com`, `ai.test.moongsan.com`
2. **검증 완료 후**: 운영 도메인으로 전환

## 🔄 운영 자동화 및 비용 최적화

### 무중단 배포 (Jenkins 기반 Blue-Green)

#### 구성 방식
```
Jenkins Pipeline (aws-shared-jenkins):
├── Prod 환경 배포 Job
├── Blue-Green 전환 스크립트
└── 롤백 Job

Production (Green):
├── aws-prod-backend-green (현재 서비스)
├── aws-prod-ai-green
└── aws-prod-database (공유)

Staging (Blue):
├── aws-prod-backend-blue (배포 대기)
├── aws-prod-ai-blue  
└── aws-prod-database (공유)

ALB Target Groups:
├── prod-backend-green-tg (100% 트래픽)
└── prod-backend-blue-tg (0% 트래픽)
```

#### Jenkins 배포 파이프라인
```groovy
// Jenkinsfile
pipeline {
    agent any
    stages {
        stage('Deploy to Blue') {
            steps {
                // Ansible 플레이북으로 Blue 환경에 배포
                ansiblePlaybook(
                    playbook: 'deploy_blue.yml',
                    inventory: 'prod-blue.ini'
                )
            }
        }
        stage('Health Check') {
            steps {
                // Blue 환경 Health Check
                sh 'curl -f http://blue-backend-ip:8080/actuator/health'
            }
        }
        stage('Switch Traffic') {
            steps {
                // ALB Target Group 가중치 변경
                sh 'aws elbv2 modify-target-group --target-group-arn $BLUE_TG_ARN --weight 100'
                sh 'aws elbv2 modify-target-group --target-group-arn $GREEN_TG_ARN --weight 0'
            }
        }
        stage('Cleanup Green') {
            steps {
                // 다음 배포를 위해 Green → Blue로 태그 변경
                sh 'ansible-playbook cleanup_old_environment.yml'
            }
        }
    }
}

### 스케줄링 운영 (00:00-08:00 서버 오프)

#### 대상 서버
```
자동 종료 대상:
✅ Backend Server (비즈니스 로직)
✅ AI Server (GPU 비용 절약 중요)
✅ Kafka Server (메시지 큐)
✅ Redis Server (캐시)

24시간 운영:
❌ Database Server (데이터 정합성)
❌ Vector DB Server (AI 학습 데이터)
❌ ALB (로드밸런서)
❌ NAT Gateway (인프라)
```

#### 스케줄링 설정
```bash
# EventBridge 규칙 (서버 종료 - 매일 00:00 KST)
aws events put-rule \
  --name "prod-servers-stop" \
  --schedule-expression "cron(0 15 * * ? *)" \
  --state ENABLED

# EventBridge 규칙 (서버 시작 - 매일 08:00 KST)
aws events put-rule \
  --name "prod-servers-start" \
  --schedule-expression "cron(0 23 * * ? *)" \
  --state ENABLED
```

#### Lambda 함수
```python
# stop_prod_servers.py
import boto3

def lambda_handler(event, context):
    ec2 = boto3.client('ec2')
    
    # 종료할 인스턴스 태그
    instances = ec2.describe_instances(
        Filters=[
            {'Name': 'tag:Environment', 'Values': ['prod']},
            {'Name': 'tag:AutoStop', 'Values': ['true']},
            {'Name': 'instance-state-name', 'Values': ['running']}
        ]
    )
    
    instance_ids = []
    for reservation in instances['Reservations']:
        for instance in reservation['Instances']:
            instance_ids.append(instance['InstanceId'])
    
    if instance_ids:
        ec2.stop_instances(InstanceIds=instance_ids)
        return f"Stopped instances: {instance_ids}"
    
    return "No instances to stop"
```

### 비용 절감 효과

#### 기본 운영 (24시간)
```
월 비용: $320
일 비용: $10.67
시간당: $0.44
```

#### 스케줄링 운영 (16시간/일)
```
종료 대상 서버 비용: $185/월 (Backend + AI + Kafka + Redis)
8시간 종료 절약: $185 × (8/24) = $62/월

최종 월 비용: $320 - $62 = $258/월
절약률: 19.4%
```

### 무중단 배포를 위한 추가 리소스

#### 추가 인스턴스 (배포 시에만)
```
Blue Environment (임시):
- Backend: t3.medium × 1 (~$1/일)
- AI: g4dn.xlarge × 1 (~$5/일)

월 배포 횟수: 4회
월 추가 비용: 4 × $6 = $24/월
```

#### 최종 비용 계산
```
기본 비용: $258/월 (스케줄링 적용)
무중단 배포: $24/월 (월 4회 배포)
총 운영 비용: $282/월

기존 GCP 대비: $420 - $282 = $138/월 절약 (33% 절감)
```

## 🧹 코드 정리 및 최적화

### 제거할 항목들
- [ ] 중복된 nginx 설정 파일들
- [ ] 사용하지 않는 Ansible 변수들
- [ ] 불필요한 GCP Terraform 모듈들

### 통합할 항목들
- [ ] Shared 환경과 Prod 환경 공통 역할들
- [ ] 데이터베이스 설정 표준화
- [ ] 모니터링 및 로깅 통합

## 📅 예상 일정

### 주간별 계획 (현재 우선순위)
- **1주차 (7/17-7/23)**: ✅ **AWS Prod VPC 생성 및 EC2 인스턴스 구성**
- **2주차 (7/24-7/30)**: 애플리케이션 배포 및 데이터 마이그레이션  
- **3주차 (7/31-8/6)**: Frontend 구성 및 통합 테스트
- **4주차 (8/7-8/13)**: DNS 전환 및 운영 안정화

### 장기 로드맵 (후순위)
- **2개월 후**: 개발환경 Spot Instance 전환 + 자동 복구 시스템
- **6개월 후**: Reserved Instance 도입 검토
- **1년 후**: Multi-AZ 고가용성 확장 검토

### 🎯 현재 집중 목표
**AWS Prod 환경 구축 완료** → 안정화 → 비용 최적화 순서

## 💰 예상 비용

### AWS Prod 환경 월 예상 비용 (최적화 적용)

#### 기본 인프라 비용 (AI 서버 분리)
- **EC2 인스턴스 (24시간)**: ~$335 (9대)
  - Backend: t3.medium × 1 (~$30)
  - AI Model: g4dn.xlarge × 1 (~$160) - GPU 포함
  - AI Serving: t3.medium × 2 (~$60) - 로드밸런싱
  - Database: t3.small × 1 (~$15) - MySQL (24시간)
  - Vector DB: t3.small × 1 (~$15) - PostgreSQL (24시간)
  - MongoDB: t3.small × 1 (~$15) - NoSQL (24시간)
  - Redis: t3.micro × 1 (~$10)
  - Kafka: t3.medium × 1 (~$30)
- **NAT Gateway**: ~$45 (1개)
- **S3 + CloudFront**: ~$10
- **ALB**: ~$20
- **Data Transfer**: ~$15

#### 스케줄링 절약 (00:00-08:00 서버 오프)
- **종료 대상**: Backend + AI Model + AI Serving(2대) + Redis + Kafka = $310/월
- **8시간 절약**: $310 × (8/24) = $103/월 절약
- **24시간 운영**: Database + Vector DB + MongoDB = $45/월

#### 무중단 배포 추가 비용
- **Blue Environment**: 월 4회 배포 × $6/회 = $24/월

#### **최종 총 비용**: ~$322/월
```
기본 비용: $380/월 (AI 서버 분리)
스케줄링 절약: -$103/월
무중단 배포 추가: +$24/월
ALB + NAT + 기타: +$21/월
= $322/월
```

### GCP 대비 절감 효과 (최종, AI 서버 분리)
- **현재 GCP 비용**: ~$420/월 (GPU + Vector DB 포함)
- **AWS 최적화 비용**: ~$322/월 (스케줄링 + 무중단배포 + AI 서버 분리)
- **예상 절감액**: ~$98/월 (23% 절감)
- **연간 절약**: ~$1,176

### 추가 비용 최적화 전략

#### 1. Reserved Instance (RI) 활용
```
현재 On-Demand 비용: $185/월 (스케줄링 적용 후)
1년 RI 적용 시: $185 × 0.7 = $130/월
3년 RI 적용 시: $185 × 0.5 = $93/월

추가 절약: $55~92/월
최종 비용: $227~190/월
```

#### 2. Spot Instance 활용 (개발/테스트용)
```
AI 서버 개발용: g4dn.xlarge Spot (~$48/월, 70% 절약)
Backend 개발용: t3.medium Spot (~$9/월, 70% 절약)

적용 시 월 절약: ~$133/월
위험: 언제든 종료 가능 (개발환경에만 권장)
```

#### 3. 스토리지 최적화
```
현재: EBS gp3 (기본 설정)
최적화: 
- OS 볼륨: gp3 최소 크기 (8GB)
- 데이터 볼륨: 사용량 기반 크기 조정
- 스냅샷: 수명주기 정책 적용

예상 절약: $15~20/월
```

#### 4. 네트워크 비용 최적화
```
NAT Gateway 대안:
- NAT Instance (t3.nano): $3.5/월 vs $45/월
- 절약: $41.5/월
- 단점: 관리 복잡성 증가, 성능 제한

VPC Endpoint 활용:
- S3 VPC Endpoint: $0 (무료)
- 데이터 전송비 절약: $5~10/월
```

#### 5. CloudWatch 비용 최적화
```
기본 메트릭: 무료
커스텀 메트릭: 필요한 것만 선별
로그 보존: 30일 → 7일로 단축

예상 절약: $5~10/월
```

### 비용 구성 요소별 분석
```
🔴 24시간 운영 (필수):
- Database + Vector DB: $30/월
- NAT Gateway: $45/월 → NAT Instance로 $3.5/월 
- ALB + S3 + 전송비: $45/월
소계: $78.5/월 (기존 $120 대비 $41.5 절약)

🟡 16시간 운영 (스케줄링):
- Backend: $20/월 → RI 적용시 $14/월
- AI (GPU): $107/월 → RI 적용시 $75/월  
- Redis: $7/월 → RI 적용시 $5/월
- Kafka: $20/월 → RI 적용시 $14/월
소계: $93/월 (기존 $154 대비 $61 절약)

🔵 무중단 배포:
- 월 4회 × $6 = $24/월

최대 절약 시 총합: $78.5 + $93 + $24 = $195.5/월
기존 $282 대비 $86.5/월 추가 절약 가능
```

### 향후 확장 계획
- **고가용성 확장**: 트래픽 증가 시 Multi-AZ 구성
- **성능 최적화**: 모니터링 데이터 기반 인스턴스 타입 조정
- **비용 최적화**: Reserved Instance, Spot Instance 활용
- **무중단 배포**: Jenkins 기반 Blue-Green 배포 파이프라인 고도화
- **스케줄링 운영**: 00:00-08:00 서버 자동 종료로 비용 절약 (~66% 절감)

### Phase 5: 개발환경 Spot Instance 전환 (후순위)

#### 개발환경 Spot Instance 구성
```
개발환경 서버:
├── dev-backend-spot (t3.medium Spot) - 자동 복구
├── dev-ai-spot (g4dn.xlarge Spot) - 자동 복구
├── dev-database (RDS 또는 t3.small) - 24시간 운영
└── dev-redis-spot (t3.micro Spot) - 자동 복구
```

#### 자동 복구 시스템
```python
# Spot Instance 중단 감지 및 자동 복구
# CloudWatch + Lambda 기반 자동 재시작
def spot_recovery_handler(event, context):
    # 1. Spot 중단 알림 감지
    # 2. 같은 설정으로 새 Spot Instance 요청
    # 3. EBS 볼륨 자동 연결
    # 4. 개발팀 Slack 알림
    
    return "Spot instance recovery initiated"
```

#### 예상 절약 효과
```
개발환경 기존 비용: $190/월
Spot 적용 후: $57/월 (70% 절약)
월 절약액: $133/월

전체 운영비: $282 - $133 = $149/월
GCP 대비 절약: $271/월 (65% 절감)
```

#### 구현 우선순위
1. **현재**: Prod 환경 AWS 이전 (1순위)
2. **2개월 후**: 개발환경 Spot Instance 전환
3. **6개월 후**: Reserved Instance 검토

## 🚨 위험 요소 및 대응책

### 주요 위험
1. **데이터 마이그레이션 중 손실**
2. **서비스 다운타임 발생**  
3. **성능 저하 가능성**
4. **DNS 전환 중 접근 불가**

### 대응 방안
1. **데이터 백업**: 마이그레이션 전 완전 백업
2. **Blue-Green 배포**: 무중단 전환
3. **단계적 테스트**: 각 단계별 검증
4. **롤백 계획**: 즉시 원복 가능한 절차

## 🎯 성공 기준

### 기술적 기준
- [ ] 모든 API 엔드포인트 정상 응답
- [ ] Database 연결 및 쿼리 성능 확인  
- [ ] Frontend 로딩 속도 기준치 달성
- [ ] 24시간 무장애 운영 확인

### 운영적 기준  
- [ ] 모니터링 및 알림 시스템 구축
- [ ] 백업 및 복구 절차 문서화
- [ ] 팀원 운영 가이드 교육 완료

---

**작성일**: 2025-07-17  
**작성자**: GitHub Copilot  
**다음 업데이트**: Phase 1 완료 후
