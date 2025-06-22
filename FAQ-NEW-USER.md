# 🙋‍♂️ 신규 사용자 FAQ (자주 묻는 질문)

## 🔧 설정 관련

### Q1: SSH 키를 GCP에 등록했는데도 연결이 안 돼요
**A:** 다음 사항들을 확인해보세요:

1. **사용자명 확인**: 
   - Jumpbox: `lsh`
   - VM들: `ubuntu`
   ```bash
   # 올바른 연결 방법
   ssh -i ~/.ssh/lsh-study-key lsh@34.22.110.81
   ```

2. **SSH 키 형식 확인**:
   ```bash
   # 공개키 파일 내용 확인
   cat ~/.ssh/lsh-study-key.pub
   # 형식: ssh-rsa AAAAB3NzaC1yc2E... your-email@example.com
   ```

3. **known_hosts 충돌 해결**:
   ```bash
   ssh-keygen -R 34.22.110.81
   ssh-keygen -R 10.0.1.2
   ```

### Q2: WireGuard 연결이 안 돼요
**A:** 단계별로 확인해보세요:

1. **클라이언트 설정 파일 문법 확인**:
   ```bash
   # 설정 파일 내용 확인
   cat ~/wireguard/your-name-client.conf
   
   # 필수 섹션들이 있는지 확인:
   # [Interface]
   # [Peer]
   ```

2. **WireGuard 도구 설치 확인**:
   ```bash
   brew install wireguard-tools
   which wg
   ```

3. **다른 VPN 충돌 확인**:
   ```bash
   # 기존 VPN 연결 종료
   # 회사 VPN, 개인 VPN 등 모두 종료 후 테스트
   ```

4. **연결 후 라우팅 확인**:
   ```bash
   sudo wg-quick up ~/wireguard/your-name-client.conf
   ip route | grep 10.0.0.0
   ping 10.0.0.2
   ```

### Q3: Ansible Vault 패스워드를 모르겠어요
**A:** 관리자에게 문의하세요. 보안상 패스워드는 별도로 공유됩니다.

임시로 테스트하려면:
```bash
# vault 파일 내용 확인 (패스워드 필요)
ansible-vault view ansible/group_vars/test/vault.yml --ask-vault-pass
```

### Q4: GCP 서비스 계정 키는 어떻게 받나요?
**A:** 관리자에게 요청하세요. 보안상 개인별로 별도 키를 발급받아야 합니다.

키를 받은 후:
```bash
mkdir -p ~/.gcp
mv received-key.json ~/.gcp/terraform-key.json
chmod 600 ~/.gcp/terraform-key.json
```

## 🚨 오류 해결

### Q5: "Permission denied (publickey)" 오류가 나요
**A:** SSH 키 관련 문제입니다:

1. **SSH Agent 확인**:
   ```bash
   ssh-add -l  # 등록된 키 확인
   ssh-add ~/.ssh/lsh-study-key  # 키 추가
   ```

2. **키 권한 확인**:
   ```bash
   chmod 600 ~/.ssh/lsh-study-key
   chmod 644 ~/.ssh/lsh-study-key.pub
   ```

3. **SSH 연결 디버깅**:
   ```bash
   ssh -v -i ~/.ssh/lsh-study-key lsh@34.22.110.81
   ```

### Q6: "Host key verification failed" 오류가 나요
**A:** known_hosts 파일 충돌입니다:

```bash
# 해당 호스트 제거
ssh-keygen -R 34.22.110.81
ssh-keygen -R 10.0.1.2
ssh-keygen -R 10.0.2.2
ssh-keygen -R 10.0.3.2

# 다시 연결 시도
ssh -i ~/.ssh/lsh-study-key lsh@34.22.110.81
```

### Q7: Terraform에서 "credentials" 오류가 나요
**A:** GCP 인증 설정을 확인하세요:

1. **환경변수 확인**:
   ```bash
   echo $GOOGLE_APPLICATION_CREDENTIALS
   ls -la $GOOGLE_APPLICATION_CREDENTIALS
   ```

2. **키 파일 문법 확인**:
   ```bash
   jq . ~/.gcp/terraform-key.json
   ```

3. **인증 테스트**:
   ```bash
   gcloud auth activate-service-account --key-file=$GOOGLE_APPLICATION_CREDENTIALS
   gcloud projects list
   ```

### Q8: Ansible에서 "Unreachable" 오류가 나요
**A:** 네트워크 연결을 확인하세요:

1. **WireGuard 연결 확인**:
   ```bash
   ping 10.0.0.2  # database 서버
   ```

2. **ProxyJump 설정 확인**:
   ```bash
   # ansible/test.ini 파일에서 ProxyJump 설정 확인
   cat ansible/test.ini
   ```

3. **상세 디버깅**:
   ```bash
   ansible -i test.ini all -m ping -vvv
   ```

## 🏗️ 배포 관련

### Q9: 첫 배포시 어떤 순서로 해야 하나요?
**A:** 다음 순서를 따르세요:

