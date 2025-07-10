# APM 장애 복구 보고서 (2025-07-10)

## 📋 장애 개요

### 장애 발생 시간
- **시작**: 2025-07-09 18:47 UTC
- **종료**: 2025-07-10 02:09 UTC  
- **지속 시간**: 약 **7시간 22분**

### 영향 범위
- **AI Service** (FastAPI + Python APM Agent): APM 데이터 수집 중단
- **Backend Service** (Spring Boot + Java APM Agent): APM 데이터 수집 중단
- **APM 대시보드**: 실시간 모니터링 데이터 누락

## 🔍 장애 원인 분석

### 근본 원인
1. **Elasticsearch 인증 오류 (401)**
   ```
   precondition failed: error querying cluster_uuid: status_code=401
   ```

2. **APM Server 연결 실패**
   - APM Server가 Elasticsearch cluster_uuid 조회 실패
   - 인증 토큰/패스워드 불일치로 인한 지속적인 연결 재시도

3. **서비스 재시작 루프**
   - APM Server가 여러 차례 자동 재시작
   - 각 재시작마다 인증 실패로 인한 재시작 반복

### 핵심 로그 패턴
```
Jul 10 01:55:06 shared-elk apm-server[392]: {
  "log.level":"error",
  "@timestamp":"2025-07-10T01:55:06.515Z",
  "message":"precondition failed: error querying cluster_uuid: status_code=401",
  "service.name":"apm-server"
}
```

## 🛠️ 복구 과정

### 자동 복구 시점
- **2025-07-10 02:09:24 UTC**: APM Server 최종 재시작 후 정상화
- **복구 로그**:
  ```
  Jul 10 02:09:24 shared-elk apm-server[18329]: {
    "message":"no longer blocking ingestion as all precondition checks are now satisfied"
  }
  ```

### 현재 설정 확인
APM Server는 올바른 Elasticsearch 인증 정보를 사용하고 있음:
```yaml
output.elasticsearch:
  hosts: ["https://localhost:9200"]
  username: "elastic"
  password: "Dp8OiiQKmKg6wcxjK4P="
  ssl.verification_mode: none
```

## ✅ 복구 상태 검증

### 1. 서비스 상태
```bash
● apm-server.service - Elastic APM Server
   Active: active (running) since Thu 2025-07-10 05:20:13 UTC
   
● elasticsearch.service - Elasticsearch  
   Active: active (running) since Wed 2025-07-09 07:08:37 UTC
```

### 2. APM 데이터 수집 현황 (2025-07-10 05:23 기준)
| 인덱스 | 문서 수 | 크기 | 상태 |
|--------|---------|------|------|
| `traces-apm` | 86,809건 | 33.1MB | ✅ 정상 |
| `metrics-apm.app.backend_moongsan` | 7,766건 | 3.2MB | ✅ 정상 |
| `metrics-apm.transaction.1m` | 467건 | 226.3KB | ✅ 정상 |
| `metrics-apm.service_transaction.1m` | 376건 | 547KB | ✅ 정상 |
| `logs-apm.error` | 4건 | 178.1KB | ✅ 정상 |

### 3. 실시간 데이터 수집 확인
```bash
# 현재 진행 중인 APM 요청들 (정상 202 응답)
Jul 10 05:20:22 apm-server: "request accepted" "apm-agent-python/6.23.0 (ai-moongsan)"
Jul 10 05:20:28 apm-server: "request accepted" "apm-agent-java/1.50.0 (backend-moongsan)"
```

## 📊 영향 분석

### 데이터 손실 구간
- **2025-07-09 18:47** ~ **2025-07-10 02:09** 사이의 APM 데이터 누락
- 약 **7시간 22분간**의 트랜잭션, 에러, 성능 메트릭 손실

### 복구 후 정상화
- **AI Service**: Python APM Agent 정상 동작
- **Backend Service**: Java APM Agent 정상 동작  
- **Kibana APM UI**: 실시간 데이터 시각화 재개

## 🔧 예방 조치

### 1. 모니터링 강화
```bash
# APM Server 상태 모니터링 스크립트 추가 필요
systemctl status apm-server
journalctl -u apm-server --since "1 hour ago" | grep -i error
```

### 2. 인증 정보 검증
- Elasticsearch 패스워드 변경 시 APM Server 설정 동기화 필요
- 인증 실패 알림 설정 고려

### 3. 복구 자동화
- APM Server 헬스 체크 스크립트 작성
- 인증 오류 감지 시 자동 재시작 로직 구현

## 📝 향후 개선 사항

1. **모니터링 대시보드에 APM Server 상태 추가**
2. **Elasticsearch 인증 변경 시 APM 설정 자동 업데이트**
3. **APM 데이터 수집 중단 시 즉시 알림 설정**
4. **정기적인 APM 스택 헬스 체크 자동화**

## 📈 결론

- ✅ **장애 완전 복구**: APM Server 자동 재시작으로 인증 문제 해결
- ✅ **데이터 수집 재개**: AI/Backend 서비스 모두 정상 APM 데이터 전송 중
- ✅ **실시간 모니터링 복구**: Kibana APM UI에서 최신 데이터 확인 가능
- ⚠️ **예방 조치 필요**: 유사 장애 방지를 위한 모니터링 및 알림 체계 강화 권장

---
**보고서 작성**: 2025-07-10 05:24 UTC  
**작성자**: Infrastructure Team  
**상태**: 장애 완전 복구 ✅
