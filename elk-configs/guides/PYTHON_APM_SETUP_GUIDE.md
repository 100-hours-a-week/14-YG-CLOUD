# 🐍 Python (FastAPI) APM Agent 설정 가이드

## 📋 개요

AI Service (FastAPI)에 Elastic APM Agent를 추가하여 애플리케이션 성능 모니터링을 구현합니다.

## 🚀 구현 단계

### 1️⃣ Python APM Agent 설치

```bash
# Dockerfile 또는 requirements.txt에 추가
pip install elastic-apm[flask]  # FastAPI 호환성을 위해 flask 포함
```

### 2️⃣ APM Agent 설정

**옵션 A: 환경변수 방식 (권장)**

```bash
export ELASTIC_APM_SERVICE_NAME="ai-moongsan"
export ELASTIC_APM_SERVER_URL="http://34.47.84.135:8200"
export ELASTIC_APM_ENVIRONMENT="production"
export ELASTIC_APM_SECRET_TOKEN=""  # 필요시 설정
```

**옵션 B: 코드 내 설정**

```python
from elasticapm.contrib.starlette import ElasticAPM, make_apm_client
from fastapi import FastAPI

# APM 클라이언트 생성
apm_config = {
    'SERVICE_NAME': 'ai-moongsan',
    'SERVER_URL': 'http://34.47.84.135:8200',
    'ENVIRONMENT': 'production',
}

apm = make_apm_client(apm_config)

# FastAPI 앱에 APM 미들웨어 추가
app = FastAPI()
app.add_middleware(ElasticAPM, client=apm)
```

### 3️⃣ 상세 계측 (선택사항)

```python
import elasticapm
from elasticapm import capture_span

# 함수 레벨 트레이싱
@capture_span('ai-inference')
def ai_inference_function(data):
    # AI 추론 로직
    pass

# 수동 스팬 생성
def some_function():
    with elasticapm.capture_span('database-query'):
        # 데이터베이스 쿼리 등
        pass
```

## 🐳 Docker 컨테이너 적용

### 방법 1: 환경변수로 설정 (권장)

```bash
docker run -d \
  -p 8100:8100 \
  -e ELASTIC_APM_SERVICE_NAME="ai-moongsan" \
  -e ELASTIC_APM_SERVER_URL="http://34.47.84.135:8200" \
  -e ELASTIC_APM_ENVIRONMENT="production" \
  himello/ai_moongsan:prod-c511992
```

### 방법 2: Docker Compose 설정

```yaml
version: '3.8'
services:
  ai-moongsan:
    image: himello/ai_moongsan:prod-c511992
    ports:
      - "8100:8100"
    environment:
      - ELASTIC_APM_SERVICE_NAME=ai-moongsan
      - ELASTIC_APM_SERVER_URL=http://34.47.84.135:8200
      - ELASTIC_APM_ENVIRONMENT=production
      - ELASTIC_APM_CAPTURE_BODY=errors
      - ELASTIC_APM_CAPTURE_HEADERS=true
```

## 🔧 테스트 및 확인

### 1. APM Agent 동작 확인

```python
# 애플리케이션 시작 시 APM 연결 테스트
import elasticapm

try:
    client = elasticapm.get_client()
    client.capture_message("APM Agent 연결 성공!")
    print("✅ APM Agent 정상 연결")
except Exception as e:
    print(f"❌ APM Agent 연결 실패: {e}")
```

### 2. 수동 이벤트 생성

```bash
curl -X POST http://10.1.0.4:8100/your-endpoint
```

### 3. Kibana APM UI 확인

```
http://34.47.84.135:5601/app/apm
```

## 📊 모니터링 포인트

- **트랜잭션**: API 요청별 응답시간
- **스팬**: AI 추론, DB 쿼리 등 개별 작업
- **에러**: 예외 및 스택 트레이스
- **메트릭**: CPU, 메모리, 처리량

## 🚨 주의사항

1. **성능 오버헤드**: APM은 약간의 성능 오버헤드가 있습니다
2. **네트워크**: AI 서버에서 APM 서버(8200포트)로 접근 가능해야 합니다
3. **샘플링**: 고부하 시 샘플링 비율 조정 필요

## 🔗 다음 단계

- [ ] Python 패키지 설치
- [ ] 코드 수정 또는 환경변수 설정
- [ ] 컨테이너 재시작
- [ ] Kibana에서 트레이스 확인
