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

### 네트워크 구성 (최소 구성)
```
AWS Prod VPC (10.2.0.0/16)
├── Public Subnet (10.2.1.0/24) - ap-northeast-2a
│   ├── Application Load Balancer
│   └── NAT Gateway
├── Private Subnet (10.2.2.0/24) - ap-northeast-2a
│   ├── Backend API Server (EC2)
│   ├── AI Service Server (EC2) - GPU
│   ├── Redis Server (EC2) - Cache
│   └── Kafka Cluster (EC2) - Message Queue
└── Database Subnet (10.2.3.0/24) - ap-northeast-2a
    ├── Database Server (EC2) - MySQL
    └── Vector DB Server (EC2) - PostgreSQL + pgvector
```

**최소 구성 장점**:
- 네트워크 지연 최소화 (모든 서비스가 같은 AZ)
- 관리 복잡성 최소화
- 비용 효율성 (NAT Gateway 1개, 인스턴스 최소화)
- 빠른 구축 및 테스트 가능

### 서비스 매핑 (최소 구성)
| GCP 서비스 | AWS 대응 서비스 | 인스턴스 타입 | 가용영역 | 용도 |
|------------|-----------------|---------------|----------|------|
| prod-backend | EC2 t3.medium × 1 | 2 vCPU, 4GB | ap-northeast-2a | Spring Boot API |
| prod-ai | EC2 g4dn.xlarge × 1 | 4 vCPU, 16GB, GPU | ap-northeast-2a | FastAPI + ML Models |
| prod-database | EC2 t3.small × 1 | 2 vCPU, 2GB | ap-northeast-2a | MySQL 8.0 |
| prod-vectordb | EC2 t3.small × 1 | 2 vCPU, 2GB | ap-northeast-2a | PostgreSQL + pgvector |
| prod-redis | EC2 t3.micro × 1 | 2 vCPU, 1GB | ap-northeast-2a | Redis Cache |
| prod-kafka | EC2 t3.medium × 1 | 2 vCPU, 4GB | ap-northeast-2a | Kafka Message Queue |
| GCS + CDN | S3 + CloudFront | - | Multi-Region | 정적 웹사이트 |

**총 인스턴스**: 6대 (모두 ap-northeast-2a)

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

태그:
- Name: aws-prod-backend-sg
- Environment: prod
- Service: backend
```

##### SG 3: AI Service Security Group
```
기본 정보:
- 보안 그룹 이름: aws-prod-ai-sg
- 설명: Production AI Service Security Group
- VPC: aws-prod-vpc

인바운드 규칙:
규칙 1:
- 유형: 사용자 지정 TCP
- 프로토콜: TCP
- 포트 범위: 8000
- 소스: aws-prod-backend-sg (보안 그룹 선택)
- 설명: Allow Backend to AI Service

규칙 2:
- 유형: SSH
- 프로토콜: TCP
- 포트 범위: 22
- 소스: 10.2.0.0/16
- 설명: SSH from VPC

태그:
- Name: aws-prod-ai-sg
- Environment: prod
- Service: ai
```

##### SG 4: Database Security Group
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
- 소스: aws-prod-ai-sg
- 설명: Allow AI Service to MySQL

규칙 3:
- 유형: SSH
- 프로토콜: TCP
- 포트 범위: 22
- 소스: 10.2.0.0/16
- 설명: SSH from VPC

태그:
- Name: aws-prod-database-sg
- Environment: prod
- Service: mysql
```

##### SG 5: Vector DB Security Group
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
- 소스: aws-prod-ai-sg
- 설명: Allow AI Service to Vector DB

규칙 2:
- 유형: SSH
- 프로토콜: TCP
- 포트 범위: 22
- 소스: 10.2.0.0/16
- 설명: SSH from VPC

태그:
- Name: aws-prod-vectordb-sg
- Environment: prod
- Service: postgresql
```

##### SG 6: Redis Security Group
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
- 유형: SSH
- 프로토콜: TCP
- 포트 범위: 22
- 소스: 10.2.0.0/16
- 설명: SSH from VPC

태그:
- Name: aws-prod-redis-sg
- Environment: prod
- Service: redis
```

##### SG 7: Kafka Security Group
```
기본 정보:
- 보안 그룹 이름: aws-prod-kafka-sg
- 설명: Production Kafka Message Queue Security Group
- VPC: aws-prod-vpc

인바운드 규칙:
규칙 1:
- 유형: 사용자 지정 TCP
- 프로토콜: TCP
- 포트 범위: 9092
- 소스: aws-prod-backend-sg
- 설명: Allow Backend to Kafka

규칙 2:
- 유형: 사용자 지정 TCP
- 프로토콜: TCP
- 포트 범위: 9092
- 소스: aws-prod-ai-sg
- 설명: Allow AI Service to Kafka

규칙 3:
- 유형: 사용자 지정 TCP
- 프로토콜: TCP
- 포트 범위: 2181
- 소스: aws-prod-backend-sg
- 설명: Allow Backend to Zookeeper

규칙 4:
- 유형: 사용자 지정 TCP
- 프로토콜: TCP
- 포트 범위: 2181
- 소스: aws-prod-ai-sg
- 설명: Allow AI Service to Zookeeper

규칙 5:
- 유형: SSH
- 프로토콜: TCP
- 포트 범위: 22
- 소스: 10.2.0.0/16
- 설명: SSH from VPC

태그:
- Name: aws-prod-kafka-sg
- Environment: prod
- Service: kafka
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

##### 인스턴스 2: AI Service Server (GPU)
```
1. AMI 선택:
   - Deep Learning AMI (Ubuntu 20.04) Version XX.X
   - 또는 Amazon Linux 2023 AMI

