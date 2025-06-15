# Backend → MySQL 연결 해결 및 접속 가이드

## 📋 개요

이 문서는 3-tier 아키텍처에서 Backend 서버(10.0.0.3)에서 Database 서버(10.0.0.2)의 MySQL로 연결하는 방법과 문제 해결 과정을 정리합니다.

## 🚨 이전 문제점들과 해결 과정

### ❌ 주요 문제점들

1. **SSH 접근 불가 문제**
   - VM들에 `ssh` 태그가 없어서 방화벽 규칙이 적용되지 않음
   - Terraform 설정에서 `network_tags = ["internal"]`만 있고 `ssh` 태그 누락

2. **WireGuard VPN 연결 실패**
   - 서버 IP 변경 (34.47.100.211 → 34.22.110.81)으로 인한 클라이언트 설정 불일치
   - 새로운 서버 키 페어 필요

3. **MySQL 사용자 권한 혼동**
   - 실제로는 이미 올바르게 설정되어 있었으나 네트워크 문제로 접근 불가

### ✅ 해결 과정

#### 1단계: SSH 태그 추가

```bash
# Terraform 설정 수정 전 직접 태그 추가
gcloud compute instances add-tags moongsan-test-database --tags=ssh --zone=asia-northeast3-a
gcloud compute instances add-tags moongsan-test-backend --tags=ssh --zone=asia-northeast3-a  
gcloud compute instances add-tags moongsan-test-ai --tags=ssh --zone=asia-northeast3-a

# Terraform 상태 동기화
terraform refresh
```

**Terraform 설정 수정:**
```hcl
# terraform/environments/test/main.tf
network_tags = ["internal", "ssh"]  # ssh 태그 추가
```

#### 2단계: WireGuard VPN 재설정

```bash
# 새로운 서버 키 생성
wg genkey | tee server-private.key | wg pubkey > server-public.key

# 서버 설정 업데이트 (34.22.110.81:51820)
# 모든 클라이언트 설정 파일 업데이트
```

#### 3단계: 네트워크 연결 검증

```bash
# VPN을 통한 ping 테스트
ping -c 2 10.0.0.2  # Database
ping -c 2 10.0.0.3  # Backend  
ping -c 2 10.0.0.4  # AI

# MySQL 포트 연결 테스트
nc -zv 10.0.0.2 3306
```

## 🔗 Backend 서버 SSH 접속 방법

### 방법 1: WireGuard VPN을 통한 직접 연결 (추천)

```bash
# WireGuard VPN 연결 확인
sudo wg show

# SSH 직접 연결
ssh -i ~/.ssh/lsh-study-key ubuntu@10.0.0.3
```

### 방법 2: ProxyJump를 통한 연결

```bash
# shared-jumpbox를 통한 접속
ssh -i ~/.ssh/lsh-study-key -J ubuntu@34.22.110.81 ubuntu@10.0.0.3
```

### 방법 3: Ansible을 통한 관리

```bash
cd /Users/lsh/Documents/local/3tier-moongsan/14-YG-CLOUD/ansible

# 단일 명령 실행
ansible test-backend -i inventories/test.ini -m shell -a "명령어" -v

# 인터랙티브 셸 (제한적)
ansible test-backend -i inventories/test.ini -m shell -a "bash" --become
```

## 💾 MySQL 접속 방법

### Backend 서버에서 MySQL 클라이언트 사용

Backend 서버에 SSH로 연결한 후:

```bash
# 1. 애플리케이션 사용자로 접속
mysql -h 10.0.0.2 -u app_user -papp_password_2024! moongsan_app

# 2. 대화형 패스워드 입력
mysql -h 10.0.0.2 -u app_user -p moongsan_app
# Password: app_password_2024!

# 3. root 사용자로 접속 (관리 작업)
mysql -h 10.0.0.2 -u root -pmoongsan_root_2024!
```

### 원격에서 Ansible을 통한 MySQL 명령 실행

```bash
cd /Users/lsh/Documents/local/3tier-moongsan/14-YG-CLOUD/ansible

# 데이터베이스 목록 확인
ansible test-backend -i inventories/test.ini -m shell \
  -a "mysql -h 10.0.0.2 -u app_user -papp_password_2024! -e 'SHOW DATABASES;'" -v

# 테이블 목록 확인
ansible test-backend -i inventories/test.ini -m shell \
  -a "mysql -h 10.0.0.2 -u app_user -papp_password_2024! moongsan_app -e 'SHOW TABLES;'" -v

# 연결 정보 확인
ansible test-backend -i inventories/test.ini -m shell \
  -a "mysql -h 10.0.0.2 -u app_user -papp_password_2024! moongsan_app -e 'SELECT CONNECTION_ID(), USER(), DATABASE(), NOW();'" -v
```

