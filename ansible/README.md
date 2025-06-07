# 14-YG-CLOUD Ansible Infrastructure (통합 버전)

3-tier 클라우드 인프라를 자동화 배포하기 위한 Ansible 프로젝트입니다.
AI, 백엔드, 프론트엔드, 데이터베이스를 포함한 완전한 애플리케이션 스택을 환경별로 관리할 수 있습니다.

## 🔄 2024년 12월 업데이트: 플레이북 통합 완료

기존의 복잡한 다중 플레이북 구조를 **하나의 통합 플레이북**으로 단순화했습니다.
- **12개 개별 플레이북** → **3개 통합 플레이북**으로 대폭 간소화
- **태그 기반 선택적 배포** 지원으로 더욱 유연한 관리

## 🏗️ 인프라 구성

### 🎯 지원 환경
- **개발(dev)**: 개발 및 테스트용 환경
- **테스트(test)**: QA 및 통합 테스트 환경  
- **프로덕션(prod)**: 실서비스 환경
- **공유(shared)**: WireGuard VPN 등 공유 인프라

### 📦 서비스 구성
| 구성 요소 | 설명 | 배포 방식 |
|----------|------|-----------|
| **AI 서비스** | 머신러닝/AI 추론 서버 | Docker 컨테이너 |
| **백엔드** | REST API 서버 | Docker 컨테이너 |
| **프론트엔드** | 웹 애플리케이션 | Docker 컨테이너 |
| **데이터베이스** | PostgreSQL | Docker 또는 호스트 설치 |
| **Redis** | 캐시 및 세션 스토어 | Docker 컨테이너 |
| **Nginx** | 리버스 프록시 & 로드밸런서 | 호스트 설치 |
| **WireGuard** | VPN 서버 | 호스트 설치 |

## 📁 디렉토리 구조

```bash
ansible/
├── ansible.cfg               # Ansible 설정
├── inventories/              # 환경별 인벤토리 디렉토리
│   ├── dev.ini              # 개발 환경 인벤토리
│   ├── test.ini             # 테스트 환경 인벤토리
│   ├── prod.ini             # 프로덕션 환경 인벤토리
│   └── shared.ini           # 공유 인프라 인벤토리
├── group_vars/               # 환경별 변수 설정
│   ├── all/vault.yml        # 전역 암호화 변수
│   ├── dev/                 # 개발 환경 설정
│   │   ├── all.yml
│   │   └── wireguard.yml
│   ├── test/                # 테스트 환경 설정
│   │   ├── all.yml
│   │   ├── vault.yml
│   │   └── wireguard.yml
│   ├── prod/                # 프로덕션 환경 설정
│   │   ├── all.yml
│   │   └── wireguard.yml
│   └── shared/              # 공유 인프라 설정
│       ├── vault.yml
│       └── wireguard.yml
├── playbooks/               # 통합 플레이북 (3개)
│   ├── main.yml             # ⭐ 통합 배포 플레이북 (모든 환경/서비스)
│   ├── deploy_shared.yml    # 공유 인프라 배포 (WireGuard VPN)
│   └── dev_db_fix.yml       # 데이터베이스 수정/복구
│   ├── deploy_shared.yml    # 공유 인프라 배포
└── roles/                   # Ansible 역할 정의
    ├── base_system/        # 기본 시스템 설정
    ├── common/             # 공통 서비스 (Docker 등)
    ├── database/           # 데이터베이스 설정
    ├── be_deploy/          # 백엔드 배포
    ├── ai_deploy/          # AI 서비스 배포
    ├── fe_deploy/          # 프론트엔드 배포
    ├── nginx_conf/         # Nginx 설정
    ├── wireguard_setup/    # WireGuard VPN 설정
    ├── redis/              # Redis 설정
    ├── db_backup/          # 백업 설정
    └── db_fix/             # DB 수정/복구
```

## 🚀 새로운 통합 사용법 (권장)

### 🎯 기본 배포 명령어

```bash
# 개발 환경 전체 배포
ansible-playbook -i inventories/dev.ini playbooks/main.yml -e "env=dev"

# 테스트 환경 전체 배포
ansible-playbook -i inventories/test.ini playbooks/main.yml -e "env=test"

# 프로덕션 환경 전체 배포 (안전 확인 포함)
ansible-playbook -i inventories/prod.ini playbooks/main.yml -e "env=prod"

# WireGuard VPN 배포 (공유 인프라)
ansible-playbook -i inventories/shared.ini playbooks/deploy_shared.yml
```

### 🏷️ 태그 기반 선택적 배포

