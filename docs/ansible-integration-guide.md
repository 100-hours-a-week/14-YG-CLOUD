# 🔄 통합된 Ansible 배포 가이드

## 📋 통합 완료 사항

### ✅ **Before (분리된 관리)**
```bash
# Dev 배포 (GitHub 레포)
cd /Users/lsh/Documents/GitHub/14-YG-CLOUD/ansible
ansible-playbook -i inventory.ini playbook.yml --limit dev --tags fe

# Prod 배포 (현재 레포)
cd /Users/lsh/Documents/local/3tier-moongsan/14-YG-CLOUD/ansible
ansible-playbook -i prod.ini playbooks/main.yml --tags be
```

### ✅ **After (통합 관리)**
```bash
# 모든 환경을 하나의 위치에서 관리
cd /Users/lsh/Documents/local/3tier-moongsan/14-YG-CLOUD/ansible

# Dev 환경 배포 (단일 서버)
ansible-playbook -i dev.ini playbooks/main.yml --tags dev,fe
ansible-playbook -i dev.ini playbooks/main.yml --tags dev,be
ansible-playbook -i dev.ini playbooks/main.yml --tags dev,ai

# Test 환경 배포 (3-Tier)
ansible-playbook -i test.ini playbooks/main.yml --tags be
ansible-playbook -i test.ini playbooks/main.yml --tags ai
ansible-playbook -i test.ini playbooks/main.yml --tags frontend

# Prod 환경 배포 (3-Tier)
ansible-playbook -i prod.ini playbooks/main.yml --tags be
ansible-playbook -i prod.ini playbooks/main.yml --tags ai
ansible-playbook -i prod.ini playbooks/main.yml --tags frontend
```

## 🎯 **환경별 특징**

### **Dev 환경 (단일 서버)**
- **호스트**: `dev.moongsan.com`
- **구조**: 모든 서비스가 하나의 서버에서 실행
- **태그**: `dev` + 서비스별 태그 (`be`, `fe`, `ai`, etc.)
- **용도**: 개발 및 테스트

### **Test 환경 (3-Tier)**
- **호스트**: 여러 서버 (backend, ai, database, jumpbox)
- **구조**: 서비스별 분리된 서버
- **태그**: 서비스별 태그만 사용
- **용도**: 통합 테스트

### **Prod 환경 (3-Tier)**
- **호스트**: 여러 서버 (backend, ai, database, jumpbox)
- **구조**: 서비스별 분리된 서버
- **태그**: 서비스별 태그만 사용
- **용도**: 운영 서비스

## 🔧 **주요 명령어 예시**

### **전체 환경 배포**
```bash
# Dev 전체 배포
ansible-playbook -i dev.ini playbooks/main.yml --tags dev

# Test 전체 배포  
ansible-playbook -i test.ini playbooks/main.yml

# Prod 전체 배포
ansible-playbook -i prod.ini playbooks/main.yml
```

### **선택적 서비스 배포**
```bash
# Dev 환경 Backend만
ansible-playbook -i dev.ini playbooks/main.yml --tags dev,be

# Test 환경 Frontend만
ansible-playbook -i test.ini playbooks/main.yml --tags frontend

# Prod 환경 Backend만
ansible-playbook -i prod.ini playbooks/main.yml --tags be_deploy
```

### **Jenkins CI/CD 통합**
```bash
# Jenkins에서 Dev 환경 Backend 배포
ansible-playbook -i dev.ini playbooks/jenkins_be_deploy.yml \
  -e docker_image_tag=123 \
  -e target_env=dev
```

## 🎉 **이점**

1. **일관된 명령어**: 모든 환경에서 동일한 패턴 사용
2. **통합 관리**: 하나의 레포지토리에서 모든 환경 관리
3. **환경별 최적화**: dev(단일), test/prod(3-tier) 각각 최적화
4. **CI/CD 호환**: Jenkins 파이프라인과 완벽 통합
5. **유지보수성**: 코드 중복 제거 및 일관성 확보

## ⚠️ **마이그레이션 주의사항**

- GitHub 버전의 `inventory.ini`와 `playbook.yml`은 더 이상 사용하지 않음
- 모든 배포는 이제 `main.yml`로 통합
- Dev 환경만 `dev` 태그 필수, 나머지는 기존대로 사용
