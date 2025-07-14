# 🚀 Phase 3: 고급 APM 구현 및 최적화 가이드

## 📋 목표
- 분산 추적(Distributed Tracing) 실전 검증
- Kibana APM 대시보드 커스터마이징 및 최적화  
- 성능 모니터링 알림 설정
- 실제 트랜잭션/비즈니스 로직 분석

## ✅ 현재 상태 확인

### APM 데이터 수집 현황
- ✅ **APM Server**: 정상 동작 (elk.moongsan.com:8200)
- ✅ **AI Service (ai-moongsan)**: Python APM Agent 정상 연결
- ✅ **Backend Service (backend-moongsan)**: Java APM Agent 정상 연결
- ✅ **Elasticsearch**: APM 데이터 인덱싱 정상

### 트레이스 데이터 생성 확인
```bash
# AI Service 트래픽 생성 (성공)
curl -X GET http://10.1.0.4:8100/health
curl -X GET http://10.1.0.4:8100/
curl -X POST http://10.1.0.4:8100/generation/description

# Backend Service 트래픽 생성 (성공)  
curl -X GET http://10.1.0.3:8080/health
curl -X GET http://10.1.0.3:8080/api/auth/status
```

## 🎯 Phase 3 실행 계획

### 1. 분산 추적 실전 검증
- [ ] AI ↔ Backend 간 호출 관계 분석
- [ ] Trace Context Propagation 확인
- [ ] 트랜잭션 흐름도 시각화

### 2. 커스텀 APM 대시보드 구축
- [ ] 서비스별 성능 메트릭 대시보드
- [ ] 에러율 및 응답시간 추이
- [ ] 비즈니스 KPI 연동 대시보드

### 3. 알림 및 모니터링 자동화
- [ ] 임계값 기반 알림 설정
- [ ] 성능 저하 자동 감지
- [ ] 장애 예측 및 대응 시나리오

### 4. 성능 최적화 분석
- [ ] 병목 지점 식별
- [ ] 데이터베이스 쿼리 성능 분석
- [ ] API 응답시간 최적화 제안

## 📊 Kibana APM 접속 정보
- **URL**: http://elk.moongsan.com:5601/app/apm
- **Services**: 
  - `ai-moongsan` (FastAPI/Python)
  - `backend-moongsan` (Spring Boot/Java)

## 🔍 실시간 모니터링 체크리스트

### APM 서비스 상태
```bash
# APM Server 상태 확인
sudo systemctl status apm-server

# 실시간 로그 모니터링
sudo journalctl -u apm-server -f

# Elasticsearch APM 인덱스 확인
curl -s 'http://127.0.0.1:9200/_cat/indices/*apm*'
```

### 트래픽 생성 스크립트
```bash
# AI Service 부하 테스트
for i in {1..10}; do
  curl -X GET http://10.1.0.4:8100/health
  curl -X POST http://10.1.0.4:8100/generation/description \
    -H 'Content-Type: application/json' \
    -d '{"url": "https://example.com/product"}'
  sleep 1
done

# Backend Service 부하 테스트  
for i in {1..10}; do
  curl -X GET http://10.1.0.3:8080/health
  curl -X GET http://10.1.0.3:8080/api/auth/status
  sleep 1
done
```

## 📈 Phase 3 성과 지표

### 기술적 성과
- [ ] **분산 추적 가시성**: 서비스 간 호출 관계 100% 추적
- [ ] **성능 메트릭 수집**: 응답시간, 처리량, 에러율 실시간 수집
- [ ] **대시보드 최적화**: 비즈니스 KPI 연동 실시간 대시보드

### 운영적 성과  
- [ ] **장애 감지 시간 단축**: 5분 → 1분 이내
- [ ] **성능 병목 식별**: 자동화된 분석 리포트
- [ ] **예방적 모니터링**: 임계값 기반 사전 알림

## 🔄 다음 단계 (Phase 4)
- OpenTelemetry 기반 통합 계측
- 멀티 클라우드 APM 확장
- AI 기반 성능 예측 모델

---

**작성일**: 2025-07-10  
**작성자**: Infrastructure Team  
**상태**: 진행 중