```bash
# 백엔드 서비스만 배포
ansible-playbook -i inventories/dev.ini playbooks/main.yml -e "env=dev" --tags "backend"

# 프론트엔드 서비스만 배포
ansible-playbook -i inventories/dev.ini playbooks/main.yml -e "env=dev" --tags "frontend"

# AI 서비스만 배포
ansible-playbook -i inventories/dev.ini playbooks/main.yml -e "env=dev" --tags "ai"

# 데이터베이스만 배포
ansible-playbook -i inventories/dev.ini playbooks/main.yml -e "env=dev" --tags "database"

# 기본 시스템 설정만
ansible-playbook -i inventories/dev.ini playbooks/main.yml -e "env=dev" --tags "base"
```

## 🏷️ 사용 가능한 태그

| 태그 | 설명 | 포함 서비스 |
|------|------|-------------|
| `base` | 기본 시스템 설정 | 사용자, 방화벽, 공통 설정 |
| `database` | 데이터베이스 | PostgreSQL, Redis, 백업 |
| `backend` | 백엔드 서비스 | API 서버, AI 서비스 |
| `frontend` | 프론트엔드 | 웹 UI, Nginx 설정 |
| `nginx` | 웹서버 | Nginx, SSL 인증서 |
| `monitoring` | 모니터링 | 로그, 메트릭 수집 |
| `backup` | 백업 시스템 | 자동 백업 설정 |

### 🔄 고급 배포 옵션

```bash
# 특정 브랜치 배포
ansible-playbook -i inventories/dev.ini playbooks/main.yml -e "env=dev" -e "branch=feature/new-ui"

# 드라이런 모드 (변경사항 미리보기)
ansible-playbook -i inventories/prod.ini playbooks/main.yml -e "env=prod" --check --diff

# 특정 서비스 조합 배포
ansible-playbook -i inventories/test.ini playbooks/main.yml -e "env=test" --tags "database,backend"
```

### 🔒 프로덕션 배포 안전 절차

```bash
# 1단계: 드라이런으로 변경사항 확인
ansible-playbook -i inventories/prod.ini playbooks/main.yml -e "env=prod" --check --diff

# 2단계: 실제 배포 (자동 확인 프롬프트 포함)
ansible-playbook -i inventories/prod.ini playbooks/main.yml -e "env=prod"

# 3단계: 특정 서비스만 업데이트 (위험 최소화)
ansible-playbook -i inventories/prod.ini playbooks/main.yml -e "env=prod" --tags "frontend"
```

## 🔐 보안 설정

### Ansible Vault 암호화
민감한 변수(데이터베이스 패스워드, API 키 등)는 Ansible Vault로 암호화되어 있습니다.

```bash
# 변수 암호화
ansible-vault encrypt group_vars/test/vault.yml

# 변수 복호화  
ansible-vault decrypt group_vars/test/vault.yml

# 문자열 직접 암호화
ansible-vault encrypt_string 'secret_password' --name 'vault_db_password'
```

### WireGuard VPN 설정
공유 인프라에 WireGuard VPN 서버를 설정하여 안전한 관리 액세스를 제공합니다.

**주요 설정**:
- **서버 주소**: `10.8.0.1/24`
- **포트**: `51820`
- **클라이언트**: admin, kane, lucy, milo, sally, tony
- **설정 파일**: `wireguard-team-keys/` 디렉토리

**클라이언트 연결**:
```bash
# 클라이언트 설정 파일 확인
ls -la wireguard-team-keys/
# admin-client.conf, kane-client.conf, lucy-client.conf, ...

# VPN 연결 후 서버 접근 테스트
ping 10.8.0.1
```
|------|------|
| `fe.image` | 프론트엔드 Docker 이미지 경로 (ex. himello/fe_moongsan) |
| `fe.tag` | 배포할 Docker 이미지 태그 (기본값: test) |
| `fe.container_name` | 컨테이너 이름 |
| `fe.port` | 호스트에서 노출할 포트 (기본값: 80) |

### 3. Playbook 실행

```bash
# 공통 시스템 설치
ansible-playbook -i inventory.ini playbook.yml --limit test --tags common

# Nginx 설정 및 인증서 발급
ansible-playbook -i inventory.ini playbook.yml --limit test --tags nginx_conf

# 백엔드 배포
ansible-playbook -i inventory.ini playbook.yml --limit test --tags be_deploy --extra-vars "tag=test-1.0.0"

# DB 설치 및 초기 설정
ansible-playbook -i inventory.ini playbook.yml --limit test --tags database
```

## 🔧 역할별 실행 흐름

