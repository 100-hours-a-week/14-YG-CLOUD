# 14-YG-CLOUD Ansible Playbook

이 프로젝트는 공동구매 플랫폼(14-YG)의 AI, FE, BE, DB 인프라 구성을 Ansible을 통해 자동화하는 템플릿입니다.
모든 구성 요소는 Docker 기반으로 배포되며, 일부 시스템 구성(Nginx, DB)은 호스트에서 직접 관리됩니다.

## 📦 구성 요소

| 구성 요소          | 설명                                                      |
|-------------------|-----------------------------------------------------------|
| **common**        | 서버 공통 환경 구성 (Docker, nginx, certbot 등)                |
| **nginx_conf**    | Nginx 설정 및 HTTPS 인증서 발급 자동화                          |
| **betest**        | 백엔드 배포 전용 역할 (레포 클론 → env 생성 → docker compose 실행) |
| **database**      | MySQL 서버 설치 및 초기 사용자/DB 설정                          |


## 📁 프로젝트 구조

```bash
ansible/
├── playbook.yml
├── inventory.ini
├── .vault_pass.txt
├── group_vars/
│   └── test/
│       └── all.yml
├── roles/
│   ├── common/
│   ├── nginx_conf/
│   ├── betest/
│   └── database/
```


## 🔐 Vault 암호화
- 민감한 변수(db_password, jwt_secret 등)는 ansible-vault로 암호화되어 있습니다.
- 암호 파일: .vault_pass.txt (비공개 저장소에서 관리)

**예시 복호화, 암호화 명령:**
```bash
# 암호화
ansible-vault encrypt group_vars/test/all.yml

# 복호화
ansible-vault decrypt group_vars/test/all.yml
```

### DockerHub 비밀번호 예시

DockerHub 로그인 시 필요한 비밀번호도 ansible-vault로 암호화하여 다음과 같이 `group_vars/test/all.yml`에 정의합니다.

```yaml
dockerhub:
  username: himello
  password: "{{ vault_dockerhub_password }}"
```

`vault_dockerhub_password`는 다음 명령어로 생성합니다:

```bash
ansible-vault encrypt_string 'your_dockerhub_password' --name 'vault_dockerhub_password'
```

`.vault_pass.txt`는 루트 디렉토리에 존재해야 하며, `.gitignore`에 등록해야 합니다.

`ansible.cfg` 설정 예시:

```ini
[defaults]
vault_password_file = .vault_pass.txt
```


## 🚀 사용 방법
### ⚠️ 운영 환경 배포 시 주의사항

운영 서버(--limit prod)에 --tags fastapi, --tags backend 등을 사용해 직접 배포하는 경우, 다음 사항을 반드시 확인해야 합니다:
#### dry-run(dry 실행) 습관화
실행 전 영향 범위를 확인하려면 --check 플래그를 활용하세요:
```bash
ansible-playbook -i inventory.ini playbook.yml \
  --limit prod --tags fastapi \
  --extra-vars "tag=v1.0.0" --check
```
> 운영 환경에서는 항상 환경 확인 + 태그 명시 + 재확인 + dry-run 후 배포를 습관화하세요.

### 1. 인벤토리 설정

`inventory.ini` 파일에 테스트 및 운영 서버를 정의합니다.

```ini
[prod]
moongsan.com ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/lsh-study-key

[test]
test.moongsan.com ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/lsh-study-key
```

### 2. 태그 전략 및 배포 방식

Docker 이미지 태그는 v1.*.* 형식을 기준으로 하며, 브랜치/배포 목적에 따라 다음과 같이 지정합니다.
Ansible에서는 --extra-vars "tag=..." 방식으로 태그를 명시해야 정확한 이미지가 배포됩니다.
```bash
# release 브랜치 (QA 서버용, 릴리즈 후보)
ansible-playbook -i inventory.ini playbook.yml \
  --limit test --tags fastapi \
  --extra-vars "tag=rc-1.0.0"

# main 브랜치 (운영 서버용, 안정 버전)
ansible-playbook -i inventory.ini playbook.yml \
  --limit prod --tags fastapi \
  --extra-vars "tag=v1.0.0"
```
>💡 tag는 group_vars/[env]/all.yml에서 기본값을 지정할 수 있지만,
운영 환경에서는 반드시 명시적으로 --extra-vars를 통해 태그를 지정하는 것을 권장합니다