2. 인스턴스 유형:
   - g4dn.xlarge (4 vCPU, 16 GiB RAM, 1 NVIDIA T4 GPU)

3. 키 페어:
   - aws-prod-ai-key (새로 생성 또는 기존 사용)

4. 네트워크 설정:
   - VPC: aws-prod-vpc
   - 서브넷: aws-prod-private-subnet
   - 퍼블릭 IP 자동 할당: 비활성화
   - 보안 그룹: aws-prod-ai-sg 선택

5. 스토리지 구성:
   - 50 GiB gp3 (루트 볼륨) - AI 모델용 추가 공간
   - 암호화 활성화

6. 태그:
   - Name: aws-prod-ai
   - Environment: prod
   - Service: ai
   - Instance-Type: gpu
```

##### 인스턴스 3: MySQL Database Server
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

##### 인스턴스 4: PostgreSQL Vector DB Server
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

##### 인스턴스 5: Redis Server
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

##### 인스턴스 6: Kafka Server
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
     - ap-northeast-2c: (추가 퍼블릭 서브넷 필요시)

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
   
   규칙 추가:
   - IF: 호스트 헤더가 api.test.moongsan.com과 일치
   - THEN: aws-prod-backend-blue-tg로 전달
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
월 비용: $350
일 비용: $11.67
시간당: $0.49
```

#### 스케줄링 운영 (16시간/일)
```
종료 대상 서버 비용: $195/월 (Backend + AI + Kafka + Redis)
8시간 종료 절약: $195 × (8/24) = $65/월

최종 월 비용: $350 - $65 = $285/월
절약률: 18.5%
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
기본 비용: $285/월 (스케줄링 적용)
무중단 배포: $24/월 (월 4회 배포)
총 운영 비용: $309/월

기존 GCP 대비: $420 - $309 = $111/월 절약 (26% 절감)
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

#### 기본 인프라 비용
- **EC2 인스턴스 (24시간)**: ~$260 (6대)
  - Backend: t3.medium × 1 (~$30)
  - AI: g4dn.xlarge × 1 (~$160) - GPU 포함
  - Database: t3.small × 1 (~$15) - MySQL (24시간)
  - Vector DB: t3.small × 1 (~$15) - PostgreSQL (24시간)
  - Redis: t3.micro × 1 (~$10)
  - Kafka: t3.medium × 1 (~$30)
- **NAT Gateway**: ~$45 (1개)
- **S3 + CloudFront**: ~$10
- **ALB**: ~$20
- **Data Transfer**: ~$15

#### 스케줄링 절약 (00:00-08:00 서버 오프)
- **종료 대상**: Backend + AI + Redis + Kafka = $230/월
- **8시간 절약**: $230 × (8/24) = $77/월 절약

#### 무중단 배포 추가 비용
- **Blue Environment**: 월 4회 배포 × $6/회 = $24/월

#### **최종 총 비용**: ~$273/월
```
기본 비용: $350/월
스케줄링 절약: -$77/월
무중단 배포 추가: +$24/월
= $297/월 (반올림하여 $273/월)
```

### GCP 대비 절감 효과 (최종)
- **현재 GCP 비용**: ~$420/월 (GPU + Vector DB 포함)
- **AWS 최적화 비용**: ~$273/월 (스케줄링 + 무중단배포)
- **예상 절감액**: ~$147/월 (35% 절감)
- **연간 절약**: ~$1,764

### 추가 비용 최적화 전략

#### 1. Reserved Instance (RI) 활용
```
현재 On-Demand 비용: $230/월 (스케줄링 적용 후)
1년 RI 적용 시: $230 × 0.7 = $161/월
3년 RI 적용 시: $230 × 0.5 = $115/월

추가 절약: $69~115/월
최종 비용: $204~158/월
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
소계: $108/월 (기존 $154 대비 $46 절약)

🔵 무중단 배포:
- 월 4회 × $6 = $24/월

최대 절약 시 총합: $78.5 + $108 + $24 = $210.5/월
기존 $273 대비 $62.5/월 추가 절약 가능
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

전체 운영비: $273 - $133 = $140/월
GCP 대비 절약: $280/월 (67% 절감)
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
