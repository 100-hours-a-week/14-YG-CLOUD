#!/usr/bin/env bash
set -euo pipefail

# ------------------------------------------
# migrate_structure.sh
#
# 설명:
#   기존 dev(단일 인스턴스) 구조를 유지하며,
#   ansible, terraform, services, scripts, docs
#   디렉토리 및 기본 파일을 새 구조로 생성하고,
#   기존 파일을 dev 하위로 이동합니다.
#
# 사용법:
#   1. 이 파일을 프로젝트 루트(예: 14-YG-CLOUD/)에 복사
#   2. 실행 권한 부여: chmod +x migrate_structure.sh
#   3. ./migrate_structure.sh 실행
#
# 주의:
#   - 실행 전 반드시 git 커밋을 남겨두어, 문제가 발생했을 때 되돌릴 수 있도록 합니다.
#   - 기존 경로가 다르다면, 스크립트 내 mv 경로를 적절히 수정하세요.
# ------------------------------------------

ROOT_DIR="$(pwd)"

echo "=== 📂 1. 새로운 디렉토리 구조 생성 ==="
mkdir -p ansible/inventories/{dev,test,prod}/group_vars
mkdir -p ansible/roles/{common,frontend,backend,ai,db,redis,monitoring,wireguard}
mkdir -p ansible/playbooks

mkdir -p terraform/modules/{network,compute,rds,redis,security,monitoring}
mkdir -p terraform/envs/{dev,test,prod}
mkdir -p terraform/scripts

mkdir -p services/{frontend,backend,ai}
mkdir -p scripts docs

echo "생성된 디렉토리:"
find ansible terraform services scripts docs -maxdepth 2 -type d

echo -e "\n=== 📦 2. 기존 Ansible 파일을 dev 하위로 이동 ==="

# ansible/inventories/hosts → ansible/inventories/dev/hosts 로 이동
if [[ -f ansible/inventories/hosts ]]; then
  mv ansible/inventories/hosts ansible/inventories/dev/hosts
  echo "이동: ansible/inventories/hosts → ansible/inventories/dev/hosts"
else
  echo "주의: ansible/inventories/hosts 파일이 없습니다. (이미 이동되었거나 경로가 다릅니다)"
fi

# ansible/group_vars/all.yml → ansible/inventories/dev/group_vars/all.yml 로 이동
if [[ -f ansible/inventories/group_vars/all.yml ]]; then
  mv ansible/inventories/group_vars/all.yml ansible/inventories/dev/group_vars/all.yml
  echo "이동: ansible/inventories/group_vars/all.yml → ansible/inventories/dev/group_vars/all.yml"
else
  echo "주의: ansible/inventories/group_vars/all.yml 파일이 없습니다."
fi

# 기존 roles/ 디렉토리가 있다면, dev용 그대로 복사(또는 이동)
if [[ -d ansible/roles ]]; then
  # 이미 roles 디렉토리가 있으므로 별도 이동 없이 유지
  echo "설명: ansible/roles/ 디렉토리는 새 구조에도 그대로 사용됩니다."
else
  echo "주의: ansible/roles/ 디렉토리가 존재하지 않습니다."
fi

# site.yml 또는 기존 dev용 Playbook을 dev 아래로 이동
if [[ -f ansible/site.yml ]]; then
  mv ansible/site.yml ansible/playbooks/site_dev.yml
  echo "이동: ansible/site.yml → ansible/playbooks/site_dev.yml"
elif [[ -f ansible/playbooks/site.yml ]]; then
  mv ansible/playbooks/site.yml ansible/playbooks/site_dev.yml
  echo "이동: ansible/playbooks/site.yml → ansible/playbooks/site_dev.yml"
else
  echo "주의: 기존 dev용 Playbook(site.yml)이 발견되지 않았습니다."
fi

echo -e "\n=== 📦 3. 새로운 Ansible Playbook 템플릿 생성 ==="
cat > ansible/playbooks/site_test.yml << 'EOF'
---
- name: Test 환경 3-티어 배포
  hosts: all
  vars_files:
    - "../inventories/test/group_vars/all.yml"
  roles:
    - common
    - db
    - redis
    - backend
    - ai
    - frontend
EOF
echo "생성: ansible/playbooks/site_test.yml"

cat > ansible/playbooks/site_prod.yml << 'EOF'
---
- name: Prod 환경 3-티어 배포
  hosts: all
  vars_files:
    - "../inventories/prod/group_vars/all.yml"
  roles:
    - common
    - db
    - redis
    - backend
    - ai
    - frontend
EOF
echo "생성: ansible/playbooks/site_prod.yml"

echo -e "\n=== 🌱 4. Terraform 파일을 환경별(dev/test/prod)로 이동/분리 ==="

