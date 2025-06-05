#!/bin/bash
# ========================================
# 14-YG-CLOUD Bootstrap 스크립트
# 초기 설정 및 WireGuard 키 생성
# ========================================

set -e

# 색상 설정
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

ENV=${1:-test}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

log "🚀 14-YG-CLOUD Bootstrap 시작 - 환경: $ENV"

# ===========================================
# 1. Terraform Backend 설정
# ===========================================

log "🔧 Terraform Backend 설정 중..."
if [[ ! -f "$SCRIPT_DIR/setup-terraform-backend.sh" ]]; then
    error "Backend 설정 스크립트를 찾을 수 없습니다."
fi

chmod +x "$SCRIPT_DIR/setup-terraform-backend.sh"
"$SCRIPT_DIR/setup-terraform-backend.sh"

# ===========================================
# 2. WireGuard 키 생성
# ===========================================

if [[ "$ENV" != "dev" ]]; then
    log "🔑 WireGuard 키 생성 중..."
    if [[ ! -f "$SCRIPT_DIR/generate-wireguard-keys.sh" ]]; then
        error "WireGuard 키 생성 스크립트를 찾을 수 없습니다."
    fi
    
    chmod +x "$SCRIPT_DIR/generate-wireguard-keys.sh"
    cd "$SCRIPT_DIR"
    ./generate-wireguard-keys.sh
fi

# ===========================================
# 3. 환경별 설정 파일 준비
# ===========================================

TERRAFORM_DIR="$PROJECT_ROOT/terraform/environments/$ENV"
if [[ ! -d "$TERRAFORM_DIR" ]]; then
    error "Terraform 환경 디렉토리를 찾을 수 없습니다: $TERRAFORM_DIR"
fi

cd "$TERRAFORM_DIR"

# terraform.tfvars 파일 확인
if [[ ! -f "terraform.tfvars" ]]; then
    if [[ -f "terraform.tfvars.example" ]]; then
        log "📄 terraform.tfvars 파일 생성 중..."
        cp terraform.tfvars.example terraform.tfvars
        warn "terraform.tfvars 파일이 생성되었습니다."
        warn "필요한 설정을 확인하고 수정해주세요."
    else
        error "terraform.tfvars.example 파일을 찾을 수 없습니다."
    fi
fi

# Terraform 초기화
log "🔧 Terraform 초기화 중..."
terraform init

# ===========================================
# 완료
# ===========================================

log "✅ Bootstrap 완료!"
echo ""
log "💡 다음 단계:"
echo "  1. terraform.tfvars 파일 검토 및 수정"
echo "  2. './scripts/deploy.sh $ENV' 실행하여 배포"
echo "  3. VPN 설정 및 서비스 확인"

# 5. Terraform 계획 확인
echo "📋 Terraform 계획 확인 중..."
terraform plan

# 6. 배포 확인
echo ""
echo "🤔 배포를 진행하시겠습니까? (y/N)"
read -r response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    echo "🚀 Terraform 배포 시작..."
    terraform apply
    
    echo ""
    echo "✅ 인프라 배포 완료!"
    echo ""
    echo "📝 다음 단계:"
    echo "1. Frontend 배포: $SCRIPT_DIR/deploy-frontend.sh $ENV"
    echo "2. Ansible 인벤토리 업데이트"
    echo "3. Backend/AI/Database 배포: ansible-playbook ..."
    echo ""
    echo "📊 배포된 리소스 정보:"
    terraform output
else
    echo "❌ 배포가 취소되었습니다."
    echo "수동으로 배포하려면: terraform apply"
fi
