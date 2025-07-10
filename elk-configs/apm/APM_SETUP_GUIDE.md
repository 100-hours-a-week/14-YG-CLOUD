# 📊 APM (Application Performance Monitoring) 연동 가이드

## 🎯 APM 서버 설정

### 1. APM Server 설치 및 설정

#### ELK 서버에 APM Server 설치
```bash
# ELK 서버에서 실행
sudo apt-get update
sudo apt-get install apm-server

# APM Server 설정
sudo nano /etc/apm-server/apm-server.yml
```

#### APM Server 설정 파일 (`apm-server.yml`)
```yaml
apm-server:
  # APM Server 호스트 설정
  host: "0.0.0.0:8200"
  
  # 최대 요청 크기
  max_request_size: 1048576
  
  # 읽기 타임아웃
  read_timeout: 30s
  
  # 쓰기 타임아웃  
  write_timeout: 30s
  
  # 최대 이벤트 크기
  max_event_size: 307200

# Elasticsearch 출력 설정
output.elasticsearch:
  hosts: ["https://localhost:9200"]
  username: "elastic"
  password: "d*nevMQl9v4Cf6UhyAxW"  # 2025-07-10 업데이트
  ssl.verification_mode: none
  
  # APM 인덱스 설정
  indices:
    - index: "apm-%{[observer.version]}-sourcemap"
      when.contains:
        processor.event: "sourcemap"
    - index: "apm-%{[observer.version]}-error-%{+yyyy.MM.dd}"
      when.contains:
        processor.event: "error"
    - index: "apm-%{[observer.version]}-transaction-%{+yyyy.MM.dd}"
      when.contains:
        processor.event: "transaction"
    - index: "apm-%{[observer.version]}-span-%{+yyyy.MM.dd}"
      when.contains:
        processor.event: "span"
    - index: "apm-%{[observer.version]}-metric-%{+yyyy.MM.dd}"
      when.contains:
        processor.event: "metric"
    - index: "apm-%{[observer.version]}-onboarding-%{+yyyy.MM.dd}"
      when.contains:
        processor.event: "onboarding"

# Kibana 설정
setup.kibana:
  host: "localhost:5601"

# 로깅 설정
logging.level: info
logging.to_files: true
logging.files:
  path: /var/log/apm-server
  name: apm-server
  keepfiles: 7
  permissions: 0644

# 모니터링 설정
monitoring.enabled: true
monitoring.elasticsearch:
  hosts: ["https://localhost:9200"]
  username: "elastic"  
  password: "d*nevMQl9v4Cf6UhyAxW"  # 2025-07-10 업데이트
  ssl.verification_mode: none
```

#### APM Server 시작
```bash
# 설정 테스트
sudo apm-server test config

# 서비스 시작
sudo systemctl start apm-server
sudo systemctl enable apm-server

# 상태 확인
sudo systemctl status apm-server
```

### 2. 방화벽 규칙 추가

#### Terraform에서 APM 포트 추가
```hcl
# shared/main.tf의 elk_allow 방화벽 규칙 수정
resource "google_compute_firewall" "elk_allow" {
  name    = "elk-allow"
  network = google_compute_network.shared_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22", "5044", "5601", "9200", "9600", "8200"]  # 8200 포트 추가
  }

  source_ranges = var.elk_firewall_source_ranges
  target_tags   = var.elk_tags
}
```

## 🖥️ Backend 애플리케이션 APM 연동

### Spring Boot APM Agent 설정

#### 1. pom.xml에 의존성 추가
```xml
<dependency>
    <groupId>co.elastic.apm</groupId>
    <artifactId>apm-agent-attach</artifactId>
    <version>1.45.0</version>
</dependency>
```

#### 2. application.yml APM 설정 추가
```yaml
# application.yml 또는 application.properties
elastic:
  apm:
    server-url: http://elk.moongsan.com:8200
    service-name: moongsan-backend
    service-version: 1.0.0
    environment: production
    application-packages: com.moongsan
    enable: true
    
    # 샘플링 설정
    transaction-sample-rate: 1.0
    
    # 로그 상관관계 설정
    enable-log-correlation: true
    
    # 스택 트레이스 설정
    stack-trace-limit: 50
    span-frames-min-duration: 5ms
    
    # 메트릭 설정
    metrics-interval: 30s
    
    # 캡처 설정
    capture-body: all
    capture-headers: true
```

#### 3. APM Agent 초기화 코드
```java
// Application.java 또는 별도 Configuration 클래스
@SpringBootApplication
public class MoongsanBackendApplication {
    
    static {
        // APM Agent 자동 연결
        ElasticApmAttacher.attach();
    }
    
    public static void main(String[] args) {
        SpringApplication.run(MoongsanBackendApplication.class, args);
    }
}
```

#### 4. 커스텀 APM 설정 클래스
```java
@Configuration
@EnableConfigurationProperties
public class ApmConfiguration {
    
    @Bean
    public ApmAgent apmAgent() {
        return ElasticApm.getAgent();
    }
    
    // 커스텀 트랜잭션 추적
    @EventListener
    public void handleTransactionEvent(TransactionEvent event) {
        // 커스텀 로직
    }
}
```

