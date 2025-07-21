# AWS Prod 환경 마이그레이션 계획서

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

---

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
- **장점**: 완전한 고가용성 (Multi-AZ), 단일 장애점 없음, 엔터프라이즈 표준 준수
- **단점**: 높은 비용 (NAT Gateway 2개: $90/월), 복잡한 관리
- **예상 비용**: $420-450/월

##### Option 2: 비용 최적화 3-Tier 아키텍처 (🎯 **권장**)
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
- **장점**: 3-Tier 구조 유지, 적절한 보안 격리, 합리적인 비용, 웹 계층 고가용성
- **단점**: NAT Gateway 단일 장애점, Private/DB 서브넷이 같은 AZ
- **예상 비용**: $280-320/월

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
- **장점**: 최소 비용, 단순한 관리, 빠른 구축
- **단점**: 보안 격리 부족, 3-Tier 표준 미준수, 확장성 제한
- **예상 비용**: $250-280/월

#### 🎯 **최종 권장: Option 2 (비용 최적화 3-Tier)**
- **선택 이유**: 표준 준수, 적절한 보안, 비용 효율성, 확장 가능성, 운영 신뢰성
- **위험 완화 방안**: NAT Gateway 모니터링 강화, NAT Instance 백업 계획, 향후 NAT Gateway 이중화 검토

### 서비스 매핑 및 인스턴스 사양
| GCP 서비스 | AWS 대응 서비스 | 인스턴스 타입 | 가용영역 | 용도 |
| :--- | :--- | :--- | :--- | :--- |
| prod-backend | EC2 t3.medium | 2 vCPU, 4GB | ap-northeast-2a | Spring Boot API |
| prod-ai-model | EC2 g4dn.xlarge | 4 vCPU, 16GB, GPU | ap-northeast-2a | ML Model Server |
| prod-ai-serving-a | EC2 t3.medium | 2 vCPU, 4GB | ap-northeast-2a | FastAPI Serving (A) |
| prod-ai-serving-b | EC2 t3.medium | 2 vCPU, 4GB | ap-northeast-2a | FastAPI Serving (B) |
| prod-database | EC2 t3.small | 2 vCPU, 2GB | ap-northeast-2a | MySQL 8.0 |
| prod-vectordb | EC2 t3.small | 2 vCPU, 2GB | ap-northeast-2a | PostgreSQL + pgvector |
| prod-mongodb | EC2 t3.small | 2 vCPU, 2GB | ap-northeast-2a | MongoDB NoSQL |
| prod-redis | EC2 t3.micro | 2 vCPU, 1GB | ap-northeast-2a | Redis Cache |
| prod-kafka | EC2 t3.medium | 2 vCPU, 4GB | ap-northeast-2a | Kafka Cluster |
| GCS + CDN | S3 + CloudFront | - | Multi-Region | 정적 웹사이트 |

#### Kafka 클러스터 구성 상세
```
단일 EC2 인스턴스에서 Docker Compose로 운영:
- Zookeeper 3대: 포트 2181, 2182, 2183
- Kafka 3대: 포트 19092, 19093, 19094 (External)
- Kafka UI: 포트 8089 (관리용)
- 내부 통신: 포트 9092 (Kafka), 2888-3888 (Zookeeper)
- 복제 팩터: 3 (고가용성 보장)
```

---

## 🚀 마이그레이션 단계별 계획

### Phase 1: AWS 인프라 구성 (수동 + Terraform Export)
**담당**: 사용자 (AWS 콘솔/CLI) + AI (가이드 제공)

#### Step 1.1: VPC 및 네트워크 구성

##### 1-1. VPC 생성
> AWS 콘솔 → VPC → "VPC 생성" 클릭

- **생성할 리소스**: `VPC만`
- **이름 태그**: `aws-prod-vpc`
- **IPv4 CIDR 블록**: `10.2.0.0/16`
- **IPv6 CIDR 블록**: `IPv6 CIDR 블록 없음`
- **테넌시**: `기본값`

**태그:**
| Key | Value |
| :--- | :--- |
| Environment | `prod` |
| Project | `moongsan` |

##### 1-2. 서브넷 생성 (3개)
> VPC → 서브넷 → "서브넷 생성" 클릭

**서브넷 1 - Public:**
- **서브넷 이름**: `aws-prod-public-subnet`
- **VPC**: `aws-prod-vpc`
- **가용 영역**: `ap-northeast-2a`
- **IPv4 CIDR 블록**: `10.2.1.0/24`

