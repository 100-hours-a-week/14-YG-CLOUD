# 🔧 문제해결 가이드

> **14-YG-CLOUD 프로젝트**에서 발생할 수 있는 모든 문제상황과 해결방법을 정리한 완전한 트러블슈팅 가이드입니다.

## 📋 목차

- [Terraform 문제해결](#terraform-문제해결)
- [Ansible 문제해결](#ansible-문제해결)
- [WireGuard VPN 문제해결](#wireguard-vpn-문제해결)
- [GCP 리소스 문제해결](#gcp-리소스-문제해결)
- [네트워크 연결 문제해결](#네트워크-연결-문제해결)
- [보안 관련 문제해결](#보안-관련-문제해결)

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

### 🔗 서비스 간 통신 문제

#### **문제**: Backend에서 Database 연결 실패
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

## 🆘 긴급 상황 대응

### 🚨 서비스 완전 중단

#### **1단계: 즉시 확인사항**
```bash
# 모든 서비스 상태 한번에 확인
curl -f http://LB_IP/health || echo "Load Balancer 문제"
ping -c 3 10.0.0.2 || echo "Backend 네트워크 문제"  
ping -c 3 10.0.0.3 || echo "Database 네트워크 문제"
```

#### **2단계: 로그 수집**
```bash
# 시스템 로그
sudo journalctl -xe

# Docker 로그  
sudo docker logs --tail 100 backend-container
sudo docker logs --tail 100 database-container

# Nginx 로그
sudo tail -f /var/log/nginx/error.log
```

#### **3단계: 서비스 재시작**
```bash
# Docker 컨테이너 재시작
sudo docker restart backend-container
sudo docker restart database-container

# Nginx 재시작
sudo systemctl restart nginx

# 전체 VM 재부팅 (최후 수단)
sudo reboot
```

### 📞 에스컬레이션 절차

1. **Level 1**: 자동 복구 시도 (스크립트)
2. **Level 2**: 수동 서비스 재시작
3. **Level 3**: 백업에서 복원
4. **Level 4**: 인프라 재배포

---

> 🛠️ **문제해결 팁**: 문제가 발생하면 당황하지 말고 단계별로 차근차근 확인하세요. 대부분의 문제는 설정 오류나 권한 문제입니다.
