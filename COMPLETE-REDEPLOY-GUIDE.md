# 🚀 완전한 3-Tier 재배포 가이드

이 가이드는 Terraform 완전 삭제 후 전체 3-tier 구조를 처음부터 재구성하는 절차입니다.

## 🆕 신규 사용자 필수 준비사항

> ⚠️ **중요**: 이 repository를 clone한 후 반드시 아래 항목들을 별도로 준비해야 합니다!

### 1. 🔐 SSH 키 설정 (필수)
```bash
# 1. SSH 키 생성 (없는 경우)
ssh-keygen -t rsa -b 4096 -C "your-email@example.com" -f ~/.ssh/lsh-study-key

# 2. SSH 키 권한 설정
chmod 600 ~/.ssh/lsh-study-key
chmod 644 ~/.ssh/lsh-study-key.pub

# 3. SSH 키를 GCP 프로젝트에 등록
# - GCP Console > Compute Engine > Metadata > SSH Keys
# - ~/.ssh/lsh-study-key.pub 내용을 복사하여 추가
# - Username: lsh (jumpbox용), ubuntu (VM용)
```

### 2. 🔑 Ansible Vault 패스워드 설정 (필수)
```bash
# Ansible vault 패스워드 파일 생성
echo "your-vault-password-here" > ~/.ansible_vault_pass
chmod 600 ~/.ansible_vault_pass

# 환경변수 설정 (선택사항, 매번 --ask-vault-pass 생략 가능)
echo 'export ANSIBLE_VAULT_PASSWORD_FILE=~/.ansible_vault_pass' >> ~/.zshrc
source ~/.zshrc
```

### 3. 🌐 WireGuard VPN 설정 (내부 네트워크 접근용)
```bash
# 1. WireGuard 설치 (macOS)
brew install wireguard-tools

# 2. 개인 클라이언트 설정 파일 요청
# - 관리자에게 개인별 .conf 파일 요청
# - 예: john-client.conf, jane-client.conf

# 3. WireGuard 연결
sudo wg-quick up /path/to/your-client.conf

# 4. 연결 확인
ping 10.0.0.2  # database 서버 접근 테스트
```

### 4. 🔧 로컬 환경 설정
```bash
# 1. 필수 도구 설치
brew install terraform ansible jq curl

# 2. Terraform 버전 확인 (1.5+ 권장)
terraform --version

# 3. Ansible 버전 확인 (2.12+ 권장)
ansible --version

# 4. SSH Agent 설정
ssh-add ~/.ssh/lsh-study-key
ssh-add -l  # 키 등록 확인
```

### 5. 🔐 GCP 서비스 계정 키 (Terraform 실행용)
```bash
# 1. GCP 서비스 계정 키 JSON 파일 획득
# - 관리자에게 서비스 계정 키 파일 요청
# - 또는 GCP Console에서 직접 생성

# 2. 키 파일 저장 및 권한 설정
mv service-account-key.json ~/.gcp/terraform-key.json
chmod 600 ~/.gcp/terraform-key.json

# 3. 환경변수 설정
echo 'export GOOGLE_APPLICATION_CREDENTIALS=~/.gcp/terraform-key.json' >> ~/.zshrc
source ~/.zshrc
```

### 6. 📁 Repository 설정
```bash
# 1. Repository clone
git clone https://github.com/your-org/3tier-moongsan.git
cd 3tier-moongsan/14-YG-CLOUD

# 2. .gitignore 확인 (민감한 파일들이 제외되어 있는지)
cat .gitignore
# 다음 항목들이 포함되어야 함:
# *.tfstate
# *.tfstate.backup
# .terraform/
# *.pem
# *.key
# *vault_pass*
# service-account-key.json

# 3. 환경별 설정 파일 복사 (템플릿에서)
cp ansible/group_vars/test/all.yml.template ansible/group_vars/test/all.yml
# 개인 환경에 맞게 수정
```

