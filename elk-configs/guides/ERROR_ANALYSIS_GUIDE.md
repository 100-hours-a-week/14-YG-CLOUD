# 🚨 에러 분석 및 메트릭 시스템

## 📊 에러 발생 현황 분석 대시보드

### 1. 실시간 에러 모니터링

#### A. 에러 발생 빈도 (Top 에러)
```json
{
  "aggs": {
    "error_types": {
      "terms": {
        "field": "message.keyword",
        "size": 20,
        "include": ".*ERROR.*|.*Exception.*|.*FATAL.*"
      }
    }
  },
  "query": {
    "bool": {
      "must": [
        {
          "range": {
            "@timestamp": {
              "gte": "now-24h"
            }
          }
        },
        {
          "query_string": {
            "query": "(server:backend OR server:ai) AND (message:*ERROR* OR message:*Exception* OR message:*FATAL*)"
          }
        }
      ]
    }
  }
}
```

#### B. 서버별 에러 통계
```json
{
  "aggs": {
    "servers": {
      "terms": {
        "field": "server.keyword"
      },
      "aggs": {
        "error_count": {
          "filter": {
            "query_string": {
              "query": "message:*ERROR* OR message:*Exception*"
            }
          }
        },
        "total_logs": {
          "value_count": {
            "field": "@timestamp"
          }
        },
        "error_rate": {
          "bucket_script": {
            "buckets_path": {
              "errors": "error_count>_count",
              "total": "total_logs"
            },
            "script": "params.errors / params.total * 100"
          }
        }
      }
    }
  }
}
```

### 2. 중요 에러 카테고리별 분석

#### Java/Spring Boot 에러 분류
```javascript
// Kibana Script Field 또는 Logstash Pipeline에서 사용
if (doc['message.keyword'].value.contains('NullPointerException')) {
  return 'NPE'
} else if (doc['message.keyword'].value.contains('SQLException')) {
  return 'DB_ERROR'
} else if (doc['message.keyword'].value.contains('TimeoutException')) {
  return 'TIMEOUT'
} else if (doc['message.keyword'].value.contains('OutOfMemoryError')) {
  return 'MEMORY'
} else if (doc['message.keyword'].value.contains('SecurityException')) {
  return 'SECURITY'
} else {
  return 'OTHER'
}
```

#### Python/AI 서비스 에러 분류
```python
# Logstash Pipeline에서 Python 에러 분류
error_categories = {
    'ValueError': 'DATA_VALIDATION',
    'TypeError': 'TYPE_ERROR', 
    'RuntimeError': 'RUNTIME',
    'MemoryError': 'MEMORY',
    'TimeoutError': 'TIMEOUT',
    'ImportError': 'MODULE',
    'KeyError': 'MISSING_KEY',
    'IndexError': 'INDEX_OUT_OF_BOUNDS'
}
```

### 3. 에러 임계값 및 알람 설정

#### 에러율 기반 알람
```yaml
# Watcher 설정
name: "error_rate_alarm"
trigger:
  schedule:
    interval: "5m"
    
input:
  search:
    request:
      indices: ["moongsan-logs-*"]
      body:
        query:
          bool:
            must:
              - range:
                  "@timestamp":
                    gte: "now-5m"
              - terms:
                  server.keyword: ["backend", "ai"]
        aggs:
          servers:
            terms:
              field: "server.keyword"
            aggs:
              total_logs:
                value_count:
                  field: "@timestamp"
              error_logs:
                filter:
                  query_string:
                    query: "message:*ERROR* OR message:*Exception*"
              error_rate:
                bucket_script:
                  buckets_path:
                    errors: "error_logs>_count"
                    total: "total_logs"
                  script: "params.errors / params.total * 100"

condition:
  script:
    source: |
      // 에러율이 5% 이상이면 알람
      for (bucket in ctx.payload.aggregations.servers.buckets) {
        if (bucket.error_rate.value > 5.0) {
          return true;
        }
      }
      return false;

actions:
  send_slack:
    webhook:
      url: "YOUR_SLACK_WEBHOOK_URL"
      body: |
        {
          "text": "🚨 에러율 알람",
          "attachments": [
            {
              "color": "danger",
              "fields": [
                {
                  "title": "알람 시간",
                  "value": "{{ctx.execution_time}}",
                  "short": true
                },
                {
                  "title": "에러율",
                  "value": "5% 이상",
                  "short": true
                }
              ]
            }
          ]
        }
```

### 4. 에러 급증 탐지