1. **인프라 생성**:
   ```bash
   cd terraform/environments/test
   terraform init
   terraform plan
   terraform apply
   ```

2. **서비스 배포**:
   ```bash
   cd ../../../ansible
   ansible-playbook -i test.ini playbooks/main.yml
   ```

3. **상태 확인**:
   ```bash
   ansible -i test.ini all -m shell -a "docker ps"
   ```

### Q10: 배포 중 실패하면 어떻게 하나요?
**A:** 에러 메시지를 확인하고 단계별로 해결하세요:

1. **일반적인 재시도**:
   ```bash
   # 배포 재실행 (멱등성 보장)
   ansible-playbook -i test.ini playbooks/main.yml
   ```

2. **특정 서버만 재배포**:
   ```bash
   ansible-playbook -i test.ini playbooks/main.yml --limit database
   ```

3. **상세 디버깅**:
   ```bash
   ansible-playbook -i test.ini playbooks/main.yml -vvv
   ```

### Q11: 전체 환경을 다시 만들고 싶어요
**A:** 완전 재구축 절차:

```bash
# 1. 전체 인프라 삭제
cd terraform/environments/test
terraform destroy

# 2. 상태 파일 정리
rm -rf .terraform/
rm terraform.tfstate*

# 3. 인프라 재생성
terraform init
terraform apply

# 4. 서비스 재배포
cd ../../../ansible
ansible-playbook -i test.ini playbooks/main.yml
```

## 🔍 모니터링 및 확인

### Q12: 서비스가 정상 동작하는지 어떻게 확인하나요?
**A:** 다음 명령들로 확인하세요:

1. **컨테이너 상태 확인**:
   ```bash
   ansible -i test.ini all -m shell -a "docker ps"
   ```

2. **개별 서비스 확인**:
   ```bash
   # 데이터베이스 연결 확인
   ansible -i test.ini database -m shell -a "docker exec mysql-container mysql -u root -p'password' -e 'SHOW DATABASES;'"
   
   # Redis 상태 확인
   ansible -i test.ini database -m shell -a "docker exec redis-container redis-cli ping"
   
   # 백엔드 API 확인
   curl -k https://api.test.moongsan.com/health
   
   # 프론트엔드 확인
   curl -I https://test.moongsan.com
   ```

### Q13: 로그는 어떻게 확인하나요?
**A:** Docker 로그를 확인하세요:

```bash
# 특정 컨테이너 로그 확인
ansible -i test.ini backend -m shell -a "docker logs backend-container"
ansible -i test.ini database -m shell -a "docker logs mysql-container"

# 실시간 로그 확인
ansible -i test.ini backend -m shell -a "docker logs -f backend-container"
```

## 🛠️ 개발 관련

### Q14: 코드 수정 후 어떻게 배포하나요?
**A:** 변경 사항에 따라 다릅니다:

1. **백엔드 코드 변경**:
   ```bash
   # 백엔드만 재배포
   ansible-playbook -i test.ini playbooks/main.yml --tags be_deploy
   ```

2. **프론트엔드 코드 변경**:
   ```bash
   # 프론트엔드만 재배포
   ansible-playbook -i test.ini playbooks/main.yml --tags fe_deploy
   ```

3. **설정 변경**:
   ```bash
   # 전체 재배포
   ansible-playbook -i test.ini playbooks/main.yml
   ```

### Q15: 다른 환경(dev, prod)도 같은 방식인가요?
**A:** 네, 동일한 절차입니다. 환경별로 인벤토리 파일만 다릅니다:

```bash
# dev 환경
ansible-playbook -i dev.ini playbooks/main.yml

# prod 환경
ansible-playbook -i prod.ini playbooks/main.yml
```

## 🔐 보안 관련

### Q16: 민감한 정보를 실수로 커밋했어요
**A:** 즉시 Git 기록에서 제거하세요:

```bash
# 파일 제거 및 기록 삭제
git rm --cached sensitive-file.json
git commit -m "Remove sensitive file"

# 기록에서 완전 제거 (필요시)
git filter-branch --force --index-filter 'git rm --cached --ignore-unmatch sensitive-file.json' --prune-empty --tag-name-filter cat -- --all
```

### Q17: .gitignore에 어떤 파일들이 있어야 하나요?
**A:** 다음 파일들은 절대 커밋하면 안 됩니다:

```
# SSH 키
*.pem
*.key
id_rsa*

# GCP 키
*-key.json
service-account*.json

# WireGuard 설정
*.conf
wg*.conf

# Terraform 상태
*.tfstate*
.terraform/

# Ansible Vault
*vault_pass*
```

## 📱 연락처

### Q18: 누구에게 도움을 요청해야 하나요?
**A:** 문제 유형별 연락처:

- **SSH/WireGuard 설정**: 인프라 관리자
- **GCP 권한**: 클라우드 관리자  
- **Ansible Vault**: 보안 관리자
- **코드 배포**: 개발팀 리더
- **긴급 장애**: 온콜 담당자

---

**💡 추가 질문이 있으시면 언제든 문의하세요!**