### 7. 🎯 초기 설정 스크립트
```bash
#!/bin/bash
# setup-new-user.sh - 신규 사용자 환경 설정

echo "🚀 신규 사용자 환경 설정을 시작합니다..."

# SSH 키 확인
if [ ! -f ~/.ssh/lsh-study-key ]; then
    echo "❌ SSH 키가 없습니다. ~/.ssh/lsh-study-key를 생성하거나 복사하세요."
    exit 1
fi

# WireGuard 연결 확인
if ! ping -c 1 10.0.0.2 >/dev/null 2>&1; then
    echo "❌ WireGuard VPN이 연결되지 않았습니다."
    echo "   sudo wg-quick up your-client.conf 를 실행하세요."
    exit 1
fi

# Ansible vault 패스워드 확인
if [ ! -f ~/.ansible_vault_pass ]; then
    echo "❌ Ansible vault 패스워드 파일이 없습니다."
    echo "   echo 'password' > ~/.ansible_vault_pass 를 실행하세요."
    exit 1
fi

# GCP 인증 확인
if [ -z "$GOOGLE_APPLICATION_CREDENTIALS" ]; then
    echo "❌ GCP 서비스 계정 키가 설정되지 않았습니다."
    exit 1
fi

# Ansible 연결 테스트
echo "🔍 Ansible 연결 테스트..."
cd ansible
if ansible -i test.ini all -m ping; then
    echo "✅ 모든 준비가 완료되었습니다!"
    echo "🎉 이제 배포를 시작할 수 있습니다."
else
    echo "❌ Ansible 연결에 실패했습니다. 설정을 다시 확인하세요."
    exit 1
fi
```

### 8. 🔒 보안 주의사항

#### 절대 Git에 커밋하면 안 되는 파일들:
- `~/.ssh/lsh-study-key` (개인 SSH 키)
- `~/.ansible_vault_pass` (Vault 패스워드)
- `*.conf` (WireGuard 클라이언트 설정)
- `service-account-key.json` (GCP 서비스 계정 키)
- `terraform.tfstate*` (Terraform 상태 파일)
- `.terraform/` (Terraform 캐시)

#### 권한 설정:
```bash
# SSH 키
chmod 600 ~/.ssh/lsh-study-key
chmod 644 ~/.ssh/lsh-study-key.pub

# Ansible vault
chmod 600 ~/.ansible_vault_pass

# GCP 키
chmod 600 ~/.gcp/terraform-key.json

# WireGuard 설정
chmod 600 ~/wireguard/*.conf
```

### 9. 🚀 첫 실행 체크리스트

신규 사용자는 다음 순서로 확인하세요:

#### ✅ 사전 준비 완료 확인
- [ ] SSH 키 생성 및 GCP 등록 완료
- [ ] Ansible Vault 패스워드 설정 완료
- [ ] WireGuard VPN 연결 및 내부 네트워크 접근 가능
- [ ] GCP 서비스 계정 키 설정 완료
- [ ] 필수 도구 설치 완료 (terraform, ansible, wg)

#### ✅ 연결 테스트
```bash
# 1. SSH 연결 테스트
ssh -i ~/.ssh/lsh-study-key lsh@34.22.110.81 "echo 'Jumpbox OK'"

# 2. WireGuard 테스트
ping -c 3 10.0.0.2

# 3. Ansible 연결 테스트
cd ansible
ansible -i test.ini all -m ping

# 4. Terraform 인증 테스트
cd terraform/environments/test
terraform init
```

#### ✅ 첫 배포 실행
```bash
# 위의 모든 테스트가 성공하면 배포 시작
ansible-playbook -i test.ini playbooks/main.yml
```

### 10. 📞 문제 해결 연락처

설정 중 문제가 발생하면:
1. **SSH 키 문제**: 관리자에게 GCP SSH 키 등록 요청
2. **WireGuard 문제**: 관리자에게 개인 클라이언트 설정 파일 요청
3. **Vault 패스워드**: 관리자에게 현재 vault 패스워드 확인
4. **GCP 권한**: 관리자에게 서비스 계정 키 및 프로젝트 권한 요청

---

## 📋 사전 준비

### 1. 환경 확인
```bash
# 현재 디렉토리 확인
pwd
# 출력: /Users/lsh/Documents/local/3tier-moongsan/14-YG-CLOUD

# Git 상태 확인
git status
git add . && git commit -m "Pre-redeploy backup"
```

### 2. 백업 (중요!)
```bash
# Terraform 상태 백업
cd terraform/environments/test
cp terraform.tfstate terraform.tfstate.backup.$(date +%Y%m%d_%H%M%S)

# Ansible 설정 백업
cd ../../../ansible
tar -czf ansible_backup_$(date +%Y%m%d_%H%M%S).tar.gz group_vars/ roles/ playbooks/ *.ini
```

## 🗑️ 1단계: 완전한 리소스 정리

