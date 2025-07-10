# 🖥️ Backend 개발자를 위한 ELK 로그 모니터링 가이드

## 🎯 빠른 접속

- **Kibana 대시보드**: http://elk.moongsan.com:5601
- **로그인**: 
  - Username: `moongsan_admin`
  - Password: `moongsan123`

## 📊 주요 기능들

### 1. 실시간 로그 확인 (Discover)

**접속 경로**: Analytics → Discover

#### 백엔드 로그만 보기
```
검색창에 입력: server.keyword :"backend" 
```

#### 애플리케이션 로그만 보기
```
검색창에 입력: server.keyword :"backend" and logtype : "application"
```

#### 에러 로그 찾기
```
검색창에 입력: server.keyword :"backend" and (message:*ERROR* OR message:*Exception* OR message:*error*)
```

#### 특정 시간대 로그 보기
- 시간 범위 선택기(우측 상단)에서 원하는 시간대 설정
- 예: Last 15 minutes, Last 1 hour, Last 24 hours

### 2. 유용한 검색 쿼리들

#### Spring Boot 애플리케이션 로그
```
server.keyword :"backend" and logtype : "application" and message : "moongsan-backend"
```

#### API 요청 로그 (특정 엔드포인트)
```
server.keyword :"backend" and message:/api/group-buys
```

#### 데이터베이스 관련 로그
```
server.keyword :"backend" and (message:*SQL* OR message:*Database* OR message:*JPA*)
```

#### 시큐리티 관련 로그
```
server.keyword :"backend" and message:*SecurityContext*
```

#### 성능 문제 추적
```
server.keyword :"backend" and (message:*slow* OR message:*timeout* OR message:*performance*)
```

### 3. 필터 사용법

#### 필드별 필터링
1. 왼쪽 사이드바에서 원하는 필드 찾기 (예: `server`, `logtype`, `service`)
2. 필드 옆 **"+"** 클릭으로 포함 필터 추가
3. 필드 옆 **"-"** 클릭으로 제외 필터 추가

#### 자주 사용하는 필터 조합
- **Backend 애플리케이션 로그**: `server.keyword :"backend"` + `logtype : application`
- **Backend 시스템 로그**: `server.keyword :"backend"` + `logtype : system`
- **Backend Docker 로그**: `server.keyword :"backend"` + `logtype : docker`

### 4. 백엔드 개발자를 위한 대시보드

**접속 경로**: Analytics → Dashboard → "Backend 개발자를 위한 로그 모니터링"

이 대시보드에서 볼 수 있는 것들:
- 📈 실시간 로그 트렌드
- 🥧 서버별 로그 분포
- 📊 로그 타입별 분포
- ⚠️ 최근 에러 로그들

### 5. 로그 레벨별 모니터링

#### INFO 레벨 로그
```
server.keyword :"backend" and message:*INFO*
```

#### WARN 레벨 로그  
```
server.keyword :"backend" and message:*WARN*
```

#### ERROR 레벨 로그
```
server.keyword :"backend" and (message:*ERROR* OR message:*FATAL*)
```

#### DEBUG 레벨 로그
```
server.keyword :"backend" and message:*DEBUG*
```

## 🔧 개발 워크플로우 활용법

### 배포 후 로그 확인
1. 배포 시간에 맞춰 시간 범위 설정
2. `server.keyword :"backend" and logtype : application` 검색
3. ERROR나 Exception 키워드로 문제 확인

### API 테스트 시 로그 추적
1. API 호출 전후 시간 설정
2. 특정 엔드포인트 로그 검색: `message:*/api/your-endpoint*`
3. 요청/응답 로그와 에러 로그 동시 확인

### 성능 모니터링
1. 시간대별 로그 트렌드 차트에서 급증 구간 확인
2. 해당 시간대 로그 상세 분석
3. 느린 쿼리나 성능 이슈 키워드 검색

## 📱 모바일에서도 접근 가능

- 모바일 브라우저에서도 동일한 URL로 접속 가능
- 반응형 디자인으로 스마트폰에서도 편리하게 사용

## 🎨 커스터마이징 

### 개인 대시보드 만들기
1. **Dashboard** → **Create dashboard**
2. 자주 보는 시각화들을 조합해서 개인용 대시보드 생성
3. 북마크에 저장해서 빠른 접근

### 저장된 검색 활용
1. **Discover**에서 자주 사용하는 검색 쿼리 저장
2. **Save** → **Save search** 클릭
3. 나중에 **Open** → **Saved searches**에서 재사용

## 🚨 알람 설정 (고급)

중요한 에러 발생시 알림을 받고 싶다면:
1. **Stack Management** → **Rules**
2. **Create rule** → **Elasticsearch query**
3. 에러 로그 감지 쿼리 설정
4. 이메일/Slack 알림 설정

## 💡 팁과 요령

### 1. 시간 범위 활용
- **상대적 시간**: "Last 15 minutes", "Last 1 hour"
- **절대적 시간**: 특정 날짜/시간 지정
- **빠른 시간 선택**: Quick select 옵션 활용

### 2. 검색 성능 최적화
- 가능한 구체적인 필터 사용
- 시간 범위를 좁게 설정
- 와일드카드(*) 남발 피하기

### 3. 로그 패턴 이해
```
일반적인 Spring Boot 로그 형식:
2025-07-03T10:30:45.123Z INFO 7 --- [moongsan-backend] [nio-8080-exec-1] c.m.m.controller.GroupBuyController : API 호출 정보
```

### 4. 유용한 단축키
- **Ctrl+/** : 검색창 포커스
- **Ctrl+Enter** : 검색 실행
- **Escape** : 모달/메뉴 닫기

## 📞 문의 및 지원

로그 시스템 관련 문의사항이나 추가 기능이 필요하면:
- 인프라팀에 문의
- 이 가이드에서 다루지 않은 고급 기능 요청 가능

## 📈 향후 추가 예정 기능

- [ ] 코드 레벨 추적 (APM 연동)
- [ ] 자동 에러 알림 시스템
- [ ] 성능 메트릭 대시보드
- [ ] 로그 기반 알람 시스템

---

**마지막 업데이트**: 2025년 7월 3일  
**시스템 관리자**: DevOps팀