---

## 🔐 변수 설정

모든 환경별 변수는 `group_vars/[env]/all.yml` 하나의 파일에서 관리됩니다.  
서비스 범주별로 중첩된 딕셔너리 구조를 사용하며, Ansible Vault로 민감한 변수는 암호화되어 있습니다.  
`.vault_pass.txt`를 통해 복호화할 수 있습니다.


### 주요 변수 구조
---
#### `nginx`
| 이름 | 설명 |
|------|------|
| `nginx.domain` | Nginx 도메인 |
| `nginx.ssl_email` | 인증서 발급용 이메일 |
---
#### `DB`
| 이름 | 설명 |
|------|------|
| `db.url`, `db.user`, `db.password` | Spring DB 연결 정보 |
| `db.root_user`, `db.root_password` | DB 초기화용 root 계정 |
| `db.name` | 생성할 DB 이름 |
---
#### `BE`
| 이름 | 설명 |
|------|------|
| `be.ai_service_base_url` | 백엔드에서 참조하는 AI 주소 |
| `be.ai_service_enabled` | AI 연동 여부 |
| `be.aws.access_key`, `be.aws.secret_key` | S3 인증 정보 |
| `be.aws.region` | S3 리전 |
| `be.aws.s3_bucket` | 버킷명 |
---
#### `AI`
| 이름 | 설명 |
|------|------|
`ai.openai_api_key` | OpenAI 키
`ai.gcp.credentials` 등 | GCP 인증 정보 (`client_id`, `private_key`, `project` 등 포함)
`ai.langsmith.*` | Langsmith 추적 설정 (api_key, project 등)
`ai.tavily_api_keys.*` | Tavily 사용자별 키
`ai.proxies[0]`, `ai.proxies[1]` | API 프록시 주소 리스트


### 3. Playbook 실행

```bash
# 공통 시스템 설치
ansible-playbook -i inventory.ini playbook.yml --limit test --tags common

# Nginx 설정 및 인증서 발급
ansible-playbook -i inventory.ini playbook.yml --limit test --tags nginx_conf

# 백엔드 배포
ansible-playbook -i inventory.ini playbook.yml --limit test --tags betest --extra-vars "tag=test-1.0.0"

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

### 🧱 Step 4. 백엔드 애플리케이션 배포

**📁 역할: `betest`**

- 백엔드 레포지토리(`14-YG-BE`)를 clone 또는 fetch/reset 합니다.
- `group_vars/test/all.yml`에서 주입되는 변수를 기반으로 `.env.prod` 파일을 생성합니다.
- Ansible은 Dockerfile을 기반으로 이미지를 pull → run까지 수행합니다.
- 서비스 로그는 `/logs/be_moongsan.log`에 기록되며, logrotate 설정으로 관리됩니다.
- 디스크 공간 확보를 위해 빌드 전마다 사용하지 않는 Docker 이미지 및 빌드 캐시를 정리합니다.
  - `docker image prune -f`
  - `docker builder prune -f`
---



## 🌐 접근 URL

| 서비스        | 예시 도메인                |
|---------------|-----------------------------|
| Frontend      | https://moongsan.com        |
| Backend API   | https://moongsan.com/api    |
| AI API        | http://localhost:8100       |
| Grafana       | https://grafana.moongsan.com |

## ⚙️ 기타 관리 방법

| 작업 항목                              | 방법                                                                 |
|----------------------------------------|----------------------------------------------------------------------|

## 📌 참고
- 모든 서비스는 /home/ubuntu/envs/{{ group }} 경로에 .env 파일이 생성됩니다.
- 로그는 /home/ubuntu/logs/ 아래로 분리되며, logrotate로 주기적 순환됩니다.
- 모든 실행은 docker run 기반이며, docker-compose는 사용하지 않습니다.
- 인증서는 Certbot으로 1회 발급 후 nginx reload로 자동 적용됩니다.
- DB는 컨테이너 외부 설치 구조로 유지되고, database 역할에서 전담합니다.