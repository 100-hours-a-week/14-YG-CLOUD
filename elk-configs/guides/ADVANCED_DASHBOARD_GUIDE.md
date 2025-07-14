# 📊 고급 대시보드 구성 가이드

## 🎯 Backend & AI 통합 모니터링 대시보드 생성

### 1. 에러 분석 대시보드

#### Kibana에서 생성할 시각화들:

#### A. 에러 발생 현황 (시간별)
1. **Analytics** → **Lens** → **Line chart**
2. **X-axis**: @timestamp (Date histogram, 1시간 간격)
3. **Y-axis**: Count of records
4. **Filters**: 
   - `(server:backend OR server:ai) AND (message:*ERROR* OR message:*Exception* OR message:*FATAL*)`
5. **Break down by**: server.keyword
6. 저장: "에러 발생 트렌드"

#### B. 에러 타입별 분포 (파이 차트)
1. **Pie chart** 선택
2. **Slice by**: message.keyword (Top 10)
3. **Filters**: 
   - `(server:backend OR server:ai) AND (message:*ERROR* OR message:*Exception*)`
4. 저장: "에러 타입 분포"

#### C. 서버별 에러 비교 (막대 차트)
1. **Vertical bar chart**
2. **X-axis**: server.keyword
3. **Y-axis**: Count
4. **Filters**: 
   - `(server:backend OR server:ai) AND (message:*ERROR* OR message:*Exception*)`
5. 저장: "서버별 에러 수"

#### D. 에러 상세 테이블
1. **Table**
2. **Rows**: 
   - @timestamp
   - server.keyword
   - host.name.keyword
   - message (truncated)
3. **Metrics**: Count
4. **Filters**: 에러 필터 동일
5. 저장: "최근 에러 로그"

### 2. API 성능 모니터링 대시보드

#### E. API 응답 시간 트렌드
1. **Line chart**
2. **X-axis**: @timestamp
3. **Filters**: 
   - `server:backend AND (message:*"completed in"* OR message:*"took"* OR message:*ms*)`
4. 저장: "API 응답 시간"

#### F. API 엔드포인트별 호출 횟수
1. **Horizontal bar chart**
2. **Y-axis**: message.keyword (API 경로 추출)
3. **X-axis**: Count
4. **Filters**: 
   - `server:backend AND (message:*"/api/"*)`
5. 저장: "API 엔드포인트 사용량"

### 3. 시스템 리소스 모니터링

#### G. 로그 볼륨 (서버별)
1. **Area stacked chart**
2. **X-axis**: @timestamp
3. **Y-axis**: Count
4. **Break down by**: server.keyword, logtype.keyword
5. 저장: "서버별 로그 볼륨"

#### H. Docker 컨테이너 상태
1. **Metric**
2. **Filters**: `logtype:docker`
3. **Metric**: Count
4. **Break down by**: server.keyword
5. 저장: "Docker 로그 수"

### 4. 통합 대시보드 생성

1. **Dashboard** → **Create dashboard**
2. 위에서 만든 모든 시각화 추가
3. 레이아웃 구성:
   ```
   [에러 발생 트렌드]         [API 응답 시간]
   [에러 타입 분포] [서버별 에러 수]
   [API 엔드포인트 사용량]    [로그 볼륨]
   [최근 에러 로그 테이블]
   ```
4. 제목: "🔍 Backend & AI 통합 모니터링"
5. **Time range**: Last 24 hours
6. **Refresh**: Every 30 seconds

## 🚨 에러 분석을 위한 고급 쿼리

### 에러 발생 빈도 분석

#### 1. 가장 많이 발생하는 에러 Top 10
```
(server:backend OR server:ai) AND (message:*ERROR* OR message:*Exception*)
```
→ message.keyword 필드로 Terms aggregation

#### 2. 시간대별 에러 급증 구간 탐지
```
(server:backend OR server:ai) AND message:*ERROR*
```
→ @timestamp로 Date histogram (1시간 간격)

#### 3. 특정 에러의 발생 패턴
```
(server:backend OR server:ai) AND message:*"NullPointerException"*
```

#### 4. API별 에러율 계산
```
# 전체 API 호출
server:backend AND message:*"/api/"*

# API 에러
server:backend AND message:*"/api/"* AND (message:*ERROR* OR message:*Exception*)
```

### 성능 문제 탐지

#### 5. 느린 응답 시간 탐지
```
server:backend AND (message:*"took longer than"* OR message:*"slow"* OR message:*"timeout"*)
```

#### 6. 메모리 관련 이슈
```
(server:backend OR server:ai) AND (message:*"OutOfMemoryError"* OR message:*"heap"* OR message:*"GC"*)
```

#### 7. 데이터베이스 연결 문제
```
server:backend AND (message:*"connection"* OR message:*"timeout"* OR message:*"refused"*) AND (message:*"database"* OR message:*"sql"*)
```

## 📈 메트릭 기반 알람 설정

### Watcher (알람) 설정 예시

#### 1. 에러 급증 알람
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
        "search_type": "query_then_fetch",
        "indices": ["moongsan-logs-*"],
        "body": {
          "query": {
            "bool": {
              "must": [
                {
                  "range": {
                    "@timestamp": {
                      "gte": "now-5m"
                    }
                  }
                },
                {
                  "query_string": {
                    "query": "(server:backend OR server:ai) AND (message:*ERROR* OR message:*Exception*)"
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
      "ctx.payload.hits.total": {
        "gt": 10
      }
    }
  },
  "actions": {
    "send_email": {
      "email": {
        "to": ["devops@moongsan.com"],
        "subject": "🚨 에러 급증 알람",
        "body": "최근 5분간 {{ctx.payload.hits.total}}개의 에러가 발생했습니다."
      }
    }
  }
}
```

### 2. API 응답 시간 알람
```json
{
  "trigger": {
    "schedule": {
      "interval": "10m"
    }
  },
  "input": {
    "search": {
      "request": {
        "search_type": "query_then_fetch",
        "indices": ["moongsan-logs-*"],
        "body": {
          "query": {
            "bool": {
              "must": [
                {
                  "range": {
                    "@timestamp": {
                      "gte": "now-10m"
                    }
                  }
                },
                {
                  "query_string": {
                    "query": "server:backend AND message:*\"took longer than 5000ms\"*"
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
      "ctx.payload.hits.total": {
        "gt": 5
      }
    }
  }
}
```

## 🎨 대시보드 템플릿

### JSON Export 파일 (백업용)
다음 단계에서 완성된 대시보드를 JSON으로 export하여 팀원들이 import할 수 있도록 제공
