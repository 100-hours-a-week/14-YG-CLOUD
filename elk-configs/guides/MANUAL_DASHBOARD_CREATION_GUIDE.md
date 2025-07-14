# 🛠️ 뭉치면 산다 대시보드 수동 생성 가이드

## 🚨 현재 상황
- Kibana API Import가 "Empty reply from server" 에러로 실패
- Sample Data 대시보드 3개만 존재
- 커스텀 대시보드 자동 생성 실패

## 🎯 해결 방법: UI에서 직접 대시보드 복제

### 1단계: Kibana 대시보드 페이지 접속
```
URL: http://elk.moongsan.com:5601/app/dashboards
로그인: moongsan_admin / moongsan123
```

### 2단계: [Logs] Web Traffic 대시보드 복제

1. **대시보드 열기**
   - `[Logs] Web Traffic` 클릭하여 대시보드 열기

2. **복제하기**
   - 우상단 **Share** 버튼 클릭
   - **Clone** 선택
   - 새 이름: `🖥️ 뭉치면 산다 - 웹 트래픽 분석`
   - **Clone dashboard** 클릭

3. **편집하기**
   - 복제된 대시보드에서 **Edit** 버튼 클릭
   - 각 패널의 제목을 뭉치면 산다에 맞게 수정:
     - `Unique Visitors vs. Average Bytes` → `🚀 뭉치면 산다 - 사용자별 트래픽`
     - `Heatmap - Visits by Time of Day` → `🌡️ 뭉치면 산다 - 시간대별 접속 히트맵`
     - `Visitors by Country` → `🌍 뭉치면 산다 - 국가별 접속 현황`

### 3단계: [eCommerce] Revenue Dashboard 복제

1. **대시보드 열기**
   - `[eCommerce] Revenue Dashboard` 클릭

2. **복제하기**
   - **Share** → **Clone**
   - 새 이름: `🛒 뭉치면 산다 - 주문 분석`

3. **편집하기**
   - 각 패널 제목 수정:
     - `Revenue` → `💰 뭉치면 산다 - 일별 매출`
     - `Sold Products per Day` → `📦 뭉치면 산다 - 일별 주문 상품수`
     - `Sales by Gender` → `👥 뭉치면 산다 - 성별 주문 분포`

### 4단계: 실제 서비스 로그 대시보드 생성

1. **새 대시보드 생성**
   - 대시보드 목록에서 **Create dashboard** 클릭
   - 제목: `🖥️ 뭉치면 산다 - 실시간 서비스 로그`

2. **패널 추가**
   - **Add panel** → **Create visualization**
   - **Discover** 선택

3. **데이터 소스 설정**
   - **Data view**: `logs-*` (Moongsan Logs) 선택
   - **Time field**: `@timestamp`

4. **시각화 설정**
   - **Add filter**: `server.keyword : "backend"` (백엔드 로그만)
   - **Time range**: Last 1 hour
   - **Refresh**: Every 30 seconds

### 5단계: 추가 시각화 생성

#### A. 로그 레벨별 분포 (파이 차트)
1. **Add panel** → **Create visualization** → **Pie**
2. **Data view**: `logs-*`
3. **Buckets**:
   - **Split slices**: `Terms` → `log.level.keyword`
4. **Title**: `📊 뭉치면 산다 - 로그 레벨 분포`

#### B. 시간별 로그 수 (라인 차트)
1. **Add panel** → **Create visualization** → **Line**
2. **Data view**: `logs-*`
3. **Buckets**:
   - **X-axis**: `Date Histogram` → `@timestamp` → `Auto`
   - **Y-axis**: `Count`
4. **Title**: `📈 뭉치면 산다 - 시간별 로그 수`

#### C. 서버별 로그 분포 (세로 막대 차트)
1. **Add panel** → **Create visualization** → **Vertical bar**
2. **Data view**: `logs-*`
3. **Buckets**:
   - **X-axis**: `Terms` → `server.keyword`
   - **Y-axis**: `Count`
4. **Title**: `🖥️ 뭉치면 산다 - 서버별 로그 분포`

## 🎨 대시보드 꾸미기

### 색상 테마 설정
1. **Edit** 모드에서 **Options** 클릭
2. **Use margins**: 체크
3. **Color mapping**: 일관된 색상 사용

### 자동 새로고침 설정
1. 대시보드 우상단 시계 아이콘 클릭
2. **Refresh**: `30 seconds` 선택
3. **Apply** 클릭

### 시간 범위 설정
1. 대시보드 우상단 달력 아이콘 클릭
2. **Quick**: `Last 1 hour` 선택 (실시간 모니터링용)
3. **Apply** 클릭

## 🔧 문제 해결 방법

### 데이터가 보이지 않는 경우
1. **Index pattern 확인**
   - Stack Management → Index Patterns
   - `logs-*` 패턴이 있는지 확인

2. **시간 범위 확장**
   - 달력 아이콘 → Last 7 days 선택

3. **필터 제거**
   - 모든 필터를 임시로 제거하고 데이터 확인

### API 에러 해결 (개발자용)
```bash
# Kibana 재시작
sudo systemctl restart kibana

# Elasticsearch 상태 확인
curl -u "moongsan_admin:moongsan123" "http://elk.moongsan.com:9200/_cluster/health"

# Kibana 로그 확인
sudo tail -f /var/log/kibana/kibana.log
```

## 📋 완료 체크리스트

- [ ] Sample 대시보드 3개 복제 완료
- [ ] 뭉치면 산다 브랜드명으로 패널 제목 변경
- [ ] 실제 서비스 로그 대시보드 생성
- [ ] 시간별/레벨별/서버별 시각화 추가
- [ ] 자동 새로고침 설정 (30초)
- [ ] 적절한 시간 범위 설정 (1시간)

## 🎯 최종 목표

생성될 대시보드 목록:
1. **🖥️ 뭉치면 산다 - 웹 트래픽 분석** (Sample 데이터 기반)
2. **🛒 뭉치면 산다 - 주문 분석** (Sample 데이터 기반)
3. **✈️ 뭉치면 산다 - 성능 분석** (Flight 샘플 응용)
4. **🖥️ 뭉치면 산다 - 실시간 서비스 로그** (실제 로그 데이터)

---

> 💡 **팁**: UI에서 수동으로 생성한 후, 나중에 Export하여 코드로 관리할 수 있습니다.