#### 이상 탐지 알람
```yaml
name: "error_spike_detection"
trigger:
  schedule:
    interval: "1m"

input:
  search:
    request:
      indices: ["moongsan-logs-*"]
      body:
        query:
          bool:
            must:
              - range:
                  "@timestamp":
                    gte: "now-10m"
              - query_string:
                  query: "(server:backend OR server:ai) AND (message:*ERROR* OR message:*Exception*)"
        aggs:
          error_timeline:
            date_histogram:
              field: "@timestamp"
              interval: "1m"
              min_doc_count: 0

condition:
  script:
    source: |
      // 최근 1분간 에러가 이전 9분 평균의 3배 이상이면 알람
      def buckets = ctx.payload.aggregations.error_timeline.buckets;
      if (buckets.size() < 10) return false;
      
      def latest = buckets[-1].doc_count;
      def sum = 0;
      for (int i = 0; i < buckets.size() - 1; i++) {
        sum += buckets[i].doc_count;
      }
      def average = sum / (buckets.size() - 1);
      
      return latest > (average * 3) && latest > 10;
```

## 📈 성능 메트릭 수집

### 1. 시스템 메트릭 (Metricbeat 추가)

#### Metricbeat 설정 파일
```yaml
# metricbeat.yml
metricbeat.config.modules:
  path: ${path.config}/modules.d/*.yml
  reload.enabled: true

metricbeat.modules:
# 시스템 메트릭
- module: system
  metricsets:
    - cpu
    - load
    - memory
    - network
    - process
    - process_summary
    - uptime
    - socket_summary
    - diskio
    - filesystem
  enabled: true
  period: 10s
  processes: ['.*']

# Docker 메트릭
- module: docker
  metricsets:
    - container
    - cpu
    - diskio
    - healthcheck
    - info
    - memory
    - network
  enabled: true
  period: 10s
  hosts: ["unix:///var/run/docker.sock"]

# JVM 메트릭 (Backend)
- module: jolokia
  metricsets: ["jmx"]
  enabled: true
  period: 10s
  hosts: ["localhost:8080"]
  namespace: "metrics"
  path: "/actuator/jolokia"

output.logstash:
  hosts: ["10.100.0.4:5044"]

processors:
  - add_host_metadata: ~
  - add_docker_metadata: ~
```

### 2. 애플리케이션 메트릭

#### Spring Boot Actuator 메트릭
```yaml
# application.yml에 추가
management:
  endpoints:
    web:
      exposure:
        include: health,info,metrics,prometheus
  endpoint:
    health:
      show-details: always
    metrics:
      enabled: true
  metrics:
    export:
      elastic:
        enabled: true
        host: http://elk.moongsan.com:9200
        index: moongsan-metrics
        username: elastic
        password: d*nevMQl9v4Cf6UhyAxW  # 2025-07-10 업데이트
```

#### 커스텀 메트릭 수집
```java
@Component
public class CustomMetrics {
    
    private final MeterRegistry meterRegistry;
    private final Counter apiCallCounter;
    private final Timer apiResponseTimer;
    private final Gauge activeUsersGauge;
    
    public CustomMetrics(MeterRegistry meterRegistry) {
        this.meterRegistry = meterRegistry;
        this.apiCallCounter = Counter.builder("api.calls.total")
            .description("Total API calls")
            .register(meterRegistry);
        this.apiResponseTimer = Timer.builder("api.response.time")
            .description("API response time")
            .register(meterRegistry);
    }
    
    public void recordApiCall(String endpoint, String method) {
        apiCallCounter.increment(
            Tags.of("endpoint", endpoint, "method", method)
        );
    }
}
```

### 3. 비즈니스 메트릭

#### 핵심 비즈니스 지표 추적
```java
@Service
public class BusinessMetricsService {
    
    private final MeterRegistry meterRegistry;
    
    // 그룹바잉 관련 메트릭
    public void recordGroupBuyCreated() {
        meterRegistry.counter("business.groupbuy.created").increment();
    }
    
    public void recordGroupBuyCompleted(double amount) {
        meterRegistry.counter("business.groupbuy.completed").increment();
        meterRegistry.gauge("business.groupbuy.amount", amount);
    }
    
    public void recordUserRegistration() {
        meterRegistry.counter("business.user.registered").increment();
    }
    
    // 에러 메트릭
    public void recordBusinessError(String errorType) {
        meterRegistry.counter("business.error.count", 
            Tags.of("type", errorType)).increment();
    }
}
```

