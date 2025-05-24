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
ansible-vault encrypt group_vars/test/be_var.yml

# 복호화
ansible-vault decrypt group_vars/test/be_var.yml
```


## 🚀 사용 방법

### 1. 인벤토리 설정

`inventory.ini` 파일에 테스트 및 운영 서버를 정의합니다.

```ini
[prod]
moongsan.com ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/lsh-study-key

[test]
test.moongsan.com ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/lsh-study-key
```

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
ansible-playbook -i inventory.ini playbook.yml --limit test --tags betest

# DB 설치 및 초기 설정
ansible-playbook -i inventory.ini playbook.yml --limit test --tags database
```

## 🔧 역할별 상세 설명

### common
- 운영 서버의 공통 환경을 초기화합니다.
- Docker 설치 (공식 스크립트 기반)
- ubuntu 유저 docker 그룹 추가
- nginx, certbot, mysql-client, git 등 설치
- /logs, /tmp 디렉토리 보안 설정
- APT 캐시 정리, 시스템 로그 정리

### nginx_conf
- Nginx 초기 설정 (http 템플릿 배포)
- Certbot으로 인증서 발급
- HTTPS 설정 템플릿 적용
- Nginx reload

### betest
- 백엔드 레포 클론 or fetch (14-YG-BE)
- .env.prod 템플릿 생성
- Docker Compose를 통한 컨테이너 빌드 및 실행
- Logrotate 설정 (be_moongsan.log)

### database
- MySQL 설치
- root 사용자 인증 방식 전환
- DB 및 사용자 생성
- MySQL 타임존 설정


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
- 서비스 실행은 docker-compose 기준이며, 직접 소스 실행은 제거됨.
- 인증서는 Certbot으로 1회 발급 후 nginx reload로 자동 적용됩니다.
- DB는 컨테이너 외부 설치 구조로 유지되고, database 역할에서 전담합니다.