**태그:**
| Key | Value |
| :--- | :--- |
| Name | `aws-prod-public-subnet` |
| Type | `public` |
| Environment | `prod` |

**서브넷 2 - Private:**
- **서브넷 이름**: `aws-prod-private-subnet`
- **VPC**: `aws-prod-vpc`
- **가용 영역**: `ap-northeast-2a`
- **IPv4 CIDR 블록**: `10.2.2.0/24`

**태그:**
| Key | Value |
| :--- | :--- |
| Name | `aws-prod-private-subnet` |
| Type | `private` |
| Environment | `prod` |

**서브넷 3 - Database:**
- **서브넷 이름**: `aws-prod-database-subnet`
- **VPC**: `aws-prod-vpc`
- **가용 영역**: `ap-northeast-2a`
- **IPv4 CIDR 블록**: `10.2.3.0/24`

**태그:**
| Key | Value |
| :--- | :--- |
| Name | `aws-prod-database-subnet` |
| Type | `database` |
| Environment | `prod` |

##### 1-3. Internet Gateway 생성 및 연결
> VPC → 인터넷 게이트웨이 → "인터넷 게이트웨이 생성"

- **이름 태그**: `aws-prod-igw`
- **생성 후 작업**: `aws-prod-vpc`에 연결

**태그:**
| Key | Value |
| :--- | :--- |
| Environment | `prod` |
| Project | `moongsan` |

##### 1-4. 탄력적 IP 및 NAT Gateway 생성
**탄력적 IP 할당:**
> EC2 → 네트워크 및 보안 → 탄력적 IP → "탄력적 IP 주소 할당"
- **네트워크 경계 그룹**: `ap-northeast-2`

**태그:**
| Key | Value |
| :--- | :--- |
| Name | `aws-prod-nat-eip` |
| Environment | `prod` |

**NAT Gateway 생성:**
> VPC → NAT 게이트웨이 → "NAT 게이트웨이 생성"
- **이름**: `aws-prod-nat-gateway`
- **서브넷**: `aws-prod-public-subnet`
- **연결 유형**: `퍼블릭`
- **탄력적 IP 할당 ID**: 위에서 생성한 `aws-prod-nat-eip` 선택

**태그:**
| Key | Value |
| :--- | :--- |
| Name | `aws-prod-nat-gateway` |
| Environment | `prod` |

##### 1-5. 라우팅 테이블 구성 (3개)
> VPC → 라우팅 테이블 → "라우팅 테이블 생성"

**라우팅 테이블 1 - Public:**
- **이름**: `aws-prod-public-rt`
- **VPC**: `aws-prod-vpc`
- **라우팅 규칙**: `0.0.0.0/0` → `aws-prod-igw`

**태그:**
| Key | Value |
| :--- | :--- |
| Name | `aws-prod-public-rt` |
| Type | `public` |
| Environment | `prod` |
- **서브넷 연결**: `aws-prod-public-subnet`

**라우팅 테이블 2 - Private:**
- **이름**: `aws-prod-private-rt`
- **VPC**: `aws-prod-vpc`
- **라우팅 규칙**: `0.0.0.0/0` → `aws-prod-nat-gateway`

**태그:**
| Key | Value |
| :--- | :--- |
| Name | `aws-prod-private-rt` |
| Type | `private` |
| Environment | `prod` |

- **서브넷 연결**: `aws-prod-private-subnet`

**라우팅 테이블 3 - Database:**
- **이름**: `aws-prod-database-rt`
- **VPC**: `aws-prod-vpc`
- **라우팅 규칙**: `0.0.0.0/0` → `aws-prod-nat-gateway`

**태그:**
| Key | Value |
| :--- | :--- |
| Name | `aws-prod-database-rt` |
| Type | `database` |
| Environment | `prod` |

- **서브넷 연결**: `aws-prod-database-subnet`

##### 1-6. 서브넷 자동 IP 할당 설정
- **Public 서브넷 (`aws-prod-public-subnet`)**: 퍼블릭 IPv4 주소 자동 할당 **활성화**
- **Private/Database 서브넷**: 퍼블릭 IPv4 주소 자동 할당 **비활성화** (기본값)

```md
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
```

---
#### Step 1.2: 보안 그룹 설정 (상세 가이드)
> EC2 → 네트워크 및 보안 → 보안 그룹 → "보안 그룹 생성"

##### SG 1: ALB Security Group
- **보안 그룹 이름**: `aws-prod-alb-sg`
- **설명**: `Production ALB Security Group`
- **VPC**: `aws-prod-vpc`

