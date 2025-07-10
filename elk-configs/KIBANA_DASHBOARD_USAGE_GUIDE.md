# 🎯 뭉치면 산다 - Kibana 대시보드 활용 가이드

## 📊 현재 설치된 대시보드 현황

### ✅ 성공적으로 설치된 Sample Data 대시보드들

#### 1. 🌐 [Logs] Web Traffic 대시보드
- **설명**: 실시간 웹 트래픽 분석
- **주요 시각화**:
  - 시간대별 방문자 수
  - HTTP 상태코드 분포
  - 응답 시간 분포
  - Top 방문 페이지

#### 2. 🛒 [eCommerce] Revenue Dashboard
- **설명**: 전자상거래 매출 분석
- **주요 시각화**:
  - 총 매출액
  - 주문 건수
  - 평균 주문 금액
  - 지역별 매출 분포

#### 3. ✈️ [Flights] Global Flight Dashboard
- **설명**: 항공편 데이터 분석
- **주요 시각화**:
  - 지연률 분석
  - 항공사별 성능
  - 경로별 통계

## 🎨 인덱스 패턴 현황

### ✅ 생성된 데이터뷰들
- `📈 logs-*` - 뭉치면 산다 서비스 로그
- `📈 filebeat-*` - 파일비트 수집 로그  
- `📈 kibana_sample_data_logs` - 샘플 웹 로그
- `📈 kibana_sample_data_ecommerce` - 샘플 전자상거래 데이터
- `📈 kibana_sample_data_flights` - 샘플 항공편 데이터

## 🚀 실제 서비스 로그 활용 방법

### 1단계: 기본 대시보드 경험
```bash
# 접속 정보
URL: http://elk.moongsan.com:5601
로그인: moongsan_admin / moongsan123
메뉴: Analytics → Dashboard
```

### 2단계: Sample 대시보드를 우리 서비스에 맞게 커스터마이징

#### 🔧 [Logs] Web Traffic → 뭉치면 산다 Web Traffic
1. **대시보드 복제**:
   - `[Logs] Web Traffic` 대시보드 열기
   - 우상단 **Actions** → **Clone**
   - 새 이름: `뭉치면 산다 - Web Traffic`

2. **데이터 소스 변경**:
   - **Edit** 모드 진입
   - 각 패널 클릭 → **Edit visualization**
   - **Data view**: `logs-*` (뭉치면 산다 로그)
   - **Filter 추가**: `server.keyword:"backend"` (백엔드 로그만)

3. **필드 매핑 조정**:
   ```json
   Sample 필드 → 우리 서비스 필드
   agent.keyword → server.keyword
   geo.src → client_ip
   request → api_path
   response → status_code
   ```

#### 🛒 [eCommerce] Revenue → 뭉치면 산다 Orders
1. **대시보드 복제**: `뭉치면 산다 - 주문 분석`
2. **필드 매핑**:
   ```json
   taxful_total_price → order_amount
   order_id → transaction_id
   customer_id → user_id
   products.product_name → product_name
   ```

### 3단계: 새로운 대시보드 생성

#### 🎯 뭉치면 산다 Backend API 모니터링
```json
주요 메트릭:
- API 엔드포인트별 호출 횟수
- 평균 응답 시간
- 에러율 (4xx, 5xx)
- 동시 접속자 수
```

#### 🤖 뭉치면 산다 AI 서비스 모니터링  
```json
주요 메트릭:
- AI 모델별 추론 요청 수
- 추론 소요 시간
- GPU 사용률
- 모델 정확도
```

## 📈 실전 활용 시나리오

### 시나리오 1: 실시간 서비스 모니터링
```bash
1. Web Traffic 대시보드에서 실시간 트래픽 확인
2. 갑작스런 트래픽 증가 감지
3. Backend API 대시보드에서 특정 API 병목 확인
4. AI 서비스 대시보드에서 AI 모델 부하 상태 확인
```

### 시나리오 2: 성능 최적화
```bash
1. 응답시간이 긴 API 엔드포인트 식별
2. 에러율이 높은 기능 파악
3. 사용자 행동 패턴 분석으로 UX 개선점 도출
```

### 시나리오 3: 비즈니스 인사이트
```bash
1. 주문 패턴 분석 (시간대, 요일별)
2. 지역별 사용자 분포 확인
3. 인기 상품 카테고리 파악
4. 고객 세그먼테이션
```

## 🔧 고급 활용법

### 1. 알림 설정 (Watcher)
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
        "search_type": "query_then_fetch",
        "indices": ["logs-*"],
        "body": {
          "query": {
            "bool": {
              "must": [
                {"range": {"@timestamp": {"gte": "now-5m"}}},
                {"term": {"status_code": 500}}
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
        "to": ["dev-team@moongsan.com"],
        "subject": "🚨 뭉치면 산다 - 서버 에러 급증 알림",
        "body": "최근 5분간 500 에러가 {{ctx.payload.hits.total}}건 발생했습니다."
      }
    }
  }
}
```

### 2. 커스텀 시각화 생성
```bash
1. Visualize → Create visualization
2. 시각화 타입 선택:
   - Line chart: 시간대별 트렌드
   - Bar chart: 카테고리별 비교
   - Pie chart: 비율 분석
   - Heat map: 시간대/요일별 패턴
   - Geographic map: 지역별 분포
```

### 3. 대시보드 자동화
```bash
# 대시보드 PDF 리포트 자동 생성
curl -X POST "elk.moongsan.com:5601/api/reporting/generate/printablePdf" \
  -H "Content-Type: application/json" \
  -u "moongsan_admin:moongsan123" \
  -d '{
    "layout": {"id": "print"},
    "relativeUrls": ["/app/dashboards#/view/dashboard-id"]
  }'
```

## 🎯 다음 단계 Action Items

### 즉시 실행 가능
1. **Sample 대시보드 체험** (10분)
   - 각 대시보드 둘러보기
   - 필터링, 시간 범위 조정 연습

2. **첫 번째 커스텀 대시보드 생성** (30분)
   - Web Traffic 대시보드 복제
   - 우리 서비스 로그로 데이터 소스 변경

### 단기 목표 (1주일)
1. **핵심 비즈니스 메트릭 대시보드 구축**
   - 실시간 주문 현황
   - 사용자 활동 패턴
   - API 성능 모니터링

2. **알림 시스템 구축**
   - 에러율 급증 알림
   - 성능 저하 알림
   - 비정상 트래픽 패턴 알림

### 중기 목표 (1개월)
1. **고급 분석 대시보드**
   - 사용자 코호트 분석
   - A/B 테스트 결과 분석
   - 수익성 분석

2. **자동화된 리포팅**
   - 일간/주간/월간 리포트 자동 생성
   - 경영진용 요약 대시보드

## 🌟 팁과 베스트 프랙티스

### 성능 최적화
- 시간 범위를 적절히 제한 (기본 15분~1시간)
- 불필요한 필드 제외
- 샘플링 활용 (대용량 데이터)

### 사용자 경험
- 의미있는 대시보드/패널 이름 사용
- 색상 코딩 일관성 유지
- 툴팁과 설명 추가

### 보안
- 민감한 데이터 필드 마스킹
- 역할 기반 접근 제어
- 정기적인 접근 권한 검토

---

> 💡 **문의사항**: 대시보드 구축 중 문제가 발생하면 ELK 설정 문서나 Kibana 공식 문서를 참고하세요.
> 
> 🔗 **유용한 링크**:
> - [Kibana 대시보드 베스트 프랙티스](https://www.elastic.co/guide/en/kibana/current/dashboard.html)
> - [Elasticsearch 쿼리 DSL](https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl.html)
