# 🎯 뭉치면 산다 - 로그 메시지 표시 개선 가이드

## 📋 현재 상황
- 기존 대시보드에서 로그 분류(레벨, 서버별)는 잘 되지만, **실제 로그 메시지 내용**이 테이블에 표시되지 않음
- AI 로그와 Backend 로그를 분리하여 각각의 로그 내용을 직접 볼 수 있도록 개선 필요

## 🛠️ 해결 방법

### 1. 기존 테이블 패널 수정
현재 테이블에서 다음과 같이 수정:

#### 현재 컬럼 구성:
- `level.keyword` (로그 레벨)
- `server.keyword` (서버명)
- `@timestamp` (시간)
- `Count of records` (로그 수)

#### 개선된 컬럼 구성:
- `@timestamp` (시간) - 최신순 정렬
- `level.keyword` (로그 레벨)
- `server.keyword` (서버명)
- `service.keyword` (서비스 타입: AI/Backend)
- **`message.keyword` (실제 로그 메시지)** ← 새로 추가

### 2. AI/Backend 로그 분리 대시보드 생성

#### 상단 차트 (3개)
1. **📈 전체 시간별 로그 수** (라인 차트)
2. **🤖 AI vs 🖥️ Backend 로그 분포** (파이 차트) - `service.keyword` 필드 사용
3. **📊 로그 레벨 분포** (막대 차트)

#### 하단 테이블 (2개)
1. **🤖 AI 서비스 로그 상세**
   - Filter: `service.keyword : "ai"`
   - 컬럼: 시간, 레벨, 서버, **로그 메시지**

2. **🖥️ Backend 서비스 로그 상세**
   - Filter: `service.keyword : "backend"`
   - 컬럼: 시간, 레벨, 서버, **로그 메시지**

## 🔧 Kibana UI에서 수정하는 방법

### Step 1: 기존 대시보드 수정
1. Kibana → Dashboards → "뭉치면 산다 - 실시간 서비스 모니터링" 열기
2. 하단 테이블 패널의 편집(Edit) 버튼 클릭
3. 오른쪽 "Available fields"에서 `message.keyword` 필드를 테이블로 드래그
4. 컬럼 순서 조정: 시간 → 레벨 → 서버 → 서비스 → 메시지
5. Save 버튼 클릭

### Step 2: AI/Backend 분리 테이블 생성
1. 새로운 Lens 시각화 생성
2. Visualization type: Data table
3. Filter 추가:
   - AI 테이블: `service.keyword : "ai"`
   - Backend 테이블: `service.keyword : "backend"`
4. 필드 구성:
   ```
   Rows:
   - @timestamp (Date histogram, 최신순)
   - level.keyword (Terms, 3개)
   - server.keyword (Terms, 3개)
   - message.keyword (Terms, 10개) ← 실제 로그 메시지
   ```

### Step 3: 대시보드 레이아웃
```
+------------------------+----------------+----------------+
|   📈 시간별 로그 수      |  🤖 AI vs BE   |  📊 로그 레벨   |
|      (라인 차트)       |   (파이 차트)   |   (막대 차트)   |
+------------------------+----------------+----------------+
|            🤖 AI 서비스 로그 상세 테이블               |
|    시간 | 레벨 | 서버 | 로그 메시지                   |
+--------------------------------------------------+
|          🖥️ Backend 서비스 로그 상세 테이블            |
|    시간 | 레벨 | 서버 | 로그 메시지                   |
+--------------------------------------------------+
```

## 📊 로그 데이터 구조 확인

### 주요 필드들:
- `@timestamp`: 로그 발생 시간
- `level.keyword`: 로그 레벨 (INFO, ERROR, DEBUG 등)
- `server.keyword`: 서버명
- `service.keyword`: 서비스 타입 (ai, backend)
- `message.keyword`: 실제 로그 메시지 내용
- `log_type.keyword`: 로그 타입 분류

### 필터 예시:
```kuery
# AI 로그만 보기
service.keyword : "ai"

# Backend 로그만 보기  
service.keyword : "backend"

# ERROR 레벨 로그만 보기
level.keyword : "ERROR"

# 특정 서버의 로그만 보기
server.keyword : "ai-server-1"
```

## 🎯 다음 단계

1. **로그 메시지 표시 개선**
   - 테이블에 `message.keyword` 필드 추가
   - 메시지 내용이 길 경우 테이블 행 높이 조정

2. **AI/Backend 분리 대시보드 완성**
   - 각 서비스별 로그 테이블 생성
   - 필터 적용하여 명확하게 분리

3. **대시보드 Export/Import**
   - 완성된 대시보드를 NDJSON 파일로 Export
   - 버전 관리 및 백업

4. **실시간 모니터링 강화**
   - 시간 범위 조정 (최근 1시간, 24시간 등)
   - 자동 새로고침 설정
   - 알림 기능 연동

## 📝 참고 사항
- Kibana에서 `message.keyword`는 정확한 일치를 위한 키워드 필드
- `message` (텍스트 필드)는 full-text 검색용
- 테이블에서는 `keyword` 타입 필드 사용 권장
