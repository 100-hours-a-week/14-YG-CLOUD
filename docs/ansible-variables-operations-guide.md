# Ansible 하드코딩 제거 운영 가이드

## 📋 개요

이 가이드는 14-YG-CLOUD 프로젝트에서 수행된 하드코딩 제거 작업의 결과물을 운영하기 위한 실무 가이드입니다.

## 🗂️ 변수 파일 구조

### 환경별 변수 파일
```
ansible/group_vars/
├── dev/all.yml          # 개발 환경 변수
├── test/all.yml         # 테스트 환경 변수  
├── prod/all.yml         # 프로덕션 환경 변수 (암호화)
└── shared/              # 공유 인프라 변수
```

### 변수 파일 내용 구조
```yaml
# 기본 서비스 정보
service_name: moongsan
env: dev

# 시스템 설정
system:
  user: ubuntu
  home_dir: "/home/ubuntu"

# 프로젝트 경로
project_paths:
  be_repo: "{{ system.home_dir }}/14-YG-BE"
  ai_repo: "{{ system.home_dir }}/14-YG-AI"
  fe_repo: "{{ system.home_dir }}/14-YG-FE"

# 네트워크 IP 매핑
internal_ips:
  database: "10.0.0.2"
  backend: "10.0.0.3"
  ai: "10.0.0.5"

# 서비스별 설정
be:
  port: 8080
  ai_service_base_url: "http://{{ internal_ips.ai }}:{{ ai.port }}"

ai:
  port: 8100

db:
  port: 3306
  host: "{{ internal_ips.database }}"
```

## 🔧 운영 작업 가이드

### 1. 새로운 환경 추가

새로운 환경(예: staging)을 추가하려면:

```bash
# 1. 변수 파일 생성
cp ansible/group_vars/dev/all.yml ansible/group_vars/staging/all.yml

# 2. 환경별 값 수정
vim ansible/group_vars/staging/all.yml
```

필수 수정 항목:
```yaml
env: staging
nginx:
  domain: "staging.moongsan.com"
# 기타 환경별 다른 설정들...
```

### 2. IP 주소 변경

서버 IP가 변경된 경우:

```yaml
# group_vars/{env}/all.yml에서 수정
internal_ips:
  database: "새로운_IP"
  backend: "새로운_IP"  
  ai: "새로운_IP"
```

**주의**: IP 변경 후 반드시 전체 서비스 재배포 필요

### 3. 포트 변경

서비스 포트를 변경하려면:

```yaml
# group_vars/{env}/all.yml에서 수정
be:
  port: 8090  # 새로운 포트

# 관련 서비스들도 자동으로 참조됨
ai_service_base_url: "http://{{ internal_ips.ai }}:{{ ai.port }}"
```

### 4. 데이터베이스 설정 변경

```yaml
# 데이터베이스 관련 설정 변경
db:
  port: 3307  # 새로운 포트
  name: "new_database_name"
  user: "new_user"
  # password는 vault로 관리
```

## 🔒 보안 변수 관리

### Ansible Vault 사용

민감한 정보는 암호화해서 관리합니다:

```bash
# 암호화된 변수 편집
ansible-vault edit group_vars/prod/all.yml

# 새로운 암호화 변수 추가
ansible-vault encrypt_string 'secret_value' --name 'vault_variable_name'
```

### 보안 변수 네이밍 규칙
```yaml
# vault_ 접두사 사용
vault_db_password: !vault |
  $ANSIBLE_VAULT;1.1;AES256
  ...

# 실제 변수에서 참조
db:
  password: "{{ vault_db_password }}"
```

## 🚀 배포 작업

### 변수 검증
배포 전 변수 참조 확인:

```bash
# Dry-run으로 변수 참조 검증
ansible-playbook -i inventories/dev.ini site.yml --check --diff

# 특정 호스트의 변수 확인
ansible-inventory -i inventories/dev.ini --host dev.moongsan.com
```

### 환경별 배포
```bash
# 개발 환경 배포
ansible-playbook -i inventories/dev.ini site.yml

# 테스트 환경 배포  
ansible-playbook -i inventories/test.ini site.yml

# 프로덕션 배포 (vault 비밀번호 필요)
ansible-playbook -i inventories/prod.ini site.yml --ask-vault-pass
```

## 🔍 트러블슈팅

### 변수 참조 오류
```bash
# 오류 메시지 예시
"AnsibleUndefinedVariable: 'dict object' has no attribute 'undefined_var'"

# 해결 방법
1. 변수가 올바른 group_vars 파일에 정의되어 있는지 확인
2. 변수명 오타 확인  
3. 변수 참조 문법 확인 {{ variable_name }}
```

### 환경별 변수 충돌
```bash
# 현재 호스트에 적용되는 모든 변수 확인
ansible -i inventories/dev.ini dev.moongsan.com -m debug -a "var=hostvars[inventory_hostname]"
```

### 템플릿 렌더링 확인
```bash
# 템플릿 결과 미리보기
ansible-playbook -i inventories/dev.ini site.yml --tags "template" --check --diff
```

## 📝 변수 수정 체크리스트

새로운 변수를 추가하거나 기존 변수를 수정할 때:

- [ ] 모든 환경 파일에 변수 추가/수정
- [ ] 변수명 규칙 준수 (snake_case, 의미있는 이름)
- [ ] 민감 정보는 vault로 암호화
- [ ] 관련 템플릿 파일에서 변수 참조 확인
- [ ] 문서 업데이트
- [ ] 테스트 환경에서 검증 후 프로덕션 적용

## 🎯 Best Practices

### 변수 네이밍 규칙
```yaml
# 좋은 예
internal_ips:
  database: "10.0.0.2"
  
project_paths:
  be_repo: "/path/to/backend"

# 피해야 할 예  
db_ip: "10.0.0.2"           # 너무 축약됨
backend_repository_path: "..." # 너무 길음
```

### 변수 구조화
```yaml
# 관련 변수들을 그룹화
be:
  port: 8080
  image: "backend:latest"
  redis:
    host: "redis-server"
    port: 6379
```

### 기본값 설정
```yaml
# 기본값 제공으로 안정성 확보
database_port: "{{ db.port | default(3306) }}"
```

## 📊 변수 사용 현황

| 카테고리 | 변수 개수 | 사용 파일 수 | 설명 |
|----------|-----------|--------------|------|
| 시스템 설정 | 5 | 12 | 사용자, 경로 등 기본 설정 |
| 네트워크 | 8 | 15 | IP, 포트, 도메인 설정 |
| 서비스 | 25 | 20 | 각 서비스별 설정값 |
| 데이터베이스 | 12 | 8 | DB 연결 및 설정 |
| Docker | 6 | 10 | 컨테이너 및 네트워크 |

## 🔄 정기 점검 항목

### 월간 점검
- [ ] 새로 추가된 하드코딩 값 확인
- [ ] 사용하지 않는 변수 정리
- [ ] 변수 문서 업데이트

### 분기별 점검  
- [ ] 변수 구조 최적화 검토
- [ ] 보안 변수 비밀번호 갱신
- [ ] 성능 영향도 분석

---

이 가이드를 통해 하드코딩 없는 안정적이고 유연한 인프라 운영이 가능합니다.

**문서 업데이트**: 변수 구조 변경 시 반드시 이 가이드도 함께 업데이트하세요.
