# ELK Stack 인증 관리 가이드

## 비밀번호 중앙 관리

Elasticsearch 비밀번호는 `ansible/group_vars/shared/elk.yml` 파일에서 중앙 관리됩니다.

```yaml
elk:
  elasticsearch:
    password: "<YOUR_PASSWORD>"
```

## 비밀번호 변경 절차

1. `ansible/group_vars/shared/elk.yml` 파일의 `password` 값을 새로운 비밀번호로 변경합니다.
2. 아래 Ansible 플레이북을 실행하여 모든 관련 서비스에 변경사항을 적용합니다.

```bash
ansible-playbook -i shared.ini playbooks/update-elk-auth.yml
```

이 플레이북은 Logstash 설정을 업데이트하고 서비스를 재시작하여 새로운 비밀번호를 적용합니다.