Ansible 역할은 실제 배포 시나리오에 따라 순차적으로 실행됩니다.  
각 역할은 독립적으로도 실행 가능하지만, 전체 흐름 안에서 다음과 같은 단계로 구성됩니다.

---

### 🛠️ Step 1. 서버 환경 초기화

**📁 역할: `common`**

- 운영 서버에 Docker, nginx, certbot, mysql-client 등을 설치합니다.
- `ubuntu` 유저를 `docker` 그룹에 추가하여 sudo 없이 Docker 명령을 사용할 수 있도록 설정합니다.
- `/home/ubuntu/logs`, `/tmp` 디렉토리를 생성하고 권한을 설정합니다.
- APT 캐시 정리 및 시스템 로그(`journalctl`) 정리를 통해 초기 서버를 클린하게 유지합니다.

---

### 🧩 Step 2. Nginx 설정 및 HTTPS 적용

**📁 역할: `nginx_conf`**

- Nginx에 HTTP용 기본 설정 템플릿을 적용합니다.
- certbot을 통해 SSL 인증서를 발급받습니다.
- HTTPS 템플릿 설정을 적용하고, Nginx를 재시작하여 보안 통신을 적용합니다.

---

### 🗄️ Step 3. 데이터베이스 초기화

**📁 역할: `database`**

- MySQL 서버를 설치합니다.
- root 사용자 인증 방식을 `mysql_native_password`로 전환하여 Spring에서 접근 가능하게 합니다.
- 지정된 이름의 데이터베이스 및 사용자 계정을 생성합니다.
- 운영 체제와 DB의 타임존을 `Asia/Seoul`, `+09:00`으로 맞춰 서버 시간을 일치시킵니다.

---

### 🧪 Step 3-1. MySQL 접근 제어 트러블슈팅 (502 오류 해결 사례)

Spring Boot 서버가 MySQL과 통신하지 못해 기동에 실패하고, Nginx를 통해 들어온 API 요청이 모두 `502 Bad Gateway`로 응답되는 문제가 발생했습니다. 

문제 원인은 Spring 컨테이너가 `172.18.0.x` 대역 (사용자 정의 Docker 네트워크인 `moongsan-net`)을 사용하고 있었는데, MySQL 권한 설정에서는 기본 브리지 대역인 `172.17.0.%`만 허용되고 있었기 때문입니다.

#### 🔍 로그 메시지
```bash
Host '172.18.0.2' is not allowed to connect to this MySQL server
```

#### ✅ 해결 방법
Ansible의 `database` 역할에 다음 항목을 추가하여 권한을 부여합니다:
```yaml
- name: Grant DB access to moongsan_admin from moongsan-net
  community.mysql.mysql_user:
    name: "{{ db.user }}"
    host: "172.18.0.%"
    password: "{{ db.password }}"
    priv: "{{ db.name }}.*:ALL"
    state: present
    login_user: "{{ db.root_user }}"
    login_password: "{{ db.root_password }}"
```

추가 후 다음을 실행해 적용합니다:
```bash
ansible-playbook -i inventory.ini playbook.yml --limit test --tags database
docker restart be_moongsan
```

#### 📌 참고 사항
- Docker는 사용자 정의 네트워크 생성 시 자동으로 `172.18.0.0/16`, `172.19.0.0/16` 등을 순차적으로 할당합니다.
- 추가 네트워크가 필요할 경우 이후 대역(예: `172.20.0.0/16`)도 자동 사용되므로, 접속 제어는 CIDR 범위로 확장 가능합니다.
- 운영 보안을 위해 `host: '%'`는 지양하고, 실제 사용하는 네트워크 대역만 열어야 합니다.


## 📊 환경별 변수 구조

### Group Variables 계층
```bash
group_vars/
├── all/vault.yml              # 전역 공통 암호화 변수
├── dev/                       # 개발 환경
│   ├── all.yml               # 개발 환경 설정
│   └── wireguard.yml         # 개발용 WireGuard 설정
├── test/                      # 테스트 환경
│   ├── all.yml               # 테스트 환경 설정
│   ├── vault.yml             # 테스트 환경 암호화 변수
│   └── wireguard.yml         # 테스트용 WireGuard 설정
├── prod/                      # 프로덕션 환경
│   ├── all.yml               # 프로덕션 환경 설정
│   └── wireguard.yml         # 프로덕션용 WireGuard 설정
└── shared/                    # 공유 인프라
    ├── vault.yml             # 공유 인프라 암호화 변수
    └── wireguard.yml         # 공유 WireGuard 설정
```

### 주요 변수 카테고리

