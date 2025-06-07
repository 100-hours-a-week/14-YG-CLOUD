# Ansible 플레이북 사용 가이드 (통합 버전)

이 디렉토리에는 3-tier 클라우드 인프라를 관리하기 위한 통합된 Ansible 플레이북이 포함되어 있습니다.

## 🔄 플레이북 구조 개선 사항

### ⚠️ 2024년 12월 - 플레이북 통합 완료
기존의 복잡한 다중 플레이북 구조를 단순화하여 **하나의 통합 플레이북**으로 전환했습니다.

**제거 예정 플레이북들:**
- `deploy_dev.yml`, `deploy_test.yml`, `deploy_prod.yml` → `main.yml`로 통합
- `ai_deploy.yml`, `be_deploy.yml`, `fe_deploy.yml` → `main.yml`의 태그 시스템으로 통합
- `site.yml`, `wireguard_deploy.yml` → 각각 `main.yml`과 `deploy_shared.yml`로 통합

## 📁 현재 플레이북 구조

### 🏗️ 핵심 플레이북
- **`main.yml`** - ⭐ **새로운 통합 배포 플레이북** (모든 환경 및 서비스 지원)
- **`deploy_shared.yml`** - 공유 인프라 배포 (WireGuard VPN)
- **`dev_db_fix.yml`** - 데이터베이스 수정/복구 (개발/테스트 전용)

### 📦 기존 플레이북들 (곧 제거 예정)
- `deploy_dev.yml`, `deploy_test.yml`, `deploy_prod.yml` - 환경별 배포
- `ai_deploy.yml`, `be_deploy.yml`, `fe_deploy.yml` - 서비스별 배포
- `site.yml`, `wireguard_deploy.yml` - 기타 배포

## 🚀 새로운 통합 사용법 (권장)

### 🎯 기본 배포 명령어

```bash
# 개발 환경 전체 배포
ansible-playbook -i inventories/dev.ini playbooks/main.yml -e "env=dev"

# 테스트 환경 전체 배포
ansible-playbook -i inventories/test.ini playbooks/main.yml -e "env=test"

# 프로덕션 환경 전체 배포 (안전 확인 포함)
ansible-playbook -i inventories/prod.ini playbooks/main.yml -e "env=prod"
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

# 인프라 기반시설만 배포
ansible-playbook -i inventories/dev.ini playbooks/main.yml -e "env=dev" --tags "base"
```

## 🏷️ 사용 가능한 태그 시스템

| 태그 | 설명 | 포함 서비스 |
|------|------|-------------|
| `base` | 기본 시스템 설정 | 사용자, 방화벽, 공통 설정 |
| `database` | 데이터베이스 | PostgreSQL, Redis, 백업 |
| `backend` | 백엔드 서비스 | API 서버, AI 서비스 |
| `frontend` | 프론트엔드 | 웹 UI, Nginx 설정 |
| `nginx` | 웹서버 | Nginx, SSL 인증서 |
| `monitoring` | 모니터링 | 로그, 메트릭 수집 |
| `backup` | 백업 시스템 | 자동 백업 설정 |

## 📊 배포 진행 단계

새로운 통합 플레이북은 **10단계 배포 과정**을 제공합니다:

1. **환경 검증** - 필수 변수 및 안전 확인
2. **기본 시스템** - 사용자, 보안 설정
3. **공통 설정** - 네트워크, 방화벽
4. **데이터베이스** - PostgreSQL 설치
5. **Redis 캐시** - Redis 서버 설정
6. **백엔드 서비스** - API 서버 배포
7. **AI 서비스** - ML 모델 배포
8. **프론트엔드** - 웹 UI 배포
9. **Nginx 설정** - 웹서버, SSL
10. **백업/모니터링** - 시스템 관리

## 🔒 프로덕션 배포 안전 절차

```bash
# 1단계: 드라이런으로 변경사항 미리보기
ansible-playbook -i inventories/prod.ini playbooks/main.yml -e "env=prod" --check --diff

# 2단계: 실제 배포 (자동 확인 프롬프트)
ansible-playbook -i inventories/prod.ini playbooks/main.yml -e "env=prod"

# 3단계: 특정 서비스만 업데이트
ansible-playbook -i inventories/prod.ini playbooks/main.yml -e "env=prod" --tags "frontend"
```

## 📈 통합의 이점

| 측면 | 이전 | 현재 |
|------|------|------|
| **파일 수** | 12개 플레이북 | 3개 플레이북 |
| **일관성** | 각각 다른 구조 | 표준화된 구조 |
| **유지보수** | 복잡함 | 단순함 |
| **배포 시간** | 긴 시간 | 빠른 배포 |
| **태그 지원** | 제한적 | 완전한 지원 |

## 🚨 마이그레이션 가이드

### 기존 → 새로운 명령어

```bash
# BEFORE
ansible-playbook -i inventory.ini playbooks/deploy_dev.yml
# AFTER  
ansible-playbook -i inventories/dev.ini playbooks/main.yml -e "env=dev"

# BEFORE
ansible-playbook -i inventory.ini playbooks/be_deploy.yml -e "target=dev"  
# AFTER
ansible-playbook -i inventories/dev.ini playbooks/main.yml -e "env=dev" --tags "backend"
```

## 🔧 특별 플레이북

### WireGuard VPN 배포
```bash
ansible-playbook -i inventories/shared.ini playbooks/deploy_shared.yml
```

### 데이터베이스 수정 (개발/테스트만)
```bash
ansible-playbook -i inventories/dev.ini playbooks/dev_db_fix.yml
```

---

⚡ **권장사항**: 새로운 `main.yml` 통합 플레이북 사용을 강력히 권장합니다!