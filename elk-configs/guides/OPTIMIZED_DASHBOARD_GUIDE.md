# 🎯 실제 데이터 최적화 대시보드 적용 가이드

## 📊 현재 상황 분석

### 실제 로그 데이터 구조
```json
{
  "@timestamp": "2025-07-03T01:26:51.000Z",
  "server": "shared-elk",
  "service": "ai-moongsan",
  "message": "AI service started successfully",
  "log_type": "application"
}
```

### 🔍 발견된 주요 사항
1. **서비스 필드**: `service: ai-moongsan`만 존재 (Backend 로그 없음)
2. **레벨 필드**: `level` 필드가 없어서 로그 레벨 분류 불가
3. **로그 타입**: `log_type` 필드 존재 (`application` 등)
4. **서버 정보**: `server` 필드로 어떤 서버에서 온 로그인지 확인 가능

## 🎨 최적화된 대시보드 설계

### 새로운 대시보드 구성요소
1. **📈 시간별 로그 수 추이** - Area Chart
2. **🖥️ 서버별 로그 분포** - Pie Chart  
3. **🤖 AI 서비스 로그 상세 내용** - Data Table
4. **📊 로그 타입별 분포** - Horizontal Bar Chart
5. **📈 서버별 시간대별 로그 수** - Multi-line Chart

### 제거된 구성요소
- ❌ Backend 로그 테이블 (데이터 없음)
- ❌ 로그 레벨 분포 차트 (`level` 필드 없음)
- ❌ AI vs Backend 비교 차트 (Backend 데이터 없음)

## 🚀 대시보드 Import 방법

### 1. Kibana 웹 UI를 통한 Import (권장)

1. **Kibana 접속**: http://elk.moongsan.com:5601
2. **Stack Management** → **Saved Objects** 클릭
3. **Import** 버튼 클릭
4. 파일 선택: `optimized-moongsan-dashboard.ndjson`
5. **Import** 실행
6. **Analytics** → **Dashboard** → **뭉치면 산다 - 실제 데이터 최적화 대시보드** 선택

### 2. 파일 위치
```bash
# 로컬 파일
/Users/lsh/Documents/local/3tier-moongsan/14-YG-CLOUD/elk-configs/dashboards/optimized-moongsan-dashboard.ndjson

# 서버 복사된 파일
lsh@elk.moongsan.com:/tmp/optimized-moongsan-dashboard.ndjson
```

### 3. 수동 Import 단계별 가이드

1. **브라우저에서 Kibana 열기**
   - URL: http://elk.moongsan.com:5601
   - 왼쪽 메뉴에서 **Management** (또는 햄버거 메뉴 → **Stack Management**)

2. **Saved Objects 관리**
   - **Kibana** → **Saved Objects** 클릭
   - 상단의 **Import** 버튼 클릭

3. **파일 Import**
   - **Select file to import** 클릭
   - `optimized-moongsan-dashboard.ndjson` 파일 선택
   - **Import** 버튼 클릭

4. **대시보드 확인**
   - 왼쪽 메뉴 **Analytics** → **Dashboard**
   - **뭉치면 산다 - 실제 데이터 최적화 대시보드** 클릭

## 📋 대시보드 특징

### 🎯 실제 데이터에 최적화된 시각화

1. **시간별 로그 추이**: 전체적인 로그 발생 패턴 파악
2. **서버별 분포**: 어떤 서버에서 로그가 많이 발생하는지 확인
3. **로그 상세 테이블**: 실제 로그 메시지 내용을 시간순으로 확인
4. **로그 타입 분포**: `application`, `system` 등 로그 유형별 분석
5. **서버별 시간대별 추이**: 서버별로 시간에 따른 로그 발생 패턴 비교

### 🔧 데이터 필드 활용

- **@timestamp**: 시간 기반 분석
- **server.keyword**: 서버별 그룹화
- **service.keyword**: 서비스 식별 (현재는 ai-moongsan만)
- **message.keyword**: 실제 로그 메시지 표시
- **log_type.keyword**: 로그 유형별 분류

## 🎨 대시보드 개선 방향

### 단기 개선
1. ✅ Backend 로그 데이터 없는 상황에 맞게 대시보드 재설계
2. ✅ 실제 존재하는 필드들(`server`, `log_type`, `message`)로 시각화 구성
3. ✅ 로그 메시지 내용이 잘 보이도록 테이블 최적화

### 장기 개선 (향후 Backend 로그 추가시)
1. Backend 로그 수집 설정 추가
2. AI vs Backend 로그 비교 차트 복원
3. 로그 레벨 필드 추가시 에러/경고 분석 차트 추가
4. 서비스별 필터 컨트롤 추가

## 🎉 대시보드 사용법

### 📊 기본 사용
1. **시간 범위 설정**: 우상단 시간 선택기로 분석 기간 설정
2. **자동 새로고침**: 실시간 모니터링을 위한 자동 새로고침 활성화
3. **드릴다운**: 차트 클릭으로 상세 분석 가능

### 🔍 상세 분석
1. **로그 상세 테이블**: 특정 시간대의 로그 메시지 확인
2. **서버별 필터링**: 특정 서버의 로그만 확인
3. **로그 타입별 분석**: application, system 로그 구분 분석

## 📈 모니터링 포인트

### 🚨 주의사항
1. **로그 급증**: 특정 시간대 로그 수 급격한 증가
2. **서버별 불균형**: 특정 서버에서만 과도한 로그 발생
3. **메시지 패턴**: 오류나 경고 메시지 패턴 모니터링

### 📋 정기 점검
1. **일일 로그 수**: 평소 대비 로그 발생량 변화
2. **서버 상태**: 서버별 로그 발생 패턴 정상성
3. **서비스 안정성**: AI 서비스 관련 로그 메시지 정상성

---

💡 **TIP**: 대시보드를 즐겨찾기에 추가하여 빠른 접근이 가능하며, URL을 북마크해두면 팀원들과 공유하기 편리합니다.
