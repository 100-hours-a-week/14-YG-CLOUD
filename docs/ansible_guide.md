# Ansible 가이드

## 디렉토리 구조

- inventories/dev
- inventories/test
- inventories/prod

## 사용법

- Dev: ansible-playbook -i inventories/dev/hosts playbooks/site_dev.yml
- Test: ansible-playbook -i inventories/test/hosts playbooks/site_test.yml
- Prod: ansible-playbook -i inventories/prod/hosts playbooks/site_prod.yml
