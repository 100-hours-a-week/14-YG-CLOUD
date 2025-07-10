# 🎯 실제 레포지토리 분석 기반 APM 추가 가이드

## 📋 레포지토리 분석 결과

### 🤖 AI 서버 (`14-YG-AI`)
- **프레임워크**: FastAPI
- **메인 파일**: `/v1/app/main.py`
- **의존성 파일**: `/v1/requirements.txt`
- **포트**: 8100
- **현재 구조**:
  ```python
  from fastapi import FastAPI
  app = FastAPI(title="generate_description_server", version="0.2.1")
  ```

### 🖥️ Backend 서버 (`14-YG-BE`)
- **프레임워크**: Spring Boot 3.4.5 (Java 21)
- **빌드 도구**: Gradle
- **메인 클래스**: `com.moogsan.moongsan_backend.MoongsanBackendApplication`
- **설정 파일**: `application.properties`
- **현재 구조**:
  ```java
  @SpringBootApplication
  @EnableScheduling
  public class MoongsanBackendApplication {
      public static void main(String[] args) {
          SpringApplication.run(MoongsanBackendApplication.class, args);
      }
  }
  ```

## 🚀 APM 라이브러리 추가 방법

### 🤖 1. AI 서버 APM 추가

#### Step 1: requirements.txt 수정
```bash
# /Users/lsh/Documents/GitHub/14-YG-AI/v1/requirements.txt에 추가
elastic-apm[flask]==6.18.1
```

#### Step 2: main.py 수정
```python
# /Users/lsh/Documents/GitHub/14-YG-AI/v1/app/main.py
from fastapi import FastAPI
from elasticapm.contrib.starlette import make_apm_client, ElasticAPM
from api import generate_post

# APM 설정
apm_config = {
    'SERVICE_NAME': 'moongsan-ai',
    'SERVICE_VERSION': '0.2.1',
    'SERVER_URL': 'http://elk.moongsan.com:8200',
    'ENVIRONMENT': 'production',
    'CAPTURE_BODY': 'all',
    'CAPTURE_HEADERS': True,
    'TRANSACTION_SAMPLE_RATE': 1.0,
    'ENABLE': True,
}

apm = make_apm_client(apm_config)

app = FastAPI(
    title="generate_description_server",
    version="0.2.1",
    description="URL to POST(상품 공동구매 주최글 작성 자동화) 서버.",
)

# APM 미들웨어 추가 - 핵심!
app.add_middleware(ElasticAPM, client=apm)

app.include_router(generate_post.router)

@app.get("/")
def read_root():
    return {"message": "Hello, this is the 14-YG-AI-server. API is running."}

@app.get("/health")
def health_check():
    return {"status": "ok"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8100)
```

#### Step 3: 환경변수 설정 (선택사항)
```bash
# /Users/lsh/Documents/GitHub/14-YG-AI/v1/.env 파일 생성
ELASTIC_APM_SERVICE_NAME=moongsan-ai
ELASTIC_APM_SERVICE_VERSION=0.2.1
ELASTIC_APM_SERVER_URL=http://elk.moongsan.com:8200
ELASTIC_APM_ENVIRONMENT=production
ELASTIC_APM_ENABLE=true
```

### 🖥️ 2. Backend 서버 APM 추가

#### Step 1: build.gradle 의존성 추가
```gradle
# /Users/lsh/Documents/GitHub/14-YG-BE/build.gradle의 dependencies 섹션에 추가
dependencies {
    // 기존 의존성들...
    
    // APM 의존성 추가
    implementation 'co.elastic.apm:apm-agent-attach:1.45.0'
    implementation 'co.elastic.apm:apm-agent-api:1.45.0'
    
    // 기존 의존성들...
}
```

#### Step 2: MoongsanBackendApplication.java 수정
```java
# /Users/lsh/Documents/GitHub/14-YG-BE/src/main/java/com/moogsan/moongsan_backend/MoongsanBackendApplication.java
package com.moogsan.moongsan_backend;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.data.jpa.repository.config.EnableJpaAuditing;
import org.springframework.scheduling.annotation.EnableScheduling;
import co.elastic.apm.attach.ElasticApmAttacher;  // APM import 추가

@SpringBootApplication
// @EnableJpaAuditing
@EnableScheduling
public class MoongsanBackendApplication {
    
    static {
        // APM Agent 자동 연결 - 이 블록 추가
        ElasticApmAttacher.attach();
    }
    
    public static void main(String[] args) {
        SpringApplication.run(MoongsanBackendApplication.class, args);
    }
}
```

