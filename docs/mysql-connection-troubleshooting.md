# MySQL 연결 트러블슈팅 가이드

## 개요

Docker 컨테이너 환경에서 BE 애플리케이션이 MySQL에 연결할 때 발생할 수 있는 문제와 해결 방법을 다룹니다.

## 문제 증상

### 1. 컨테이너 시작 시 MySQL 연결 실패
```
Access denied for user 'moongsan_admin'@'172.21.0.4' (using password: YES)
```

### 2. Flyway 마이그레이션 실패
```
org.flywaydb.core.internal.exception.FlywaySqlException: 
Unable to obtain connection from database: Access denied
```

### 3. Spring Boot 애플리케이션 시작 실패
```
org.springframework.beans.factory.BeanCreationException: 
Error creating bean with name 'entityManagerFactory'
```

## 근본 원인

### MySQL 인증 플러그인 호환성 문제

Docker 컨테이너의 동적 IP 할당으로 인해 MySQL 사용자가 여러 IP에 대해 생성되는데, 이때 서로 다른 인증 플러그인(`mysql_native_password` vs `caching_sha2_password`)이 사용되어 Java MySQL 커넥터와 호환성 문제가 발생할 수 있습니다.

### 네트워크 구조
```
BE Container (172.21.0.4) → Docker Gateway (172.21.0.1) → Host MySQL (10.178.0.18:3306)
```

## 해결 방법

### 1. 문제 진단

#### 현재 MySQL 사용자 확인
```bash
ssh ubuntu@dev.moongsan.com 'mysql -u root -ppass -e "SELECT user, host, plugin FROM mysql.user WHERE user=\"moongsan_admin\";"'
```

#### 컨테이너 IP 확인
```bash
ssh ubuntu@dev.moongsan.com "docker inspect be-moongsan | grep IPAddress"
```

#### BE 컨테이너 환경변수 확인
```bash
ssh ubuntu@dev.moongsan.com "docker exec be-moongsan env | grep -i 'DATABASE\|DB_'"
```

### 2. MySQL 사용자 재설정

#### 문제 있는 사용자 삭제
```bash
ssh ubuntu@dev.moongsan.com 'mysql -u root -ppass -e "DROP USER \"moongsan_admin\"@\"172.21.0.4\";"'
```

#### mysql_native_password로 사용자 생성
```bash
ssh ubuntu@dev.moongsan.com 'mysql -u root -ppass -e "CREATE USER \"moongsan_admin\"@\"172.21.0.4\" IDENTIFIED WITH mysql_native_password BY \"N4pT!6xuV2#rLm3z\";"'
```

#### 권한 부여
```bash
ssh ubuntu@dev.moongsan.com 'mysql -u root -ppass -e "GRANT ALL PRIVILEGES ON moongsan_dev_db.* TO \"moongsan_admin\"@\"172.21.0.4\"; FLUSH PRIVILEGES;"'
```

### 3. 컨테이너 재시작
```bash
ssh ubuntu@dev.moongsan.com "docker restart be-moongsan"
```

### 4. 결과 확인

#### 컨테이너 로그 확인
```bash
ssh ubuntu@dev.moongsan.com "docker logs be-moongsan | tail -50"
```

#### API 서버 응답 확인
```bash
curl -s -o /dev/null -w "%{http_code}" https://dev.moongsan.com/api/health
```

## 예방 방법

### 1. 일관된 인증 플러그인 사용

모든 MySQL 사용자를 `mysql_native_password`로 생성하여 Java 애플리케이션과의 호환성을 보장합니다.

```sql
CREATE USER 'username'@'host' IDENTIFIED WITH mysql_native_password BY 'password';
```

### 2. IP 범위 권한 설정

컨테이너의 동적 IP 할당을 고려하여 서브넷 범위로 권한을 부여합니다.

```sql
GRANT ALL PRIVILEGES ON database_name.* TO 'username'@'172.21.0.%';
```

### 3. 환경변수 검증

Ansible 배포 시 올바른 데이터베이스 연결 정보가 설정되었는지 확인합니다.

```yaml
# group_vars/dev/all.yml
db:
  url: "jdbc:mysql://172.21.0.1:3306/{{ service_name }}_{{ env }}_db?serverTimezone=Asia/Seoul"
  user: "{{ service_name }}_admin"
  password: N4pT!6xuV2#rLm3z
  driver: com.mysql.cj.jdbc.Driver
```

## 관련 파일

- `ansible/group_vars/dev/all.yml`: 데이터베이스 연결 설정
- `ansible/roles/be_deploy/tasks/main.yml`: BE 컨테이너 배포 설정
- `ansible/roles/database/tasks/main.yml`: MySQL 사용자 및 권한 설정

## 참고 사항

### MySQL 8.0 인증 플러그인
- `mysql_native_password`: MySQL 5.7 이하에서 사용되던 기본 인증 방식
- `caching_sha2_password`: MySQL 8.0의 기본 인증 방식 (Java 커넥터와 호환성 문제 있을 수 있음)

### Docker 네트워킹
- `moongsan-net`: 커스텀 브리지 네트워크 (172.21.0.x 서브넷)
- 컨테이너는 게이트웨이(172.21.0.1)를 통해 호스트 MySQL에 접근
- MySQL은 실제 클라이언트 IP(172.21.0.4)를 인식

## 추가 트러블슈팅

### 네트워크 연결 테스트
```bash
# 호스트에서 MySQL 포트 확인
ssh ubuntu@dev.moongsan.com "netstat -tulpn | grep 3306"

# MySQL 바인드 주소 확인
ssh ubuntu@dev.moongsan.com "sudo cat /etc/mysql/mysql.conf.d/mysqld.cnf | grep bind-address"
```

### MySQL 프로세스 모니터링
```bash
ssh ubuntu@dev.moongsan.com 'mysql -u root -ppass -e "SHOW PROCESSLIST;"'
```

### Docker 네트워크 정보
```bash
ssh ubuntu@dev.moongsan.com "docker network inspect moongsan-net"
```
