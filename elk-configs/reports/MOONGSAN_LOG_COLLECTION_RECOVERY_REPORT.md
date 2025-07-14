# 🔧 moongsan-log 수집 중단 문제 해결 완료!

## 📋 문제 요약

**증상**: 7/9 18:48 이후 moongsan-log (애플리케이션 로그) 데이터가 수집되지 않음  
**영향 범위**: 애플리케이션 로그 수집만 중단, APM 데이터는 정상 수집  
**해결 완료**: 2025-07-10 05:47 (KST 14:47)

## 🚨 문제 상황

### 발견된 증상
- Kibana 대시보드에 7/9 18:48 이후 새로운 로그가 표시되지 않음
- moongsan-logs-* 인덱스에 최신 데이터가 없는 것처럼 보임
- APM 데이터는 정상적으로 수집되고 있었음

### 사용자 혼란 포인트
- **APM vs 로그 수집의 차이점**: 
  - APM: 애플리케이션 성능 메트릭 (직접 Elasticsearch 전송)
  - 로그 수집: Filebeat → Logstash → Elasticsearch 파이프라인

## 🔍 문제 분석 과정

### 1. 서비스 상태 확인
```bash
# ✅ Elasticsearch: 정상 실행 중
sudo systemctl status elasticsearch

# ✅ Filebeat (각 서버): 정상 실행 중
ssh ubuntu@10.1.0.3 "sudo systemctl status filebeat"  # Backend 서버
ssh ubuntu@10.1.0.4 "sudo systemctl status filebeat"  # AI 서버

# ✅ 애플리케이션 컨테이너: 정상 실행 중
docker ps | grep moongsan  # ai-moongsan, be-moongsan 정상 실행
```

### 2. 로그 수집 파이프라인 진단
```bash
# ❌ Logstash: 실행 중이지만 Elasticsearch 연결 실패
sudo systemctl status logstash
```

### 3. 근본 원인 발견
**Logstash 로그에서 발견된 에러**:
```
[ERROR][logstash.outputs.elasticsearch] Encountered a retryable error 
{:code=>401, :url=>"https://localhost:9200/_bulk"}
"unable to authenticate user [elastic] for REST request"
```

**문제**: Elasticsearch 인증 설정이 변경되었지만 Logstash가 여전히 이전 패스워드를 사용하고 있었음

## ✅ 해결 방법

### 1. Elasticsearch 패스워드 재설정
```bash
sudo /usr/share/elasticsearch/bin/elasticsearch-reset-password -u elastic
# 새 패스워드: d*nevMQl9v4Cf6UhyAxW
```

### 2. Logstash 설정 업데이트
```bash
# /etc/logstash/conf.d/beats-input.conf 파일에서 패스워드 변경
sed -i 's/password => "<OLD_PASSWORD>"/password => "<NEW_PASSWORD>"/' \
  /etc/logstash/conf.d/beats-input.conf
```

### 3. Logstash 재시작
```bash
# 기존 프로세스 강제 종료 후 재시작
sudo kill -9 $(pgrep logstash)
sudo systemctl start logstash
```

### 4. 연결 복구 확인
```
[INFO] Restored connection to ES instance {:url=>"https://elastic:xxxxxx@localhost:9200/"}
[INFO] Elasticsearch version determined (8.18.3)
[INFO] Pipeline started {"pipeline.id"=>"main"}
[INFO] Starting server on port: 5044
```

## 📊 해결 결과

### 데이터 복구 현황
- **복구 완료 시간**: 2025-07-10 05:47:11.175Z
- **오늘 수집된 로그**: 107,647개 (계속 증가 중)
- **최신 로그 확인**: AI/Backend 서비스 모두 실시간 수집 재개

### 수집되는 로그 데이터
```json
// AI 서비스 로그
{
  "timestamp": "2025-07-10T05:47:11.175Z",
  "service": "ai-moongsan",
  "server": "ai",
  "message": "INFO: 35.191.219.241:52446 - \"GET /health HTTP/1.1\" 200 OK"
}

// Backend 서비스 로그
{
  "timestamp": "2025-07-10T05:47:09.328Z",
  "service": ["backend-api", "backend-service"],
  "server": "backend",
  "message": "2025-07-10T05:47:08.513Z DEBUG 7 --- [moongsan-backend] [io-8080-exec-25] o.s.security.web.FilterChain"
}
```

## 🔄 로그 수집 아키텍처 정리

### 현재 로그 수집 파이프라인
```
[AI 서버] /var/moongsan/log/ai_moongsan.log 
    ↓ (Filebeat)
[Backend 서버] /var/moongsan/log/be_moongsan.log 
    ↓ (Filebeat)
[ELK 서버] Logstash:5044 
    ↓ (Processing)
[ELK 서버] Elasticsearch:9200 
    ↓ (Index: moongsan-logs-YYYY.MM.dd)
[ELK 서버] Kibana:5601 대시보드
```

### APM vs 로그 수집 차이점
| 구분 | APM | 로그 수집 |
|------|-----|-----------|
| **데이터 타입** | 성능 메트릭, 트레이스 | 애플리케이션 로그 메시지 |
| **수집 방식** | Java Agent → 직접 APM Server | Filebeat → Logstash → Elasticsearch |
| **인덱스** | apm-* | moongsan-logs-* |
| **의존성** | APM Server 인증만 필요 | Logstash-Elasticsearch 인증 필요 |

## 🎯 향후 예방 조치

### 1. 모니터링 강화
```bash
# 로그 수집 파이프라인 상태 체크 스크립트 활용
./elk-configs/scripts/check-log-pipeline-health.sh
```

### 2. 인증 설정 변경 시 체크리스트
- [ ] Elasticsearch 패스워드 변경 시
- [ ] Logstash 설정 파일 업데이트
- [ ] Logstash 서비스 재시작
- [ ] APM Server 설정 확인 (필요시)
- [ ] Kibana 연결 확인

### 3. 자동화 개선 방안
- Logstash 설정에서 Elasticsearch 패스워드를 환경변수로 관리
- 인증 실패 시 자동 알림 설정
- 정기적인 로그 수집 상태 모니터링

## 🎉 결론

**문제**: Elasticsearch 인증 설정 변경 후 Logstash가 새 패스워드로 연결하지 못해 로그 수집 중단  
**해결**: Logstash 설정 업데이트 및 재시작으로 연결 복구  
**결과**: **실시간 로그 수집 완전 복구**, Kibana 대시보드에서 최신 데이터 확인 가능

이제 Kibana 대시보드에서 AI/Backend 서비스의 풍부한 로그 데이터를 활용한 모니터링이 가능합니다! 🎊

---

**💡 핵심 교훈**: 
- APM과 로그 수집은 서로 다른 파이프라인으로 독립적으로 작동
- Elasticsearch 인증 변경 시 연관된 모든 서비스(Logstash, APM Server 등) 재시작 필요
- 로그 수집 중단 시 단계별 진단: 서비스 상태 → 네트워크 연결 → 인증 문제 순으로 확인
