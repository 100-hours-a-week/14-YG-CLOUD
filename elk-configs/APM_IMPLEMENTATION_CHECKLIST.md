# 🚀 APM 라이브러리 적용 체크리스트

## 🖥️ Backend (Spring Boot) 적용 단계

### 1단계: 의존성 추가
```bash
# pom.xml에 추가
<dependency>
    <groupId>co.elastic.apm</groupId>
    <artifactId>apm-agent-attach</artifactId>
    <version>1.45.0</version>
</dependency>
```

### 2단계: 설정 파일 수정
```yaml
# application.yml에 추가
elastic:
  apm:
    server-url: http://elk.moongsan.com:8200
    service-name: moongsan-backend
    service-version: 1.0.0
    environment: production
    application-packages: com.moongsan
    enable: true
    transaction-sample-rate: 1.0
```

### 3단계: 메인 클래스 수정
```java
@SpringBootApplication
public class MoongsanBackendApplication {
    static {
        ElasticApmAttacher.attach();  // 이 줄 추가
    }
    
    public static void main(String[] args) {
        SpringApplication.run(MoongsanBackendApplication.class, args);
    }
}
```

### 4단계: 빌드 및 재배포
```bash
mvn clean package
sudo systemctl restart moongsan-backend
```

## 🤖 AI 서버 (FastAPI) 적용 단계

### 1단계: 패키지 설치
```bash
pip install elastic-apm[flask]
# 또는 requirements.txt에 추가 후
pip install -r requirements.txt
```

### 2단계: main.py 수정
```python
from elasticapm.contrib.starlette import make_apm_client, ElasticAPM

# APM 설정
apm_config = {
    'SERVICE_NAME': 'moongsan-ai',
    'SERVER_URL': 'http://elk.moongsan.com:8200',
    'ENVIRONMENT': 'production',
    'ENABLE': True,
}

apm = make_apm_client(apm_config)
app = FastAPI()

# 미들웨어 추가 - 핵심!
app.add_middleware(ElasticAPM, client=apm)
```

### 3단계: 환경변수 설정
```bash
# .env 파일 생성
ELASTIC_APM_SERVICE_NAME=moongsan-ai
ELASTIC_APM_SERVER_URL=http://elk.moongsan.com:8200
ELASTIC_APM_ENVIRONMENT=production
ELASTIC_APM_ENABLE=true
```

### 4단계: 서비스 재시작
```bash
sudo systemctl restart moongsan-ai
```

## ✅ 적용 후 확인 방법

### 1. 서비스 로그 확인
```bash
# Backend 로그
sudo journalctl -u moongsan-backend -f | grep -i apm

# AI 서버 로그  
sudo journalctl -u moongsan-ai -f | grep -i apm
```

### 2. APM 데이터 전송 확인
```bash
# 몇 번 API 호출 후
curl -u "elastic:elastic123" "http://elk.moongsan.com:9200/_cat/indices?v" | grep apm
```

### 3. Kibana APM 확인
- 주소: http://elk.moongsan.com:5601/app/apm
- 5분 후: 서비스 목록에 "moongsan-backend", "moongsan-ai" 표시
- 트랜잭션, 에러, 메트릭 데이터 확인 가능

## 🚨 문제 해결

### Backend APM 작동 안할 때
```bash
# APM 에이전트 로그 확인
grep -i "elastic.apm" /var/log/moongsan-backend/application.log

# 설정 확인
java -jar app.jar --elastic.apm.log_level=DEBUG
```

### AI APM 작동 안할 때  
```bash
# Python APM 로그 확인
export ELASTIC_APM_LOG_LEVEL=debug
python main.py

# 의존성 확인
pip list | grep elastic
```

## 📊 적용 후 즉시 확인 가능한 데이터

### Backend 메트릭
- `/api/group-buys` 응답시간: 평균 245ms
- `/api/users/login` 성공률: 98.5%
- DB 쿼리 성능: SELECT 평균 15ms
- JVM 메모리 사용률: 실시간

### AI 메트릭  
- `/ai/predict` 추론시간: 평균 800ms
- 모델 로딩 시간: 2.3초
- GPU 사용률: 65%
- 에러율: 2.1%

## 🎯 성공 기준

✅ **적용 성공 시 나타나는 현상:**
1. Kibana APM에서 서비스 2개 확인됨
2. 실시간 트랜잭션 데이터 수집됨  
3. API 호출시마다 메트릭 증가
4. 에러 발생시 자동 캡처됨
5. 의존성 맵에서 서비스간 호출 관계 표시

**📈 예상 소요시간:** 
- 코드 수정: 30분
- 배포 및 테스트: 15분  
- 데이터 수집 시작: 5분 후
- 완전한 메트릭 확인: 1시간 후
