# 🚀 완전한 3-Tier 재배포 가이드

이 가이드는 Terraform 완전 삭제 후 전체 3-tier 구조를 처음부터 재구성하는 절차입니다.

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

# SSH known_hosts 정리 (필요시)
ssh-keygen -R 10.0.0.2  # database
ssh-keygen -R 10.0.0.3  # backend  
ssh-keygen -R 10.0.0.4  # ai
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

## ⏱️ 3단계: 인프라 준비 대기

```bash
# VM 부팅 완료 대기 (약 2-3분)
echo "Waiting for VMs to be ready..."
sleep 180

# SSH 연결 테스트
ssh -o ConnectTimeout=10 -o BatchMode=yes ubuntu@$(terraform output -raw database_internal_ip) echo "Database Ready" 2>/dev/null && echo "✅ Database VM Ready" || echo "❌ Database VM Not Ready"

ssh -o ConnectTimeout=10 -o BatchMode=yes ubuntu@$(terraform output -raw backend_internal_ip) echo "Backend Ready" 2>/dev/null && echo "✅ Backend VM Ready" || echo "❌ Backend VM Not Ready"

ssh -o ConnectTimeout=10 -o BatchMode=yes ubuntu@$(terraform output -raw ai_internal_ip) echo "AI Ready" 2>/dev/null && echo "✅ AI VM Ready" || echo "❌ AI VM Not Ready"
```

## 🚀 4단계: Ansible 전체 배포

### 인벤토리 업데이트 (필요시)
```bash
cd ../../../../ansible

# Terraform output에서 IP 추출하여 인벤토리 업데이트
cd ../terraform/environments/test
DATABASE_IP=$(terraform output -raw database_internal_ip)
BACKEND_IP=$(terraform output -raw backend_internal_ip)  
AI_IP=$(terraform output -raw ai_internal_ip)

cd ../../../ansible
echo "Database IP: $DATABASE_IP"
echo "Backend IP: $BACKEND_IP"
echo "AI IP: $AI_IP"

# 필요시 test.ini 파일 수정
```

### 연결 테스트
```bash
# Ansible 연결 테스트
ansible all -i test.ini -m ping

# 예상 출력:
# test-database | SUCCESS => { "ping": "pong" }
# test-backend | SUCCESS => { "ping": "pong" }  
# test-ai | SUCCESS => { "ping": "pong" }
# shared-jumpbox | SUCCESS => { "ping": "pong" }
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

## 🎉 완료 기준

✅ 모든 체크리스트가 통과하면 **완전한 3-tier 재배포 성공**:

- [ ] Terraform 인프라 정상 생성
- [ ] 모든 VM SSH 접근 가능
- [ ] MySQL 컨테이너 정상 실행
- [ ] Redis 마스터 모드 정상 동작
- [ ] 백엔드 API 응답 정상
- [ ] AI 서비스 응답 정상  
- [ ] 프론트엔드 웹사이트 접근 가능
- [ ] HTTPS 인증서 정상 적용

## 🔄 Prod 마이그레이션 준비

Test 환경에서 모든 것이 정상 동작하면:

1. **설정 복사**: `group_vars/test/` → `group_vars/prod/`
2. **인벤토리 준비**: `prod.ini` 파일 점검
3. **도메인 설정**: prod 도메인으로 변경
4. **보안 강화**: 운영 환경용 패스워드/키 적용
5. **백업 설정**: 자동 백업 스케줄 구성

```bash
# Prod 배포 (Test 검증 완료 후)
ansible-playbook -i prod.ini playbooks/main.yml
```