**인바운드 규칙:**
| 유형 | 프로토콜 | 포트 범위 | 소스 | 설명 |
| :--- | :--- | :--- | :--- | :--- |
| HTTP | TCP | 80 | `0.0.0.0/0` | Allow HTTP from internet |
| HTTPS | TCP | 443 | `0.0.0.0/0` | Allow HTTPS from internet |

**태그:**
| Key | Value |
| :--- | :--- |
| Name | `aws-prod-alb-sg` |
| Environment | `prod` |
| Service | `alb` |

##### SG 2: Backend Security Group
- **보안 그룹 이름**: `aws-prod-backend-sg`
- **설명**: `Production Backend API Security Group`
- **VPC**: `aws-prod-vpc`

**인바운드 규칙:**
| 유형 | 프로토콜 | 포트 범위 | 소스 | 설명 |
| :--- | :--- | :--- | :--- | :--- |
| 사용자 지정 TCP | TCP | 8080 | `aws-prod-alb-sg` | Allow ALB to Backend API |
| SSH | TCP | 22 | `10.2.0.0/16` | SSH from VPC |

**태그:**
| Key | Value |
| :--- | :--- |
| Name | `aws-prod-backend-sg` |
| Environment | `prod` |
| Service | `backend` |

##### SG 3: AI Model Server Security Group
- **보안 그룹 이름**: `aws-prod-ai-model-sg`
- **설명**: `Production AI Model Server Security Group (GPU)`
- **VPC**: `aws-prod-vpc`

**인바운드 규칙:**
| 유형 | 프로토콜 | 포트 범위 | 소스 | 설명 |
| :--- | :--- | :--- | :--- | :--- |
| 사용자 지정 TCP | TCP | 8000 | `aws-prod-ai-serving-sg` | Allow AI Serving to Model Server |
| SSH | TCP | 22 | `10.2.0.0/16` | SSH from VPC |

**태그:**
| Key | Value |
| :--- | :--- |
| Name | `aws-prod-ai-model-sg` |
| Environment | `prod` |
| Service | `ai-model` |

##### SG 4: AI Serving Security Group
- **보안 그룹 이름**: `aws-prod-ai-serving-sg`
- **설명**: `Production AI Serving API Security Group`
- **VPC**: `aws-prod-vpc`

**인바운드 규칙:**
| 유형 | 프로토콜 | 포트 범위 | 소스 | 설명 |
| :--- | :--- | :--- | :--- | :--- |
| 사용자 지정 TCP | TCP | 8100 | `aws-prod-backend-sg` | Allow Backend to AI Serving A |
| 사용자 지정 TCP | TCP | 8101 | `aws-prod-backend-sg` | Allow Backend to AI Serving B |
| 사용자 지정 TCP | TCP | 8100 | `aws-prod-alb-sg` | Allow ALB to AI Serving A (직접 접근) |
| 사용자 지정 TCP | TCP | 8101 | `aws-prod-alb-sg` | Allow ALB to AI Serving B (직접 접근) |
| SSH | TCP | 22 | `10.2.0.0/16` | SSH from VPC |

**태그:**
| Key | Value |
| :--- | :--- |
| Name | `aws-prod-ai-serving-sg` |
| Environment | `prod` |
| Service | `ai-serving` |

##### SG 5: Database Security Group
- **보안 그룹 이름**: `aws-prod-database-sg`
- **설명**: `Production MySQL Database Security Group`
- **VPC**: `aws-prod-vpc`

**인바운드 규칙:**
| 유형 | 프로토콜 | 포트 범위 | 소스 | 설명 |
| :--- | :--- | :--- | :--- | :--- |
| MySQL/Aurora | TCP | 3306 | `aws-prod-backend-sg` | Allow Backend to MySQL |
| MySQL/Aurora | TCP | 3306 | `aws-prod-ai-serving-sg` | Allow AI Serving to MySQL |
| SSH | TCP | 22 | `10.2.0.0/16` | SSH from VPC |

**태그:**
| Key | Value |
| :--- | :--- |
| Name | `aws-prod-database-sg` |
| Environment | `prod` |
| Service | `mysql` |

##### SG 6: Vector DB Security Group
- **보안 그룹 이름**: `aws-prod-vectordb-sg`
- **설명**: `Production PostgreSQL Vector DB Security Group`
- **VPC**: `aws-prod-vpc`

