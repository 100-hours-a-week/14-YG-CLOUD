# Ansible 배포 아키텍처 가이드

## 📋 목차
1. [개요](#개요)
2. [서버별 Role 매핑](#서버별-role-매핑)
3. [Docker 네트워크 구조](#docker-네트워크-구조)
4. [3-Tier 아키텍처 설명](#3-tier-아키텍처-설명)
5. [배포 순서 및 의존성](#배포-순서-및-의존성)
6. [네트워크 통신 흐름](#네트워크-통신-흐름)

## 개요

이 문서는 3-tier 클라우드 인프라에서 각 서버별로 실행되는 Ansible Role들과 Docker 네트워크 구조를 설명합니다.

### 인프라 구성
- **Database 서버**: `test-database (10.0.0.2)`
- **Backend 서버**: `test-backend (10.0.0.3)`  
- **AI 서버**: `test-ai (10.0.0.4)`

## 서버별 Role 매핑

### 🗄️ Database 서버 (test-database - 10.0.0.2)

| 순서 | Role 명 | 설명 | 포트 | 태그 | 실행 조건 |
|------|---------|------|------|------|-----------|
| 1 | `base_system` | 기본 시스템 설정 (패키지, 사용자) | - | `base, always` | 항상 실행 |
| 2 | `common` | 공통 설정 (Docker, 네트워크) | - | `base, network, always` | 항상 실행 |
| 3 | `database` | MySQL 컨테이너 배포 | 3306 | `database` | `'database' in group_names` |
| 4 | `db_backup` | 데이터베이스 백업 시스템 | - | `backup, database` | `'database' in group_names` |

**주요 컨테이너:**
- `mysql-moongsan`: MySQL 8.0 데이터베이스
- 백업 스크립트 및 cron 작업

### 🔧 Backend 서버 (test-backend - 10.0.0.3)

| 순서 | Role 명 | 설명 | 포트 | 태그 | 실행 조건 |
|------|---------|------|------|------|-----------|
| 1 | `base_system` | 기본 시스템 설정 | - | `base, always` | 항상 실행 |
| 2 | `common` | 공통 설정 (Docker, 네트워크) | - | `base, network, always` | 항상 실행 |
| 3 | `redis` | Redis 캐시 컨테이너 배포 | 6379 | `backend, cache` | `'backend' in group_names` |
| 4 | `be_deploy` | Spring Boot API 컨테이너 배포 | 8080 | `backend` | `'backend' in group_names` |

**주요 컨테이너:**
- `redis-moongsan`: Redis 7.2 캐시 서버
- `be-moongsan`: Spring Boot API 서버

### 🤖 AI 서버 (test-ai - 10.0.0.4)

| 순서 | Role 명 | 설명 | 포트 | 태그 | 실행 조건 |
|------|---------|------|------|------|-----------|
| 1 | `base_system` | 기본 시스템 설정 | - | `base, always` | 항상 실행 |
| 2 | `common` | 공통 설정 (Docker, 네트워크) | - | `base, network, always` | 항상 실행 |
| 3 | `ai_deploy` | FastAPI AI 컨테이너 배포 | 8100 | `ai` | `'ai' in group_names` |

**주요 컨테이너:**
- `ai-moongsan`: FastAPI AI 서비스

## Docker 네트워크 구조

### moongsan-net (Backend 서버 전용)
- **사용 위치**: Backend 서버에서만 생성 및 사용
- **목적**: Redis와 Spring Boot 애플리케이션 간의 내부 통신
- **구성 요소**:
  - Redis 컨테이너 (`redis:latest`)
  - Spring Boot 애플리케이션 컨테이너

### AI 서버 네트워크
- **네트워크**: Docker 기본 네트워크 (bridge) 사용
- **특징**: 
  - `moongsan-net`을 사용하지 않음
  - 포트 매핑을 통한 외부 통신
  - Backend 서버와 독립적인 네트워크 구성

### 네트워크 생성
Backend 서버에서만 `moongsan-net`이라는 사용자 정의 브리지 네트워크가 생성됩니다:

```yaml
# docker_net role에서 실행 (Backend 서버만)
- name: Ensure Docker network moongsan-net exists
  community.docker.docker_network:
    name: moongsan-net
    state: present
```

### 컨테이너 네트워크 설정
- **Backend 서버**: Redis와 Spring Boot 컨테이너가 `moongsan-net` 네트워크 사용
- **AI 서버**: FastAPI 컨테이너가 기본 Docker bridge 네트워크 사용

```yaml
# Backend 서버 컨테이너
networks:
  - name: moongsan-net

# AI 서버 컨테이너  
# networks 설정 없음 (기본 bridge 네트워크 사용)
```

## 3-Tier 아키텍처 설명

```
┌─────────────────────────────────────────────────────────────────┐
│                        🌐 인터넷                                 │
└─────────────────────┬───────────────────────────────────────────┘
                      │
              ┌───────▼───────┐
              │   CDN/LB      │
              │34.8.174.93    │ ← Frontend (GCS + CDN)
              └───────┬───────┘
                      │
        ┌─────────────┼─────────────┐
        │    Private Network        │
        │    (10.0.0.0/24)         │
        │                          │
   ┌────▼────┐  ┌────▼────┐  ┌────▼────┐
   │Backend  │  │   AI    │  │Database │
   │10.0.0.3 │  │10.0.0.4 │  │10.0.0.2 │
   └────┬────┘  └────┬────┘  └────┬────┘
        │            │            │
   ┌────▼────┐  ┌────▼────┐       │
   │moongsan-│  │default  │       │
   │net      │  │bridge   │       │
   │         │  │         │       │
   │ Redis   │  │FastAPI  │  ┌────▼────┐
   │:6379    │  │   AI    │  │ MySQL   │
   │         │  │:8100    │  │:3306    │
   │ Spring  │  │         │  │         │
   │ Boot    │  │         │  │ Backup  │
   │:8080    │  │         │  │ System  │
   └─────────┘  └─────────┘  └─────────┘
```

### Tier별 역할

#### 🗄️ Data Tier (Database 서버)
- **역할**: 데이터 저장, 지속성, 백업
- **구성요소**:
  - MySQL 8.0: 주 데이터베이스
  - 자동 백업 시스템
- **포트**: 3306 (MySQL)

#### 🔧 Application Tier (Backend 서버)  
- **역할**: 비즈니스 로직, API 제공, 캐싱
- **구성요소**:
  - Spring Boot API 서버
  - Redis 캐시 서버
- **포트**: 8080 (API), 6379 (Redis)

#### 🤖 AI Tier (AI 서버)
- **역할**: 머신러닝 모델 서빙, AI 추론
- **구성요소**:
  - FastAPI AI 서비스
  - ML 모델 서빙
- **포트**: 8100 (AI API)

## 배포 순서 및 의존성

### 배포 단계
1. **기본 시스템 설정** (`base_system`)
2. **공통 설정** (`common` + `docker_net`)
3. **데이터베이스 배포** (`database`)
4. **Redis 캐시 배포** (`redis`)
5. **백엔드 API 배포** (`be_deploy`)
6. **AI 서비스 배포** (`ai_deploy`)
7. **백업 시스템 설정** (`db_backup`)

### Role 의존성
```yaml
# be_deploy 의존성 (현재 임시 비활성화)
dependencies:
  - role: clone_cloud    # 소스 코드 복제
  - role: docker_net     # Docker 네트워크 생성
  - role: redis          # Redis 캐시 서버
```

## 네트워크 통신 흐름

### 내부 통신 (Private Network)
```yaml
# Backend → Database
spring.datasource.url: jdbc:mysql://10.0.0.2:3306/moongsan_test_db

# Backend → Redis (로컬)
spring.redis.host: localhost  # Backend 서버 내부
spring.redis.port: 6379

# Backend → AI
ai.service.url: http://10.0.0.4:8100/predict

# AI → Database (필요시)
database.url: mysql://10.0.0.2:3306/moongsan_test_db
```

### Docker 네트워크 이점
1. **Backend 내부 통신**: `moongsan-net`을 통한 Redis-Spring Boot 간 격리된 통신
2. **서비스 디스커버리**: Backend 내에서 컨테이너 이름으로 DNS 해석 
3. **네트워크 분리**: Backend의 내부 통신과 외부 통신 분리
4. **AI 서버 독립성**: AI 서버는 기본 네트워크로 단순하게 운영
5. **포트 관리**: 각 서버별 최적화된 포트 매핑

### 보안 특징
1. **Private 네트워크**: 모든 내부 통신은 10.0.0.0/24 대역
2. **VPN 접근**: WireGuard VPN을 통한 관리자 접근
3. **방화벽**: 각 서버별 필요 포트만 개방
4. **네트워크 분리**: Docker 네트워크를 통한 격리

## 운영 가이드

### 서비스 상태 확인
```bash
# Backend 서버에서 moongsan-net 컨테이너 확인
docker ps --filter network=moongsan-net

# Backend 서버 네트워크 정보 확인  
docker network inspect moongsan-net

# AI 서버에서 기본 네트워크 컨테이너 확인
docker ps --format "table {{.Names}}\t{{.Ports}}\t{{.Status}}"

# 서비스별 로그 확인
docker logs mysql-moongsan        # Database 서버
docker logs redis-moongsan       # Backend 서버  
docker logs be-moongsan          # Backend 서버
docker logs ai-moongsan          # AI 서버
```

### 태그별 배포
```bash
# 전체 배포
ansible-playbook -i inventories/test.ini playbooks/main.yml -e "env=test"

# Backend만 배포
ansible-playbook -i inventories/test.ini playbooks/main.yml -e "env=test" --tags backend

# AI 서비스만 배포  
ansible-playbook -i inventories/test.ini playbooks/main.yml -e "env=test" --tags ai

# 데이터베이스만 배포
ansible-playbook -i inventories/test.ini playbooks/main.yml -e "env=test" --tags database
```

---
*최종 업데이트: 2024년 6월 8일*

## 변수 관리 및 설정

### 주요 변수 설정 파일
- **위치**: `ansible/group_vars/test/all.yml`
- **목적**: 환경별 설정값 중앙 관리

### 핵심 변수 구조

#### 1. 내부 네트워크 IP 매핑
```yaml
internal_ips:
  jumpbox: "10.0.0.5"
  backend: "10.0.0.2"
  ai: "10.0.0.4"
  database: "10.0.0.2"  # Backend와 동일 서버
```

#### 2. Docker 네트워크 설정
```yaml
docker:
  network_name: "moongsan-net"
  network_driver: bridge
  network_subnet: "172.20.0.0/16"
```

#### 3. 서비스별 설정
```yaml
# Database 설정
db:
  url: "jdbc:mysql://{{ internal_ips.database }}:{{ db.port }}/{{ db.name }}"
  host: "{{ internal_ips.database }}"
  port: 3306
  user: "moongsan_admin"
  name: "moongsan_test_db"

# Redis 설정  
redis:
  image: "redis:7.2-alpine"
  container_name: "redis-moongsan"
  port: 6379
  password: "redis_secure_password_123!"

# Backend 설정
be:
  port: 8080
  ai_service_base_url: "http://{{ internal_ips.ai }}:{{ ai.port }}"
  redis:
    host: "{{ redis.container_name }}"
    port: "{{ redis.port }}"

# AI 설정
ai:
  port: 8100
```

### 변수 사용의 이점
1. **중앙 집중식 관리**: 모든 설정값이 한 곳에서 관리
2. **환경별 분리**: dev/test/prod 환경별 다른 값 설정 가능
3. **유지보수성**: IP 변경 시 한 곳만 수정하면 전체 반영
4. **재사용성**: 동일한 변수를 여러 Role에서 참조 가능
5. **오타 방지**: 하드코딩 대신 변수 참조로 일관성 보장

### 하드코딩 제거 완료 목록
- ✅ **IP 주소**: `10.0.0.x` → `{{ internal_ips.* }}`
- ✅ **포트 번호**: `8080`, `8100`, `3306` → `{{ *.port }}`
- ✅ **Docker 네트워크**: `moongsan-net` → `{{ docker.network_name }}`
- ✅ **컨테이너명**: `redis-moongsan` → `{{ redis.container_name }}`
- ✅ **데이터베이스 설정**: 사용자명, 비밀번호, DB명 변수화
- ✅ **AI 서비스 URL**: Backend에서 AI 서비스 호출 URL 변수화
