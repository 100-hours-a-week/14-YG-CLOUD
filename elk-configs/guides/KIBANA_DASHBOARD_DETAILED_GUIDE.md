# 🚀 AI/Backend 로그 분리 대시보드 완성 가이드

## 📊 현재 상황 분석
- 기존 대시보드에서 로그 메시지가 테이블에 표시되지 않음
- AI 로그와 Backend 로그를 분리하여 각각의 내용을 명확히 보고 싶음

## 🛠️ 즉시 실행 가능한 해결책

### 1. Kibana UI에서 직접 수정하기

#### Step 1: 기존 테이블 패널 개선
1. **Kibana 접속**: http://elk.moongsan.com:5601/app/dashboards
2. **대시보드 열기**: "뭉치면 산다 - 실시간 서비스 모니터링"
3. **테이블 패널 편집**:
   - 하단 테이블의 "Edit" 버튼 클릭
   - 오른쪽 Available fields에서 `message.keyword` 찾기
   - `message.keyword`를 테이블로 드래그 앤 드롭
   - 컬럼 너비 조정: 메시지 컬럼을 넓게 설정

#### Step 2: AI 로그 전용 테이블 추가
1. **새 패널 추가**: 대시보드에서 "Create new" → "Lens"
2. **Data table 선택**
3. **필터 설정**: `service.keyword : "ai"`
4. **컬럼 구성**:
   ```
   Rows 추가:
   - @timestamp (Date histogram, Interval: Auto)
   - level.keyword (Terms, Size: 3)
   - server.keyword (Terms, Size: 3)  
   - message.keyword (Terms, Size: 10)
   ```
5. **정렬**: @timestamp 내림차순 (최신 로그 먼저)
6. **제목**: "🤖 AI 서비스 로그 상세"

#### Step 3: Backend 로그 전용 테이블 추가
1. **AI 테이블 복제**: 위에서 만든 AI 테이블을 복제
2. **필터 변경**: `service.keyword : "backend"`
3. **제목 변경**: "🖥️ Backend 서비스 로그 상세"

### 2. 대시보드 레이아웃 최적화

#### 최종 레이아웃:
```
+-------------------+------------------+------------------+
|  📈 시간별 로그 수   |   🤖 AI vs BE    |   📊 로그 레벨    |
|     (라인 차트)     |    (파이 차트)    |    (막대 차트)    |
+-------------------+------------------+------------------+
|              🤖 AI 서비스 로그 상세                    |
| 시간        레벨    서버      로그 메시지              |
+---------------------------------------------------+
|            🖥️ Backend 서비스 로그 상세               |  
| 시간        레벨    서버      로그 메시지              |
+---------------------------------------------------+
```

### 3. 컬럼 설정 최적화

#### AI/Backend 테이블 컬럼:
| 컬럼 | 필드 | 설정 | 너비 |
|------|------|------|------|
| ⏰ 시간 | @timestamp | Date histogram, 1분 간격 | 150px |
| 📊 레벨 | level.keyword | Terms, 상위 3개 | 80px |
| 🖥️ 서버 | server.keyword | Terms, 상위 3개 | 120px |
| 💬 메시지 | message.keyword | Terms, 상위 10개 | 400px+ |

## 🔧 고급 설정

### 필터 추가 옵션:
```kuery
# AI 서비스의 ERROR 로그만
service.keyword : "ai" AND level.keyword : "ERROR"

# Backend 서비스의 특정 서버 로그만  
service.keyword : "backend" AND server.keyword : "backend-server-1"

# 최근 1시간 로그만
@timestamp >= now-1h
```

### 시간 범위 설정:
- **실시간 모니터링**: Last 15 minutes, 자동 새로고침 30초
- **문제 분석**: Last 24 hours
- **일간 리포트**: Last 7 days

## 📝 완료 후 Export/Import

### Export 명령:
```bash
cd /Users/lsh/Documents/local/3tier-moongsan/14-YG-CLOUD/elk-configs/scripts
./manage-dashboards.sh export
```

### 파일 확인:
- `moongsan-service-monitoring-dashboard.ndjson`: 개선된 기존 대시보드
- 새로운 대시보드도 export 하여 백업

## 🎯 예상 결과

### 개선 전:
- 테이블에 로그 수만 표시
- AI/Backend 구분 없이 혼재
- 실제 로그 내용 확인 불가

### 개선 후:
- **실제 로그 메시지 내용** 테이블에 표시
- **AI 로그와 Backend 로그 완전 분리**
- 시간, 레벨, 서버, 메시지를 한눈에 확인
- 문제 발생시 빠른 원인 파악 가능

## 🚨 주의사항
1. `message.keyword` 필드가 없다면 `message` 필드 사용
2. 테이블 행이 너무 많으면 성능 저하 가능 → Size 제한 (10-20개)
3. 메시지가 길면 테이블 너비 조정 필요
4. 실시간 새로고침시 리소스 사용량 확인

## 📞 지원
- 설정 중 문제 발생시 Kibana UI에서 직접 수정
- Export한 대시보드 파일로 언제든 복원 가능
- 가이드 파일: `/elk-configs/LOG_MESSAGE_IMPROVEMENT_GUIDE.md`

---

## 📖 기존 대시보드 사용 가이드

### 대시보드 관리 스크립트
```bash
cd /Users/lsh/Documents/local/3tier-moongsan/14-YG-CLOUD/elk-configs/scripts

# 현재 대시보드를 파일로 Export
./manage-dashboards.sh export

# 기존 대시보드 Import
./manage-dashboards.sh import

# 개선된 대시보드 Import
./manage-dashboards.sh import improved

# 모든 대시보드 백업
./manage-dashboards.sh backup

# 현재 대시보드 목록 보기
./manage-dashboards.sh list

# 대시보드 상태 확인
./manage-dashboards.sh status
```

### 필터링 및 검색 예시
```kuery
# 특정 서버의 로그만 보기
server.keyword : "backend-server-1"

# 에러 레벨 로그만 보기
level.keyword : "ERROR"

# AI 서비스 로그만 보기
service.keyword : "ai"

# Backend 서비스 로그만 보기
service.keyword : "backend"

# 복합 조건
service.keyword : "ai" AND level.keyword : "ERROR"
```
