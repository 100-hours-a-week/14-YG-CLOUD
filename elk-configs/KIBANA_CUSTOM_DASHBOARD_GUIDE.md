# 🎨 Kibana APM 커스텀 대시보드 구축 가이드

## 📊 대시보드 구성 요소

### 1. 서비스 성능 개요 대시보드
```json
{
  "title": "APM Service Performance Overview",
  "description": "AI/Backend 서비스 성능 종합 모니터링",
  "widgets": [
    {
      "type": "apm_service_map",
      "title": "서비스 의존성 맵",
      "query": {
        "service.name": ["ai-moongsan", "backend-moongsan"]
      }
    },
    {
      "type": "apm_transactions",
      "title": "트랜잭션 처리량",
      "metrics": ["transaction.duration.histogram", "transaction.marks"]
    },
    {
      "type": "apm_errors", 
      "title": "에러율 추이",
      "metrics": ["error.count", "error.rate"]
    }
  ]
}
```

### 2. AI 서비스 전용 대시보드
```json
{
  "title": "AI Service (FastAPI) Performance",
  "filters": {
    "service.name": "ai-moongsan",
    "service.environment": "production"
  },
  "visualizations": [
    {
      "title": "API 엔드포인트별 응답시간",
      "type": "histogram",
      "field": "transaction.duration.us",
      "group_by": "url.path"
    },
    {
      "title": "Python 메모리 사용량",
      "type": "line_chart", 
      "field": "system.memory.usage"
    },
    {
      "title": "FastAPI 요청 상태 분포",
      "type": "pie_chart",
      "field": "http.response.status_code"
    }
  ]
}
```

### 3. Backend 서비스 전용 대시보드  
```json
{
  "title": "Backend Service (Spring Boot) Performance",
  "filters": {
    "service.name": "backend-moongsan",
    "service.environment": "production"
  },
  "visualizations": [
    {
      "title": "Spring Boot 트랜잭션 추이",
      "type": "area_chart",
      "field": "transaction.duration.us",
      "group_by": "transaction.name"
    },
    {
      "title": "JVM 힙 메모리 사용률",
      "type": "gauge",
      "field": "jvm.memory.heap.used"
    },
    {
      "title": "Database 연결 풀 상태",
      "type": "line_chart",
      "field": "database.connection.pool.active"
    }
  ]
}
```

## 🎯 핵심 성능 지표 (KPI)

### Application Performance Index (API)
```
API Score = (
  Throughput(30%) + 
  Response_Time(25%) + 
  Error_Rate(20%) + 
  Availability(25%)
) * 100
```

### 서비스별 SLA 목표
- **AI Service**:
  - 평균 응답시간: < 500ms
  - 95th percentile: < 1000ms
  - 에러율: < 1%
  - 가용성: > 99.5%

- **Backend Service**:
  - 평균 응답시간: < 200ms
  - 95th percentile: < 500ms
  - 에러율: < 0.5%
  - 가용성: > 99.9%

## 🚨 알림 설정

### 1. 성능 저하 알림
```json
{
  "alert_name": "High Response Time Alert",
  "conditions": {
    "metric": "transaction.duration.us",
    "operator": "gt",
    "threshold": 1000000,
    "timeframe": "5m"
  },
  "actions": [
    {
      "type": "email",
      "recipients": ["devops@moongsan.com"]
    },
    {
      "type": "slack",
      "webhook": "#alerts"
    }
  ]
}
```

### 2. 에러율 급증 알림
```json
{
  "alert_name": "Error Rate Spike Alert", 
  "conditions": {
    "metric": "error.rate",
    "operator": "gt", 
    "threshold": 5,
    "timeframe": "3m"
  },
  "severity": "critical"
}
```

### 3. 서비스 다운 알림
```json
{
  "alert_name": "Service Availability Alert",
  "conditions": {
    "metric": "service.uptime",
    "operator": "lt",
    "threshold": 0.99,
    "timeframe": "1m"
  },
  "severity": "emergency"
}
```

## 📈 분산 추적 분석

### Trace Context Propagation 검증
```bash
# 1. AI Service에서 Backend Service 호출 시뮬레이션
curl -H "traceparent: 00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01" \
     -X POST http://10.1.0.4:8100/generation/description

# 2. Backend Service에서 Database 호출 추적
curl -H "X-Trace-Id: test-distributed-trace-$(date +%s)" \
     -X GET http://10.1.0.3:8080/api/products
```

### 트랜잭션 흐름 분석 쿼리
```elasticsearch
GET /apm-*/_search
{
  "query": {
    "bool": {
      "must": [
        {"term": {"processor.event": "transaction"}},
        {"range": {"@timestamp": {"gte": "now-1h"}}}
      ]
    }
  },
  "aggs": {
    "services": {
      "terms": {"field": "service.name"},
      "aggs": {
        "avg_duration": {"avg": {"field": "transaction.duration.us"}},
        "error_rate": {
          "filter": {"term": {"transaction.result": "error"}},
          "bucket_script": {
            "buckets_path": {"total": "_count", "errors": "error_count.doc_count"}
          }
        }
      }
    }
  }
}
```

## 🔍 성능 최적화 체크리스트

### AI Service (FastAPI) 최적화
- [ ] **비동기 처리 개선**: `async/await` 패턴 적용
- [ ] **캐싱 전략**: Redis 기반 응답 캐싱
- [ ] **리소스 풀링**: HTTP 연결 풀 최적화
- [ ] **코드 프로파일링**: 병목 함수 식별

### Backend Service (Spring Boot) 최적화  
- [ ] **JVM 튜닝**: 힙 메모리 및 GC 설정 최적화
- [ ] **Database 연결**: Connection Pool 크기 조정
- [ ] **쿼리 최적화**: N+1 문제 해결, 인덱스 활용
- [ ] **캐싱 레이어**: Redis/EhCache 적용

### Infrastructure 최적화
- [ ] **로드 밸런싱**: 트래픽 분산 최적화
- [ ] **오토 스케일링**: CPU/메모리 기반 자동 확장
- [ ] **CDN 활용**: 정적 자원 캐싱
- [ ] **네트워크 최적화**: 레이턴시 감소

---

**Updated**: 2025-07-10 01:42  
**Next Review**: Phase 4 진입 시
