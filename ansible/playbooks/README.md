# Ansible 플레이북 사용 가이드

이 디렉토리에는 3-tier 클라우드 인프라를 관리하기 위한 Ansible 플레이북들이 포함되어 있습니다.

## 📁 플레이북 구조

### 🏗️ 환경별 전체 배포 플레이북 (권장)
- `deploy_dev.yml` - 개발 환경 전체 배포
- `deploy_test.yml` - 테스트 환경 전체 배포  
- `deploy_prod.yml` - 프로덕션 환경 전체 배포
- `deploy_shared.yml` - 공유 인프라 배포 (WireGuard VPN 등)

### 🔧 개별 서비스 배포 플레이북
- `ai_deploy.yml` - AI 서비스 개별 배포
- `be_deploy.yml` - 백엔드 서비스 개별 배포
- `fe_deploy.yml` - 프론트엔드 서비스 개별 배포
- `wireguard_deploy.yml` - WireGuard VPN 개별 배포

### 🛠️ 유틸리티 플레이북
- `site.yml` - 범용 전체 배포 플레이북
- `dev_db_fix.yml` - 데이터베이스 수정/복구 (개발/테스트 전용)

## 🚀 기본 사용법

### 환경별 전체 배포 (권장)

```bash
# 개발 환경 배포
ansible-playbook -i inventory.ini playbooks/deploy_dev.yml

# 테스트 환경 배포
ansible-playbook -i inventory_test.ini playbooks/deploy_test.yml

# 프로덕션 환경 배포 (주의!)
ansible-playbook -i inventory_prod.ini playbooks/deploy_prod.yml --check  # 드라이런 먼저
ansible-playbook -i inventory_prod.ini playbooks/deploy_prod.yml

# 공유 인프라 (WireGuard VPN) 배포
ansible-playbook -i inventory.ini playbooks/deploy_shared.yml
```

### 개별 서비스 배포

```bash
# 백엔드만 배포
ansible-playbook -i inventory.ini playbooks/be_deploy.yml -e "target=dev"

# AI 서비스만 배포
ansible-playbook -i inventory.ini playbooks/ai_deploy.yml -e "target=test"

# WireGuard VPN만 배포
ansible-playbook -i inventory.ini playbooks/wireguard_deploy.yml
```

### 태그 기반 선택적 배포

```bash
# 기본 시스템 설정만
ansible-playbook -i inventory.ini playbooks/deploy_dev.yml --tags "base"

# 데이터베이스 설정만
ansible-playbook -i inventory.ini playbooks/deploy_dev.yml --tags "database"

# 백엔드 + AI 서비스만
ansible-playbook -i inventory.ini playbooks/deploy_dev.yml --tags "backend,ai"

# WireGuard 제외하고 모든 것 배포
ansible-playbook -i inventory.ini playbooks/deploy_dev.yml --skip-tags "wireguard"
```

## 🏷️ 지원하는 태그

- `base` - 기본 시스템 설정
- `network` - 네트워크 및 공통 서비스
- `database` - 데이터베이스 설정
- `backend` - 백엔드 서비스
- `ai` - AI 서비스
- `nginx` - 웹 서버 및 프록시
- `backup` - 백업 설정
- `wireguard` - WireGuard VPN 설정

## 🔒 WireGuard VPN 배포

⚠️ **중요**: WireGuard VPN 서버는 `shared-jumpbox`(34.47.100.211)에만 설치됩니다!

### WireGuard 서버 배포

```bash
# WireGuard 서버 배포 (항상 shared-jumpbox에 배포됨)
ansible-playbook wireguard_playbook.yml

# 또는 기본 배포 플레이북을 통해
ansible-playbook playbooks/wireguard_deploy.yml
```

### 클라이언트 설정 확인

팀원별 클라이언트 설정 파일은 `wireguard-team-keys/` 디렉토리에 있습니다:

```bash
ls -la wireguard-team-keys/
# admin-client.conf    - 시스템 관리자용
# lucy-client.conf     - Backend 개발자용 
# kane-client.conf     - Backend 개발자용
# milo-client.conf     - AI 개발자용
# tony-client.conf     - AI 개발자용
# sally-client.conf    - Cloud 엔지니어용
```

### 환경별 연결 설정

각 환경에서 shared-jumpbox로 연결할 때 사용하는 설정:

- **Dev 환경**: `group_vars/dev/wireguard.yml` - 개발 네트워크 접근
- **Test 환경**: `group_vars/test/wireguard.yml` - 테스트 네트워크 접근  
- **Prod 환경**: `group_vars/prod/wireguard.yml` - 프로덕션 네트워크 접근 (제한적)

## 🛠️ 데이터베이스 관리

```bash
# 개발 환경 DB 수정/복구
ansible-playbook -i inventory.ini playbooks/dev_db_fix.yml -e "target=dev"

# 테스트 환경 DB 수정/복구
ansible-playbook -i inventory_test.ini playbooks/dev_db_fix.yml -e "target=test"
```

⚠️ **주의**: `dev_db_fix.yml`은 개발/테스트 환경에서만 사용하세요!

## 🔍 배포 검증

### 서비스 상태 확인

```bash
# 모든 Docker 컨테이너 상태 확인
ansible -i inventory.ini dev -m shell -a "docker ps"

# 특정 서비스 로그 확인
ansible -i inventory.ini dev -m shell -a "docker logs backend_container"

# WireGuard 상태 확인
ansible -i inventory.ini shared -m shell -a "wg show"
```

### 연결성 테스트

```bash
# 데이터베이스 연결 테스트
ansible -i inventory.ini dev -m shell -a "docker exec backend_container curl -f http://database:5432"

# 웹 서비스 응답 테스트
curl -f http://your-domain.com/health
```

## 📋 체크리스트

### 배포 전

- [ ] 인벤토리 파일 확인 (`inventory.ini`, `inventory_test.ini`)
- [ ] 변수 설정 확인 (`group_vars/*/`)
- [ ] SSH 키 설정 확인
- [ ] 백업 확인 (프로덕션의 경우)

### 배포 중

- [ ] 드라이런 실행 (`--check` 옵션)
- [ ] 단계별 배포 (태그 사용)
- [ ] 로그 모니터링

### 배포 후

- [ ] 서비스 상태 확인
- [ ] 연결성 테스트
- [ ] 로그 확인
- [ ] 모니터링 설정

## 🆘 문제 해결

### 일반적인 문제

1. **SSH 연결 실패**
   ```bash
   # SSH 연결 테스트
   ansible -i inventory.ini all -m ping
   ```

2. **Docker 서비스 실행 안됨**
   ```bash
   # Docker 서비스 시작
   ansible -i inventory.ini all -m systemd -a "name=docker state=started" --become
   ```

3. **WireGuard 설정 문제**
   ```bash
   # WireGuard 서비스 재시작
   ansible -i inventory.ini shared -m systemd -a "name=wg-quick@wg0 state=restarted" --become
   ```

### 로그 확인

```bash
# Ansible 실행 로그 (verbose)
ansible-playbook -i inventory.ini playbooks/deploy_dev.yml -v

# 매우 상세한 로그
ansible-playbook -i inventory.ini playbooks/deploy_dev.yml -vvv
```

## 📚 참고 자료

- [Ansible 공식 문서](https://docs.ansible.com/)
- [WireGuard 설정 가이드](../docs/security-guide.md)
- [배포 가이드](../docs/deployment-guide.md)
- [트러블슈팅 가이드](../docs/troubleshooting-guide.md)