# 기존 terraform/*.tf → terraform/envs/dev/ 로 이동
shopt -s nullglob
TF_ROOT_FILES=(terraform/*.tf terraform/*.tfvars)
if (( ${#TF_ROOT_FILES[@]} )); then
  for f in "${TF_ROOT_FILES[@]}"; do
    mv "$f" terraform/envs/dev/
    echo "이동: $f → terraform/envs/dev/"
  done
else
  echo "주의: terraform 루트에 .tf, .tfvars 파일이 없습니다."
fi
shopt -u nullglob

# 기존 modules 디렉토리가 없다면 생성 안내
if [[ ! -d terraform/modules ]]; then
  echo "주의: terraform/modules/ 디렉토리가 없었습니다. 수동으로 모듈화를 진행하세요."
else
  echo "terraform/modules/ 디렉토리가 이미 존재합니다."
fi

# envs/dev/main.tf이 없으면 기본 템플릿 생성
if [[ ! -f terraform/envs/dev/main.tf ]]; then
  cat > terraform/envs/dev/main.tf << 'EOF'
# DEV 환경용 Terraform (기존 단일 인스턴스 정의 유지)
# 예시:
# resource "aws_instance" "dev_server" {
#   ami           = var.dev_ami
#   instance_type = var.dev_instance_type
#   # ... 나머지 설정 ...
# }
EOF
  echo "생성: terraform/envs/dev/main.tf (템플릿)"
fi

# envs/dev/variables.tf, terraform.tfvars, outputs.tf 템플릿 생성
for file in variables.tf terraform.tfvars outputs.tf; do
  target="terraform/envs/dev/$file"
  if [[ ! -f $target ]]; then
    touch "$target"
    echo "생성: $target"
  fi
done

# test/prod 환경 폴더에 템플릿 파일 생성
for env in test prod; do
  base="terraform/envs/$env"
  for name in main.tf variables.tf terraform.tfvars outputs.tf; do
    target="$base/$name"
    if [[ -f $target ]]; then
      echo "이미 존재: $target"
    else
      cat > "$target" << EOF
# $env 환경용 Terraform 템플릿
# TODO: modules를 호출하여 3-티어 아키텍처 정의
# 예시:
# module "network" {
#   source = "../../modules/network"
#   # ...
# }
EOF
      echo "생성: $target"
    fi
  done
done

echo -e "\n=== 📦 5. 서비스 코드 디렉토리 구조 생성 ==="
# services 폴더에 README 등 초기 파일 생성
for svc in frontend backend ai; do
  svc_dir="services/$svc"
  if [[ ! -d $svc_dir ]]; then
    mkdir -p "$svc_dir"
    echo "생성: $svc_dir/"
  fi
  # Dockerfile 템플릿 생성 (파일이 없을 때만)
  df="$svc_dir/Dockerfile"
  if [[ ! -f $df ]]; then
    cat > "$df" << EOF
# $svc 서비스용 Dockerfile
# TODO: 실제 언어/프레임워크 (React/Spring/FastAPI) 빌드/실행 명령어 작성
EOF
    echo "생성: $df"
  fi
  # 기본 README
  rm="$(ls $svc_dir/README.md 2>/dev/null || true)"
  if [[ -z "$rm" ]]; then
    cat > "$svc_dir/README.md" << EOF
# $svc 서비스

이 디렉토리에는 $svc 서비스 코드와 Dockerfile이 위치합니다.
- Dockerfile: $svc 이미지를 빌드하기 위한 설정
- src/ (또는 해당 서비스 코드 디렉토리)

EOF
    echo "생성: $svc_dir/README.md"
  fi
done

echo -e "\n=== 📦 6. scripts/ 및 docs/ 기본 파일 생성 ==="
if [[ ! -f scripts/migrate_3tier.sh ]]; then
  cat > scripts/migrate_3tier.sh << 'EOF'
#!/usr/bin/env bash
# 예시: 3-티어 마이그레이션 시 사용할 스크립트 템플릿
echo "이곳에 3-티어 이전 작업을 위한 추가 스크립트를 작성하세요."
EOF
  chmod +x scripts/migrate_3tier.sh
  echo "생성: scripts/migrate_3tier.sh"
fi

if [[ ! -f docs/architecture.md ]]; then
  cat > docs/architecture.md << EOF
# 3-티어 아키텍처 다이어그램 & 설명

(여기에 mermaid 또는 다이어그램 설명을 작성하세요)
EOF
  echo "생성: docs/architecture.md"
fi

if [[ ! -f docs/ansible_guide.md ]]; then
  cat > docs/ansible_guide.md << EOF
# Ansible 가이드

## 디렉토리 구조

- inventories/dev
- inventories/test
- inventories/prod

## 사용법

- Dev: ansible-playbook -i inventories/dev/hosts playbooks/site_dev.yml
- Test: ansible-playbook -i inventories/test/hosts playbooks/site_test.yml
- Prod: ansible-playbook -i inventories/prod/hosts playbooks/site_prod.yml
EOF
  echo "생성: docs/ansible_guide.md"
fi

if [[ ! -f docs/terraform_guide.md ]]; then
  cat > docs/terraform_guide.md << EOF
# Terraform 가이드

## 디렉토리 구조

- envs/dev
- envs/test
- envs/prod
- modules/

## 사용법

- Dev: cd terraform/envs/dev && terraform init && terraform apply -var-file=terraform.tfvars
- Test: cd terraform/envs/test && terraform init && terraform apply -var-file=terraform.tfvars
- Prod: cd terraform/envs/prod && terraform init && terraform apply -var-file=terraform.tfvars
EOF
  echo "생성: docs/terraform_guide.md"
fi

echo -e "\n=== ✅ 완료: 디렉토리 구조 리팩토링 및 파일 이동이 완료되었습니다! ==="
echo "이제 Git 상태를 확인한 뒤, 필요하다면 새로 생성된 플레이북/모듈/서비스 코드 템플릿을 채워 주세요."