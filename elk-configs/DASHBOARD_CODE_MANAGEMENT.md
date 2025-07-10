# 📊 뭉치면 산다 - Kibana 대시보드 코드 관리

## 🎯 현재 상태

### ✅ 완성된 대시보드
- **뭉치면 산다 - 실시간 서비스 모니터링**
  - 📈 시간별 로그 수 (Line Chart)
  - 📊 로그 레벨 분포 (Pie Chart)  
  - 🖥️ 서버별 로그 분포 (Bar Chart)
  - 📋 최근 서비스 로그 (Table)

### 📁 파일 구조
```
elk-configs/
├── dashboards/
│   └── moongsan-service-monitoring-dashboard.ndjson  # 메인 대시보드
├── scripts/
│   ├── manage-dashboards.sh                          # 대시보드 관리 스크립트
│   ├── install-famous-dashboards.sh                  # Sample 대시보드 설치
│   └── quick-dashboard-setup.sh                     # 빠른 설정 가이드
└── KIBANA_DASHBOARD_USAGE_GUIDE.md                  # 활용 가이드
```

## 🚀 대시보드 배포/관리 방법

### 1️⃣ 현재 대시보드 Export (코드화)
```bash
cd elk-configs/scripts
./manage-dashboards.sh export
```

### 2️⃣ 대시보드 Import (배포)
```bash
cd elk-configs/scripts
./manage-dashboards.sh import
```

### 3️⃣ 전체 대시보드 백업
```bash
./manage-dashboards.sh backup
```

### 4️⃣ 대시보드 상태 확인
```bash
./manage-dashboards.sh list
./manage-dashboards.sh status
```

## 🔧 개발 워크플로우

### A. 대시보드 수정 후 코드화
1. **Kibana UI에서 대시보드 편집**
   - http://elk.moongsan.com:5601/app/dashboards
   - "뭉치면 산다 - 실시간 서비스 모니터링" 선택
   - Edit 모드에서 시각화 수정

2. **수정 사항 코드로 Export**
   ```bash
   ./manage-dashboards.sh export
   ```

3. **Git에 커밋**
   ```bash
   git add elk-configs/dashboards/moongsan-service-monitoring-dashboard.ndjson
   git commit -m "feat: 대시보드 시각화 업데이트"
   ```

### B. 다른 환경에 배포
1. **Git에서 최신 코드 Pull**
   ```bash
   git pull origin main
   ```

2. **대시보드 Import**
   ```bash
   ./manage-dashboards.sh import
   ```

## 📊 대시보드 구성 요소

### 1. 📈 시간별 로그 수 (Line Chart)
```json
{
  "data_source": "logs-*",
  "visualization": "line",
  "x_axis": "@timestamp (Date Histogram)",
  "y_axis": "Count",
  "title": "📈 시간별 로그 수"
}
```

### 2. 📊 로그 레벨 분포 (Pie Chart)  
```json
{
  "data_source": "logs-*",
  "visualization": "pie",
  "slice_by": "level.keyword",
  "metric": "Count",
  "title": "📊 로그 레벨 분포"
}
```

### 3. 🖥️ 서버별 로그 분포 (Bar Chart)
```json
{
  "data_source": "logs-*",
  "visualization": "vertical_bar",
  "x_axis": "server.keyword",
  "y_axis": "Count",
  "title": "🖥️서버별 로그 분포"
}
```

### 4. 📋 최근 서비스 로그 (Table)
```json
{
  "data_source": "logs-*", 
  "visualization": "table",
  "columns": ["level.keyword", "server.keyword", "@timestamp", "Count"],
  "title": "📋 최근 서비스 로그"
}
```

## 🎨 대시보드 커스터마이징

### 새로운 패널 추가
1. **Kibana UI에서 Edit 모드 진입**
2. **Add panel → Create visualization**
3. **원하는 시각화 타입 선택**
4. **데이터 소스: `logs-*` 선택**
5. **필드 설정 후 Save**
6. **Export로 코드화**

### 기존 패널 수정
1. **Edit 모드에서 패널 클릭**
2. **Edit visualization 선택**
3. **설정 변경 후 Save**
4. **Export로 코드화**

## 🔄 CI/CD 연동 방안

### 자동 배포 스크립트 예시
```bash
#!/bin/bash
# deploy-dashboard.sh

echo "🚀 대시보드 자동 배포 시작..."

# 1. 최신 코드 Pull
git pull origin main

# 2. 대시보드 Import
cd elk-configs/scripts
./manage-dashboards.sh import

# 3. 상태 확인
./manage-dashboards.sh status

echo "✅ 대시보드 배포 완료!"
```

### GitHub Actions 예시
```yaml
name: Deploy Dashboard
on:
  push:
    paths:
      - 'elk-configs/dashboards/**'
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Deploy Dashboard
        run: |
          cd elk-configs/scripts
          ./manage-dashboards.sh import
```

## 🔒 보안 고려사항

### 인증 정보 관리
```bash
# 환경변수로 관리
export KIBANA_USERNAME="moongsan_admin"
export KIBANA_PASSWORD="moongsan123"
export KIBANA_URL="http://elk.moongsan.com:5601"

# 스크립트에서 환경변수 사용
USERNAME=${KIBANA_USERNAME:-"moongsan_admin"}
```

### 접근 권한 제어
- Kibana Role-based access control 설정
- 민감한 로그 필드 마스킹
- 대시보드별 사용자 권한 분리

## 📈 모니터링 및 알림

### 대시보드 성능 모니터링
```bash
# 대시보드 로딩 시간 체크
curl -w "@curl-format.txt" -s -o /dev/null \
  "http://elk.moongsan.com:5601/app/dashboards#/view/ceebc166-d33d-40e7-aad4-91e73c2d6c6e"
```

### 자동 알림 설정
- 에러율 급증 시 Slack/Email 알림
- 대시보드 접속 실패 시 알림
- 데이터 수집 중단 시 알림

---

## 🎯 다음 개발 계획

### 단기 (1주일)
- [ ] AI 서비스 전용 대시보드 추가
- [ ] API 엔드포인트별 성능 분석 패널
- [ ] 실시간 알림 시스템 구축

### 중기 (1개월)  
- [ ] 비즈니스 메트릭 대시보드
- [ ] 사용자 행동 분석 대시보드
- [ ] 자동화된 리포팅 시스템

### 장기 (3개월)
- [ ] Machine Learning 기반 이상 탐지
- [ ] 예측 분석 대시보드
- [ ] 통합 모니터링 솔루션

---

> 💡 **문의**: 대시보드 관련 문제가 있으면 `manage-dashboards.sh status`로 상태를 먼저 확인하세요.
> 
> 🔗 **접속**: http://elk.moongsan.com:5601/app/dashboards
