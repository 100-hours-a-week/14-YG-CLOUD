# SSH 서비스 활성화 가이드 (IaC 준수)

## 개요
Infrastructure as Code 원칙에 따라 startup-script 대신 Ansible을 사용하여 SSH 서비스를 관리합니다.

## 단계별 진행

### 1. GCP 콘솔을 통한 초기 SSH 설정

각 VM에 대해 다음을 수행:

#### 대상 서버:
- `moongsan-test-database` (10.0.0.2)
- `moongsan-test-backend` (10.0.0.3)  
- `moongsan-test-ai` (10.0.0.4)

#### 설정 방법:
1. **GCP Console > Compute Engine > VM instances**
2. 각 VM의 **SSH** 버튼 클릭 (브라우저 SSH 사용)
3. 다음 명령어들을 순서대로 실행:

```bash
# SSH 서비스 설치 및 활성화
sudo apt update
sudo apt install -y openssh-server python3 python3-pip

# SSH 서비스 시작 및 자동 시작 설정
sudo systemctl enable ssh
sudo systemctl start ssh
sudo systemctl status ssh

# 방화벽에서 SSH 허용
sudo ufw allow ssh

# SSH 설정 확인
sudo ss -tlnp | grep :22
```

### 2. SSH 연결 테스트

초기 설정 완료 후:

```bash
# shared-jumpbox에서 각 서버로 연결 테스트
ssh -i ~/.ssh/lsh-study-key -o ProxyJump=lsh@34.22.110.81 ubuntu@10.0.0.2
ssh -i ~/.ssh/lsh-study-key -o ProxyJump=lsh@34.22.110.81 ubuntu@10.0.0.3
ssh -i ~/.ssh/lsh-study-key -o ProxyJump=lsh@34.22.110.81 ubuntu@10.0.0.4
```

### 3. Ansible을 통한 자동화된 설정

SSH 연결이 가능해지면:

```bash
# 전체 설정 적용
ansible-playbook -i inventories/test.ini playbooks/enable_ssh_service.yml

# 특정 서버만 설정
ansible-playbook -i inventories/test.ini playbooks/enable_ssh_service.yml --limit database

# 설정 확인만
ansible-playbook -i inventories/test.ini playbooks/enable_ssh_service.yml --tags verify
```

### 4. 다음 단계 (SSH 연결 확인 후)

1. **베이스 시스템 설정**: Docker, 기본 패키지 설치
2. **데이터베이스 배포**: MySQL 컨테이너 설정
3. **백엔드 배포**: Spring Boot 애플리케이션 배포  
4. **AI 서비스 배포**: FastAPI 애플리케이션 배포
5. **네트워크 테스트**: 3-tier 통신 검증

## IaC 원칙 준수사항

✅ **인프라 정의**: Terraform으로 VM, 네트워크, 방화벽 관리
✅ **애플리케이션 설정**: Ansible로 서비스 설정 및 배포 관리  
✅ **버전 관리**: 모든 설정 파일이 Git으로 관리됨
✅ **재현 가능**: 동일한 설정을 다른 환경에 적용 가능
✅ **선언적 설정**: 원하는 상태를 명시적으로 정의

## 현재 상태

- ✅ **인프라**: VM들이 올바른 IP로 생성됨 (10.0.0.2, 10.0.0.3, 10.0.0.4)
- ✅ **네트워크**: VPC peering 정상 작동 (ping 성공)
- ✅ **shared-jumpbox**: SSH 연결 가능 (34.22.110.81)
- ⏳ **SSH 서비스**: 각 VM에서 수동 활성화 필요
- ⏳ **애플리케이션**: SSH 연결 후 Ansible 배포 예정