**인바운드 규칙:**
| 유형 | 프로토콜 | 포트 범위 | 소스 | 설명 |
| :--- | :--- | :--- | :--- | :--- |
| PostgreSQL | TCP | 5432 | `aws-prod-ai-serving-sg` | Allow AI Serving to Vector DB |
| SSH | TCP | 22 | `10.2.0.0/16` | SSH from VPC |

**태그:**
| Key | Value |
| :--- | :--- |
| Name | `aws-prod-vectordb-sg` |
| Environment | `prod` |
| Service | `postgresql` |

##### SG 7: MongoDB Security Group
- **보안 그룹 이름**: `aws-prod-mongodb-sg`
- **설명**: `Production MongoDB NoSQL Database Security Group`
- **VPC**: `aws-prod-vpc`

**인바운드 규칙:**
| 유형 | 프로토콜 | 포트 범위 | 소스 | 설명 |
| :--- | :--- | :--- | :--- | :--- |
| 사용자 지정 TCP | TCP | 27017 | `aws-prod-backend-sg` | Allow Backend to MongoDB |
| 사용자 지정 TCP | TCP | 27017 | `aws-prod-ai-serving-sg` | Allow AI Serving to MongoDB |
| SSH | TCP | 22 | `10.2.0.0/16` | SSH from VPC |

**태그:**
| Key | Value |
| :--- | :--- |
| Name | `aws-prod-mongodb-sg` |
| Environment | `prod` |
| Service | `mongodb` |

##### SG 8: Redis Security Group
- **보안 그룹 이름**: `aws-prod-redis-sg`
- **설명**: `Production Redis Cache Security Group`
- **VPC**: `aws-prod-vpc`

**인바운드 규칙:**
| 유형 | 프로토콜 | 포트 범위 | 소스 | 설명 |
| :--- | :--- | :--- | :--- | :--- |
| 사용자 지정 TCP | TCP | 6379 | `aws-prod-backend-sg` | Allow Backend to Redis |
| 사용자 지정 TCP | TCP | 6379 | `aws-prod-ai-serving-sg` | Allow AI Serving to Redis |
| SSH | TCP | 22 | `10.2.0.0/16` | SSH from VPC |

**태그:**
| Key | Value |
| :--- | :--- |
| Name | `aws-prod-redis-sg` |
| Environment | `prod` |
| Service | `redis` |

##### SG 9: Kafka Security Group
- **보안 그룹 이름**: `aws-prod-kafka-sg`
- **설명**: `Production Kafka Cluster Security Group`
- **VPC**: `aws-prod-vpc`

**인바운드 규칙:**
| 유형 | 프로토콜 | 포트 범위 | 소스 | 설명 |
| :--- | :--- | :--- | :--- | :--- |
| 사용자 지정 TCP | TCP | 9092 | `aws-prod-backend-sg` | Allow Backend to Kafka |
| 사용자 지정 TCP | TCP | 9092 | `aws-prod-ai-serving-sg` | Allow AI Serving to Kafka |
| 사용자 지정 TCP | TCP | 19092-19094 | `10.2.0.0/16` | Allow VPC to Kafka External |
| 사용자 지정 TCP | TCP | 8089 | `10.2.0.0/16` | Allow VPC to Kafka UI |
| SSH | TCP | 22 | `10.2.0.0/16` | SSH from VPC |

**태그:**
| Key | Value |
| :--- | :--- |
| Name | `aws-prod-kafka-sg` |
| Environment | `prod` |
| Service | `kafka-cluster` |

---
#### Step 1.3: EC2 인스턴스 생성
> EC2 → 인스턴스 → "인스턴스 시작"

##### 인스턴스 1: Backend Server
- **AMI**: `Amazon Linux 2023 AMI (HVM) - Kernel 5.14, SSD Volume Type`, `64bit(x86)`
- **인스턴스 유형**: `t3.medium` (2 vCPU, 4 GiB RAM)
- **키 페어**: `aws-prod-backend-key`
- **네트워크**: VPC(`aws-prod-vpc`), 서브넷(`aws-prod-private-subnet`), 보안 그룹(`aws-prod-backend-sg`), 퍼블릭 IP 자동 할당(`비활성화`)
- **스토리지**: 20 GiB gp3 (루트 볼륨, 암호화 활성화)

**태그:**
| Key | Value |
| :--- | :--- |
| Name | `aws-prod-backend` |
| Environment | `prod` |
| Service | `backend` |
| Backup | `true` |

