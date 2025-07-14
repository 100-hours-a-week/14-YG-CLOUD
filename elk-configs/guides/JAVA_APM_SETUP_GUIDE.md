# ☕ Java (Spring Boot) APM Agent 설정 가이드

## 📋 개요

Backend Service (Spring Boot)에 Elastic APM Java Agent를 추가하여 애플리케이션 성능 모니터링을 구현합니다.

## 🚀 구현 단계

### 1️⃣ Java APM Agent 다운로드

```bash
# APM Java Agent JAR 파일 다운로드 (8.18.3 버전)
curl -L -o elastic-apm-agent.jar https://repo1.maven.org/maven2/co/elastic/apm/elastic-apm-agent/1.50.0/elastic-apm-agent-1.50.0.jar
```

### 2️⃣ APM Agent 설정

**옵션 A: 환경변수 방식 (권장)**

```bash
export ELASTIC_APM_SERVICE_NAME="backend-moongsan"
export ELASTIC_APM_SERVER_URLS="http://34.47.84.135:8200"
export ELASTIC_APM_ENVIRONMENT="production"
export ELASTIC_APM_SECRET_TOKEN=""
export ELASTIC_APM_LOG_LEVEL="INFO"
```

**옵션 B: JVM 시스템 프로퍼티**

```bash
java -javaagent:elastic-apm-agent.jar \
     -Delastic.apm.service_name=backend-moongsan \
     -Delastic.apm.server_urls=http://34.47.84.135:8200 \
     -Delastic.apm.environment=production \
     -jar your-application.jar
```

### 3️⃣ Spring Boot 애플리케이션 설정

**application.yml 추가 설정 (선택사항)**

```yaml
elastic:
  apm:
    service-name: backend-moongsan
    server-urls: http://34.47.84.135:8200
    environment: production
    log-level: INFO
    capture-body: errors
    capture-headers: true
```

### 4️⃣ 상세 계측 (선택사항)

```java
// 수동 트레이싱이 필요한 경우
import co.elastic.apm.api.ElasticApm;
import co.elastic.apm.api.Transaction;
import co.elastic.apm.api.Span;

@Service
public class SomeService {
    
    @Transactional
    public void businessMethod() {
        // 커스텀 스팬 생성
        Span span = ElasticApm.currentSpan()
            .startSpan("database", "query", "mysql");
        try {
            // 비즈니스 로직
        } finally {
            span.end();
        }
    }
}
```

## 🐳 Docker 컨테이너 적용

### 방법 1: Dockerfile에 APM Agent 추가

```dockerfile
FROM openjdk:17-jre-slim

# APM Agent 다운로드
ADD https://repo1.maven.org/maven2/co/elastic/apm/elastic-apm-agent/1.50.0/elastic-apm-agent-1.50.0.jar /elastic-apm-agent.jar

# 애플리케이션 JAR 복사
COPY your-app.jar /app.jar

# APM Agent와 함께 실행
ENTRYPOINT ["java", "-javaagent:/elastic-apm-agent.jar", "-jar", "/app.jar"]
```

### 방법 2: Docker Run 명령어

```bash
docker run -d \
  -p 8080:8080 \
  -e ELASTIC_APM_SERVICE_NAME="backend-moongsan" \
  -e ELASTIC_APM_SERVER_URLS="http://34.47.84.135:8200" \
  -e ELASTIC_APM_ENVIRONMENT="production" \
  -v /path/to/elastic-apm-agent.jar:/elastic-apm-agent.jar \
  --entrypoint="java" \
  your-image:tag \
  -javaagent:/elastic-apm-agent.jar \
  -jar /app.jar
```

### 방법 3: Docker Compose 설정

```yaml
version: '3.8'
services:
  backend-moongsan:
    image: himello/be_moongsan:prod-cf79652
    ports:
      - "8080:8080"
    environment:
      - ELASTIC_APM_SERVICE_NAME=backend-moongsan
      - ELASTIC_APM_SERVER_URLS=http://34.47.84.135:8200
      - ELASTIC_APM_ENVIRONMENT=production
      - ELASTIC_APM_LOG_LEVEL=INFO
    volumes:
      - ./elastic-apm-agent.jar:/elastic-apm-agent.jar
    command: >
      java -javaagent:/elastic-apm-agent.jar
           -jar /app.jar
```

## 🔧 테스트 및 확인

### 1. APM Agent 동작 확인

Spring Boot 시작 로그에서 다음 메시지 확인:
```
[elastic-apm-agent] INFO co.elastic.apm.agent.impl.ElasticApmAgent - Elastic APM Agent connected to APM Server
```

### 2. 수동 이벤트 생성

```bash
# Backend API 테스트
curl -X GET http://10.1.0.3:8080/health
curl -X GET http://10.1.0.3:8080/api/your-endpoint
```

### 3. Kibana APM UI 확인

```
http://34.47.84.135:5601/app/apm
```

## 📊 모니터링 포인트

- **HTTP 요청**: REST API 엔드포인트별 응답시간
- **데이터베이스**: SQL 쿼리 성능 및 커넥션 풀
- **Redis**: 캐시 액세스 패턴
- **JVM**: 가비지 컬렉션, 메모리 사용량
- **트랜잭션**: `@Transactional` 메서드 성능
- **에러**: 예외 및 스택 트레이스

## 🚨 주의사항

1. **성능 오버헤드**: APM Agent는 약 3-5%의 성능 오버헤드가 있습니다
2. **네트워크**: Backend 서버에서 APM 서버(8200포트)로 접근 가능해야 합니다
3. **메모리**: APM Agent가 약 50-100MB 추가 메모리를 사용합니다
4. **샘플링**: 고부하 시 샘플링 비율 조정 필요

## 🔗 다음 단계

- [ ] APM Java Agent JAR 다운로드
- [ ] Dockerfile 또는 환경변수 설정
- [ ] 컨테이너 재시작
- [ ] Kibana에서 Spring Boot 트레이스 확인
- [ ] AI ↔ Backend 분산 추적 확인