#### Step 3: application.properties 설정 추가
```properties
# /Users/lsh/Documents/GitHub/14-YG-BE/src/main/resources/application.properties에 추가

# 기존 설정들...

# APM 설정 추가
elastic.apm.server-url=http://elk.moongsan.com:8200
elastic.apm.service-name=moongsan-backend
elastic.apm.service-version=0.0.1-SNAPSHOT
elastic.apm.environment=production
elastic.apm.application-packages=com.moogsan
elastic.apm.enable=true
elastic.apm.transaction-sample-rate=1.0
elastic.apm.enable-log-correlation=true
elastic.apm.capture-body=all
elastic.apm.capture-headers=true
elastic.apm.metrics-interval=30s
```

## 🛠️ 배포 및 적용 명령어

### 🤖 AI 서버 배포
```bash
cd /Users/lsh/Documents/GitHub/14-YG-AI/v1

# 의존성 설치
pip install -r requirements.txt

# 로컬 테스트
python app/main.py

# 프로덕션 서버에 배포 (서버에서 실행)
# sudo systemctl restart moongsan-ai
```

### 🖥️ Backend 서버 배포
```bash
cd /Users/lsh/Documents/GitHub/14-YG-BE

# Gradle 빌드
./gradlew clean build

# 로컬 테스트
./gradlew bootRun

# 프로덕션 서버에 배포 (서버에서 실행)
# sudo systemctl restart moongsan-backend
```

## 🔍 적용 후 확인 방법

### 1. 서비스 로그 확인
```bash
# AI 서버 로그에서 APM 관련 메시지 확인
grep -i "elastic" /var/log/moongsan-ai/app.log

# Backend 서버 로그에서 APM 관련 메시지 확인  
grep -i "elastic" /var/log/moongsan-backend/app.log
```

### 2. APM 인덱스 생성 확인
```bash
# 5-10분 후 APM 인덱스 확인
curl -u "elastic:elastic123" "http://elk.moongsan.com:9200/_cat/indices?v" | grep apm
```

### 3. Kibana에서 APM 데이터 확인
- **URL**: http://elk.moongsan.com:5601/app/apm
- **확인 항목**:
  - Services: `moongsan-backend`, `moongsan-ai` 표시됨
  - Transactions: API 호출 데이터 수집됨
  - Errors: 에러 발생시 자동 캡처됨

## ⚡ 핵심 포인트

### 🤖 AI 서버 핵심 변경사항
1. **requirements.txt**: `elastic-apm[flask]==6.18.1` 추가
2. **main.py**: APM 미들웨어 1줄 추가 `app.add_middleware(ElasticAPM, client=apm)`
3. **포트**: 8100 → APM 서버가 자동 인식

### 🖥️ Backend 서버 핵심 변경사항  
1. **build.gradle**: APM 의존성 2개 추가
2. **Application.java**: `static { ElasticApmAttacher.attach(); }` 블록 추가
3. **application.properties**: APM 설정 10줄 추가

### 📊 예상 결과
- **5분 후**: Kibana APM에서 서비스 2개 표시
- **10분 후**: 실시간 트랜잭션 데이터 수집 시작
- **1시간 후**: 완전한 성능 메트릭 및 에러 추적 가능

## 🚨 주의사항

1. **패키지명 정확성**: Backend의 `com.moogsan` 패키지명 확인 필요
2. **포트 충돌**: AI 서버 8100 포트, Backend 기본 8080 포트 확인
3. **메모리 사용량**: APM 에이전트로 인한 약간의 메모리 증가 (5-10MB)
4. **성능 영향**: 샘플링률 1.0(100%)은 개발/테스트용, 운영시 0.1(10%) 권장

---

**🎯 이제 정확한 파일 경로와 코드를 기반으로 APM을 적용할 수 있습니다!**