##### 인스턴스 2: AI Model Server (GPU)
- **AMI**: `Deep Learning AMI (Ubuntu 20.04)` 또는 `Amazon Linux 2023`
- **인스턴스 유형**: `g4dn.xlarge` (4 vCPU, 16 GiB RAM, 1 NVIDIA T4 GPU)
- **키 페어**: `aws-prod-ai-model-key`
- **네트워크**: VPC(`aws-prod-vpc`), 서브넷(`aws-prod-private-subnet`), 보안 그룹(`aws-prod-ai-model-sg`), 퍼블릭 IP 자동 할당(`비활성화`)
- **스토리지**: 50 GiB gp3 (루트), 100 GiB gp3 (추가 볼륨), 암호화 활성화

**태그:**
| Key | Value |
| :--- | :--- |
| Name | `aws-prod-ai-model` |
| Environment | `prod` |
| Service | `ai-model` |
| Instance-Type | `gpu` |

##### 인스턴스 3: AI Serving Server A
- **AMI**: `Amazon Linux 2023 AMI`
- **인스턴스 유형**: `t3.medium` (2 vCPU, 4 GiB RAM)
- **키 페어**: `aws-prod-ai-serving-key`
- **네트워크**: VPC(`aws-prod-vpc`), 서브넷(`aws-prod-private-subnet`), 보안 그룹(`aws-prod-ai-serving-sg`), 퍼블릭 IP 자동 할당(`비활성화`)
- **스토리지**: 20 GiB gp3 (루트 볼륨, 암호화 활성화)

**태그:**
| Key | Value |
| :--- | :--- |
| Name | `aws-prod-ai-serving-a` |
| Environment | `prod` |
| Service | `ai-serving` |
| Function | `feature-a` |

##### 인스턴스 4: AI Serving Server B
- **AMI**: `Amazon Linux 2023 AMI`
- **인스턴스 유형**: `t3.medium`
- **키 페어**: `aws-prod-ai-serving-key`
- **네트워크**: VPC(`aws-prod-vpc`), 서브넷(`aws-prod-private-subnet`), 보안 그룹(`aws-prod-ai-serving-sg`)
- **스토리지**: 20 GiB gp3 (루트 볼륨, 암호화 활성화)

**태그:**
| Key | Value |
| :--- | :--- |
| Name | `aws-prod-ai-serving-b` |
| Environment | `prod` |
| Service | `ai-serving` |
| Function | `feature-b` |

##### 인스턴스 5: MySQL Database Server
- **AMI**: `Amazon Linux 2023 AMI`
- **인스턴스 유형**: `t3.small` (2 vCPU, 2 GiB RAM)
- **키 페어**: `aws-prod-db-key`
- **네트워크**: VPC(`aws-prod-vpc`), 서브넷(`aws-prod-database-subnet`), 보안 그룹(`aws-prod-database-sg`), 퍼블릭 IP 자동 할당(`비활성화`)
- **스토리지**: 30 GiB gp3 (루트), 50 GiB gp3 (데이터 볼륨), 암호화 활성화

**태그:**
| Key | Value |
| :--- | :--- |
| Name | `aws-prod-database` |
| Environment | `prod` |
| Service | `mysql` |
| Backup | `true` |

##### 인스턴스 6: PostgreSQL Vector DB Server
- **AMI**: `Amazon Linux 2023 AMI`
- **인스턴스 유형**: `t3.small` (2 vCPU, 2 GiB RAM)
- **키 페어**: `aws-prod-vectordb-key`
- **네트워크**: VPC(`aws-prod-vpc`), 서브넷(`aws-prod-database-subnet`), 보안 그룹(`aws-prod-vectordb-sg`), 퍼블릭 IP 자동 할당(`비활성화`)
- **스토리지**: 20 GiB gp3 (루트), 30 GiB gp3 (데이터 볼륨), 암호화 활성화

**태그:**
| Key | Value |
| :--- | :--- |
| Name | `aws-prod-vectordb` |
| Environment | `prod` |
| Service | `postgresql` |
| Vector-Extension | `pgvector` |

##### 인스턴스 7: MongoDB Server
- **AMI**: `Amazon Linux 2023 AMI`
- **인스턴스 유형**: `t3.small` (2 vCPU, 2 GiB RAM)
- **키 페어**: `aws-prod-mongodb-key`
- **네트워크**: VPC(`aws-prod-vpc`), 서브넷(`aws-prod-database-subnet`), 보안 그룹(`aws-prod-mongodb-sg`), 퍼블릭 IP 자동 할당(`비활성화`)
- **스토리지**: 20 GiB gp3 (루트), 30 GiB gp3 (데이터 볼륨), 암호화 활성화

