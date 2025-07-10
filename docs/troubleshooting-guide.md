# 🔧 문제해결 가이드

> **14-YG-CLOUD 프로젝트**에서 발생할 수 있는 모든 문제상황과 해결방법을 정리한 완전한 트러블슈팅 가이드입니다.

## 📋 목차

- [Terraform 문제해결](#terraform-문제해결)
- [Ansible 문제해결](#ansible-문제해결)
- [WireGuard VPN 문제해결](#wireguard-vpn-문제해결)
- [GCP 리소스 문제해결](#gcp-리소스-문제해결)
- [네트워크 연결 문제해결](#네트워크-연결-문제해결)
  - [Backend → MySQL 연결 문제 (완전한 해결 가이드)](#문제-backend에서-mysql-database-연결-실패-완전한-해결-가이드)
- [보안 관련 문제해결](#보안-관련-문제해결)
- [로그 수집 문제해결](#로그수집문제해결)

---

## Terraform 문제해결

### 🚨 상태 파일 문제

#### **문제**: "Backend configuration changed" 오류
```bash
Error: Backend configuration changed
```

**해결방법**:
```bash
# 1. 상태 파일 재초기화
terraform init -reconfigure

# 2. 강제 복사 (기존 상태 덮어쓰기)
terraform init -force-copy

# 3. 상태 파일 확인
terraform state list
```

#### **문제**: "Resource already exists" 오류
```bash
Error: A resource with the ID "xxx" already exists
```

**해결방법**:
```bash
# 1. 기존 리소스를 Terraform 상태로 가져오기
terraform import google_compute_instance.backend projects/PROJECT_ID/zones/ZONE/instances/INSTANCE_NAME

# 2. 상태 파일에서 리소스 제거 (삭제 없이)
terraform state rm google_compute_instance.backend

# 3. 상태 새로고침
terraform refresh
```

### 🔧 계획 및 적용 문제

#### **문제**: "Permission denied" 오류
```bash
Error: Error when reading or editing Project Service: googleapi: Error 403: Insufficient Permission
```

**해결방법**:
```bash
# 1. 서비스 계정 권한 확인
gcloud projects get-iam-policy PROJECT_ID

# 2. 필요한 API 활성화
gcloud services enable compute.googleapis.com
gcloud services enable storage.googleapis.com
gcloud services enable cloudkms.googleapis.com

# 3. 인증 재설정
gcloud auth application-default login
```

#### **문제**: "Quota exceeded" 오류
```bash
Error: Quota 'CPUS' exceeded. Limit: 8.0 in region asia-northeast3
```

**해결방법**:
```bash
# 1. 현재 할당량 확인
gcloud compute project-info describe --project=PROJECT_ID

# 2. 할당량 증가 요청
# GCP Console > IAM & Admin > Quotas에서 요청

# 3. 임시 해결: 다른 리전 사용
region = "asia-northeast1"  # terraform.tfvars에서 변경
```

### 📊 상태 관리 문제

#### **문제**: 상태 파일 잠김
```bash
Error: Error acquiring the state lock
```

**해결방법**:
```bash
# 1. 강제 잠금 해제 (주의: 다른 작업이 진행 중이 아님을 확인)
terraform force-unlock LOCK_ID

# 2. 잠금 상태 확인
gsutil ls gs://YOUR-TERRAFORM-STATE-BUCKET/.terraform/

# 3. 수동 잠금 파일 삭제 (최후 수단)
gsutil rm gs://YOUR-TERRAFORM-STATE-BUCKET/.terraform/LOCK_FILE
```

---

## Ansible 문제해결

### 🔐 연결 문제

#### **문제**: SSH 연결 실패
```bash
UNREACHABLE! => {"changed": false, "msg": "Failed to connect to the host via ssh", "unreachable": true}
```

**해결방법**:
```bash
# 1. SSH 연결 직접 테스트
ssh -i ~/.ssh/gcp-key moongsan@34.64.123.45

# 2. SSH 설정 확인
ansible all -i inventory_test.ini -m ping -vvv

# 3. 인벤토리 파일 확인
cat inventory_test.ini

# 4. SSH 키 권한 확인
chmod 600 ~/.ssh/gcp-key
```

#### **문제**: "Permission denied (publickey)" 오류
```bash
Permission denied (publickey)
```

**해결방법**:
```bash
# 1. 올바른 사용자명 확인
ansible_user=moongsan  # inventory 파일에서

# 2. SSH 키가 서버에 등록되었는지 확인
ssh-copy-id -i ~/.ssh/gcp-key.pub moongsan@SERVER_IP

# 3. GCP 메타데이터에 SSH 키 추가
gcloud compute project-info add-metadata \
    --metadata-from-file ssh-keys=~/.ssh/gcp-key.pub
```

### 📦 Vault 문제

#### **문제**: Vault 암호 오류
```bash
ERROR! Decryption failed (no vault secrets were found that could decrypt)
```

**해결방법**:
```bash
# 1. Vault 패스워드 파일 확인
cat .vault_pass.txt

# 2. 수동으로 패스워드 입력
ansible-playbook -i inventory_test.ini playbooks/site.yml --ask-vault-pass

# 3. Vault 파일 재암호화
ansible-vault rekey group_vars/all/vault.yml
```

### 🚀 배포 실패 문제

#### **문제**: Docker 컨테이너 시작 실패
```bash
TASK [be_deploy : Start backend container] ****
fatal: [backend-test]: FAILED! => {"changed": false, "msg": "Error starting container"}
```

**해결방법**:
```bash
# 1. 서버에 직접 접속하여 확인
ssh -i ~/.ssh/gcp-key moongsan@BACKEND_IP

# 2. Docker 로그 확인
sudo docker logs backend-container

# 3. 컨테이너 수동 실행 테스트
sudo docker run -d --name test-backend -p 8080:8080 backend-image

# 4. 포트 충돌 확인
sudo netstat -tlnp | grep 8080
```

---

## WireGuard VPN 문제해결

### 🌐 연결 문제

#### **문제**: VPN 연결이 안됨
```bash
wg-quick: `wg0' already exists
```

**해결방법**:
```bash
# 1. 기존 연결 종료
sudo wg-quick down wg0

# 2. 인터페이스 확인
ip addr show

# 3. 새로 연결 시도
sudo wg-quick up wg0

# 4. 연결 상태 확인
sudo wg show
```

#### **문제**: "Operation not permitted" 오류
```bash
wg-quick: `wg0' is not a WireGuard interface
```

**해결방법**:
```bash
# 1. 관리자 권한으로 실행
sudo wg-quick up wg0

# 2. WireGuard 모듈 로드 확인
sudo modprobe wireguard

# 3. 커널 모듈 상태 확인
lsmod | grep wireguard
```

### 🔧 구성 문제

#### **문제**: Ping이 안됨 (VPN 연결은 성공)
```bash
# VPN은 연결되었지만 내부 네트워크 ping 실패
ping 10.0.0.2  # No response
```

**해결방법**:
```bash
# 1. 라우팅 테이블 확인
ip route show

# 2. 서버에서 IP 포워딩 활성화
echo 'net.ipv4.ip_forward = 1' | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# 3. iptables 규칙 확인
sudo iptables -L -n

# 4. 방화벽 규칙 추가
sudo iptables -A FORWARD -i wg0 -j ACCEPT
sudo iptables -A FORWARD -o wg0 -j ACCEPT
```

---

## GCP 리소스 문제해결

### 💾 스토리지 문제

#### **문제**: GCS 버킷 접근 불가
```bash
Error: storage: bucket doesn't exist
```

**해결방법**:
```bash
# 1. 버킷 존재 확인
gsutil ls gs://your-bucket-name/

# 2. 권한 확인
gsutil iam get gs://your-bucket-name/

# 3. 버킷 생성 (없는 경우)
gsutil mb gs://your-bucket-name/

# 4. 서비스 계정 권한 부여
gsutil iam ch serviceAccount:your-sa@project.iam.gserviceaccount.com:objectAdmin gs://your-bucket-name/
```

### 🔑 인증 문제

#### **문제**: "Application Default Credentials" 오류
```bash
Error: google: could not find default credentials
```

**해결방법**:
```bash
# 1. 서비스 계정 키 설정
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/service-account.json"

# 2. gcloud 인증
gcloud auth application-default login

# 3. 프로젝트 설정
gcloud config set project YOUR_PROJECT_ID

# 4. 인증 상태 확인
gcloud auth list
```

### 🌐 네트워크 문제

#### **문제**: Load Balancer 헬스체크 실패
```bash
Backend service health check failed
```

**해결방법**:
```bash
# 1. 백엔드 서비스 상태 확인
curl -i http://BACKEND_IP:8080/health

# 2. 방화벽 규칙 확인
gcloud compute firewall-rules list

# 3. 헬스체크 경로 수정
# Terraform 설정에서 health_checks 블록 확인

# 4. 로드밸런서 로그 확인
gcloud logging read "resource.type=http_load_balancer"
```

---

## 네트워크 연결 문제해결

### 🕒 API 타임아웃 문제

#### **문제**: `/api/generation/description` 엔드포인트 30초 타임아웃 (2025-07-08 해결됨)

**증상**:
```bash
# Frontend에서 API 호출 시
Request timeout after 30 seconds
504 Gateway Timeout

# 브라우저 네트워크 탭에서
Status: 504 (Gateway Timeout)
Time: 30.0 seconds
```

**근본 원인**: 
- GCP Load Balancer의 `prod-backend-service`가 30초 타임아웃으로 설정
- AI 생성 작업은 일반적으로 30초 이상 소요
- URL 라우팅: `/api/generation/*` → `prod-backend-service` (30초) vs `/generation/*` → `prod-ai-service` (120초)

**해결 방법**:

**1단계: 현재 타임아웃 설정 확인**
```bash
# 백엔드 서비스 타임아웃 확인
gcloud compute backend-services list --format="table(name,timeoutSec,protocol)"

# 결과 예시:
# NAME                  TIMEOUT_SEC  PROTOCOL
# prod-ai-service       120          HTTP
# prod-backend-service  30           HTTP  <- 문제 발생 지점
```

**2단계: URL 라우팅 확인**
```bash
# URL 맵 라우팅 규칙 확인
gcloud compute url-maps describe prod-url-map --format="yaml" | grep -A 20 pathMatchers

# 라우팅 규칙:
# /api/* → prod-backend-service (30초)
# /generation/* → prod-ai-service (120초)
# 따라서 /api/generation/* 은 백엔드 서비스로 라우팅됨
```

**3단계: 타임아웃 증가 (권장 해결책)**
```bash
# 백엔드 서비스 타임아웃을 120초로 증가
gcloud compute backend-services update prod-backend-service --timeout=120 --global

# 적용 확인
gcloud compute backend-services list --format="table(name,timeoutSec,protocol)"
# prod-backend-service도 120초로 변경됨을 확인
```

**4단계: 대안 해결책 (URL 라우팅 변경)**
```bash
# 만약 세밀한 제어가 필요한 경우:
# /api/generation/* 패턴을 AI 서비스로 라우팅하도록 URL 맵 수정
gcloud compute url-maps edit prod-url-map

# pathRules에 추가:
# - paths:
#   - /api/generation/*
#   service: https://www.googleapis.com/compute/v1/projects/PROJECT_ID/global/backendServices/prod-ai-service
```

**검증 방법**:
```bash
# 1. 타임아웃 설정 확인
gcloud compute backend-services describe prod-backend-service --global --format="value(timeoutSec)"

# 2. API 테스트
curl -X POST "https://your-domain.com/api/generation/description" \
  -H "Content-Type: application/json" \
  -d '{"prompt": "test"}' \
  --max-time 150  # 120초 + 여유시간

# 3. ELK 로그 모니터링
# Kibana에서 타임아웃 관련 로그 확인
```

**예방 조치**:
- 모든 백엔드 서비스의 타임아웃을 AI 작업에 맞게 설정 (120초 이상)
- URL 라우팅 규칙을 명확히 문서화
- ELK Stack에서 타임아웃 관련 알람 설정
- AI 작업의 경우 비동기 처리 고려

---

### 🔗 서비스 간 통신 문제

#### **문제**: Backend에서 MySQL Database 연결 실패 (완전한 해결 가이드)

**증상들**:
```bash
# SSH 접근 불가
ssh: connect to host 10.0.0.3 port 22: Connection refused

# MySQL 연결 실패
mysql: ERROR 2003 (HY000): Can't connect to MySQL server on '10.0.0.2'

# Ansible 연결 실패
UNREACHABLE! => {"msg": "Failed to connect to the host via ssh"}
```

**근본 원인 분석 및 해결**:

**1단계: SSH 태그 및 방화벽 문제 해결**
```bash
# 문제: VM에 ssh 태그가 없어서 방화벽 규칙 미적용
# 해결: SSH 태그 추가

# 즉시 해결 (gcloud 사용)
gcloud compute instances add-tags moongsan-test-database --tags=ssh --zone=asia-northeast3-a
gcloud compute instances add-tags moongsan-test-backend --tags=ssh --zone=asia-northeast3-a  
gcloud compute instances add-tags moongsan-test-ai --tags=ssh --zone=asia-northeast3-a

# Terraform 설정 수정 (영구 해결)
# terraform/environments/test/main.tf
network_tags = ["internal", "ssh"]  # ssh 태그 추가

# 상태 동기화
terraform refresh
terraform plan  # "No changes" 확인
```

**2단계: WireGuard VPN 연결 복구**
```bash
# 문제: 서버 IP 변경으로 인한 VPN 연결 실패
# 해결: 새 서버 설정으로 업데이트

# 새 서버 키 생성
wg genkey | tee server-private.key | wg pubkey > server-public.key

# 클라이언트 설정 업데이트 (새 IP: 34.22.110.81)
# 모든 팀원 클라이언트 설정 파일 업데이트 필요
```

**3단계: 네트워크 연결 검증**
```bash
# VPN 연결 확인
sudo wg show

# 내부 네트워크 ping 테스트
ping -c 2 10.0.0.2  # Database
ping -c 2 10.0.0.3  # Backend  
ping -c 2 10.0.0.4  # AI

# SSH 연결 테스트
ssh -i ~/.ssh/lsh-study-key ubuntu@10.0.0.3

# MySQL 포트 연결 테스트
nc -zv 10.0.0.2 3306
# 성공: Connection to 10.0.0.2 3306 port [tcp/mysql] succeeded!
```

**4단계: MySQL 클라이언트 설치 및 연결 테스트**
```bash
# Backend 서버에 MySQL 클라이언트 설치
ansible test-backend -i inventories/test.ini -m apt \
  -a "name=mysql-client state=present update_cache=yes" --become

# 연결 테스트 (Backend에서 Database로)
ansible test-backend -i inventories/test.ini -m shell \
  -a "mysql -h 10.0.0.2 -u app_user -papp_password_2024! moongsan_app -e 'SELECT CONNECTION_ID(), USER(), DATABASE(), NOW();'" -v

# 성공 결과 예시:
# CONNECTION_ID() USER()              DATABASE()    NOW()
# 102             app_user@10.0.0.3   moongsan_app  2025-06-13 00:50:26
```

**5단계: 실제 데이터 조작 테스트**
```bash
# 테스트 테이블 생성
ansible test-backend -i inventories/test.ini -m shell \
  -a "mysql -h 10.0.0.2 -u app_user -papp_password_2024! moongsan_app -e 'CREATE TABLE test_connection (id INT AUTO_INCREMENT PRIMARY KEY, message VARCHAR(100), created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP);'"

# 데이터 INSERT
ansible test-backend -i inventories/test.ini -m shell \
  -a "mysql -h 10.0.0.2 -u app_user -papp_password_2024! moongsan_app -e \"INSERT INTO test_connection (message) VALUES ('Backend to Database connection successful!');\""

# 데이터 SELECT 확인
ansible test-backend -i inventories/test.ini -m shell \
  -a "mysql -h 10.0.0.2 -u app_user -papp_password_2024! moongsan_app -e 'SELECT * FROM test_connection;'"
```

**문제 해결 체크리스트**:
1. ✅ **WireGuard VPN 연결** - `sudo wg show`
2. ✅ **VM 태그 확인** - `gcloud compute instances describe VM_NAME --zone=ZONE`
3. ✅ **SSH 접근** - `ssh -i ~/.ssh/key ubuntu@10.0.0.X`
4. ✅ **MySQL 서비스** - `docker ps | grep mysql`
5. ✅ **포트 연결** - `nc -zv 10.0.0.2 3306`
6. ✅ **MySQL 사용자** - `SELECT user, host FROM mysql.user;`

**참고 문서**: `docs/backend-mysql-connection-guide.md`

#### **문제**: Backend에서 Database 연결 실패 (기본)
```bash
Connection refused: database_host:3306
```

**해결방법**:
```bash
# 1. 네트워크 연결 테스트
ping 10.0.0.3  # Database IP

# 2. 포트 연결 테스트
telnet 10.0.0.3 3306

# 3. 방화벽 규칙 확인
sudo iptables -L -n

# 4. MySQL 바인딩 주소 확인
mysql -e "SHOW VARIABLES LIKE 'bind_address';"
```

### 🌍 외부 접근 문제

#### **문제**: Load Balancer를 통한 접근 실패
```bash
curl: (7) Failed to connect to LB_IP port 80: Connection refused
```

**해결방법**:
```bash
# 1. Load Balancer 상태 확인
gcloud compute backend-services get-health BACKEND_SERVICE_NAME --global

# 2. 백엔드 서비스 직접 테스트
curl -i http://BACKEND_INTERNAL_IP:8080/

# 3. 방화벽 태그 확인
gcloud compute instances describe INSTANCE_NAME --zone=ZONE

# 4. 헬스체크 간격 조정
# health_check_grace_period_sec 값 증가
```

---

## 보안 관련 문제해결

### 🔐 SSH 키 문제

#### **문제**: SSH 키 인식 실패
```bash
Warning: Identity file not accessible: No such file or directory
```

**해결방법**:
```bash
# 1. SSH 키 파일 확인
ls -la ~/.ssh/

# 2. 키 권한 설정
chmod 600 ~/.ssh/gcp-key
chmod 644 ~/.ssh/gcp-key.pub

# 3. SSH 에이전트에 키 추가
ssh-add ~/.ssh/gcp-key

# 4. SSH 연결 테스트
ssh -i ~/.ssh/gcp-key -v moongsan@SERVER_IP
```

### 🔒 Vault 접근 문제

#### **문제**: Ansible Vault 파일 손상
```bash
ERROR! input is not vault encrypted data
```

**해결방법**:
```bash
# 1. 파일 헤더 확인
head -1 group_vars/all/vault.yml
# 정상: $ANSIBLE_VAULT;1.1;AES256;...

# 2. 백업에서 복원
cp group_vars/all/vault.yml.backup group_vars/all/vault.yml

# 3. 새로 암호화
ansible-vault encrypt_string 'secret_value' --name 'vault_variable'

# 4. 파일 재생성
ansible-vault create group_vars/all/vault.yml
```

---

## 로그 수집 문제해결

## 🚨 로그 수집 중단 문제 (2025-07-10 완전 해결)

### 🔍 문제 식별 방법

#### 1. 증상 확인
```bash
# Kibana 대시보드에서 최신 로그 부재 확인
# 또는 직접 Elasticsearch 쿼리
curl -k -u elastic:PASSWORD 'https://elk.moongsan.com:9200/moongsan-logs-$(date +%Y.%m.%d)/_search?size=1&sort=@timestamp:desc'
```

#### 2. 로그 수집 파이프라인 상태 체크
```bash
# 자동화된 상태 체크 스크립트 실행
./elk-configs/scripts/check-log-pipeline-health.sh
```

#### 3. 서비스별 상태 확인
```bash
# ELK 서버 서비스들
ssh lsh@elk.moongsan.com "sudo systemctl status elasticsearch logstash kibana"

# 각 서버의 Filebeat 상태
ssh ubuntu@10.1.0.3 "sudo systemctl status filebeat"  # Backend
ssh ubuntu@10.1.0.4 "sudo systemctl status filebeat"  # AI
```

### 🚨 공통 원인들과 해결법

#### 원인 1: Elasticsearch 인증 문제 (가장 빈번)
**증상**: Logstash가 401 Unauthorized 에러 발생
```bash
# 문제 확인
sudo journalctl -u logstash | grep "401\|unauthorized"

# 해결: 패스워드 재설정
sudo /usr/share/elasticsearch/bin/elasticsearch-reset-password -u elastic
# 새 패스워드를 Logstash 설정에 반영
sudo nano /etc/logstash/conf.d/beats-input.conf
sudo systemctl restart logstash
```

#### 원인 2: Logstash 파이프라인 오류
**증상**: Logstash가 실행 중이지만 로그 처리 안됨
```bash
# 문제 확인
sudo tail -f /var/log/logstash/logstash-plain.log

# 해결: 설정 검증 후 재시작
sudo /usr/share/logstash/bin/logstash --config.test_and_exit
sudo systemctl restart logstash
```

#### 원인 3: Filebeat 연결 문제
**증상**: Filebeat가 Logstash에 연결하지 못함
```bash
# 문제 확인
sudo tail -f /var/log/filebeat/filebeat

# 해결: Logstash 연결 테스트
telnet 10.100.0.4 5044
sudo systemctl restart filebeat
```

### 🔧 단계별 진단 프로세스

#### Step 1: 서비스 상태 확인
```bash
# 모든 핵심 서비스 상태 한번에 확인
for service in elasticsearch logstash kibana; do
  echo "=== $service ==="
  ssh lsh@elk.moongsan.com "sudo systemctl is-active $service"
done
```

#### Step 2: 네트워크 연결 확인
```bash
# Filebeat -> Logstash 연결 테스트
ssh ubuntu@10.1.0.3 "telnet 10.100.0.4 5044"

# Logstash -> Elasticsearch 연결 테스트  
ssh lsh@elk.moongsan.com "curl -k https://localhost:9200/_cluster/health"
```

#### Step 3: 인증 및 권한 확인
```bash
# Elasticsearch 인증 테스트
curl -k -u elastic:PASSWORD 'https://elk.moongsan.com:9200/_cluster/health'

# 인덱스 생성 권한 테스트
curl -k -u elastic:PASSWORD -X PUT 'https://elk.moongsan.com:9200/test-index'
```

#### Step 4: 로그 파일 점검
```bash
# 각 구성요소별 로그 확인
sudo tail -f /var/log/elasticsearch/elasticsearch.log
sudo tail -f /var/log/logstash/logstash-plain.log  
sudo tail -f /var/log/filebeat/filebeat
```

### 📋 예방 조치 체크리스트

#### 정기 모니터링 (일주일마다)
- [ ] 로그 수집 파이프라인 상태 체크
- [ ] 인덱스 크기 및 문서 수 모니터링
- [ ] 각 서비스 메모리/CPU 사용률 확인

#### 인증 정보 관리
- [ ] Elasticsearch 패스워드 변경 시 연관 서비스 업데이트
- [ ] Ansible vault에 중앙화된 인증 정보 관리
- [ ] 패스워드 변경 후 전체 파이프라인 테스트

#### 자동화 도구 활용
```bash
# 정기 상태 체크를 위한 cron 설정
0 */6 * * * /path/to/elk-configs/scripts/check-log-pipeline-health.sh
```

### 🎯 문제별 빠른 해결 가이드

| 문제 유형 | 주요 증상 | 빠른 해결 |
|----------|----------|----------|
| **인증 문제** | 401 에러, unauthorized | 패스워드 재설정 → Logstash 재시작 |
| **네트워크 문제** | Connection refused | 방화벽/보안그룹 확인 |
| **설정 문제** | Pipeline 시작 실패 | 설정 검증 → 문법 오류 수정 |
| **용량 문제** | Disk full, 메모리 부족 | 오래된 인덱스 삭제, 메모리 증설 |

### 💡 추가 팁

#### APM vs 로그 수집 구분하기
- **APM**: apm-* 인덱스, 성능 메트릭
- **로그 수집**: moongsan-logs-* 인덱스, 애플리케이션 로그
- **독립적 파이프라인**: 하나가 문제여도 다른 하나는 정상 작동 가능

#### 최신 패스워드 관리
```bash
# Ansible 변수로 중앙 관리
# ansible/group_vars/shared/elk.yml 참조
elk.elasticsearch.password: "현재_패스워드"
```

--- 
:exception=>LogStash::Outputs::ElasticSearch::HttpClient::Pool::HostUnreachableError, 
:message=>"Elasticsearch Unreachable: [https://localhost:9200/][Manticore::SocketException] 
Connect to localhost:9200 [localhost/127.0.0.1] failed: Connection refused"}
```

**근본 원인**: Elasticsearch 인증 설정 변경 후 Logstash가 기존 연결을 재사용하려 시도했으나 실패

### 해결 방법

#### 1. 즉시 해결 (재시작)
```bash
# ELK 서버에서 Logstash 재시작
sudo systemctl restart logstash

# 재시작 후 상태 확인
sudo systemctl status logstash
```

#### 2. 연결 확인
```bash
# Elasticsearch 연결 테스트
curl -k -u elastic:PASSWORD 'https://localhost:9200/_cluster/health'

# Logstash 로그 모니터링
sudo journalctl -u logstash --no-pager -f
```

#### 3. 성공 지표
```bash
# 로그에서 이런 메시지가 보이면 성공
[INFO ][logstash.outputs.elasticsearch][main] Restored connection to ES instance
[INFO ][logstash.outputs.elasticsearch][main] Elasticsearch version determined (8.18.3)
```

### 결과 확인

#### 인덱스 데이터 확인
```bash
# 수집된 인덱스 목록 확인
curl -k -u elastic:PASSWORD -s 'https://localhost:9200/_cat/indices?v' | grep moongsan

# 최신 로그 확인  
curl -k -u elastic:PASSWORD -s 'https://localhost:9200/moongsan-logs-2025.07.09/_search?size=3&sort=@timestamp:desc'
```

#### 예상 결과
- 수백만 개의 로그 데이터 확인
- AI 서비스: `service: ai-moongsan`, `server: ai`
- Backend 서비스: `service: [backend-api, backend-service]`, `server: backend`

### 예방 조치

#### 1. 모니터링 알림 설정
```bash
# Logstash 상태 체크 스크립트
#!/bin/bash
if ! systemctl is-active logstash > /dev/null; then
    echo "❌ Logstash가 중단되었습니다!"
    # 알림 발송 로직 추가
fi
```

#### 2. 정기 점검 항목
- [ ] ELK 스택 서비스 상태 (elasticsearch, kibana, logstash)
- [ ] Filebeat 상태 (prod-ai, prod-backend)
- [ ] 일일 로그 수집량 확인
- [ ] Elasticsearch 디스크 사용량

#### 3. 설정 변경 시 주의사항
- Elasticsearch 인증 설정 변경 시 Logstash 재시작 필수
- SSL 인증서 갱신 시 모든 Beats 재시작 필요
- 네트워크 설정 변경 시 연결 테스트 필수

### 성능 최적화

#### Logstash 설정 최적화
```yaml
# /etc/logstash/conf.d/beats-input.conf
output {
  elasticsearch {
    hosts => ["https://localhost:9200"]
    user => "elastic"
    password => "PASSWORD"
    ssl_verification_mode => "none"
    index => "%{[@metadata][index]}"
    retry_initial_interval => 5
    retry_max_interval => 30
    # 성능 향상을 위한 배치 설정
    flush_size => 500
    idle_flush_time => 5
  }
}
```

---

## 최신 해결 사례 (2025-06-23)

### 🚨 **문제**: prod 환경 내부 VM에서 인터넷 연결 불가

**증상**:
```bash
# prod 내부 VM에서
ping 8.8.8.8  # 실패
apt update    # 실패
```
원인: NAT Gateway는 생성되었으나 기본 라우트(prod-default-route)가 누락

✅ 해결방법:
```bash
# 1. 누락된 라우트 생성
gcloud compute routes create prod-default-route \
    --project=moongsan-admin \
    --network=prod-vpc \
    --destination-range=0.0.0.0/0 \
    --next-hop-gateway=projects/moongsan-admin/global/gateways/default-internet-gateway \
    --priority=1000

# 2. Terraform 상태에 임포트
terraform import google_compute_route.prod_default_route prod-default-route

# 3. 상태 확인
terraform plan  # No changes 확인
```

🚨 문제: AI 서비스 ChromeDriver 버전 불일치
증상:

```bash
# AI 컨테이너 로그에서
selenium.common.exceptions.SessionNotCreatedException: Message: session not created: 
This version of ChromeDriver only supports Chrome version 114
Current browser version is 131.0.6778.108
```
원인: Chrome 137+ 버전에 대한 ChromeDriver API 변경

✅ 해결방법 (Dockerfile.j2 수정):
```Docker
# Chrome for Testing API 사용
RUN CHROME_VERSION=$(google-chrome --version | awk '{print $3}') && \
    if [[ "$CHROME_VERSION" > "114" ]]; then \
        wget -O /tmp/chromedriver.zip \
             "https://storage.googleapis.com/chrome-for-testing-public/${CHROME_VERSION}/linux64/chromedriver-linux64.zip" && \
        cd /tmp && \
        unzip chromedriver.zip && \
        mv chromedriver-linux64/chromedriver /usr/local/bin/chromedriver; \
    else \
        # 기존 방식 유지
        CHROME_MAJOR=${CHROME_VERSION%%.*} && \
        DRIVER_VERSION=$(curl -fsS "https://chromedriver.storage.googleapis.com/LATEST_RELEASE_${CHROME_MAJOR}") && \
        wget -O /tmp/chromedriver.zip \
             "https://chromedriver.storage.googleapis.com/${DRIVER_VERSION}/chromedriver_linux64.zip"; \
    fi
```

🚨 문제: AI 서비스 GCP 인증 실패
증상:
```bash
# AI 컨테이너 로그에서
google.auth.exceptions.MalformedError: Unable to parse JSON key file: Expecting ',' delimiter
```
원인: service-account.json의 private_key 필드에 개행 문자 처리 문제

✅ 해결방법 (service-account.json.j2 수정):
```json
{
  "private_key": "{{ gcp.ai.private_key | trim | replace('\n', '\\n') }}"
}
```

🚨 문제: AI 서비스 Backend API 엔드포인트 파싱 오류

증상:
```bash
# AI 컨테이너 로그에서
requests.exceptions.InvalidURL: Invalid URL '/users/token': No scheme supplied.
```
원인: BACKEND_URL에 /api 경로 누락

✅ 해결방법 (group_vars/prod/all.yml 수정):
```yaml
ai:
  backend_url: "http://{{ internal_ips.backend }}:{{ app_ports.backend }}/api"
```

🚨 문제: 프론트엔드 배포 시 S3 버킷명 하드코딩
증상: constants.ts에 하드코딩된 버킷명으로 환경별 배포 불가

✅ 해결방법 (fe_gcs_deploy 역할에 추가):
```yaml
- name: Replace S3 bucket name in constants.ts
  replace:
    path: "{{ project_paths.fe_repo }}/src/constants.ts"
    regexp: 'S3_BUCKET_NAME\s*=\s*["\'][^"\']*["\']'
    replace: 'S3_BUCKET_NAME = "{{ gcs.frontend.bucket_name }}"'
```
🚨 문제: 운영 DB 덤프 임포트 자동화 필요

✅ 해결방법 (simple_db_fix.yml 플레이북 생성):
```yaml
- name: Import database dump to production
  mysql_db:
    name: "{{ mysql.database }}"
    state: import
    target: /tmp/dump.sql
    login_host: "{{ internal_ips.database }}"
    login_user: "{{ mysql.user }}"
    login_password: "{{ mysql.password }}"
```
사용법:
```bash
ansible-playbook -i prod.ini playbooks/simple_db_fix.yml
```
🚨 문제: Terraform 상태와 실제 인프라 불일치

증상: terraform plan에서 이미 존재하는 리소스를 생성하려고 시도

✅ 해결방법:
```bash
# 1. 기존 리소스를 상태에 임포트
terraform import google_compute_route.prod_default_route prod-default-route

# 2. 상태 확인
terraform state list

# 3. 계획 검증
terraform plan  # "No changes" 나와야 함
```
🚨 문제: DBeaver를 통한 prod DB 직접 접속

✅ 해결방법:
```conf
Connection Settings:
- Host: 10.1.0.2 (내부 IP - WireGuard VPN 필요)
```

### 📞 에스컬레이션 절차

1. **Level 1**: 자동 복구 시도 (스크립트)
2. **Level 2**: 수동 서비스 재시작
3. **Level 3**: 백업에서 복원
4. **Level 4**: 인프라 재배포

---

> 🛠️ **문제해결 팁**: 문제가 발생하면 당황하지 말고 단계별로 차근차근 확인하세요. 대부분의 문제는 설정 오류나 권한 문제입니다.

## 📚 관련 문서

- [Backend → MySQL 연결 완전 가이드](./backend-mysql-connection-guide.md)
- [인프라 아키텍처 가이드](./infrastructure-architecture.md)
- [배포 가이드](./deployment-guide.md)
- [보안 가이드](./security-guide.md)

---

**문서 최종 업데이트**: 2025-06-13  
**주요 추가 내용**: Backend → MySQL 연결 문제 완전 해결 가이드 추가