### Terraform Destroy
```bash
cd terraform/environments/test

# 현재 상태 확인
terraform state list

# 완전 삭제 (주의: 모든 리소스 삭제됨)
terraform destroy -auto-approve

# 상태 파일 정리
rm -f terraform.tfstate terraform.tfstate.backup
rm -rf .terraform/
```

### 로컬 정리
```bash
# Docker 정리 (필요시)
docker system prune -a -f

# SSH known_hosts 정리 (VM 재생성으로 호스트 키 변경됨)
ssh-keygen -R 10.0.0.2  # database
ssh-keygen -R 10.0.0.3  # backend  
ssh-keygen -R 10.0.0.4  # ai
```

## 🔗 1.5단계: VPC 피어링 확인 (중요!)

### Shared 환경 상태 확인
```bash
cd terraform/environments/shared

# Shared VPC와 jumpbox 상태 확인
terraform show | grep -A 5 "google_compute_network_peering"

# VPC 피어링이 INACTIVE 상태라면 재적용 필요
terraform apply -auto-approve
```

### VPC 피어링 문제 해결
```bash
# 피어링 상태가 비정상이면 shared 환경 재적용
cd terraform/environments/shared
terraform apply -auto-approve

# 피어링 양방향 연결 확인
terraform show | grep "state.*=" | grep -E "(ACTIVE|INACTIVE)"
```

## 🏗️ 2단계: Terraform 인프라 재구성

### 인프라 생성
```bash
cd terraform/environments/test

# Terraform 초기화
terraform init

# 플랜 검토
terraform plan

# 인프라 생성
terraform apply -auto-approve
```

### 생성 완료 확인
```bash
# 리소스 상태 확인
terraform state list

# 출력값 확인
terraform output

# 중요 IP 확인
terraform output -json | jq '.vm_ips.value'
```

## ⏱️ 3단계: 인프라 준비 대기 및 네트워크 연결 확인

### VM 부팅 대기
```bash
# VM 부팅 완료 대기 (약 2-3분)
echo "Waiting for VMs to be ready..."
sleep 180
```

### ProxyJump 연결 테스트 (중요!)
```bash
# Shared jumpbox 연결 확인
ssh -i ~/.ssh/lsh-study-key lsh@34.22.110.81 "echo 'Jumpbox connected'"

# Shared jumpbox에서 내부 VM으로 네트워크 연결 확인
ssh -i ~/.ssh/lsh-study-key lsh@34.22.110.81 "ping -c 3 10.0.0.2"  # database
ssh -i ~/.ssh/lsh-study-key lsh@34.22.110.81 "ping -c 3 10.0.0.3"  # backend
ssh -i ~/.ssh/lsh-study-key lsh@34.22.110.81 "ping -c 3 10.0.0.4"  # ai
```

### SSH 키 충돌 해결 (VM 재생성 후 필수!)
```bash
# VM이 재생성되면서 호스트 키가 변경되므로 기존 키 제거
ssh-keygen -R 10.0.0.2  # database
ssh-keygen -R 10.0.0.3  # backend  
ssh-keygen -R 10.0.0.4  # ai

# ProxyJump를 통한 SSH 연결 테스트
ssh -i ~/.ssh/lsh-study-key -o ProxyJump="lsh@34.22.110.81" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ubuntu@10.0.0.2 "echo 'Database SSH OK'"
ssh -i ~/.ssh/lsh-study-key -o ProxyJump="lsh@34.22.110.81" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ubuntu@10.0.0.3 "echo 'Backend SSH OK'"
ssh -i ~/.ssh/lsh-study-key -o ProxyJump="lsh@34.22.110.81" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ubuntu@10.0.0.4 "echo 'AI SSH OK'"
```

## 🚀 4단계: Ansible 전체 배포

### 인벤토리 업데이트 (필요시)
```bash
cd ansible

# Shared jumpbox IP 확인 (인벤토리에 이미 설정되어 있어야 함)
# shared-jumpbox ansible_host=34.22.110.81 ansible_user=lsh

# 내부 IP는 고정이므로 변경 불필요:
# test-backend ansible_host=10.0.0.3
# test-ai ansible_host=10.0.0.4  
# test-database ansible_host=10.0.0.2
```