**태그:**
| Key | Value |
| :--- | :--- |
| Name | `aws-prod-mongodb` |
| Environment | `prod` |
| Service | `mongodb` |
| Database-Type | `nosql` |

##### 인스턴스 8: Redis Server
- **AMI**: `Amazon Linux 2023 AMI`
- **인스턴스 유형**: `t3.micro` (2 vCPU, 1 GiB RAM)
- **키 페어**: `aws-prod-redis-key`
- **네트워크**: VPC(`aws-prod-vpc`), 서브넷(`aws-prod-private-subnet`), 보안 그룹(`aws-prod-redis-sg`), 퍼블릭 IP 자동 할당(`비활성화`)
- **스토리지**: 10 GiB gp3 (루트 볼륨, 암호화 활성화)

**태그:**
| Key | Value |
| :--- | :--- |
| Name | `aws-prod-redis` |
| Environment | `prod` |
| Service | `redis` |
| Cache | `true` |

##### 인스턴스 9: Kafka Server
- **AMI**: `Amazon Linux 2023 AMI`
- **인스턴스 유형**: `t3.medium` (2 vCPU, 4 GiB RAM)
- **키 페어**: `aws-prod-kafka-key`
- **네트워크**: VPC(`aws-prod-vpc`), 서브넷(`aws-prod-private-subnet`), 보안 그룹(`aws-prod-kafka-sg`), 퍼블릭 IP 자동 할당(`비활성화`)
- **스토리지**: 20 GiB gp3 (루트), 50 GiB gp3 (데이터 볼륨), 암호화 활성화

**태그:**
| Key | Value |
| :--- | :--- |
| Name | `aws-prod-kafka` |
| Environment | `prod` |
| Service | `kafka` |
| Message-Queue | `true` |

##### EC2 인스턴스 생성 후 확인사항:
> 1. 모든 인스턴스가 "running" 상태인지 확인
> 2. Private IP가 올바른 서브넷 범위에 할당되었는지 확인
> 3. 보안 그룹이 올바르게 적용되었는지 확인
> 4. EBS 볼륨이 암호화되어 있는지 확인
> 5. 태그가 정확히 설정되었는지 확인

---

#### Step 1.4: Application Load Balancer 설정
> EC2 → 로드 밸런싱 → 로드 밸런서 → "로드 밸런서 생성"

##### ALB 기본 구성
- **이름**: `aws-prod-alb`
- **체계**: `Internet-facing`
- **네트워크**: VPC(`aws-prod-vpc`), 서브넷(`ap-northeast-2a: aws-prod-public-subnet`)

   주의사항:
   - ALB는 최소 2개 AZ 권장하지만, 단일 AZ로도 운영 가능
   - 향후 고가용성 필요시 ap-northeast-2c에 추가 퍼블릭 서브넷 생성

- **보안 그룹**: `aws-prod-alb-sg`

- **태그:**

   | Key | Value |
   | :--- | :--- |
   | Name | `aws-prod-alb` |
   | Environment | `prod` |
   | Service | `load-balancer` |

##### 타겟 그룹 생성
| 이름 | 타겟 타입 | 프로토콜:포트 | VPC | 상태 확인 경로 | 태그 |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `aws-prod-backend-blue-tg` | Instance | HTTP:8080 | `aws-prod-vpc` | `/health` | Name: `aws-prod-backend-blue-tg`, Environment: `prod`, Deployment: `blue` |
| `aws-prod-backend-green-tg`| Instance | HTTP:8080 | `aws-prod-vpc` | `/health` | Name: `aws-prod-backend-green-tg`, Environment: `prod`, Deployment: `green` |
| `aws-prod-ai-serving-a-tg`| Instance | HTTP:8100 | `aws-prod-vpc` | `/health` | Name: `aws-prod-ai-serving-a-tg`, Environment: `prod`, Service: `ai-serving-a` |
| `aws-prod-ai-serving-b-tg`| Instance | HTTP:8101 | `aws-prod-vpc` | `/health` | Name: `aws-prod-ai-serving-b-tg`, Environment: `prod`, Service: `ai-serving-b` |

