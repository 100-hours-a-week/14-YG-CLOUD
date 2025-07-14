# 🎯 AI/Backend 로그 분리 테이블 생성 가이드

## 📊 현재 상황
- ✅ 모든 로그가 보이는 테이블 완성됨
- ❌ 필터가 적용되지 않아서 AI/Backend 로그가 섞여서 보임

## 🛠️ 해결 방법: 분리된 테이블 2개 생성

### Step 1: AI 로그 전용 테이블 생성

#### 1-1. 새 시각화 생성
1. 대시보드 편집 모드에서 **"Create new"** 클릭
2. **"Lens"** 선택
3. **"Data table"** 선택

#### 1-2. 데이터 소스 설정
- **Index pattern**: `moongsan-logs-*` 선택

#### 1-3. 필터 설정 (중요!)
1. 상단 검색바에 다음 입력:
   ```
   service.keyword : "ai"
   ```
2. 또는 **"Add filter"** 버튼 클릭:
   - **Field**: `service.keyword`
   - **Operator**: `is`
   - **Value**: `ai`

#### 1-4. 테이블 컬럼 구성
**Rows**에 다음 필드들을 순서대로 추가:

1. **@timestamp**
   - Operation: Date histogram
   - Interval: Auto
   - Custom label: "⏰ 시간"

2. **level.keyword**
   - Operation: Terms
   - Size: 3
   - Order by: Alphabetical
   - Custom label: "📊 레벨"

3. **server.keyword**
   - Operation: Terms
   - Size: 3
   - Order by: Alphabetical
   - Custom label: "🖥️ 서버"

4. **message.keyword**
   - Operation: Terms
   - Size: 10
   - Order by: @timestamp (Descending)
   - Custom label: "💬 로그 메시지"

#### 1-5. 정렬 및 제목 설정
- **Sorting**: @timestamp, Descending (최신순)
- **Title**: "🤖 AI 서비스 로그 상세"
- **Save and return**

### Step 2: Backend 로그 전용 테이블 생성

#### 2-1. AI 테이블 복제 (빠른 방법)
1. 방금 만든 AI 테이블의 **메뉴 아이콘** (3점) 클릭
2. **"Clone panel"** 선택

#### 2-2. 필터 수정
1. 복제된 테이블의 **연필 아이콘** (Edit) 클릭
2. 필터를 다음으로 변경:
   ```
   service.keyword : "backend"
   ```
3. **Title**: "🖥️ Backend 서비스 로그 상세"
4. **Save and return**

### Step 3: 레이아웃 정리

#### 3-1. 대시보드 레이아웃 최적화
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

#### 3-2. 패널 크기 조정
- AI 테이블: 너비 24, 높이 15
- Backend 테이블: 너비 24, 높이 15
- 나란히 배치 또는 위아래 배치

## 🔧 필터 확인 방법

### 올바른 필터 적용 확인:
1. **AI 테이블**에서 `service` 컬럼 값이 모두 `ai`인지 확인
2. **Backend 테이블**에서 `service` 컬럼 값이 모두 `backend`인지 확인

### 필터가 안 보일 때:
- 테이블 상단에 파란색 필터 태그가 보여야 함: `service.keyword: ai`
- 안 보이면 필터가 제대로 적용되지 않은 것

## 🚨 문제 해결

### 필터가 적용되지 않을 때:
1. **검색바 사용**: 테이블 편집 시 상단 검색바에 직접 입력
2. **KQL 문법 확인**: `service.keyword : "ai"` (따옴표 포함)
3. **필드명 확인**: `service.keyword` vs `service` (keyword 버전 사용)

### 데이터가 안 보일 때:
1. **시간 범위 확인**: Last 24 hours 또는 Last 7 days로 설정
2. **인덱스 패턴 확인**: `moongsan-logs-*`가 올바르게 선택되었는지
3. **필드 새로고침**: Index pattern에서 필드 refresh

## 🎯 예상 결과

### 완료 후:
- 🤖 **AI 테이블**: AI 서비스 로그만 표시
- 🖥️ **Backend 테이블**: Backend 서비스 로그만 표시  
- 💬 **로그 메시지**: 실제 로그 내용이 명확하게 보임
- ⏰ **시간순 정렬**: 최신 로그가 맨 위에 표시

### 확인 방법:
각 테이블에서 `server` 컬럼을 보면:
- AI 테이블: `ai-server`, `ai-worker` 등
- Backend 테이블: `backend-server`, `backend-api` 등