### Ansible 연결 테스트 (중요!)
```bash
cd ansible

# Shared jumpbox 연결 테스트
ansible -i test.ini jumpbox -m ping

# 내부 서버 ProxyJump 연결 테스트
ansible -i test.ini internal_servers -m ping

# 모든 서버 연결 테스트
ansible -i test.ini all -m ping

# 예상 출력:
# shared-jumpbox | SUCCESS => { "ping": "pong" }
# test-database | SUCCESS => { "ping": "pong" }
# test-backend | SUCCESS => { "ping": "pong" }  
# test-ai | SUCCESS => { "ping": "pong" }
```

### 전체 배포 실행
```bash
# 🎯 완전한 3-tier 배포 (한 번에!)
ansible-playbook -i test.ini playbooks/main.yml

# 또는 단계별 배포
ansible-playbook -i test.ini playbooks/main.yml --tags "base"      # 1. 기본 시스템
ansible-playbook -i test.ini playbooks/main.yml --tags "database"  # 2. 데이터베이스  
ansible-playbook -i test.ini playbooks/main.yml --tags "backend"   # 3. 백엔드 + Redis
ansible-playbook -i test.ini playbooks/main.yml --tags "ai"        # 4. AI 서비스
ansible-playbook -i test.ini playbooks/main.yml --tags "frontend"  # 5. 프론트엔드
```

### 트러블슈팅: 연결 실패 시
```bash
# SSH Agent 포워딩 확인
ssh-add -l

# SSH 키 경로 확인
ls -la ~/.ssh/lsh-study-key*

# ProxyJump 수동 테스트
ssh -i ~/.ssh/lsh-study-key -o ProxyJump="lsh@34.22.110.81" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ubuntu@10.0.0.3

# VPC 피어링 상태 재확인
cd ../terraform/environments/shared
terraform show | grep "state.*=" | grep -E "(ACTIVE|INACTIVE)"
```

## ✅ 5단계: 배포 검증

### 서비스 상태 확인
```bash
# 데이터베이스 확인
ansible database -i test.ini -m shell -a "docker ps | grep mysql" --become

# Redis 확인  
ansible backend -i test.ini -m shell -a "docker exec redis-moongsan redis-cli ping" --become

# Redis 마스터 모드 확인
ansible backend -i test.ini -m shell -a "docker exec redis-moongsan redis-cli INFO replication | grep role:master" --become

# 백엔드 서비스 확인
ansible backend -i test.ini -m shell -a "curl -s http://localhost:8080/health || echo 'Backend not ready yet'" --become

# AI 서비스 확인  
ansible ai -i test.ini -m shell -a "curl -s http://localhost:8100/health || echo 'AI not ready yet'" --become
```

### 웹 접근 테스트
```bash
# 도메인 접근 (브라우저에서)
echo "https://test.moongsan.com"

# 또는 curl 테스트
curl -I https://test.moongsan.com
```

## 🎯 6단계: 전체 시스템 동작 테스트

### Redis 쓰기/읽기 테스트
```bash
ansible backend -i test.ini -m shell -a 'docker exec redis-moongsan redis-cli SET deployment_test "$(date) - Full redeploy successful"' --become

ansible backend -i test.ini -m shell -a 'docker exec redis-moongsan redis-cli GET deployment_test' --become
```

### 데이터베이스 연결 테스트
```bash
ansible database -i test.ini -m shell -a 'docker exec mysql-moongsan mysql -u root -ppass -e "SHOW DATABASES;"' --become
```

### 백엔드 API 테스트
```bash
# Health check
curl https://test.moongsan.com/api/health

# 또는 내부 네트워크에서
ansible backend -i test.ini -m shell -a "curl -s http://localhost:8080/actuator/health"
```

## 📊 7단계: 성능 및 완성도 확인

### 전체 시스템 상태 요약
```bash
# 모든 Docker 컨테이너 상태
ansible all -i test.ini -m shell -a "docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'" --become

# 디스크 사용량
ansible all -i test.ini -m shell -a "df -h /" 

# 메모리 사용량
ansible all -i test.ini -m shell -a "free -h"
```

## 🚨 트러블슈팅

### 자주 발생하는 문제들

1. **SSH 연결 실패**
   ```bash
   # WireGuard VPN 연결 확인
   ping 10.0.0.2
   
   # SSH 키 권한 확인
   chmod 600 ~/.ssh/id_rsa
   ```

2. **Redis READONLY 에러**
   ```bash
   # 자동으로 해결되어야 하지만, 수동 확인
   ansible backend -i test.ini -m shell -a "docker exec redis-moongsan redis-cli REPLICAOF NO ONE" --become
   ```