## 🤖 AI 서버 APM 연동 (Python/FastAPI)

### Python APM Agent 설정

#### 1. 패키지 설치
```bash
# AI 서버에서
pip install elastic-apm
```

#### 2. FastAPI APM 미들웨어 설정
```python
# main.py
from fastapi import FastAPI
from elasticapm.contrib.starlette import make_apm_client, ElasticAPM

# APM 클라이언트 설정
apm_config = {
    'SERVICE_NAME': 'moongsan-ai',
    'SERVICE_VERSION': '1.0.0',
    'SERVER_URL': 'http://elk.moongsan.com:8200',
    'ENVIRONMENT': 'production',
    'CAPTURE_BODY': 'all',
    'CAPTURE_HEADERS': True,
    'TRANSACTION_SAMPLE_RATE': 1.0,
    'ENABLE': True,
}

apm = make_apm_client(apm_config)

app = FastAPI(title="Moongsan AI API")

# APM 미들웨어 추가
app.add_middleware(ElasticAPM, client=apm)

# 나머지 애플리케이션 코드...
```

#### 3. 커스텀 트레이싱
```python
import elasticapm
from elasticapm import capture_span

@app.post("/ai/predict")
async def predict(request: PredictRequest):
    # 커스텀 스팬 생성
    with capture_span("ai_model_inference"):
        result = await ai_model.predict(request.data)
    
    # 커스텀 메트릭 추가
    elasticapm.tag(model_version="v1.2.3")
    elasticapm.tag(request_size=len(request.data))
    
    return result
```

#### 4. 환경변수 설정
```bash
# .env 파일 또는 시스템 환경변수
ELASTIC_APM_SERVICE_NAME=moongsan-ai
ELASTIC_APM_SERVICE_VERSION=1.0.0
ELASTIC_APM_SERVER_URL=http://elk.moongsan.com:8200
ELASTIC_APM_ENVIRONMENT=production
```

## 📊 APM 대시보드 및 알람

### Kibana APM 설정

#### 1. APM 인덱스 패턴 생성
```
apm-*
```

#### 2. APM 전용 대시보드 구성
- **트랜잭션 성능**: 평균 응답 시간, 처리량
- **에러율**: 서비스별 에러 발생률
- **의존성 맵**: 서비스 간 호출 관계
- **인프라 메트릭**: CPU, 메모리 사용률

### 3. APM 알람 설정

#### 응답 시간 임계값 알람
```json
{
  "trigger": {
    "schedule": {
      "interval": "5m"
    }
  },
  "input": {
    "search": {
      "request": {
        "indices": ["apm-*-transaction-*"],
        "body": {
          "query": {
            "bool": {
              "must": [
                {
                  "range": {
                    "@timestamp": {"gte": "now-5m"}
                  }
                },
                {
                  "range": {
                    "transaction.duration.us": {"gte": 5000000}
                  }
                }
              ]
            }
          }
        }
      }
    }
  },
  "condition": {
    "compare": {
      "ctx.payload.hits.total": {"gt": 10}
    }
  }
}
```

## 🚀 배포 스크립트

### APM 에이전트 자동 배포
```bash
#!/bin/bash
# deploy-apm.sh

echo "🚀 APM Agent 배포 시작..."

# Backend 서버에 APM 설정 배포
echo "📦 Backend APM 설정 배포..."
scp -i ~/.ssh/lsh-study-key apm/backend-apm-config.yml ubuntu@10.1.0.3:/tmp/
ssh -i ~/.ssh/lsh-study-key ubuntu@10.1.0.3 "sudo cp /tmp/backend-apm-config.yml /var/moongsan/config/"

# AI 서버에 APM 설정 배포  
echo "🤖 AI APM 설정 배포..."
scp -i ~/.ssh/lsh-study-key apm/ai-apm-config.py ubuntu@10.1.0.4:/tmp/
ssh -i ~/.ssh/lsh-study-key ubuntu@10.1.0.4 "sudo cp /tmp/ai-apm-config.py /var/moongsan/ai/"

# 서비스 재시작
echo "🔄 서비스 재시작..."
ssh -i ~/.ssh/lsh-study-key ubuntu@10.1.0.3 "sudo systemctl restart moongsan-backend"
ssh -i ~/.ssh/lsh-study-key ubuntu@10.1.0.4 "sudo systemctl restart moongsan-ai"

echo "✅ APM Agent 배포 완료!"
```

## 📈 예상 APM 메트릭

### Backend 서비스
- **트랜잭션**: API 엔드포인트별 성능
- **스팬**: DB 쿼리, 외부 API 호출
- **에러**: Exception 추적 및 스택트레이스
- **메트릭**: JVM 메모리, GC, 스레드 풀

### AI 서비스  
- **트랜잭션**: ML 추론 요청 성능
- **스팬**: 모델 로딩, 전처리, 후처리
- **에러**: 모델 에러, 데이터 검증 에러
- **메트릭**: GPU 사용률, 메모리 사용량

이제 코드 레벨의 성능 추적과 에러 분석이 가능합니다! 🎉
