# 🔒 보안 및 Git 관리 가이드

## 🚨 중요: 절대 커밋하면 안 되는 파일들

### 🔑 민감한 정보가 포함된 파일들
```bash
# Terraform 변수 파일
*.tfvars
terraform.tfvars

# GCP 서비스 계정 키
*.json (패키지 파일 제외)
service-account*.json

# SSH 키
*.pem, *.key, id_rsa*, *.pub

# WireGuard 설정
*.conf, wireguard-keys/

# 환경 변수 파일
.env, .env.*

# Terraform 상태 파일
*.tfstate, *.tfstate.*
```

## ✅ .gitignore 설정 완료

현재 프로젝트의 .gitignore는 다음과 같은 민감한 정보들을 자동으로 제외합니다:

### 1. **Terraform 관련**
- ✅ 상태 파일 (tfstate)
- ✅ 변수 파일 (tfvars) 
- ✅ 모듈 캐시 (.terraform/)

### 2. **보안 관련**
- ✅ GCP 서비스 계정 키 (*.json)
- ✅ SSH 키 파일들
- ✅ WireGuard 키 및 설정
- ✅ Ansible Vault 패스워드

### 3. **환경 설정**
- ✅ 환경 변수 파일 (.env)
- ✅ 로그 파일들
- ✅ 임시 파일들

## 🔍 보안 체크리스트

### 커밋 전 확인사항
```bash
# 1. Git 상태 확인 (민감한 파일 포함 여부)
git status

# 2. 무시된 파일들 확인
git status --ignored

# 3. 스테이징된 파일들 내용 확인
git diff --cached

# 4. 민감한 정보 검색
grep -r "private_key\|secret\|password" . --exclude-dir=.git
```

### 실수로 커밋한 경우 대처법
```bash
# 1. 마지막 커밋에서 파일 제거
git rm --cached 파일명
git commit --amend

# 2. 히스토리에서 완전 제거 (주의!)
git filter-branch --force --index-filter \
  'git rm --cached --ignore-unmatch 파일명' \
  --prune-empty --tag-name-filter cat -- --all
```

## 📋 안전한 개발 워크플로우

### 1. **초기 설정**
```bash
# 1. 리포지토리 클론
git clone <repository-url>
cd 14-YG-CLOUD

# 2. 예제 파일 복사
cp terraform/environments/test/terraform.tfvars.example \
   terraform/environments/test/terraform.tfvars

# 3. WireGuard 키 생성
./scripts/generate-wireguard-keys.sh

# 4. 민감한 정보 입력
vim terraform/environments/test/terraform.tfvars
```

### 2. **개발 중**
```bash
# 커밋 전 보안 체크
git add .
git status
git diff --cached | grep -i "key\|secret\|password"

# 안전한 커밋
git commit -m "feat: 새로운 기능 추가"
```

### 3. **배포 시**
```bash
# 안전한 배포 (자동화 스크립트 사용)
./scripts/deploy.sh test

# 수동 배포 시 주의사항
cd terraform/environments/test
terraform plan  # 변경사항 확인
terraform apply  # 신중하게 적용
```

## 🛡️ 추가 보안 조치

### 1. **Git hooks 설정**
```bash
# pre-commit hook으로 민감한 정보 검사
cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash
if git diff --cached --name-only | xargs grep -l "private_key\|secret\|password" 2>/dev/null; then
    echo "❌ 민감한 정보가 포함된 파일을 커밋하려고 합니다!"
    echo "파일을 확인하고 민감한 정보를 제거하세요."
    exit 1
fi
EOF
chmod +x .git/hooks/pre-commit
```

### 2. **환경별 분리**
```bash
# 개발환경: 테스트 키 사용
# 프로덕션: 별도 보안 저장소에서 키 관리

# 예: GCP Secret Manager 사용
gcloud secrets create terraform-vars \
    --data-file=terraform.tfvars \
    --project=your-project
```

### 3. **정기 보안 점검**
```bash
# 1. Git 히스토리에서 민감한 정보 검색
git log -p | grep -i "private_key\|secret\|password"

# 2. 현재 워킹 디렉토리 검사
find . -type f -name "*.tf*" -exec grep -l "private_key\|secret" {} \;

# 3. 백업 파일 정리
find . -name "*.backup" -o -name "*~" -delete
```

## 🚨 보안 사고 대응

### 민감한 정보 유출 시
1. **즉시 조치**
   - 해당 키/시크릿 무효화
   - 새로운 키 생성
   - Git 히스토리에서 제거

2. **예방 조치**
   - .gitignore 규칙 강화
   - pre-commit hook 설정
   - 팀원 교육

3. **모니터링**
   - GitHub secret scanning 활성화
   - 정기적인 보안 점검

## 📚 참고 자료

- [GitHub Secret Scanning](https://docs.github.com/en/code-security/secret-scanning)
- [Git Security Best Practices](https://git-scm.com/book/en/v2/Git-Tools-Credential-Storage)
- [Terraform Security Best Practices](https://www.terraform.io/docs/cloud/guides/recommended-practices/part1.html)

---

**⚠️ 주의**: 이 가이드를 팀원들과 공유하고, 모든 개발자가 보안 규칙을 준수하도록 교육하세요.