3. **MySQL 연결 실패**
   ```bash
   # MySQL 컨테이너 로그 확인
   ansible database -i test.ini -m shell -a "docker logs mysql-moongsan --tail 20" --become
   ```

4. **프론트엔드 404 에러**
   ```bash
   # GCS 버킷 업로드 확인
   ansible-playbook -i test.ini playbooks/main.yml --tags "frontend"
   ```

## 🛠️ 트러블슈팅 가이드

### 🔗 VPC 피어링 문제

#### 증상: Ansible 연결 실패 (Connection timed out)
```bash
# 오류 예시:
# fatal: [test-backend]: UNREACHABLE! => changed=false 
#   msg: Data could not be sent to remote host "10.0.0.3". Make sure this host can be reached over ssh: Connection timed out during banner exchange
```

#### 해결 방법:
```bash
# 1. VPC 피어링 상태 확인
cd terraform/environments/shared
terraform show | grep -A 3 "google_compute_network_peering"

# 2. INACTIVE 상태라면 shared 환경 재적용
terraform apply -auto-approve

# 3. 피어링 양방향 연결 확인
# shared-to-test: ACTIVE
# test-to-shared: ACTIVE 이어야 정상
```

### 🔑 SSH 키 충돌 문제

#### 증상: Host key verification failed
```bash
# 오류 예시:
# @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
# @    WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!     @
# @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
```

#### 해결 방법:
```bash
# VM 재생성 후 호스트 키 초기화 (필수!)
ssh-keygen -R 10.0.0.2  # database
ssh-keygen -R 10.0.0.3  # backend  
ssh-keygen -R 10.0.0.4  # ai

# 또는 전체 known_hosts 백업 후 초기화
cp ~/.ssh/known_hosts ~/.ssh/known_hosts.backup
> ~/.ssh/known_hosts
```

### 🐳 Docker 설치 문제

#### 증상: database 서버에서 Docker 컨테이너 실행 실패
```bash
# 오류 예시:
# Error connecting: Error while fetching server API version: ('Connection aborted.', FileNotFoundError(2, 'No such file or directory'))
```

#### 해결 방법:
```bash
# base_system 역할에서 database도 Docker 설치하도록 수정됨
# 재배포 시 자동 해결됨

# 수동 확인:
ansible database -i test.ini -m shell -a "docker --version"
ansible database -i test.ini -m shell -a "sudo systemctl status docker"
```

### 🌐 Docker 네트워크 문제

#### 증상: network named moongsan-net could not be found
```bash
# 오류 예시:
# Parameter error: network named moongsan-net could not be found. Does it exist?
```

#### 해결 방법:
```bash
# docker_net 역할이 database 배포에 추가됨
# playbooks/main.yml에서 database 섹션에 Docker 네트워크 설정 포함

# 수동 확인:
ansible database -i test.ini -m shell -a "docker network ls" --become
```

### 📝 변수 참조 문제

#### 증상: 'mongo' is undefined
```bash
# 오류 예시:
# AnsibleUndefinedVariable: 'mongo' is undefined
```

#### 해결 방법:
```bash
# be_deploy 템플릿에서 변수 참조 수정됨:
# {{ mongo.host }} → {{ db.mongo.host }}

# 변수 구조 확인:
cd ansible
grep -r "mongo" group_vars/test/all.yml
```

### 🤖 AI 서비스 빌드 문제

#### 증상: Dependency resolution exceeded maximum depth
```bash
# 오류 예시:
# × Dependency resolution exceeded maximum depth
# ╰─> Pip cannot resolve the current dependencies as the dependency graph is too complex
```

#### 해결 방법 (향후 개선):
```bash
# 1. requirements.txt 버전 고정
# 2. pip resolver 옵션 조정:
#    pip install --use-deprecated=legacy-resolver
# 3. conda 환경 사용 고려
# 4. 다단계 Docker 빌드 최적화

# 현재는 AI 서비스를 제외하고 배포 진행 가능
ansible-playbook -i test.ini playbooks/main.yml --skip-tags "ai"
```

### 🔍 일반적인 확인 사항