##### 리스너 및 규칙 구성
- **HTTP (80)**: `HTTPS (443)`으로 리디렉션
- **HTTPS (443)**:
  - **SSL 인증서**: `*.test.moongsan.com` (ACM)
  - **규칙**:

      | 우선순위 | 경로 | 전달 대상 |
      | :--- | :--- | :--- |
      | 1 | `/ai/serving-a/*` | `aws-prod-ai-serving-a-tg` |
      | 2 | `/ai/serving-b/*` | `aws-prod-ai-serving-b-tg` |
      | 3 | `/api/*` | `aws-prod-backend-blue-tg` |
      | 기본값 | - | `aws-prod-backend-blue-tg` |

---

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
#### Step 1.5: 비용 최적화 - 서버 스케줄링 설정
> Lambda → 함수 → "함수 생성"

##### Lambda 함수 1: 서버 종료 (00:00 KST)
- **함수 이름**: `aws-prod-server-stop-scheduler`
- **런타임**: `Python 3.11`
- **아키텍처**: `x86_64`
- **실행 역할**: `aws-prod-scheduler-role` (새 역할 생성), 정책 연결: `AWSLambdaBasicExecutionRole` or `EC2FullAccess`
- **제한 시간**: 5분
- **환경 변수**:
  - `REGION`: `ap-northeast-2`
  - `ENVIRONMENT`: `prod`

**함수 코드:**
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

##### Lambda 함수 2: 서버 시작 (08:00 KST)
- **함수 이름**: `aws-prod-server-start-scheduler`
- **런타임**: `Python 3.11`
- **실행 역할**: `aws-prod-scheduler-role` (기존 역할 사용)

**함수 코드:**
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

##### EventBridge 스케줄 설정
> EventBridge → 규칙 → "규칙 생성"

**규칙 1: 서버 종료 스케줄 (00:00 KST)**
- **이름**: `aws-prod-server-stop-schedule`
- **설명**: Stop prod servers at midnight KST
- **이벤트 버스**: `default`
- **규칙 유형**: `일정`
- **일정 표현식**: `cron(0 15 * * ? *)`  # UTC 15:00 = KST 00:00
- **유연한 시간 창**: `사용 안 함`
- **대상**: Lambda 함수 `aws-prod-server-stop-scheduler`

- **태그:**
| Key | Value |
| :--- | :--- |
| Name | `aws-prod-server-stop-schedule` |
| Environment | `prod` |
| Service | `scheduler` |
| Type | `stop` |

**규칙 2: 서버 시작 스케줄 (08:00 KST)**
- **이름**: `aws-prod-server-start-schedule`
- **설명**: Start prod servers at 8 AM KST
- **이벤트 버스**: `default`
- **규칙 유형**: `일정`
- **일정 표현식**: `cron(0 23 * * ? *)`  # UTC 23:00 = KST 08:00
- **유연한 시간 창**: `사용 안 함`
- **대상**: Lambda 함수 `aws-prod-server-start-scheduler`

- **태그:**
| Key | Value |
| :--- | :--- |
| Name | `aws-prod-server-start-schedule` |
| Environment | `prod` |
| Service | `scheduler` |
| Type | `start` |

##### IAM 정책 세부 설정 (사용자 지정)
> IAM → 정책 → "정책 생성"

- **정책 이름**: `AWS-Prod-EC2-Scheduler-Policy`
- **정책 문서**:
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

> 1. Lambda 함수가 올바르게 생성되었는지 확인
> 2. IAM 역할에 필요한 권한이 있는지 확인
> 3. EventBridge 규칙이 활성화되었는지 확인
> 4. 테스트 실행으로 함수 동작 확인
> 5. CloudWatch 로그에서 실행 결과 확인
> 6. 예상 비용 절감 효과: 약 40% (16시간 가동 vs 24시간)

```md
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
```
---

### Phase 2: 애플리케이션 배포 (Ansible 자동화)
**담당**: AI (Ansible 플레이북 개발 및 실행)

#### Step 2.1: Database 및 인프라 서비스 설정
- MySQL 8.0, PostgreSQL 15 + pgvector, Redis, Kafka 클러스터 설치 및 설정
- 기존 데이터 마이그레이션 (덤프/복원)

#### Step 2.2: Backend API 배포
- Java 17 + Spring Boot 환경 구성 및 배포, Health Check 설정

#### Step 2.3: AI Service 배포  
- Python 3.9 + FastAPI 환경 구성, ML 모델 및 의존성 설치, API 엔드포인트 테스트

#### Step 2.4: 운영 자동화 설정
- **무중단 배포**: Jenkins 기반 Blue-Green 배포 파이프라인 구축
- **스케줄링**: EC2 인스턴스 자동 시작/종료 설정 (00:00-08:00 오프)
- **모니터링**: CloudWatch 알람 및 대시보드 구성
- **백업**: 자동 스냅샷 및 데이터베이스 백업