## 🔍 연결 상태 검증

### 네트워크 연결 확인

```bash
# Backend에서 Database 포트 연결 테스트
ansible test-backend -i inventories/test.ini -m shell -a "nc -zv 10.0.0.2 3306" -v

# 결과 예시:
# Connection to 10.0.0.2 3306 port [tcp/mysql] succeeded!
```

### MySQL 서비스 상태 확인

```bash
# Database 서버의 MySQL 컨테이너 상태
ansible test-database -i inventories/test.ini -m shell \
  -a "sudo docker ps | grep mysql" --become -v

# MySQL 사용자 목록 확인
ansible test-database -i inventories/test.ini -m shell \
  -a "sudo docker exec moongsan_mysql mysql -uroot -pmoongsan_root_2024! -e 'SELECT user, host FROM mysql.user;'" --become -v
```

## 📊 현재 설정 정보

### 네트워크 정보
- **Backend IP**: 10.0.0.3
- **Database IP**: 10.0.0.2
- **MySQL Port**: 3306
- **VPC CIDR**: 10.0.0.0/24

### MySQL 사용자 정보
- **애플리케이션 사용자**: `app_user` / `app_password_2024!`
- **관리자 사용자**: `root` / `moongsan_root_2024!`
- **데이터베이스**: `moongsan_app`
- **접근 권한**: `%` (모든 호스트에서 접근 가능)

### Docker 컨테이너 정보
- **컨테이너명**: `moongsan_mysql`
- **이미지**: `mysql:8.0`
- **포트 바인딩**: `0.0.0.0:3306->3306/tcp`
- **상태**: healthy

## 🧪 연결 테스트 예시

### 기본 연결 테스트

```sql
-- 연결 후 실행할 수 있는 SQL 명령들
SHOW DATABASES;
USE moongsan_app;
SHOW TABLES;

-- 연결 정보 확인
SELECT CONNECTION_ID(), USER(), DATABASE(), NOW();

-- 테스트 테이블 생성 및 데이터 조작
CREATE TABLE test_connection (
    id INT AUTO_INCREMENT PRIMARY KEY,
    message VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO test_connection (message) 
VALUES ('Backend to Database connection successful!');

SELECT * FROM test_connection;
```

### 실제 연결 테스트 결과

```bash
# 2025-06-13 00:50:26 연결 성공 로그
CONNECTION_ID() USER()              DATABASE()    NOW()
102             app_user@10.0.0.3   moongsan_app  2025-06-13 00:50:26
```

## 🔧 문제 해결 체크리스트

### 연결 실패 시 확인사항

1. **WireGuard VPN 연결 확인**
   ```bash
   sudo wg show
   ping 10.0.0.2
   ```

2. **SSH 접근 확인**
   ```bash
   ssh -i ~/.ssh/lsh-study-key ubuntu@10.0.0.3
   ```

3. **MySQL 서비스 상태 확인**
   ```bash
   docker ps | grep mysql
   ```

4. **방화벽 규칙 확인**
   ```bash
   gcloud compute firewall-rules list --filter="name~test"
   ```

5. **MySQL 사용자 권한 확인**
   ```sql
   SELECT user, host FROM mysql.user WHERE user='app_user';
   ```

## 📝 주요 학습 사항

1. **인프라 우선**: 네트워크와 방화벽 설정이 먼저 해결되어야 애플리케이션 레벨 연결 가능
2. **태그 기반 방화벽**: GCP에서는 네트워크 태그를 통한 방화벽 규칙 적용이 중요
3. **VPN 의존성**: Private IP만 있는 VM들은 VPN을 통한 관리 필수
4. **Docker 네트워크**: 컨테이너 포트 바인딩이 `0.0.0.0:3306`으로 설정되어야 외부 접근 가능

## 🚀 다음 단계

이제 Backend → Database 연결이 확인되었으므로:

1. **Backend Spring Boot 애플리케이션 배포**
2. **application.yml에서 DB 연결 설정 적용**
3. **AI 서비스 배포**
4. **전체 3-tier 통합 테스트**

---

**문서 작성일**: 2025-06-13  
**최종 검증일**: 2025-06-13 00:50:26  
**연결 상태**: ✅ 정상 작동
