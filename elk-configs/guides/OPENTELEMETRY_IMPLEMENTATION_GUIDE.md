# 🌐 OpenTelemetry 구축 가이드

## 📋 개요

OpenTelemetry를 사용한 관측성(Observability) 구축:
- 벤더 중립적 계측 프레임워크
- 메트릭, 로그, 트레이스 통합 수집
- 다양한 백엔드 지원 (Elastic, Jaeger, Prometheus 등)

## 🏗️ 아키텍처

```
┌─────────────────┐    ┌─────────────────┐
│   AI Service    │    │ Backend Service │
│  (FastAPI)      │    │  (Spring Boot)  │
│                 │    │                 │
│ OTel SDK        │    │ OTel Agent      │
│ (Python)        │    │ (Java)          │
└─────────┬───────┘    └─────────┬───────┘
          │                      │
          └──────────┬───────────┘
                     │ OTLP/gRPC
          ┌─────────────────┐
          │ OTel Collector  │
          │ (elk.moongsan.  │
          │     com)        │
          └─────────┬───────┘
                    │
     ┌──────────────┼──────────────┐
     │              │              │
┌─────────┐ ┌──────────────┐ ┌─────────┐
│ Elastic │ │ Prometheus   │ │ Jaeger  │
│ Stack   │ │ + Grafana    │ │ Tracing │
└─────────┘ └──────────────┘ └─────────┘
```

## 🚀 구현 계획

### Phase 1: OpenTelemetry Collector 설치
### Phase 2: 애플리케이션 계측 (Python & Java)
### Phase 3: 백엔드 연동 (Elastic + Prometheus + Jaeger)
### Phase 4: 통합 대시보드 구축

## ⚡ 장점

### 🔧 기술적 장점
- **벤더 중립성**: 백엔드 변경 시 계측 코드 재사용
- **표준화**: OpenTelemetry는 CNCF 표준
- **확장성**: 다양한 언어와 프레임워크 지원

### 📊 관측성 향상
- **메트릭**: Prometheus 형식 메트릭 수집
- **트레이스**: Jaeger로 분산 추적
- **로그**: 기존 ELK 스택과 연동

---

## 🛠️ 상세 구현

### 1️⃣ OpenTelemetry Collector 설치

```yaml
# otel-collector-config.yaml
receivers:
  otlp:
    protocols:
      grpc:
        endpoint: 0.0.0.0:4317
      http:
        endpoint: 0.0.0.0:4318

processors:
  batch:
  memory_limiter:
    limit_mib: 400

exporters:
  # Elasticsearch에 트레이스 전송
  elasticsearch:
    endpoints: ["https://localhost:9200"]
    user: elastic
    password: "d*nevMQl9v4Cf6UhyAxW"  # 2025-07-10 업데이트
    tls:
      insecure_skip_verify: true
    index: "otel-traces"
  
  # Prometheus 메트릭 엔드포인트
  prometheus:
    endpoint: "0.0.0.0:8889"
  
  # Jaeger로 트레이스 전송
  jaeger:
    endpoint: "jaeger.moongsan.com:14250"
    tls:
      insecure: true

service:
  pipelines:
    traces:
      receivers: [otlp]
      processors: [memory_limiter, batch]
      exporters: [elasticsearch, jaeger]
    
    metrics:
      receivers: [otlp]
      processors: [memory_limiter, batch]
      exporters: [prometheus]
```

### 2️⃣ AI Service 계측 (Python)

