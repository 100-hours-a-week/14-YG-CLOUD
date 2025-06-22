# 🆕 신규 사용자 체크리스트

## 📋 필수 준비사항 체크리스트

### ✅ 1단계: 기본 환경 설정
- [ ] Repository clone 완료
- [ ] macOS 기본 개발도구 설치 (Xcode Command Line Tools)
- [ ] Homebrew 설치 완료
- [ ] Git 설정 완료 (user.name, user.email)

### ✅ 2단계: 필수 도구 설치
```bash
# Homebrew로 한번에 설치
brew install terraform ansible jq curl wireguard-tools
```

- [ ] Terraform 설치 및 버전 확인 (1.5+)
- [ ] Ansible 설치 및 버전 확인 (2.12+)
- [ ] jq 설치 (JSON 파싱용)
- [ ] curl 설치 (API 테스트용)
- [ ] wireguard-tools 설치 (VPN 연결용)

### ✅ 3단계: SSH 키 설정
```bash
# SSH 키 생성
ssh-keygen -t rsa -b 4096 -C "your-email@example.com" -f ~/.ssh/lsh-study-key

# 권한 설정
chmod 600 ~/.ssh/lsh-study-key
chmod 644 ~/.ssh/lsh-study-key.pub
```

- [ ] SSH 키 생성 완료
- [ ] SSH 키 GCP 프로젝트 등록 완료
  - [ ] GCP Console > Compute Engine > Metadata > SSH Keys
  - [ ] 사용자명: `lsh` (jumpbox용), `ubuntu` (VM용)
- [ ] SSH Agent에 키 등록: `ssh-add ~/.ssh/lsh-study-key`

### ✅ 4단계: GCP 인증 설정
- [ ] GCP 서비스 계정 키 JSON 파일 획득 (관리자 요청)
- [ ] 키 파일 저장: `~/.gcp/terraform-key.json`
- [ ] 권한 설정: `chmod 600 ~/.gcp/terraform-key.json`
- [ ] 환경변수 설정: 
  ```bash
  echo 'export GOOGLE_APPLICATION_CREDENTIALS=~/.gcp/terraform-key.json' >> ~/.zshrc
  source ~/.zshrc
  ```

### ✅ 5단계: Ansible Vault 설정
- [ ] 관리자에게 현재 vault 패스워드 확인
- [ ] Vault 패스워드 파일 생성:
  ```bash
  echo 'actual-vault-password' > ~/.ansible_vault_pass
  chmod 600 ~/.ansible_vault_pass
  ```
- [ ] 환경변수 설정 (선택):
  ```bash
  echo 'export ANSIBLE_VAULT_PASSWORD_FILE=~/.ansible_vault_pass' >> ~/.zshrc
  ```

### ✅ 6단계: WireGuard VPN 설정
- [ ] 관리자에게 개인 WireGuard 클라이언트 설정 파일 요청
  - 파일명 형식: `[이름]-client.conf` (예: john-client.conf)
- [ ] 설정 파일 저장: `~/wireguard/your-name-client.conf`
- [ ] 권한 설정: `chmod 600 ~/wireguard/*.conf`
- [ ] VPN 연결 테스트:
  ```bash
  sudo wg-quick up ~/wireguard/your-name-client.conf
  ping 10.0.0.2  # database 서버 접근 테스트
  ```

### ✅ 7단계: 프로젝트 설정
- [ ] 환경별 설정 파일 확인/생성:
  ```bash
  # 템플릿이 있는 경우 복사
  cp ansible/group_vars/test/all.yml.template ansible/group_vars/test/all.yml
  ```
- [ ] 개인 환경에 맞게 설정 수정
- [ ] .gitignore 확인 (민감한 파일들이 제외되는지)

### ✅ 8단계: 연결 테스트
```bash
# 자동 체크 스크립트 실행
./scripts/setup-new-user.sh
```

또는 수동으로 확인:
- [ ] SSH 연결 테스트:
  ```bash
  ssh -i ~/.ssh/lsh-study-key lsh@34.22.110.81 "echo 'Jumpbox OK'"
  ```
- [ ] WireGuard 연결 테스트:
  ```bash
  ping -c 3 10.0.0.2
  ```
- [ ] Terraform 인증 테스트:
  ```bash
  cd terraform/environments/test
  terraform init
  ```
- [ ] Ansible 연결 테스트:
  ```bash
  cd ansible
  ansible -i test.ini all -m ping
  ```

## 🚀 첫 배포 실행

모든 준비가 완료되면:

```bash
# 1. 전체 배포 (처음 실행시)
cd ansible
ansible-playbook -i test.ini playbooks/main.yml

# 2. 서비스 상태 확인
ansible -i test.ini all -m shell -a "docker ps"
```

## 🔧 선택적 설정

### 환경변수 자동 설정
```bash
# 환경변수 템플릿 적용
cat scripts/env-template.sh >> ~/.zshrc
source ~/.zshrc
```

### IDE 설정 (VS Code)
필요한 VS Code 확장:
- [ ] Terraform
- [ ] Ansible
- [ ] YAML
- [ ] JSON
- [ ] GitLens
- [ ] Remote-SSH (서버 접속용)

## ❗ 주의사항

### 절대 Git에 커밋하면 안 되는 파일들:
- `~/.ssh/lsh-study-key` (SSH 개인키)
- `~/.ansible_vault_pass` (Vault 패스워드)
- `*.conf` (WireGuard 클라이언트 설정)
- `service-account-key.json` (GCP 서비스 계정 키)
- `terraform.tfstate*` (Terraform 상태 파일)
- `.terraform/` (Terraform 캐시)

### 권한 설정 체크:
```bash
# 모든 민감한 파일의 권한을 600으로 설정
chmod 600 ~/.ssh/lsh-study-key
chmod 600 ~/.ansible_vault_pass
chmod 600 ~/.gcp/terraform-key.json
chmod 600 ~/wireguard/*.conf
```

## 🆘 문제 해결

### SSH 연결 실패시:
1. SSH 키가 GCP에 정확히 등록되었는지 확인
2. 사용자명이 올바른지 확인 (jumpbox: `lsh`, VM: `ubuntu`)
3. known_hosts 충돌시: `ssh-keygen -R 34.22.110.81`

### WireGuard 연결 실패시:
1. 클라이언트 설정 파일 문법 확인
2. 관리자에게 서버 설정 확인 요청
3. 다른 VPN이나 방화벽 충돌 확인

### Ansible 연결 실패시:
1. WireGuard VPN 연결 상태 확인
2. SSH Agent에 키 등록 확인: `ssh-add -l`
3. Vault 패스워드 정확성 확인

### Terraform 실패시:
1. GCP 서비스 계정 키 경로 확인
2. 프로젝트 권한 확인
3. 네트워크 연결 상태 확인

## 📞 도움 요청

설정 중 문제 발생시 관리자에게 다음 정보와 함께 문의:
1. 실행한 명령어
2. 에러 메시지 전문
3. 운영체제 및 도구 버전
4. 어느 단계까지 성공했는지

---

**성공적인 설정을 위해 위 체크리스트를 하나씩 확인해주세요! 🎯**
