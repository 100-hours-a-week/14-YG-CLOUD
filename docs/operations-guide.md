# 🚀 운영 가이드

> **14-YG-CLOUD 인프라 운영을 위한 완전한 가이드** - 일상적인 운영 작업부터 비상 상황까지

## 📋 목차

- [일상 운영](#일상-운영)
- [배포 운영](#배포-운영)  
- [모니터링 운영](#모니터링-운영)
- [보안 운영](#보안-운영)
- [백업 및 복구](#백업-및-복구)
- [비상 상황 대응](#비상-상황-대응)

---

## 일상 운영

### 🔍 시스템 상태 확인

#### 인프라 상태 점검
```bash
# 1. 모든 VM 상태 확인
gcloud compute instances list --project=your-project-id

# 2. 로드밸런서 상태 확인  
gcloud compute forwarding-rules list --global

# 3. VPN 연결 상태 확인
sudo wg show
```

#### 애플리케이션 상태 점검
```bash
# 1. Backend API 상태 (Jump Box에서)
curl -s http://10.0.1.10:8080/health | jq

# 2. AI 서비스 상태
curl -s http://10.0.1.30:8100/health | jq

# 3. 데이터베이스 연결 상태
mysql -h 10.0.1.20 -u app_user -p -e "SELECT 1"
```

### 📊 리소스 사용량 모니터링

#### CPU 및 메모리 확인
```bash
# 각 서버에서 실행
top -bn1 | head -20
free -h
df -h
```

#### 네트워크 트래픽 확인
```bash
# 네트워크 사용량
iftop -t -s 60
netstat -i
```

### 🔄 서비스 재시작

#### Backend API 서비스
```bash
# Jump Box에서 SSH로 접속
ssh -i ~/.ssh/gcp_key ubuntu@10.0.1.10

# 서비스 재시작
sudo systemctl restart backend-api
sudo systemctl status backend-api
```

#### AI 서비스
```bash
ssh -i ~/.ssh/gcp_key ubuntu@10.0.1.30
sudo systemctl restart ai-service
sudo systemctl status ai-service
```

#### 데이터베이스 서비스
```bash
ssh -i ~/.ssh/gcp_key ubuntu@10.0.1.20
sudo systemctl restart mysql
sudo systemctl restart redis
```

---

## 배포 운영

### 📦 새 버전 배포

#### 1. 사전 준비
```bash
# Git에서 최신 코드 확인
git status
git pull origin main

# 인프라 상태 확인
cd terraform/environments/test
terraform plan -var-file="terraform.tfvars"
```

#### 2. 배포 실행
```bash
# Ansible로 애플리케이션 배포
cd ansible
ansible-playbook -i inventories/test.ini main.yml -e "env=test" --vault-password-file .vault_pass
```

#### 3. 배포 검증
```bash
# 서비스 상태 확인
ansible -i inventories/test.ini all -m command -a "systemctl status backend-api"

# 헬스체크
curl -s http://your-domain.com/api/health
curl -s http://your-domain.com/generation/health
```

### 🎯 환경별 배포

#### Test 환경 배포
```bash
# 1. 인프라 변경사항 적용
cd terraform/environments/test
terraform apply -var-file="terraform.tfvars"

# 2. 애플리케이션 배포  
cd ../../ansible
ansible-playbook -i inventories/test.ini main.yml -e "env=test"
```

#### Production 배포
```bash
# 1. Test 환경에서 검증 완료 후
cd terraform/environments/prod
terraform apply -var-file="terraform.tfvars"

# 2. 프로덕션 배포
cd ../../ansible
ansible-playbook -i inventories/prod.ini main.yml -e "env=prod"
```

### 🔄 롤백 절차

#### 1. 긴급 롤백 (코드)
```bash
# 이전 Git 커밋으로 롤백
git log --oneline -10
git checkout <previous-commit-hash>

# 재배포
ansible-playbook -i inventories/test.ini main.yml -e "env=test"
```

#### 2. 인프라 롤백
```bash
# Terraform 상태 복원
terraform state pull > backup.tfstate
terraform apply -var="previous_config=true"
```

---

## 모니터링 운영

### 📈 성능 모니터링

#### GCP 모니터링 대시보드
- **CPU 사용률**: < 80%
- **메모리 사용률**: < 85%  
- **디스크 사용률**: < 90%
- **네트워크 대역폭**: 정상 범위

#### 애플리케이션 로그 모니터링
```bash
# Backend API 로그
sudo journalctl -u backend-api -f

# AI 서비스 로그
sudo journalctl -u ai-service -f

# 시스템 로그
sudo tail -f /var/log/syslog
```

### 🚨 알림 설정

#### 중요 메트릭 임계값
- **CPU**: 80% 이상 5분 지속시 알림
- **메모리**: 90% 이상 3분 지속시 알림
- **디스크**: 95% 이상시 즉시 알림
- **서비스 다운**: 즉시 알림

#### 알림 채널
- 이메일: admin@company.com
- Slack: #infrastructure-alerts
- SMS: 긴급상황시

---

## 보안 운영

### 🔐 정기 보안 점검

#### 1. 인증서 갱신 (매월)
```bash
# Let's Encrypt 인증서 상태 확인
sudo certbot certificates

# 자동 갱신 테스트
sudo certbot renew --dry-run
```

#### 2. VPN 키 로테이션 (분기별)
```bash
# 새 WireGuard 키 생성
wg genkey | tee privatekey | wg pubkey > publickey

# 설정 업데이트
sudo nano /etc/wireguard/wg0.conf
```

#### 3. 시스템 업데이트 (매주)
```bash
# 모든 서버에서 실행
sudo apt update && sudo apt upgrade -y
sudo reboot  # 필요시
```

### 🛡️ 보안 모니터링

#### 로그인 시도 모니터링
```bash
# 실패한 SSH 로그인 시도
sudo grep "Failed password" /var/log/auth.log | tail -20

# 성공한 로그인
sudo grep "Accepted password" /var/log/auth.log | tail -10
```

#### 방화벽 상태 확인
```bash
# UFW 상태
sudo ufw status verbose

# iptables 규칙
sudo iptables -L -n
```

---

## 백업 및 복구

### 💾 정기 백업

#### 1. 데이터베이스 백업 (일일)
```bash
# MySQL 백업
mysqldump -h 10.0.1.20 -u backup_user -p database_name > backup_$(date +%Y%m%d).sql

# GCS에 업로드
gsutil cp backup_$(date +%Y%m%d).sql gs://your-backup-bucket/mysql/
```

#### 2. 설정 파일 백업 (주간)
```bash
# 중요 설정 백업
tar -czf config_backup_$(date +%Y%m%d).tar.gz \
    /etc/nginx/ \
    /etc/wireguard/ \
    /etc/systemd/system/

# GCS에 업로드
gsutil cp config_backup_$(date +%Y%m%d).tar.gz gs://your-backup-bucket/configs/
```

#### 3. Terraform 상태 백업 (배포시마다)
```bash
# 상태 파일 백업
terraform state pull > terraform_state_$(date +%Y%m%d_%H%M).json
gsutil cp terraform_state_$(date +%Y%m%d_%H%M).json gs://your-backup-bucket/terraform/
```

### 🔄 복구 절차

#### 1. 데이터베이스 복구
```bash
# 백업에서 복구
gsutil cp gs://your-backup-bucket/mysql/backup_20240101.sql .
mysql -h 10.0.1.20 -u root -p database_name < backup_20240101.sql
```

#### 2. 전체 시스템 복구
```bash
# 1. Terraform으로 인프라 재생성
cd terraform/environments/test
terraform apply -var-file="terraform.tfvars"

# 2. Ansible로 서비스 재설정
cd ../../ansible
ansible-playbook -i inventories/test.ini main.yml -e "env=test"

# 3. 데이터베이스 복구
# (위의 데이터베이스 복구 절차 따르기)
```

---

## 비상 상황 대응

### 🚨 서비스 장애 대응

#### 1단계: 즉시 대응 (5분 내)
```bash
# 서비스 상태 확인
curl -I http://your-domain.com

# 로드밸런서 백엔드 상태 확인
gcloud compute backend-services get-health backend-service --global
```

#### 2단계: 원인 분석 (15분 내)
```bash
# 시스템 로그 확인
sudo journalctl -xe

# 애플리케이션 로그 확인
sudo journalctl -u backend-api -n 100

# 리소스 사용량 확인
top
free -h
df -h
```

#### 3단계: 복구 조치 (30분 내)
```bash
# 서비스 재시작
sudo systemctl restart backend-api

# 또는 VM 재시작
gcloud compute instances reset INSTANCE_NAME --zone=ZONE
```

### 🔧 일반적인 문제 해결

#### Backend API 응답 없음
```bash
# 1. 프로세스 확인
ps aux | grep java

# 2. 포트 확인
netstat -tulpn | grep 8080

# 3. 서비스 재시작
sudo systemctl restart backend-api
```

#### AI 서비스 메모리 부족
```bash
# 1. 메모리 사용량 확인
free -h

# 2. 프로세스 메모리 확인
ps aux --sort=-%mem | head

# 3. 서비스 재시작 (메모리 해제)
sudo systemctl restart ai-service
```

#### 데이터베이스 연결 실패
```bash
# 1. MySQL 상태 확인
sudo systemctl status mysql

# 2. 연결 테스트
mysql -h 10.0.1.20 -u app_user -p -e "SELECT 1"

# 3. 재시작
sudo systemctl restart mysql
```

### 📞 에스컬레이션

#### 심각도별 대응
- **P1 (전체 서비스 다운)**: 즉시 관리자 연락
- **P2 (부분 서비스 영향)**: 30분 내 대응
- **P3 (경미한 문제)**: 업무시간 내 대응

#### 연락처
- **Primary**: admin@company.com
- **Secondary**: +82-10-1234-5678
- **Slack**: #emergency-response

---

## 📚 관련 문서

- [인프라 아키텍처](./infrastructure-architecture.md) - 시스템 구조 이해
- [배포 가이드](./deployment-guide.md) - 상세 배포 절차
- [보안 가이드](./security-guide.md) - 보안 설정 및 관리
- [문제해결 가이드](./troubleshooting-guide.md) - 상세 트러블슈팅
