# 🎯 ELK 종합 대시보드 & APM 완성 가이드

## ✅ 구축 완료 현황

### 🚀 서비스 상태
- **Elasticsearch**: ✅ 정상 작동 (https://elk.moongsan.com:9200)
- **Logstash**: ✅ 정상 작동 (포트 5044)
- **Kibana**: ✅ 정상 작동 (http://elk.moongsan.com:5601)
- **APM Server**: ✅ 정상 작동 (http://elk.moongsan.com:8200)
- **방화벽**: ✅ 모든 포트 개방 완료

### 🔑 접속 정보
- **Kibana URL**: http://elk.moongsan.com:5601
- **로그인**: 
  - Username: `moongsan_admin`
  - Password: `moongsan123`
- **APM Server**: http://elk.moongsan.com:8200

## 🎯 1. 대시보드 생성 (지금 바로!)

### 📊 Backend 로그 대시보드 생성

1. **Kibana 접속**: http://elk.moongsan.com:5601
2. **Analytics → Dashboard → Create new dashboard**
3. **Create visualization 클릭**

#### 📈 실시간 로그 발생량 차트
```
Visualization Type: Line
Data source: logs-*
Metrics: Count
Buckets: Date Histogram (@timestamp)
Filters: server.keyword:"backend"
```

#### 🔴 에러 타입 분포 파이차트
```
Visualization Type: Pie
Data source: logs-*
Metrics: Count
Buckets: Terms (log.level.keyword)
Filters: server.keyword:"backend" AND (message:*ERROR* OR message:*Exception*)
```

#### ⚠️ 최근 에러 로그 테이블
```
Visualization Type: Data Table
Data source: logs-*
Metrics: Count
Buckets: 
- Terms (@timestamp, Size: 20, Order: Descending)
- Terms (message.keyword, Size: 1)
Filters: server.keyword:"backend" AND (message:*ERROR* OR message:*Exception*)
```

### 🤖 AI 서버 대시보드

#### 🧠 AI 추론 요청량
```
Visualization Type: Line
Data source: logs-*
Metrics: Count
Buckets: Date Histogram (@timestamp)
Filters: server.keyword:"ai" AND (message:*predict* OR message:*inference*)
```

#### ⚡ 모델 성능 메트릭
```
Visualization Type: Metric
Data source: logs-*
Metrics: Average (response_time)
Filters: server.keyword:"ai"
```

## 🚨 2. 에러 분석 대시보드

### 📊 총 에러 발생 수 (24시간)
```sql
# Kibana Discovery 검색 쿼리
server.keyword:* AND (log.level:"ERROR" OR message:*ERROR* OR message:*Exception* OR message:*Failed*)
```

### 🖥️ 서버별 에러 분포
```sql
# 서버별 에러 개수
server.keyword:"backend" AND message:*ERROR*     # Backend 에러
server.keyword:"ai" AND message:*ERROR*          # AI 서버 에러  
server.keyword:"database" AND message:*ERROR*    # DB 서버 에러
```

### 🥇 가장 많이 발생한 에러 TOP 10
```
Visualization Type: Data Table
Data source: logs-*
Metrics: Count
Buckets:
- Terms (message.keyword, Size: 10, Order by Count Desc)
- Terms (server.keyword, Size: 5, Order by Count Desc)
Filters: message:*ERROR* OR message:*Exception* OR message:*Failed*
```

## 🔧 3. APM 연동

### 🖥️ Backend (Spring Boot) APM 설정

#### pom.xml 의존성 추가
```xml
<dependency>
    <groupId>co.elastic.apm</groupId>
    <artifactId>apm-agent-attach</artifactId>
    <version>1.45.0</version>
</dependency>
```

#### application.yml 설정
```yaml
elastic:
  apm:
    server-url: http://elk.moongsan.com:8200
    service-name: moongsan-backend
    service-version: 1.0.0
    environment: production
    application-packages: com.moongsan
    enable: true
    transaction-sample-rate: 1.0
    enable-log-correlation: true
    capture-body: all
    capture-headers: true
```

#### Application.java 초기화
```java
@SpringBootApplication
public class MoongsanBackendApplication {
    static {
        ElasticApmAttacher.attach();
    }
    
    public static void main(String[] args) {
        SpringApplication.run(MoongsanBackendApplication.class, args);
    }
}
```

### 🤖 AI 서버 (Python/FastAPI) APM 설정

#### 패키지 설치
```bash
pip install elastic-apm
```

#### main.py 설정
```python
from fastapi import FastAPI
from elasticapm.contrib.starlette import make_apm_client, ElasticAPM

apm_config = {
    'SERVICE_NAME': 'moongsan-ai',
    'SERVICE_VERSION': '1.0.0',
    'SERVER_URL': 'http://elk.moongsan.com:8200',
    'ENVIRONMENT': 'production',
    'CAPTURE_BODY': 'all',
    'TRANSACTION_SAMPLE_RATE': 1.0,
}

apm = make_apm_client(apm_config)
app = FastAPI(title="Moongsan AI API")
app.add_middleware(ElasticAPM, client=apm)
```

## 📊 4. 주요 메트릭 모니터링

### 🔢 에러 발생 통계 쿼리

#### 지난 24시간 총 에러 수
```sql
GET logs-*/_count
{
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
          "bool": {
            "should": [
              {"match": {"log.level": "ERROR"}},
              {"wildcard": {"message": "*ERROR*"}},
              {"wildcard": {"message": "*Exception*"}},
              {"wildcard": {"message": "*Failed*"}}
            ]
          }
        }
      ]
    }
  }
}
```

#### 서버별 에러 분포
```sql
GET logs-*/_search
{
  "size": 0,
  "query": {
    "bool": {
      "should": [
        {"match": {"log.level": "ERROR"}},
        {"wildcard": {"message": "*ERROR*"}}
      ]
    }
  },
  "aggs": {
    "servers": {
      "terms": {
        "field": "server.keyword",
        "size": 10
      }
    }
  }
}
```

#### 시간대별 에러 트렌드
```sql
GET logs-*/_search
{
  "size": 0,
  "query": {
    "range": {
      "@timestamp": {
        "gte": "now-7d"
      }
    }
  },
  "aggs": {
    "error_trend": {
      "date_histogram": {
        "field": "@timestamp",
        "calendar_interval": "1h"
      },
      "aggs": {
        "servers": {
          "terms": {
            "field": "server.keyword"
          }
        }
      }
    }
  }
}
```

## 🎯 5. 즉시 확인 가능한 항목

### ✅ 현재 확인 가능
1. **로그 수집**: Filebeat → Logstash → Elasticsearch
2. **Kibana 접속**: 로그 검색 및 필터링
3. **APM 서버**: 성능 모니터링 준비 완료
4. **대시보드**: 수동 생성 가능

### 🚀 다음 단계 (코드 배포 후)
1. **APM 에이전트**: Backend/AI 서버에 코드 적용
2. **실시간 메트릭**: 트랜잭션, 에러, 성능 데이터
3. **자동 알람**: 임계값 초과 시 알림
4. **비즈니스 메트릭**: 사용자 행동, API 사용량 등

## 📱 6. 빠른 접속 링크

- **🎯 Kibana 메인**: http://elk.moongsan.com:5601
- **🔍 Discover (로그 검색)**: http://elk.moongsan.com:5601/app/discover
- **📊 Dashboard**: http://elk.moongsan.com:5601/app/dashboards
- **⚙️ Management**: http://elk.moongsan.com:5601/app/management

## 🆘 문제 해결

### 로그가 보이지 않을 때
```bash
# Filebeat 상태 확인
sudo systemctl status filebeat

# Logstash 상태 확인  
sudo systemctl status logstash

# 로그 재시작
sudo systemctl restart filebeat
sudo systemctl restart logstash
```

### APM 데이터가 보이지 않을 때
```bash
# APM 서버 상태 확인
curl http://elk.moongsan.com:8200

# APM 에이전트 로그 확인
tail -f /var/log/apm-server/apm-server.log
```

---

**🎉 모든 준비가 완료되었습니다!**  
이제 Kibana에서 실제 대시보드를 만들고 APM을 적용하여 완전한 모니터링 시스템을 구축하세요! 🚀