### Phase 3: Frontend 및 로드밸런서 구성
**담당**: 사용자 (S3/CloudFront) + AI (ALB 설정)

#### Step 3.1: S3 + CloudFront 설정
- S3 버킷 생성 및 정적 웹사이트 호스팅, CloudFront 배포 설정, React 빌드 파일 업로드

#### Step 3.2: Application Load Balancer
- ALB 생성 및 Target Group 설정, Backend/AI 서비스 등록, SSL 인증서 적용

### Phase 4: 테스트 및 DNS 전환
**담당**: 공동 작업

#### Step 4.1: 통합 테스트
- 각 서비스 개별 테스트, End-to-End 테스트, 성능 및 부하 테스트

#### Step 4.2: DNS 점진적 전환
1. **테스트 도메인**: `test.moongsan.com`
2. **검증 완료 후**: 운영 도메인으로 전환

## 운영 자동화 및 비용 최적화

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
                ansiblePlaybook(playbook: 'deploy_blue.yml', inventory: 'prod-blue.ini')
            }
        }
        stage('Health Check') {
            steps {
                sh 'curl -f http://blue-backend-ip:8080/actuator/health'
            }
        }
        stage('Switch Traffic') {
            steps {
                sh 'aws elbv2 modify-target-group --target-group-arn $BLUE_TG_ARN --weight 100'
                sh 'aws elbv2 modify-target-group --target-group-arn $GREEN_TG_ARN --weight 0'
            }
        }
        stage('Cleanup Green') {
            steps {
                sh 'ansible-playbook cleanup_old_environment.yml'
            }
        }
    }
}
```

### 스케줄링 운영 (00:00-08:00 서버 오프)

#### 대상 서버
- **자동 종료 대상**: ✅ Backend, AI, Kafka, Redis 서버
- **24시간 운영**: ❌ Database, Vector DB, ALB, NAT Gateway

#### 스케줄링 설정
```bash
# 서버 종료 (매일 00:00 KST)
aws events put-rule --name "prod-servers-stop" --schedule-expression "cron(0 15 * * ? *)"
# 서버 시작 (매일 08:00 KST)
aws events put-rule --name "prod-servers-start" --schedule-expression "cron(0 23 * * ? *)"
```

### 비용 절감 효과

#### 최종 비용 계산
- **기본 비용**: $258/월 (스케줄링 적용)
- **무중단 배포**: $24/월 (월 4회 배포)
- **총 운영 비용**: $282/월
- **기존 GCP 대비**: $138/월 절약 (33% 절감)

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

- **1주차 (7/17-7/23)**: ✅ AWS Prod VPC 생성 및 EC2 인스턴스 구성
- **2주차 (7/24-7/30)**: 애플리케이션 배포 및 데이터 마이그레이션  
- **3주차 (7/31-8/6)**: Frontend 구성 및 통합 테스트
- **4주차 (8/7-8/13)**: DNS 전환 및 운영 안정화

### 장기 로드맵 (후순위)
- **1️⃣**: 개발환경 Spot Instance 전환 + 자동 복구 시스템
- **2️⃣**: Reserved Instance 도입 검토
- **3️⃣**: Multi-AZ 고가용성 확장 검토

### 🎯 현재 집중 목표
**AWS Prod 환경 구축 완료** → 안정화 → 비용 최적화 순서

## 💰 예상 비용

### AWS Prod 환경 월 예상 비용 (최적화 적용)
- **최종 총 비용**: ~$322/월
- **GCP 대비 절감 효과**: ~$98/월 (23% 절감)

### 추가 비용 최적화 전략
- **Reserved Instance (RI) 활용**: 추가 $55~92/월 절약
- **Spot Instance 활용 (개발/테스트용)**: 월 $133/월 절약
- **스토리지 및 네트워크 최적화**: 월 $60~80/월 절약

## 🚨 위험 요소 및 대응책
- **위험**: 데이터 손실, 다운타임, 성능 저하, DNS 전환 문제
- **대응**: 데이터 백업, Blue-Green 배포, 단계적 테스트, 롤백 계획

## 🎯 성공 기준
- **기술적**: API 정상 응답, DB 성능, Frontend 로딩 속도
- **운영적**: 모니터링/알림, 백업/복구 절차, 팀원 교육

---

**작성일**: 2025-07-17  
**작성자**: GitHub Copilot  
**다음 업데이트**: Phase 1 완료 후