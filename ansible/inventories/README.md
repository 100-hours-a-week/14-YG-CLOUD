# Inventory Structure

환경별 인벤토리가 분리되어 있습니다.

## 디렉토리 구조

```
inventories/
├── shared/hosts.ini    # WireGuard VPN 서버 (shared-jumpbox)
├── dev/hosts.ini       # 개발 환경 (단일 서버)
├── test/hosts.ini      # 테스트 환경 (3-tier 아키텍처)
└── prod/hosts.ini      # 운영 환경 (단일 서버)
```

## 사용법

### 환경별 배포

```bash
# Shared 환경 (WireGuard VPN)
ansible-playbook -i inventories/shared/hosts.ini wireguard_playbook.yml

# Dev 환경
ansible-playbook -i inventories/dev/hosts.ini playbooks/deploy_dev.yml

# Test 환경 (3-tier)
ansible-playbook -i inventories/test/hosts.ini playbooks/deploy_test.yml

# Prod 환경
ansible-playbook -i inventories/prod/hosts.ini playbooks/deploy_prod.yml
```

### 연결 테스트

```bash
# 각 환경별 ping 테스트
ansible all -i inventories/dev/hosts.ini -m ping
ansible all -i inventories/test/hosts.ini -m ping
ansible all -i inventories/prod/hosts.ini -m ping
ansible shared -i inventories/shared/hosts.ini -m ping
```

## 환경별 특징

- **shared**: WireGuard VPN 서버 (모든 환경 공통 접근점)
- **dev**: 단일 서버 개발 환경
- **test**: 3-tier 아키텍처 (shared-jumpbox를 통한 ProxyJump)
- **prod**: 단일 서버 운영 환경

## 기본 설정

`ansible.cfg`에서 기본 인벤토리는 `dev` 환경으로 설정되어 있습니다.
