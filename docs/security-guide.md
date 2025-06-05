# 🔐 통합 보안 가이드

> **14-YG-CLOUD 프로젝트**의 모든 보안 설정을 총망라한 완전한 보안 가이드입니다.

## 📋 목차

- [Part 1: Git 보안](#part-1-git-보안)
- [Part 2: Ansible Vault 보안](#part-2-ansible-vault-보안)
- [Part 3: WireGuard VPN 설정](#part-3-wireguard-vpn-설정)
- [Part 4: 종합 보안 체크리스트](#part-4-종합-보안-체크리스트)

---

## Part 1: Git 보안

### 🚨 절대 커밋하면 안 되는 파일들

#### 🔑 민감한 정보가 포함된 파일들
```bash
# Terraform 변수 파일
*.tfvars
terraform.tfvars

# GCP 서비스 계정 키
*.json (패키지 파일 제외)
service-account*.json

# SSH 키
*.pem, *.key, id_rsa*, *.pub

# WireGuard 설정
*.conf, wireguard-keys/

# 환경 변수 파일
.env, .env.*

# Terraform 상태 파일
*.tfstate, *.tfstate.*

# Ansible Vault 패스워드
.vault_pass.txt
```

### ✅ .gitignore 설정 완료

현재 프로젝트의 .gitignore는 다음과 같은 민감한 정보들을 자동으로 제외합니다:

#### 1. **Terraform 관련**
- ✅ 상태 파일 (tfstate)
- ✅ 변수 파일 (tfvars) 
- ✅ 모듈 캐시 (.terraform/)

#### 2. **보안 관련**
- ✅ GCP 서비스 계정 키 (*.json)
- ✅ SSH 키 파일들
- ✅ WireGuard 키 및 설정
- ✅ Ansible Vault 패스워드

#### 3. **환경 설정**
- ✅ 환경 변수 파일 (.env)
- ✅ 로그 파일들
- ✅ 임시 파일들

### 🔍 커밋 전 보안 체크리스트
```bash
# 1. 민감한 파일 체크
git status
git diff --cached

# 2. 실수로 추가된 민감 파일 제거
git reset HEAD <파일명>

# 3. .gitignore 정상 작동 확인
git check-ignore -v <파일명>

# 4. 안전한 커밋
git commit -m "안전한 변경사항"
```

### 🚨 만약 민감한 정보를 실수로 커밋했다면?

```bash
# 1. 최근 커밋에서 제거 (아직 push 안 한 경우)
git reset --soft HEAD~1
git reset HEAD <민감한_파일>
git commit -m "민감한 정보 제거"

# 2. 이미 push한 경우 - 히스토리 제거 필요
git filter-branch --force --index-filter 'git rm --cached --ignore-unmatch <민감한_파일>' --prune-empty --tag-name-filter cat -- --all
git push origin --force --all

# 3. 즉시 키/패스워드 변경
# - GCP 서비스 계정 키 재발급
# - 데이터베이스 패스워드 변경  
# - SSH 키 재생성
```

---

## Part 2: Ansible Vault 보안

### 🔐 Vault 구조

#### 1. Vault 패스워드 파일
```
ansible/.vault_pass.txt
```
- Vault 암호화/복호화에 사용되는 패스워드 파일
- **절대 Git에 커밋하지 마세요** (`.gitignore`에 포함됨)

#### 2. 암호화된 설정 파일
```
ansible/group_vars/dev/all.yml     # 개발 환경 설정 (암호화됨)
ansible/group_vars/test/all.yml    # 테스트 환경 설정 (암호화됨)
ansible/group_vars/prod/all.yml    # 프로덕션 환경 설정 (암호화됨)
ansible/group_vars/all/vault.yml   # 공통 민감 정보 (암호화됨)
```

### 🛠️ Vault 사용법

#### 1. 새 vault 파일 생성
```bash
cd ansible
ansible-vault create group_vars/all/vault.yml
```

#### 2. 기존 파일 암호화
```bash
cd ansible
ansible-vault encrypt group_vars/dev/all.yml
```

#### 3. 암호화된 파일 편집
```bash
cd ansible
ansible-vault edit group_vars/dev/all.yml
```

#### 4. 암호화된 파일 보기
```bash
cd ansible
ansible-vault view group_vars/dev/all.yml
```

#### 5. 파일 복호화 (임시)
```bash
cd ansible
ansible-vault decrypt group_vars/dev/all.yml --output=-
```

### 🗝️ Vault에 저장해야 할 정보들

```yaml
# group_vars/all/vault.yml 예시
vault_mysql_root_password: "super_secure_db_password"
vault_mysql_app_password: "app_db_password"
vault_redis_password: "redis_secure_password"
vault_jwt_secret: "jwt_signing_secret"
vault_api_key: "external_api_key"

# 환경별 민감 정보
vault_database_host: "10.0.0.3"
vault_database_port: 3306
vault_gcp_project_id: "your-project-id"
```

### 🔧 Ansible 실행 시 Vault 사용

```bash
# 패스워드 파일 사용
ansible-playbook -i inventory_test.ini playbooks/site.yml --vault-password-file .vault_pass.txt

# 패스워드 프롬프트
ansible-playbook -i inventory_test.ini playbooks/site.yml --ask-vault-pass

# 환경 변수 사용
export ANSIBLE_VAULT_PASSWORD_FILE=.vault_pass.txt
ansible-playbook -i inventory_test.ini playbooks/site.yml
```

---

## Part 3: WireGuard VPN 설정

### 🌐 WireGuard 개요

**WireGuard**는 현대적인 VPN 프로토콜로, 간단하고 빠르며 안전한 VPN 연결을 제공합니다.

#### 주요 특징
- ✅ **빠른 성능**: 기존 VPN 대비 월등한 속도
- ✅ **간단한 설정**: 최소한의 설정으로 VPN 구성
- ✅ **강력한 암호화**: ChaCha20, Poly1305 암호화
- ✅ **크로스 플랫폼**: Linux, macOS, Windows, iOS, Android 지원

#### 사용 목적
- 🔒 Private Network(10.0.0.0/24)에 안전하게 접근
- 🔒 Jump Box 없이도 내부 VM들에 직접 접근
- 🔒 개발자별 독립적인 VPN 클라이언트 관리

### 🌐 네트워크 구성

#### IP 주소 체계
```
┌─────────────────────────────────────────────────────────┐
│                     인터넷                               │
└─────────────────────┬───────────────────────────────────┘
                      │
              ┌───────▼───────┐
              │   Jump Box    │
              │ 34.64.179.41  │ ← 외부 IP
              │  10.0.0.5     │ ← 내부 IP  
              │  10.8.0.1     │ ← WireGuard 서버 IP
              └───────┬───────┘
                      │
        ┌─────────────┼─────────────┐
        │         Private Network   │
        │        (10.0.0.0/24)      │
        │                           │
   ┌────▼────┐  ┌────▼────┐  ┌────▼────┐
   │Backend  │  │Database │  │   AI    │
   │10.0.0.2 │  │10.0.0.3 │  │10.0.0.4 │
   └─────────┘  └─────────┘  └─────────┘
```

#### VPN 클라이언트 IP 할당
| 클라이언트 | VPN IP | 목적 | 키 |
|------------|--------|------|-----|
| **서버** | 10.8.0.1/24 | Jump Box WireGuard 서버 | 서버 키 |
| **frontend** | 10.8.0.10/32 | 개발자 로컬 접근 | 클라이언트 키 1 |
| **backend** | 10.8.0.20/32 | Backend 서비스 전용 | 클라이언트 키 2 |
| **ai** | 10.8.0.30/32 | AI 서비스 전용 | 클라이언트 키 3 |
| **database** | 10.8.0.40/32 | Database 전용 | 클라이언트 키 4 |

### 🛠️ WireGuard 설정 과정

#### 1. 키 생성 (자동화)
```bash
# 키 생성 스크립트 실행
cd /Users/lsh/Documents/local/3tier-moongsan/14-YG-CLOUD
./scripts/generate-wireguard-keys.sh

# 생성된 키 확인
cat wireguard-keys/server-keys.txt
cat wireguard-keys/client-keys.txt
```

#### 2. 서버 설정 (Jump Box)
```bash
# WireGuard 설치
sudo apt update
sudo apt install wireguard

# 서버 설정 파일
sudo tee /etc/wireguard/wg0.conf << EOF
[Interface]
PrivateKey = <서버_개인키>
Address = 10.8.0.1/24
ListenPort = 51820
PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -A FORWARD -o %i -j ACCEPT; iptables -t nat -A POSTROUTING -o ens4 -j MASQUERADE
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -D FORWARD -o %i -j ACCEPT; iptables -t nat -D POSTROUTING -o ens4 -j MASQUERADE

[Peer]
PublicKey = <클라이언트_공개키>
AllowedIPs = 10.8.0.10/32

EOF

# 서비스 시작
sudo systemctl enable wg-quick@wg0
sudo systemctl start wg-quick@wg0
```

#### 3. 클라이언트 설정 (로컬)
```bash
# macOS에서 WireGuard 설치
brew install wireguard-tools

# 클라이언트 설정 파일 생성
cat > ~/wg-client.conf << EOF
[Interface]
PrivateKey = <클라이언트_개인키>
Address = 10.8.0.10/32
DNS = 8.8.8.8

[Peer]
PublicKey = <서버_공개키>
AllowedIPs = 10.0.0.0/16, 10.8.0.0/24
Endpoint = <Jump_Box_외부_IP>:51820
PersistentKeepalive = 25
EOF

# VPN 연결
wg-quick up ~/wg-client.conf

# 연결 확인
ping 10.0.0.2  # Backend 서버
ping 10.0.0.3  # Database 서버
```

### 🔧 WireGuard 관리 명령어

```bash
# 연결 상태 확인
sudo wg show

# VPN 시작/중지
sudo wg-quick up wg0
sudo wg-quick down wg0

# 설정 다시 로드
sudo systemctl restart wg-quick@wg0

# 로그 확인
sudo journalctl -u wg-quick@wg0 -f
```

---

## Part 4: 종합 보안 체크리스트

### 🔍 일일 보안 체크리스트

#### **개발 시작 전**
- [ ] `.gitignore` 파일이 최신 상태인지 확인
- [ ] Vault 패스워드 파일이 Git에서 제외되었는지 확인
- [ ] 민감한 정보가 평문으로 저장되지 않았는지 확인

#### **커밋 전**
- [ ] `git status`로 커밋 대상 파일 확인
- [ ] `git diff --cached`로 변경 내용 재검토
- [ ] 민감한 정보가 포함되지 않았는지 확인
- [ ] 하드코딩된 IP, 패스워드, 키가 없는지 확인

#### **배포 전**
- [ ] Ansible Vault 파일들이 암호화되어 있는지 확인
- [ ] WireGuard 키 파일들이 Git에서 제외되었는지 확인
- [ ] 환경 변수 파일(.env)이 Git에서 제외되었는지 확인

### 🚨 보안 인시던트 대응 절차

#### **민감한 정보 노출 시**
1. **즉시 대응**
   ```bash
   # Git 히스토리에서 완전 제거
   git filter-branch --force --index-filter 'git rm --cached --ignore-unmatch <파일명>' --prune-empty --tag-name-filter cat -- --all
   ```

2. **키/패스워드 변경**
   - GCP 서비스 계정 키 즉시 비활성화 및 재발급
   - 데이터베이스 패스워드 변경
   - SSH 키 재생성
   - WireGuard 키 재생성

3. **영향 범위 분석**
   - 노출된 정보로 접근 가능한 시스템 확인
   - 로그 분석으로 의심스러운 활동 탐지
   - 필요시 관련 시스템 일시 중단

#### **VPN 보안 강화**
- [ ] 정기적인 WireGuard 키 로테이션 (3개월)
- [ ] 미사용 클라이언트 키 비활성화
- [ ] VPN 접근 로그 정기 모니터링
- [ ] 강력한 키 생성 (최소 256비트)

### 🎯 보안 모범 사례

#### **개발자 워크플로우**
1. **환경 분리**: Dev/Test/Prod 환경별 독립적인 인증 정보
2. **최소 권한 원칙**: 필요한 최소한의 권한만 부여
3. **정기 감사**: 주기적인 접근 권한 및 키 검토
4. **문서화**: 모든 보안 절차를 명확히 문서화

#### **인프라 보안**
1. **네트워크 분리**: Private 네트워크 + VPN 접근
2. **암호화**: 모든 민감한 데이터 암호화 저장
3. **모니터링**: 실시간 보안 이벤트 모니터링
4. **백업**: 암호화된 백업 및 복구 절차

---

> 🛡️ **보안은 일회성이 아닌 지속적인 프로세스**입니다. 이 가이드를 주기적으로 검토하고 업데이트하여 최신 보안 위협에 대응하세요.