```python
# requirements.txt
opentelemetry-api
opentelemetry-sdk
opentelemetry-auto-instrumentation
opentelemetry-exporter-otlp

# otel_setup.py
from opentelemetry import trace, metrics
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.metrics import MeterProvider
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
from opentelemetry.exporter.otlp.proto.grpc.metric_exporter import OTLPMetricExporter
from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor
from opentelemetry.instrumentation.requests import RequestsInstrumentor

def setup_otel():
    # Trace 설정
    trace.set_tracer_provider(TracerProvider(
        resource=Resource.create({"service.name": "ai-moongsan"})
    ))
    
    otlp_exporter = OTLPSpanExporter(
        endpoint="http://elk.moongsan.com:4317",
        insecure=True
    )
    
    span_processor = BatchSpanProcessor(otlp_exporter)
    trace.get_tracer_provider().add_span_processor(span_processor)
    
    # 자동 계측
    FastAPIInstrumentor.instrument_app(app)
    RequestsInstrumentor().instrument()

# main.py
from otel_setup import setup_otel

setup_otel()
```

### 3️⃣ Backend Service 계측 (Java)

```xml
<!-- pom.xml -->
<dependency>
    <groupId>io.opentelemetry</groupId>
    <artifactId>opentelemetry-api</artifactId>
    <version>1.32.0</version>
</dependency>
<dependency>
    <groupId>io.opentelemetry.instrumentation</groupId>
    <artifactId>opentelemetry-spring-boot-starter</artifactId>
    <version>1.32.0-alpha</version>
</dependency>
```

```yaml
# application.yml
otel:
  service:
    name: be-moongsan
  exporter:
    otlp:
      endpoint: http://elk.moongsan.com:4317
  instrumentation:
    spring-webmvc:
      enabled: true
    jdbc:
      enabled: true
    mongodb:
      enabled: true
```

### 4️⃣ Docker Compose로 전체 스택 구성

```yaml
# docker-compose.otel.yml
version: '3.8'

services:
  otel-collector:
    image: otel/opentelemetry-collector-contrib:latest
    command: ["--config=/etc/otel-collector-config.yaml"]
    volumes:
      - ./otel-collector-config.yaml:/etc/otel-collector-config.yaml
    ports:
      - "4317:4317"   # OTLP gRPC receiver
      - "4318:4318"   # OTLP HTTP receiver
      - "8889:8889"   # Prometheus metrics
    networks:
      - monitoring

  jaeger:
    image: jaegertracing/all-in-one:latest
    ports:
      - "16686:16686"  # Jaeger UI
      - "14250:14250"  # gRPC
    environment:
      - COLLECTOR_OTLP_ENABLED=true
    networks:
      - monitoring

  prometheus:
    image: prom/prometheus:latest
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
    networks:
      - monitoring

  grafana:
    image: grafana/grafana:latest
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
    networks:
      - monitoring

networks:
  monitoring:
    driver: bridge
```

---

## 📊 모니터링 스택 비교

| 기능 | Elastic APM | OpenTelemetry |
|------|-------------|---------------|
| **설치 복잡도** | 🟢 간단 | 🟡 중간 |
| **기존 ELK 통합** | 🟢 완벽 | 🟡 양호 |
| **벤더 중립성** | 🟡 Elastic 종속 | 🟢 완전 중립 |
| **확장성** | 🟡 제한적 | 🟢 매우 높음 |
| **커뮤니티** | 🟡 Elastic 생태계 | 🟢 CNCF 표준 |
| **학습 곡선** | 🟢 낮음 | 🟡 중간 |

---

## 🎯 권장 접근법

### 1️⃣ 단계적 구축 (추천)

1. **Phase 1**: Elastic APM으로 빠른 시작
   - 기존 ELK 인프라 활용
   - 빠른 ROI 달성

2. **Phase 2**: OpenTelemetry 병행 도입
   - 점진적 마이그레이션
   - 두 시스템 병행 운영

3. **Phase 3**: 통합 최적화
   - 필요에 따라 선택적 사용
   - 하이브리드 모니터링

### 2️⃣ 즉시 실행 가능한 옵션

**Elastic APM 우선 구축**을 권장합니다:
- 기존 ELK 스택과 완벽 호환
- 30분 내 기본 APM 구축 가능
- Kibana에서 즉시 모니터링 시작

어떤 방향으로 진행하고 싶으신지 말씀해 주시면, 해당 옵션에 대한 상세한 구현 가이드를 제공해드리겠습니다!
