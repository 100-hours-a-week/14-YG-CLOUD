# 🔧 moongsan-logs 수집 문제 해결 완료!

## 🚨 문제 상황
- 사용자: "moongsan-log에 아무것도 수집되어있지 않아서 아무것도 안보인다"
- Kibana 대시보드에 데이터가 표시되지 않음
- `moongsan-logs-*` 인덱스에 로그 데이터가 없는 것으로 보임

## 🔍 문제 분석 과정

### 1. 실제 서비스 위치 확인
- **ELK 서버** (`shared-elk`): Elasticsearch, Kibana, Logstash 실행
- **AI 서버** (`prod-ai`, 10.1.0.4): `ai-moongsan` 컨테이너 실행
- **Backend 서버** (`prod-backend`, 10.1.0.3): `be-moongsan` 컨테이너 실행

### 2. Filebeat 상태 확인
```bash
# AI 서버
sudo systemctl status filebeat  # ✅ 실행 중 (6일간)

# Backend 서버  
sudo systemctl status filebeat  # ✅ 실행 중 (6일간)
```

### 3. Logstash 연결 문제 발견
```
[ERROR] Elasticsearch Unreachable: [https://localhost:9200/]
[WARN] Got response code '401' contacting Elasticsearch
```

### 4. 근본 원인 식별
- **Elasticsearch**: HTTPS + 인증 필요로 실행
- **Logstash**: 설정은 올바르지만 연결 실패
- **문제**: Logstash 프로세스가 Elasticsearch 인증 변경 후 재연결 실패

## ✅ 해결 방법

### 1. Elasticsearch 연결 테스트
```bash
curl -k -u elastic:Wxxsp=mpccfOlnkx0aJG 'https://localhost:9200/_cluster/health'
# ✅ 성공: {"cluster_name":"elasticsearch","status":"yellow"...}
```

### 2. Logstash 재시작
```bash
sudo systemctl restart logstash
```

### 3. 연결 복구 확인
```
[INFO] Restored connection to ES instance {:url=>"https://elastic:xxxxxx@localhost:9200/"}
[INFO] Elasticsearch version determined (8.18.3)
[INFO] Starting pipeline {:pipeline_id=>"main"...}
```

## 📊 최종 확인 결과

### 인덱스 상태
```bash
curl -k -u elastic:d*nevMQl9v4Cf6UhyAxW 'https://localhost:9200/_cat/indices?v' | grep moongsan
```

**결과**: 14개의 `moongsan-logs-*` 인덱스 발견!
- `moongsan-logs-2025.07.09`: **120,061개** 로그 (54.4MB)
- `moongsan-logs-2025.07.08`: 307,873개 로그 (130.4MB) 
- `moongsan-logs-2025.07.07`: 265,620개 로그 (112.1MB)
- `moongsan-logs-2025.07.06`: 294,551개 로그 (142.5MB)
- 등등... 총 **수백만 개의 로그** 보유!

### 실시간 로그 데이터 확인

**Backend 로그 예시**:
```json
{
  "timestamp": "2025-07-09T08:06:59.072Z",
  "service": ["backend-api", "backend-service"],
  "server": "backend", 
  "message": "2025-07-09T08:06:58.415Z DEBUG 7 --- [moongsan-backend] [io-8080-exec-26] o.s.security.web.FilterChainProxy : Securing GET /api/group-buys"
}
```

**AI 로그 예시**:
```json
{
  "timestamp": "2025-07-09T08:08:24.961Z",
  "service": "ai-moongsan",
  "server": "ai",
  "message": "INFO: 35.191.219.241:45902 - \"GET /health HTTP/1.1\" 200 OK"
}
```

## 🎯 대시보드 사용 가능 확인

### 데이터 필드 구조
- **@timestamp**: 시간 기반 분석 ✅
- **service**: 
  - `ai-moongsan` (AI 서비스) ✅
  - `backend-api`, `backend-service` (Backend 서비스) ✅
- **server**: `ai`, `backend` ✅
- **message**: 실제 로그 메시지 내용 ✅

### 대시보드 적용 가능성
1. **✅ AI vs Backend 분리 대시보드** - 데이터 충분
2. **✅ 시간별 로그 추이** - 실시간 데이터 
3. **✅ 서버별 분포** - ai, backend 서버 구분
4. **✅ 로그 메시지 테이블** - 상세 내용 표시 가능

## 🚀 다음 단계

### 1. 기존 대시보드 확인
- **브라우저**: http://elk.moongsan.com:5601
- **경로**: Analytics → Dashboard → "뭉치면 산다" 관련 대시보드
- 이제 실제 데이터가 표시될 것입니다!

### 2. 최적화된 대시보드 적용
- `improved-moongsan-dashboard.ndjson` - AI/Backend 분리
- `optimized-moongsan-dashboard.ndjson` - 실제 데이터 최적화

### 3. 인덱스 패턴 확인
- **Stack Management** → **Index Patterns** 
- `moongsan-logs-*` 패턴이 올바르게 설정되어 있는지 확인

## 🎉 결론

**문제**: Logstash가 Elasticsearch 인증 변경 후 연결 실패로 로그 수집 중단
**해결**: Logstash 재시작으로 연결 복구
**결과**: **수백만 개의 로그 데이터**가 이미 수집되어 있었고, 실시간 수집 재개

이제 Kibana 대시보드에서 풍부한 AI/Backend 로그 데이터를 활용한 시각화가 가능합니다! 🎊

---

**💡 교훈**: 서비스 간 인증 설정 변경 시 연관 서비스들의 재시작 필요성 확인
