# Ansible Vault 보안 가이드

## 개요
이 문서는 14-YG-CLOUD 프로젝트에서 Ansible Vault를 사용하여 민감한 정보를 안전하게 관리하는 방법을 설명합니다.

## Vault 구조

### 1. Vault 패스워드 파일
```
ansible/.vault_pass.txt
```
- Vault 암호화/복호화에 사용되는 패스워드 파일
- **절대 Git에 커밋하지 마세요** (`.gitignore`에 포함됨)

### 2. 암호화된 설정 파일
```
ansible/group_vars/dev/all.yml     # 개발 환경 설정 (암호화됨)
ansible/group_vars/test/all.yml    # 테스트 환경 설정 (암호화됨)
ansible/group_vars/prod/all.yml    # 프로덕션 환경 설정 (암호화됨)
ansible/group_vars/all/vault.yml   # 공통 민감 정보 (암호화됨)
```

## Vault 사용법

### 1. 새 vault 파일 생성
```bash
cd ansible
ansible-vault create group_vars/all/vault.yml
```

### 2. 기존 파일 암호화
```bash
cd ansible
ansible-vault encrypt group_vars/dev/all.yml
```

### 3. 암호화된 파일 편집
```bash
cd ansible
ansible-vault edit group_vars/dev/all.yml
```

### 4. 암호화된 파일 보기
```bash
cd ansible
ansible-vault view group_vars/dev/all.yml
```

### 5. 파일 복호화 (임시)
```bash
cd ansible
ansible-vault decrypt group_vars/dev/all.yml
# 편집 후 다시 암호화 필요
ansible-vault encrypt group_vars/dev/all.yml
```

## 민감 정보 관리

### 필수 변수들
다음 변수들은 `group_vars/all/vault.yml`에 저장되어야 합니다:

```yaml
# AWS 자격 증명
vault_aws_access_key: "{{ 실제_AWS_액세스_키 }}"
vault_aws_secret_key: "{{ 실제_AWS_시크릿_키 }}"

# OpenAI API 키
vault_openai_api_key: "{{ 실제_OPENAI_API_키 }}"
```

### 환경별 파일에서 참조
각 환경 파일에서는 vault 변수를 참조합니다:

```yaml
# group_vars/dev/all.yml 예시
aws_access_key: "{{ vault_aws_access_key }}"
aws_secret_key: "{{ vault_aws_secret_key }}"
openai_api_key: "{{ vault_openai_api_key }}"
```

## 보안 모범 사례

### 1. 패스워드 관리
- `.vault_pass.txt`는 절대 Git에 커밋하지 마세요
- 패스워드는 팀 내에서 안전한 방법으로 공유하세요
- 정기적으로 vault 패스워드를 변경하세요

### 2. 파일 권한
```bash
chmod 600 ansible/.vault_pass.txt
chmod 640 ansible/group_vars/*/all.yml
```

### 3. Git 관리
- 암호화된 파일만 커밋하세요
- `.gitignore`가 제대로 설정되어 있는지 확인하세요
- Git hooks을 사용하여 민감 정보 노출을 방지하세요

## 배포 시 사용법

### Ansible Playbook 실행
```bash
cd ansible
ansible-playbook -i inventory.ini playbook.yml --ask-vault-pass
```

또는 vault 패스워드 파일 사용:
```bash
cd ansible
ansible-playbook -i inventory.ini playbook.yml --vault-password-file .vault_pass.txt
```

### Terraform과 함께 사용
Ansible이 Terraform 배포 후 실행될 때 자동으로 vault가 해독됩니다.

## 트러블슈팅

### 1. "ERROR! input is already encrypted"
파일이 이미 암호화된 상태입니다. `ansible-vault edit`를 사용하세요.

### 2. "ERROR! Decryption failed"
잘못된 vault 패스워드이거나 파일이 손상되었습니다. 패스워드를 확인하세요.

### 3. "vault_password_file not found"
`ansible.cfg`에서 vault_password_file 경로를 확인하고, 올바른 디렉토리에서 명령을 실행하세요.

## 응급 복구

암호화된 파일에 문제가 생긴 경우:

1. 백업에서 복원
2. Git 히스토리에서 이전 버전 복구
3. 수동으로 재생성 후 다시 암호화

**중요**: 민감 정보가 포함된 파일은 절대 평문으로 커밋하지 마세요!