#### 서비스 상태 확인
```bash
# 전체 컨테이너 상태
ssh -i ~/.ssh/lsh-study-key -o ProxyJump="lsh@34.22.110.81" ubuntu@10.0.0.2 "sudo docker ps"  # database
ssh -i ~/.ssh/lsh-study-key -o ProxyJump="lsh@34.22.110.81" ubuntu@10.0.0.3 "sudo docker ps"  # backend

# 로그 확인
ssh -i ~/.ssh/lsh-study-key -o ProxyJump="lsh@34.22.110.81" ubuntu@10.0.0.3 "sudo docker logs be-moongsan --tail 50"
```

#### 네트워크 연결 확인
```bash
# Jumpbox에서 내부 VM ping 테스트
ssh -i ~/.ssh/lsh-study-key lsh@34.22.110.81 "ping -c 3 10.0.0.2"

# 포트 연결 확인
ssh -i ~/.ssh/lsh-study-key lsh@34.22.110.81 "nc -zv 10.0.0.2 3306"  # MySQL
ssh -i ~/.ssh/lsh-study-key lsh@34.22.110.81 "nc -zv 10.0.0.3 8080"  # Backend
```

## ✅ 배포 성공 체크리스트

### 1️⃣ 인프라 레벨
- [ ] Terraform destroy 완료 (모든 리소스 삭제)
- [ ] Terraform apply 완료 (31개 리소스 생성)
- [ ] VPC 피어링 ACTIVE 상태 (shared ↔ test)
- [ ] SSH 키 초기화 완료

### 2️⃣ 네트워크 레벨  
- [ ] Shared jumpbox 연결 성공 (34.22.110.81)
- [ ] ProxyJump를 통한 내부 VM 연결 성공
- [ ] Ansible ping 테스트 모든 서버 성공

### 3️⃣ 서비스 레벨
- [ ] **데이터베이스**: `mysql-moongsan` 컨테이너 실행 (포트 3306)
- [ ] **백엔드**: `be-moongsan` 컨테이너 실행 (포트 8080)
- [ ] **Redis**: `redis-moongsan` 마스터 모드 실행 (포트 6379)  
- [ ] **MongoDB**: `mongo-moongsan` 컨테이너 실행 (포트 27017)
- [ ] **프론트엔드**: GCS + CDN 배포 완료

### 4️⃣ 기능 레벨
- [ ] Redis 마스터 모드 확인: `role:master`
- [ ] MySQL max_connections 500 설정
- [ ] 프론트엔드 사이트 접근: https://test.moongsan.com
- [ ] CDN 캐시 무효화 완료

## 🎉 배포 성공 예시

### 성공적인 배포 결과:
```bash
# 컨테이너 상태 (예상 출력)
$ ssh ubuntu@10.0.0.2 "sudo docker ps"
NAMES            STATUS       PORTS
mysql-moongsan   Up 2 hours   0.0.0.0:3306->3306/tcp, 33060/tcp

$ ssh ubuntu@10.0.0.3 "sudo docker ps"  
NAMES            STATUS          PORTS
be-moongsan      Up 38 minutes   0.0.0.0:8080->8080/tcp
redis-moongsan   Up 41 minutes   0.0.0.0:6379->6379/tcp
mongo-moongsan   Up 2 hours      0.0.0.0:27017->27017/tcp

# Redis 마스터 모드 확인
$ docker exec redis-moongsan redis-cli INFO replication | grep role
role:master

# 프론트엔드 배포 완료
✅ Frontend deployment completed successfully!
🌍 Frontend URL: https://test.moongsan.com
💾 Bucket: moongsan-test-frontend
🔄 Cache invalidation: Success
```

## 🚀 다음 단계: Production 마이그레이션

test 환경에서 모든 체크리스트가 통과되면 prod 환경으로 마이그레이션을 진행할 수 있습니다:

1. **설정 복사**: `test.ini` → `prod.ini`, `group_vars/test/` → `group_vars/prod/`
2. **도메인 변경**: `test.moongsan.com` → `moongsan.com`  
3. **보안 강화**: SSH 접근 제한, 방화벽 규칙 최적화
4. **백업 설정**: 운영 데이터 백업 스케줄 설정
5. **모니터링**: 로그 수집 및 알림 설정

---

## 📋 요약

이 가이드를 통해 **완전한 3-tier 자동화 배포**가 성공적으로 구현되었습니다:

- 🏗️ **Terraform**: 인프라 완전 자동화 (destroy → apply)
- 🔧 **Ansible**: 서버 설정 및 애플리케이션 배포 완전 자동화  
- 🌐 **VPC 피어링**: shared jumpbox를 통한 안전한 내부 접근
- 🐳 **Docker**: 모든 서비스 컨테이너화
- ⚡ **Redis**: 항상 마스터 모드 보장
- 🌍 **CDN**: 프론트엔드 GCS + CDN 자동 배포