## 🎯 통합 메트릭 대시보드

### 1. 시스템 헬스 대시보드

#### CPU, 메모리, 디스크 사용률
```json
{
  "title": "🖥️ 시스템 리소스 모니터링",
  "panels": [
    {
      "title": "CPU 사용률",
      "type": "line",
      "targets": [
        {
          "expr": "system.cpu.user.pct",
          "legendFormat": "{{host.name}} CPU"
        }
      ]
    },
    {
      "title": "메모리 사용률", 
      "type": "line",
      "targets": [
        {
          "expr": "system.memory.used.pct",
          "legendFormat": "{{host.name}} Memory"
        }
      ]
    },
    {
      "title": "디스크 I/O",
      "type": "line", 
      "targets": [
        {
          "expr": "system.diskio.read.bytes",
          "legendFormat": "{{host.name}} Read"
        },
        {
          "expr": "system.diskio.write.bytes", 
          "legendFormat": "{{host.name}} Write"
        }
      ]
    }
  ]
}
```

### 2. 애플리케이션 성능 대시보드

#### JVM 메트릭 (Backend)
```json
{
  "title": "☕ JVM 메트릭",
  "panels": [
    {
      "title": "JVM 힙 메모리",
      "type": "line",
      "targets": [
        {
          "expr": "jvm.memory.used",
          "legendFormat": "Used Memory"
        },
        {
          "expr": "jvm.memory.committed", 
          "legendFormat": "Committed Memory"
        }
      ]
    },
    {
      "title": "GC 횟수",
      "type": "bar",
      "targets": [
        {
          "expr": "jvm.gc.collections",
          "legendFormat": "GC Collections"
        }
      ]
    },
    {
      "title": "스레드 풀",
      "type": "gauge",
      "targets": [
        {
          "expr": "jvm.threads.live",
          "legendFormat": "Active Threads"
        }
      ]
    }
  ]
}
```

### 3. 비즈니스 메트릭 대시보드

#### 핵심 비즈니스 지표
```json
{
  "title": "📊 비즈니스 메트릭",
  "panels": [
    {
      "title": "일일 그룹바잉 생성",
      "type": "stat",
      "targets": [
        {
          "expr": "business.groupbuy.created",
          "legendFormat": "생성된 그룹바잉"
        }
      ]
    },
    {
      "title": "사용자 등록 추이",
      "type": "line",
      "targets": [
        {
          "expr": "business.user.registered",
          "legendFormat": "신규 사용자"
        }
      ]
    },
    {
      "title": "에러 발생 현황",
      "type": "pie",
      "targets": [
        {
          "expr": "business.error.count",
          "legendFormat": "{{type}}"
        }
      ]
    }
  ]
}
```

## 🚀 배포 및 모니터링 자동화

### Metricbeat 배포 스크립트
```bash
#!/bin/bash
# deploy-metrics.sh

echo "📊 메트릭 수집 시스템 배포..."

# 모든 서버에 Metricbeat 설치
for server in "10.1.0.2" "10.1.0.3" "10.1.0.4"; do
    echo "📦 $server에 Metricbeat 설치..."
    ssh -i ~/.ssh/lsh-study-key ubuntu@$server << 'EOF'
        curl -L -O https://artifacts.elastic.co/downloads/beats/metricbeat/metricbeat-8.18.3-amd64.deb
        sudo dpkg -i metricbeat-8.18.3-amd64.deb
EOF
done

# 설정 파일 배포
scp -i ~/.ssh/lsh-study-key metricbeat/metricbeat-backend.yml ubuntu@10.1.0.3:/tmp/
scp -i ~/.ssh/lsh-study-key metricbeat/metricbeat-ai.yml ubuntu@10.1.0.4:/tmp/
scp -i ~/.ssh/lsh-study-key metricbeat/metricbeat-database.yml ubuntu@10.1.0.2:/tmp/

# 설정 적용 및 서비스 시작
for server in "10.1.0.2" "10.1.0.3" "10.1.0.4"; do
    ssh -i ~/.ssh/lsh-study-key ubuntu@$server << 'EOF'
        sudo cp /tmp/metricbeat-*.yml /etc/metricbeat/metricbeat.yml
        sudo systemctl enable metricbeat
        sudo systemctl start metricbeat
EOF
done

echo "✅ 메트릭 수집 시스템 배포 완료!"
```

이제 실시간 에러 분석, 성능 메트릭 수집, 그리고 APM을 통한 코드 레벨 추적이 가능합니다! 🎉
