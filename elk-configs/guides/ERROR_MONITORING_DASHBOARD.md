# 🚨 실시간 에러 분석 & 통계 대시보드

## 📊 에러 발생 현황 실시간 모니터링

### 🔢 핵심 에러 메트릭

#### 1. 총 에러 발생 수 (지난 24시간)
```
Query: log.level:"ERROR" OR message:*ERROR* OR message:*Exception* OR message:*Failed*
Time Range: Last 24 hours
Visualization: Metric (Big Number)
```

#### 2. 에러 발생률 (분당)
```
Query: log.level:"ERROR" OR message:*ERROR*
Time Range: Last 1 hour
Visualization: Line Chart
X-axis: @timestamp (1 minute intervals)
Y-axis: Count
```

#### 3. 서버별 에러 분포
```
Query: (log.level:"ERROR" OR message:*ERROR*) AND server.keyword:*
Visualization: Pie Chart
Split Slices: server.keyword (Top 5)
```

### 🔥 가장 많이 발생하는 에러 TOP 10

#### 에러 메시지별 발생 빈도
```
Query: log.level:"ERROR" OR message:*ERROR* OR message:*Exception*
Visualization: Data Table
Columns:
- message.keyword (Terms, Size: 10, Order by Count Desc)
- server.keyword (Terms, Size: 1)
- Count
```

#### 예상 결과:
```
에러 메시지                           서버      발생 횟수
ConnectionException: DB timeout       backend   45
NullPointerException: User not found  backend   32
FileNotFoundException: Model file     ai        28
OutOfMemoryError: Heap space         backend   15
ValidationException: Invalid input    ai        12
```

### 📈 에러 트렌드 분석 (7일)

#### 시간대별 에러 발생 패턴
```
Query: log.level:"ERROR" OR message:*ERROR*
Time Range: Last 7 days
Visualization: Area Chart
X-axis: @timestamp (1 hour intervals)
Y-axis: Count
Split Series: server.keyword
```

#### 일별 에러 증감 현황
```
Query: log.level:"ERROR"
Visualization: Bar Chart
X-axis: @timestamp (1 day intervals)  
Y-axis: Count
Split Bars: server.keyword
```

### 🚨 심각도별 에러 분류

#### Critical vs Warning vs Error
```javascript
// Kibana Scripted Field 예시
if (doc['log.level.keyword'].value == 'FATAL' || 
    doc['message.keyword'].value.contains('CRITICAL')) {
  return 'CRITICAL';
} else if (doc['log.level.keyword'].value == 'ERROR') {
  return 'ERROR';
} else if (doc['log.level.keyword'].value == 'WARN') {
  return 'WARNING';
}
```

### 🎯 서버별 상세 에러 분석

#### Backend 서버 에러 분석
```
Query: server.keyword:"backend" AND (log.level:"ERROR" OR message:*Exception*)
분석 항목:
- API 엔드포인트별 에러 발생률
- 데이터베이스 연결 에러
- 인증/권한 관련 에러
- 비즈니스 로직 에러
```

#### AI 서버 에러 분석
```
Query: server.keyword:"ai" AND (log.level:"ERROR" OR message:*failed*)
분석 항목:
- 모델 추론 실패
- GPU 메모리 부족
- 입력 데이터 검증 에러
- 모델 로딩 실패
```

#### Database 서버 에러 분석
```
Query: server.keyword:"database" AND (log.level:"ERROR" OR message:*ERROR*)
분석 항목:
- 연결 시간 초과
- 쿼리 실행 오류
- 디스크 공간 부족
- 복제 지연 문제
```

## 📊 실시간 알람 설정

### 🔴 Critical 에러 즉시 알람
```json
{
  "trigger": {
    "schedule": {
      "interval": "1m"
    }
  },
  "input": {
    "search": {
      "request": {
        "indices": ["logs-*"],
        "body": {
          "query": {
            "bool": {
              "must": [
                {
                  "range": {
                    "@timestamp": {"gte": "now-1m"}
                  }
                },
                {
                  "bool": {
                    "should": [
                      {"match": {"log.level": "FATAL"}},
                      {"wildcard": {"message": "*CRITICAL*"}},
                      {"wildcard": {"message": "*OutOfMemoryError*"}}
                    ]
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
      "ctx.payload.hits.total": {"gte": 1}
    }
  },
  "actions": {
    "send_slack": {
      "webhook": {
        "url": "https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK",
        "body": "🚨 CRITICAL ERROR 발생!\nServer: {{ctx.payload.hits.hits.0._source.server}}\nMessage: {{ctx.payload.hits.hits.0._source.message}}"
      }
    }
  }
}
```

