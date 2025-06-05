# 배포 워크플로우 가이드

## 개요

14-YG-CLOUD 프로젝트는 Terraform과 Ansible을 조합한 Infrastructure as Code (IaC) 접근 방식을 사용합니다.

- **Terraform**: 인프라 프로비저닝 (GCP 리소스 생성)
- **Ansible**: 설정 관리 및 애플리케이션 배포

## 배포 순서

### 1단계: Terraform으로 인프라 생성
```bash
# 인프라 생성 (네트워크, VM, 방화벽 등)
cd terraform/environments/test
terraform init
terraform plan
terraform apply
```

### 2단계: Ansible로 서버 설정
```bash
# 서버 설정 및 애플리케이션 배포
cd ansible
ansible-playbook playbooks/site.yml
```

## 자동화된 배포 스크립트

### 전체 배포
```bash
# 모든 단계 실행 (권장)
./scripts/deploy.sh test

# 프로덕션 배포
./scripts/deploy.sh prod
```

### 선택적 배포
```bash
# Terraform만 실행
./scripts/deploy.sh test --terraform-only

# Ansible만 실행 (인프라가 이미 있는 경우)
./scripts/deploy.sh test --ansible-only

# 특정 Ansible 태그만 실행
./scripts/deploy.sh test --ansible-only
# 실행 시 태그 선택 가능: base, database, backend, ai, nginx, monitoring
```

## 배포 흐름 상세

### Terraform 단계
1. **인프라 검증**: `terraform validate`
2. **변경 계획**: `terraform plan`
3. **사용자 확인**: 변경사항 검토 후 승인
4. **인프라 적용**: `terraform apply`
5. **출력값 저장**: Ansible이 사용할 정보 저장

### Ansible 단계
1. **연결 테스트**: `ansible all -m ping`
2. **단계별 설정**:
   - `base`: 기본 시스템 설정 (패키지, Docker)
   - `common`: 공통 설정
   - `database`: MySQL 설정
   - `backend`: 백엔드 애플리케이션 배포
   - `ai`: AI 서비스 배포
   - `nginx`: 웹서버 및 로드밸런서 설정
   - `monitoring`: 모니터링 도구 설정

### 검증 단계
1. **서비스 상태 확인**: Docker, 애플리케이션 서비스
2. **네트워크 연결 확인**: 서버 간 통신
3. **배포 완료 리포트**: 소요 시간 및 다음 단계 안내

## startup_script vs Ansible 역할 분담

### 🔧 **startup_script 사용 범위 (최소화)**
- **WireGuard VPN 설정**: 인프라 레벨 네트워크 설정
- **기본 OS 설정**: 필수 시스템 초기화

```terraform
# jumpbox만 startup_script 사용
module "jumpbox" {
  startup_script = module.wireguard.startup_script
}

# 다른 VM들은 startup_script 제거
module "backend" {
  # startup_script 없음 - Ansible로 관리
}
```

### 🚀 **Ansible 사용 범위 (권장)**
- **애플리케이션 배포**: Docker 컨테이너, 서비스 설정
- **설정 관리**: 환경변수, 설정 파일
- **운영 작업**: 백업, 모니터링, 로그 관리

```yaml
# 단계별 Ansible 역할
- base_system    # Docker, 기본 패키지
- database       # MySQL 설정
- backend        # Spring Boot 애플리케이션
- ai             # Python AI 서비스
- nginx          # 웹서버 설정
```

## 장점

### 1. **명확한 역할 분담**
- Terraform: 인프라 생명주기 관리
- Ansible: 애플리케이션 설정 관리

### 2. **문제 해결 용이성**
- startup_script 실패 → VM 재생성 필요
- Ansible 실패 → 해당 태스크만 재실행

### 3. **환경별 관리**
```bash
# 환경별 독립적 배포
./scripts/deploy.sh dev     # 개발환경
./scripts/deploy.sh test    # 테스트환경  
./scripts/deploy.sh prod    # 프로덕션환경
```

### 4. **선택적 배포**
```bash
# 데이터베이스만 재설정
ansible-playbook playbooks/site.yml --tags database

# 백엔드 애플리케이션만 업데이트
ansible-playbook playbooks/site.yml --tags backend
```

## 문제 해결

### Terraform 관련
```bash
# 상태 확인
terraform show

# 특정 리소스 재생성
terraform taint module.backend.google_compute_instance.vm
terraform apply

# 인프라 완전 삭제
terraform destroy
```

### Ansible 관련
```bash
# 연결 테스트
ansible all -m ping

# 특정 서버만 설정
ansible backend -m shell -a "systemctl status docker"

# 특정 역할만 실행
ansible-playbook playbooks/site.yml --tags base --limit backend
```

## 모니터링 및 로그

### 배포 로그 확인
```bash
# Docker 서비스 로그
ansible all -m shell -a "journalctl -u docker --since today"

# 애플리케이션 로그
ansible backend -m shell -a "docker logs backend-app"
```

### 시스템 상태 확인
```bash
# 모든 서버 시스템 정보
ansible all -m setup

# 디스크 사용량
ansible all -m shell -a "df -h"

# 메모리 사용량
ansible all -m shell -a "free -h"
```

이 워크플로우를 통해 안정적이고 예측 가능한 인프라 배포를 달성할 수 있습니다.
