# 🔍 Elastic APM 구축 가이드

## 📋 개요

기존 ELK 스택에 APM(Application Performance Monitoring)을 추가하여:
- 애플리케이션 성능 메트릭 수집
- 분산 추적(Distributed Tracing) 구현
- 에러 및 예외 실시간 모니터링
- 트랜잭션 성능 분석

## 🏗️ 아키텍처

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   AI Service    │    │ Backend Service │    │   Database      │
│  (FastAPI)      │    │  (Spring Boot)  │    │   (MongoDB)     │
│                 │    │                 │    │                 │
│ APM Agent       │    │ APM Agent       │    │                 │
│ (Python)        │    │ (Java)          │    │                 │
└─────────┬───────┘    └─────────┬───────┘    └─────────────────┘
          │                      │
          └──────────┬───────────┘
                     │ HTTP/gRPC
          ┌─────────────────┐
          │   APM Server    │
          │ (elk.moongsan.  │
          │     com)        │
          └─────────┬───────┘
                    │
          ┌─────────────────┐
          │ Elasticsearch   │
          │   + Kibana      │
          │   APM UI        │
          └─────────────────┘
```

## 🚀 구현 계획

### Phase 1: APM Server 설치 (ELK 서버)
### Phase 2: AI Service APM Agent 설정 (FastAPI/Python)
### Phase 3: Backend Service APM Agent 설정 (Spring Boot/Java)
### Phase 4: APM 대시보드 및 알림 설정

## ⚡ 기대 효과

### 🔍 모니터링 개선
- **트랜잭션 추적**: API 요청의 전체 생명주기 추적
- **성능 병목 식별**: 느린 쿼리, API 호출 지점 파악
- **에러 집계**: 실시간 에러 발생 현황 및 스택 트레이스

### 📊 비즈니스 인사이트
- **사용자 경험**: 응답 시간, 처리량 메트릭
- **서비스 의존성**: 마이크로서비스 간 호출 관계 시각화
- **리소스 사용량**: CPU, 메모리, DB 연결 풀 상태

### 🚨 알림 및 자동화
- **임계값 기반 알림**: 응답 시간, 에러율 임계값 초과시 알림
- **이상 탐지**: ML 기반 이상 패턴 감지
- **자동 스케일링**: 메트릭 기반 오토스케일링 트리거

---

## 🛠️ 상세 구현 단계

### 1️⃣ APM Server 설치
```bash
# ELK 서버에 APM Server 설치
wget https://artifacts.elastic.co/downloads/apm-server/apm-server-8.18.3-linux-x86_64.tar.gz
tar -xzf apm-server-8.18.3-linux-x86_64.tar.gz
sudo mv apm-server-8.18.3-linux-x86_64 /opt/apm-server
```

### 2️⃣ AI Service 계측 (Python/FastAPI)
```python
# requirements.txt 추가
elastic-apm[flask]

# app.py 수정
from elasticapm.contrib.starlette import make_apm_client, ElasticAPM

apm_client = make_apm_client({
    'SERVICE_NAME': 'ai-moongsan',
    'SECRET_TOKEN': 'your-secret-token',
    'SERVER_URL': 'http://elk.moongsan.com:8200',
    'ENVIRONMENT': 'production'
})

app.add_middleware(ElasticAPM, client=apm_client)
```

### 3️⃣ Backend Service 계측 (Java/Spring Boot)
```xml
<!-- pom.xml 의존성 추가 -->
<dependency>
    <groupId>co.elastic.apm</groupId>
    <artifactId>apm-agent-api</artifactId>
    <version>1.36.0</version>
</dependency>
```

```yaml
# application.yml
elastic:
  apm:
    service-name: be-moongsan
    server-url: http://elk.moongsan.com:8200
    secret-token: your-secret-token
    environment: production
```

### 4️⃣ 대시보드 설정
- Kibana APM 앱에서 서비스 메트릭 확인
- 커스텀 대시보드 생성
- 알림 정책 설정

---

## 📈 모니터링 메트릭

### 🎯 핵심 지표
- **처리량 (Throughput)**: requests/minute
- **응답 시간 (Response Time)**: 평균, 95th percentile
- **에러율 (Error Rate)**: 4xx, 5xx 응답 비율
- **Apdex 점수**: 사용자 만족도 지표

### 🔧 기술 지표
- **JVM 메트릭**: Heap, GC, Thread 상태
- **Python 메트릭**: 메모리 사용량, GIL 상태
- **데이터베이스**: 연결 풀, 쿼리 실행 시간
- **외부 API**: 서드파티 서비스 호출 성능

---

## 🚨 알림 정책

### Critical (즉시 대응)
- 에러율 > 5%
- 평균 응답 시간 > 2초
- 서비스 다운

### Warning (모니터링 필요)
- 에러율 > 1%
- 95th percentile 응답 시간 > 5초
- CPU/메모리 사용률 > 80%

### Info (트렌드 분석)
- 일일 트래픽 변화
- 성능 개선/악화 추세
- 새로운 에러 패턴

---

## 🎨 대시보드 구성

### 1. 서비스 개요 대시보드
- 전체 서비스 상태 한눈에 보기
- 트래픽, 에러율, 응답 시간 요약

### 2. 서비스별 상세 대시보드
- AI 서비스 전용 메트릭
- Backend 서비스 전용 메트릭
- 서비스 간 의존성 맵

### 3. 인프라 모니터링 대시보드
- 서버 리소스 사용량
- 컨테이너 상태
- 네트워크 메트릭

### 4. 비즈니스 메트릭 대시보드
- 사용자 행동 패턴
- 기능별 사용 통계
- 수익 관련 지표
