# 🔍 Backend 개발자를 위한 검색 쿼리 모음

## 📋 복사해서 바로 사용 가능한 검색 쿼리들

### 🏃‍♂️ 자주 사용하는 기본 쿼리

#### 1. Backend 서버 전체 로그
```
server:backend
```

#### 2. Backend 애플리케이션 로그만
```
server:backend AND logtype:application
```

#### 3. Backend 에러 로그
```
server:backend AND (message:*ERROR* OR message:*Exception* OR message:*FATAL*)
```

#### 4. Backend API 요청 로그
```
server:backend AND message:*nio-8080-exec*
```

#### 5. Backend Spring Boot 로그
```
server:backend AND message:*moongsan-backend*
```

### 🎯 특정 기능별 로그 추적

#### 6. 그룹바잉 API 로그
```
server:backend AND message:*/api/group-buys*
```

#### 7. 사용자 인증 관련 로그
```
server:backend AND (message:*SecurityContext* OR message:*Authentication* OR message:*authorization*)
```

#### 8. 데이터베이스 관련 로그
```
server:backend AND (message:*SQL* OR message:*JPA* OR message:*Hibernate* OR message:*Database*)
```

#### 9. 컨트롤러 로그
```
server:backend AND message:*Controller*
```

#### 10. 서비스 레이어 로그
```
server:backend AND message:*Service*
```

### ⚠️ 문제 진단용 쿼리

#### 11. 예외 발생 로그
```
server:backend AND (message:*Exception* OR message:*Error* OR message:*Failed*)
```

#### 12. 성능 관련 로그
```
server:backend AND (message:*slow* OR message:*timeout* OR message:*performance* OR message:*elapsed*)
```

#### 13. 메모리 관련 로그
```
server:backend AND (message:*memory* OR message:*heap* OR message:*GC*)
```

#### 14. 연결 문제 로그
```
server:backend AND (message:*connection* OR message:*connect* OR message:*refused*)
```

#### 15. HTTP 상태 코드별 로그
```
server:backend AND (message:*" 500 "* OR message:*" 404 "* OR message:*" 400 "*)
```

### 📊 로그 레벨별 쿼리

#### 16. INFO 레벨
```
server:backend AND message:*INFO*
```

#### 17. WARN 레벨
```
server:backend AND message:*WARN*
```

#### 18. DEBUG 레벨
```
server:backend AND message:*DEBUG*
```

#### 19. TRACE 레벨
```
server:backend AND message:*TRACE*
```

### 🕐 시간 기반 쿼리 (시간 범위와 함께 사용)

#### 20. 최근 5분간 에러
```
server:backend AND message:*ERROR*
(시간 범위: Last 5 minutes)
```

#### 21. 특정 시간대 API 호출량 모니터링
```
server:backend AND message:*GET* OR message:*POST* OR message:*PUT* OR message:*DELETE*
(시간 범위: 원하는 시간대 설정)
```

### 🔄 배포 및 운영 관련

#### 22. 애플리케이션 시작/종료 로그
```
server:backend AND (message:*Started* OR message:*Stopped* OR message:*Starting* OR message:*Shutdown*)
```

#### 23. 설정 관련 로그
```
server:backend AND (message:*config* OR message:*property* OR message:*profile*)
```

#### 24. 헬스체크 로그
```
server:backend AND (message:*health* OR message:*/actuator*)
```

### 🌐 API 엔드포인트별 상세 추적

#### 25. 특정 사용자 ID 관련 로그
```
server:backend AND message:*userId=YOUR_USER_ID*
```

#### 26. 특정 API 메소드 로그
```
server:backend AND message:*"POST /api/group-buys"*
```

#### 27. API 응답 시간 모니터링
```
server:backend AND message:*"completed in"* OR message:*"took"* OR message:*"ms"*
```

### 💾 데이터베이스 쿼리 분석

#### 28. 느린 쿼리 탐지
```
server:backend AND (message:*"slow query"* OR message:*"execution time"* OR message:*"took longer than"*)
```

#### 29. 트랜잭션 관련 로그
```
server:backend AND (message:*transaction* OR message:*commit* OR message:*rollback*)
```

#### 30. 커넥션 풀 관련 로그
```
server:backend AND (message:*"connection pool"* OR message:*"HikariCP"* OR message:*"datasource"*)
```

## 🎨 고급 검색 팁

### 와일드카드 사용법
- `message:*error*` : 'error'가 포함된 모든 메시지
- `message:error*` : 'error'로 시작하는 메시지
- `message:*error` : 'error'로 끝나는 메시지

### 범위 검색
```
@timestamp:[now-1h TO now]  // 최근 1시간
```

### 정확한 구문 검색
```
message:"정확한 문구"
```

### 필드 존재 여부 확인
```
_exists_:error_field
```

### 복합 조건
```
(server:backend AND logtype:application) OR (server:backend AND message:*ERROR*)
```

## 🚀 사용법

1. Kibana의 **Discover** 페이지로 이동
2. 검색창에 원하는 쿼리 복사&붙여넣기
3. 시간 범위 설정 (우측 상단)
4. Enter 키 또는 🔍 버튼 클릭
5. 결과 확인 및 분석

## 💡 프로 팁

- **북마크 활용**: 자주 사용하는 쿼리는 브라우저 북마크로 저장
- **저장된 검색**: Kibana의 "Save" 기능으로 쿼리 저장
- **대시보드 활용**: 여러 쿼리 결과를 하나의 화면에서 모니터링
- **자동 새로고침**: 실시간 모니터링을 위해 auto-refresh 설정

---

**💬 사용 후기나 추가 쿼리 요청**: DevOps팀으로 연락주세요!