**한 번의 명령어로 전체 3-tier 스택을 완전히 재구성**할 수 있는 완전 자동화 환경이 완성되었습니다! 🎉

---

# 🔐 신규 사용자를 위한 필수 준비물 가이드

이 프로젝트를 새로 clone하여 사용하려면 다음 파일들과 설정이 **별도로 필요**합니다.

## 🔴 필수 준비물 체크리스트

### 1. 🗝️ SSH 키 (필수)
```bash
# ~/.ssh/lsh-study-key (개인 키)
# ~/.ssh/lsh-study-key.pub (공개 키)

# 키 생성 방법:
ssh-keygen -t rsa -b 4096 -f ~/.ssh/lsh-study-key -C "your-email@domain.com"
chmod 600 ~/.ssh/lsh-study-key
chmod 644 ~/.ssh/lsh-study-key.pub

# 키 등록 필요한 곳:
# - GCP Compute Engine > 메타데이터 > SSH 키
# - 각 VM 인스턴스 (terraform으로 자동 등록됨)
```

### 2. 🛡️ Ansible Vault 패스워드 (필수)
```bash
# 파일 위치: ~/.ansible-vault-pass
# 또는 원하는 위치에 생성 후 환경변수 설정

# 패스워드 파일 생성:
echo "your-secure-vault-password" > ~/.ansible-vault-pass
chmod 600 ~/.ansible-vault-pass

# 환경변수 설정 (선택사항):
export ANSIBLE_VAULT_PASSWORD_FILE=~/.ansible-vault-pass
```

### 3. 🔐 WireGuard VPN 설정 (필수)
```bash
# 클라이언트 설정 파일 필요:
# - admin-client.conf (또는 개인별 설정 파일)
# - wg0.conf (서버 설정 - 서버 관리자만 필요)

# 클라이언트 설정 파일 위치:
# /etc/wireguard/wg0.conf (Linux)
# 또는 WireGuard 앱에서 import

# 설정 파일 예시:
[Interface]
PrivateKey = YOUR_PRIVATE_KEY
Address = 10.0.0.x/24
DNS = 8.8.8.8

[Peer]
PublicKey = SERVER_PUBLIC_KEY
Endpoint = SERVER_IP:51820
AllowedIPs = 10.0.0.0/8, 192.168.0.0/16
PersistentKeepalive = 25
```

### 4. 🌐 GCP 서비스 계정 키 (필수)
```bash
# GCP 콘솔에서 서비스 계정 키 생성:
# IAM > 서비스 계정 > 키 생성 > JSON 다운로드

# 키 파일 위치:
# ~/.gcp/service-account-key.json

# 환경변수 설정:
export GOOGLE_APPLICATION_CREDENTIALS=~/.gcp/service-account-key.json

# 필요한 권한:
# - Compute Engine Admin
# - Storage Admin  
# - DNS Admin
# - VPC Access Admin
```

### 5. 📦 Ansible 암호화된 변수들 (선택사항)
```bash
# 현재 암호화된 변수 파일들:
# ansible/group_vars/*/vault.yml (있다면)

# 복호화 확인:
ansible-vault view ansible/group_vars/test/vault.yml

# 새로운 암호화된 변수 생성:
ansible-vault create ansible/group_vars/prod/vault.yml
```

## 🔧 설정 가이드

### 1. 초기 설정 스크립트
```bash
#!/bin/bash
# setup-environment.sh

echo "🚀 Moongsan 3-Tier 환경 설정 시작..."

# 1. SSH 키 확인
if [ ! -f ~/.ssh/lsh-study-key ]; then
    echo "❌ SSH 키가 없습니다. 생성해주세요:"
    echo "ssh-keygen -t rsa -b 4096 -f ~/.ssh/lsh-study-key"
    exit 1
fi

# 2. Ansible Vault 패스워드 확인
if [ ! -f ~/.ansible-vault-pass ]; then
    echo "❌ Ansible Vault 패스워드 파일이 없습니다."
    echo "echo 'your-password' > ~/.ansible-vault-pass && chmod 600 ~/.ansible-vault-pass"
    exit 1
fi

# 3. GCP 서비스 계정 키 확인
if [ -z "$GOOGLE_APPLICATION_CREDENTIALS" ]; then
    echo "❌ GCP 서비스 계정 키가 설정되지 않았습니다."
    echo "export GOOGLE_APPLICATION_CREDENTIALS=~/.gcp/service-account-key.json"
    exit 1
fi

# 4. WireGuard 연결 확인
if ! ping -c 1 10.0.0.1 >/dev/null 2>&1; then
    echo "❌ WireGuard VPN이 연결되지 않았습니다."
    echo "WireGuard 클라이언트를 실행하고 VPN에 연결해주세요."
    exit 1
fi

echo "✅ 모든 필수 설정이 완료되었습니다!"
echo "🎯 이제 배포를 시작할 수 있습니다:"
echo "   cd ansible && ansible-playbook -i test.ini playbooks/main.yml"
```