### ⚠️ 에러 임계값 알람 (시간당 50개 이상)
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
        "indices": ["logs-*"],
        "body": {
          "query": {
            "bool": {
              "must": [
                {
                  "range": {
                    "@timestamp": {"gte": "now-1h"}
                  }
                },
                {
                  "match": {"log.level": "ERROR"}
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
      "ctx.payload.hits.total": {"gte": 50}
    }
  }
}
```

## 🎯 비즈니스 임팩트 분석

### 💰 에러가 비즈니스에 미치는 영향

#### 주문 실패율 분석
```
Query: server.keyword:"backend" AND message:*/api/order* AND log.level:"ERROR"
측정 항목:
- 시간당 주문 실패 건수
- 실패 원인별 분류
- 매출 손실 추정
```

#### 사용자 경험 영향도
```
Query: server.keyword:"ai" AND message:*prediction* AND log.level:"ERROR"
측정 항목:
- AI 추천 실패율
- 사용자 이탈률 상관관계
- 서비스 가용성 지표
```

## 📱 모바일 대시보드 설정

### 📊 모바일 최적화 에러 대시보드
```
대시보드 구성:
1. 총 에러 수 (큰 숫자)
2. 서버별 상태 (신호등 표시)
3. 최근 심각한 에러 (최대 5개)
4. 트렌드 차트 (간소화)
```

## 🔍 에러 근본 원인 분석

### 🕵️ 에러 패턴 분석

#### 연쇄 에러 추적
```sql
# 같은 시간대에 발생한 연관 에러 찾기
GET logs-*/_search
{
  "query": {
    "bool": {
      "must": [
        {"match": {"log.level": "ERROR"}},
        {
          "range": {
            "@timestamp": {
              "gte": "2025-07-03T02:00:00",
              "lte": "2025-07-03T02:05:00"
            }
          }
        }
      ]
    }
  },
  "sort": [{"@timestamp": {"order": "asc"}}]
}
```

#### 에러 발생 전후 로그 분석
```sql
# 에러 발생 5분 전후 로그 분석
GET logs-*/_search
{
  "query": {
    "bool": {
      "must": [
        {"match": {"server.keyword": "backend"}},
        {
          "range": {
            "@timestamp": {
              "gte": "now-10m",
              "lte": "now"
            }
          }
        }
      ]
    }
  },
  "sort": [{"@timestamp": {"order": "desc"}}]
}
```

## 🚀 자동화된 에러 대응

### 🤖 자동 복구 스크립트 트리거

#### 메모리 부족 시 자동 재시작
```bash
#!/bin/bash
# 메모리 부족 에러 감지 시 자동 실행
if [[ "$ERROR_MESSAGE" == *"OutOfMemoryError"* ]]; then
    echo "🚨 메모리 부족 감지, 서비스 재시작..."
    sudo systemctl restart moongsan-backend
    # Slack 알림
    curl -X POST $SLACK_WEBHOOK -d "{'text':'Backend 서비스 자동 재시작됨 (메모리 부족)'}"
fi
```

#### 데이터베이스 연결 실패 시 자동 복구
```bash
#!/bin/bash
# DB 연결 실패 감지 시 연결 풀 재설정
if [[ "$ERROR_MESSAGE" == *"Connection timeout"* ]]; then
    echo "🔧 DB 연결 복구 시도..."
    # DB 연결 풀 리셋 API 호출
    curl -X POST http://backend.moongsan.com/admin/db/reset-pool
fi
```

---

**📊 이제 실시간으로 에러 현황을 모니터링하고 즉시 대응할 수 있습니다!**

주요 확인 포인트:
- ✅ **에러 발생량**: 평상시 대비 급증 여부
- ✅ **에러 타입**: 새로운 에러 패턴 출현
- ✅ **서버별 분포**: 특정 서버 집중 여부  
- ✅ **시간대 패턴**: 트래픽과 에러의 상관관계
- ✅ **비즈니스 임팩트**: 에러가 매출/사용자에 미치는 영향
