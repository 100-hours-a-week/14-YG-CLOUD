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
---
#### `FE`
| 이름 | 설명 |
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

### 🧠 Step 5. AI 서비스 패키지 버전 고정 (임시 수정 내역)

**📁 역할: `aitest`**

- FastAPI 기반 AI 애플리케이션을 `/home/ubuntu/14-YG-AI`에 배치합니다.
- .env 및 GCP 인증 키 파일을 템플릿으로 자동 생성합니다.
- 멀티 스테이지 Dockerfile을 활용해 이미지 빌드 및 실행을 자동화하며, 최적화된 대형 패키지를 포함합니다.
- /generation/description에서 상품 상세 설명을 생성하며, 로그는 /var/log/moongsan/ai_moongsan.log에 기록됩니다.
- 배포 후 불필요한 이미지/캐시는 자동 정리됩니다.

---

### 🧾 Step 6. 프론트엔드 애플리케이션 배포

**📁 역할: `fetest`**

- 프론트엔드 레포지토리(`14-YG-FE`)를 clone 또는 fetch/reset 합니다.
- `.env` 파일을 템플릿(`vite.env.j2`)으로 생성하여 `VITE_BASE_URL`을 환경에 맞게 자동 주입합니다.
- `vite.config.ts` 파일 역시 환경에 맞는 proxy 설정을 주입하여 개발 모드에서 API를 연결할 수 있게 합니다.
- `npm install`, `npm run build`로 정적 빌드 후, `/var/www/react`로 결과물을 복사하여 nginx가 서빙합니다.
- 로그는 `/logs/fe_moongsan.log`에 기록되며, logrotate 설정으로 관리됩니다.
- 디스크 공간 확보를 위해 불필요한 node_modules 캐시 및 Docker 빌드 캐시가 정리됩니다.
  - `rm -rf node_modules/`
  - `npm cache clean --force`

---

### 🗃️ Step 7. DB 백업 자동화 구성

**📁 역할: `db_backup`**

- 백업 스크립트(`db_backup.sh`)는 `/var/script/{{ service_name }}/` 경로에 배치되며, 매일 새벽 3시에 cron으로 자동 실행됩니다.
- DB 백업은 `mysqldump`를 통해 수행되며, 결과는 `/var/backup/{{ service_name }}/`에 `.sql` 파일로 저장됩니다.
- 백업 파일명은 `moongsan_{{ env }}_db_YYYY-MM-DD-HH-MM.sql` 형식으로 환경별로 구분됩니다.
- 생성된 백업 파일은 GCS(`gs://{{ gcs.name }}/{{ env }}/db/`)에 업로드됩니다.
- 서비스 계정 키(`my-gcs-key.json`)는 Ansible 템플릿으로 자동 생성되며 `/var/secret/{{ service_name }}/`에 위치합니다.
- 백업 실행 로그는 `/var/log/{{ service_name }}/db_backup.log`에 기록되며, logrotate로 일 1회 순환됩니다.

**📦 생성 예시**

| 경로 | 설명 |
|------|------|
| `/var/script/moongsan/db_backup.sh` | cron에서 실행되는 백업 스크립트 |
| `/var/backup/moongsan/moongsan_test_db_2025-05-27-03-00.sql` | 환경별 백업 파일 |
| `/var/log/moongsan/db_backup.log` | 로그 파일 |
| `/var/secret/moongsan/my-gcs-key.json` | GCP 서비스 계정 키 (Vault 템플릿 기반) |

> 💡 환경 정보(`env`), GCS 버킷명(`gcs.name`)은 `group_vars/[env]/all.yml`에서 명시적으로 정의됩니다.

---

## 🌐 접근 URL

| 서비스        | 예시 도메인                |
|---------------|-----------------------------|
| Frontend      | https://moongsan.com        |
| Backend API   | https://moongsan.com/api    |
| AI API        | https://moongsan.com/generation      |
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