#### 🌐 네트워크 및 도메인
```yaml
nginx:
  domain: "example.com"
  ssl_email: "admin@example.com"
```

#### 🗄️ 데이터베이스
```yaml
database:
  host: "localhost"
  port: 3306
  name: "app_db"
  user: "app_user" 
  password: "{{ vault_db_password }}"
  root_password: "{{ vault_db_root_password }}"
```

#### ⚙️ 백엔드 서비스
```yaml
backend:
  image_tag: "v1.0.0"
  port: 8080
  ai_service_url: "http://ai-service:8000"
  aws:
    access_key: "{{ vault_aws_access_key }}"
    secret_key: "{{ vault_aws_secret_key }}"
    region: "ap-northeast-2"
    s3_bucket: "my-app-bucket"
```

#### 🤖 AI 서비스
```yaml
ai:
  image_tag: "v1.0.0"
  port: 8000
  openai_api_key: "{{ vault_openai_api_key }}"
  gcp:
    project_id: "my-project"
    credentials: "{{ vault_gcp_credentials }}"
```

#### 🔒 WireGuard VPN
```yaml
wireguard:
  interface: "wg0"
  port: 51820
  server_address: "10.8.0.1/24"
  clients:
    - name: "admin"
      ip: "10.8.0.2/32"
    - name: "developer"
      ip: "10.8.0.3/32"
```

## 🔧 운영 가이드

### 배포 모범 사례

#### 1. 프로덕션 배포 절차
```bash
# 1단계: 드라이런으로 변경사항 확인
ansible-playbook -i inventories/prod.ini main.yml -e "env=prod" --check

# 2단계: 백업 확인
ansible -i inventories/prod.ini prod -m shell -a "ls -la /var/backup/"

# 3단계: 단계별 배포 (선택적)
ansible-playbook -i inventories/prod.ini main.yml -e "env=prod" --tags "base,database"

# 4단계: 전체 배포
ansible-playbook -i inventories/prod.ini main.yml -e "env=prod"
```

#### 2. 롤백 절차
```bash
# 이전 이미지 태그로 롤백
ansible-playbook -i inventories/prod.ini main.yml \
  -e "env=prod" -e "image_tag=v1.0.0-rollback" --tags "backend"

# 데이터베이스 롤백 (필요시)
ansible-playbook -i inventories/prod.ini dev_db_fix.yml \
  -e "env=prod" -e "restore_backup=true"
```

### 모니터링 및 트러블슈팅

#### 서비스 상태 확인
```bash
# 모든 컨테이너 상태
ansible -i inventories/dev.ini dev -m shell -a "docker ps -a"

# 특정 서비스 로그
ansible -i inventories/dev.ini dev -m shell -a "docker logs backend-container --tail 100"

# 시스템 리소스 확인
ansible -i inventories/dev.ini dev -m shell -a "df -h && free -h"
```

#### WireGuard 연결 확인
```bash
# VPN 서버 상태
ansible -i inventories/shared.ini shared -m shell -a "wg show"

# 클라이언트 연결 테스트
ping 10.8.0.1  # VPN 연결 후
```

## 📚 추가 리소스

### 관련 문서
- [📖 플레이북 사용 가이드](playbooks/README.md)
- [🔒 보안 가이드](../docs/security-guide.md)
- [🚀 배포 가이드](../docs/deployment-guide.md)
- [🔧 트러블슈팅 가이드](../docs/troubleshooting-guide.md)

### 유용한 명령어
```bash
# Ansible 구문 검사
ansible-playbook --syntax-check main.yml

# 인벤토리 확인
ansible-inventory -i inventories/dev.ini --list

# 변수 덤프
ansible -i inventories/dev.ini dev -m setup

# Vault 편집
ansible-vault edit group_vars/test/vault.yml
```

## 🏗️ 개발 및 기여

### 새로운 역할 추가
1. `roles/` 디렉토리에 새 역할 생성
2. 필요한 디렉토리 구조 생성 (`tasks/`, `templates/`, `defaults/`)
3. 해당 역할을 플레이북에 추가
4. 문서 업데이트

### 새로운 환경 추가
1. `group_vars/new_env/` 디렉토리 생성
2. 필요한 변수 파일 생성 (`all.yml`, `vault.yml`)
3. 인벤토리 파일에 새 환경 추가
4. 환경별 플레이북 생성 (`playbooks/deploy_new_env.yml`)

---

*이 README는 Ansible 인프라의 전체적인 이해를 돕기 위해 작성되었습니다. 자세한 사용법은 각 디렉토리의 README 파일을 참고하세요.*