### 2. 환경변수 설정 (.bashrc 또는 .zshrc)
```bash
# Moongsan 3-Tier 프로젝트 환경변수
export ANSIBLE_VAULT_PASSWORD_FILE=~/.ansible-vault-pass
export GOOGLE_APPLICATION_CREDENTIALS=~/.gcp/service-account-key.json
export ANSIBLE_HOST_KEY_CHECKING=False

# SSH 키 자동 로드
ssh-add ~/.ssh/lsh-study-key 2>/dev/null

# 프로젝트 디렉토리 단축명령
alias cdmoon='cd ~/Documents/local/3tier-moongsan/14-YG-CLOUD'
alias ansible-moon='cd ~/Documents/local/3tier-moongsan/14-YG-CLOUD/ansible'
```

## 🚨 보안 주의사항

### 1. 절대 Git에 포함하면 안 되는 파일들
```bash
# .gitignore에 반드시 포함:
*.key
*.pem
*-key.json
vault.yml
.env
.env.*
**/secrets/**
```

### 2. 민감한 정보 관리
```bash
# 1. SSH 키는 개인 키 매니저 사용
# 2. Ansible Vault 패스워드는 별도 저장소
# 3. GCP 서비스 계정 키는 정기적 순환
# 4. WireGuard 설정은 개인별 분리
```

### 3. 팀 공유 방법
```bash
# 1. 비밀번호: 별도 보안 채널 (1Password, Bitwarden 등)
# 2. SSH 키: 개인별 생성, 공개키만 공유
# 3. VPN 설정: 개인별 클라이언트 설정 파일 생성
# 4. GCP 키: 개인별 서비스 계정 생성 권장
```

## 📋 신규 사용자 체크리스트

### 배포 전 준비사항
- [ ] 프로젝트 clone 완료
- [ ] SSH 키 생성 및 GCP 등록
- [ ] Ansible Vault 패스워드 설정
- [ ] GCP 서비스 계정 키 다운로드 및 설정
- [ ] WireGuard VPN 연결 설정
- [ ] 환경변수 설정 (.bashrc/.zshrc)
- [ ] 초기 설정 스크립트 실행

### 첫 배포 테스트
```bash
# 1. 환경 확인
cd ansible
ansible --version
ansible-vault --help

# 2. 연결 테스트  
ansible -i test.ini all -m ping

# 3. 테스트 배포
ansible-playbook -i test.ini playbooks/main.yml --tags "base" --check

# 4. 실제 배포
ansible-playbook -i test.ini playbooks/main.yml
```

## 🎯 트러블슈팅 FAQ

### Q: "Vault password required" 오류가 발생합니다
```bash
# A: Vault 패스워드 파일 경로 확인
export ANSIBLE_VAULT_PASSWORD_FILE=~/.ansible-vault-pass
# 또는
ansible-playbook -i test.ini playbooks/main.yml --ask-vault-pass
```

### Q: SSH 연결이 안 됩니다
```bash
# A: 키 권한 및 VPN 연결 확인
chmod 600 ~/.ssh/lsh-study-key
ssh-add ~/.ssh/lsh-study-key
# WireGuard VPN 연결 상태 확인
```

### Q: GCP 권한 오류가 발생합니다
```bash
# A: 서비스 계정 키 및 권한 확인
gcloud auth list
gcloud auth activate-service-account --key-file=$GOOGLE_APPLICATION_CREDENTIALS
```

---

이제 **완전한 3-tier 자동화 배포 환경**을 누구나 재현할 수 있습니다! 🚀

위의 준비물들만 갖추면 `ansible-playbook` 한 번으로 전체 인프라를 배포할 수 있습니다.
