#!/bin/bash
# ========================================
# Terraform Bootstrap 스크립트
# GCS 백엔드 및 KMS 암호화 설정
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

# 프로젝트 루트 설정
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BOOTSTRAP_DIR="$PROJECT_ROOT/terraform/bootstrap"

log "🚀 Terraform Bootstrap 시작"

# Bootstrap 디렉토리 확인
if [[ ! -d "$BOOTSTRAP_DIR" ]]; then
    error "Bootstrap 디렉토리를 찾을 수 없습니다: $BOOTSTRAP_DIR"
fi

cd "$BOOTSTRAP_DIR"

# GCP 인증 확인
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
    warn "GCP 인증이 필요합니다."
    echo "다음 명령어로 인증하세요:"
    echo "gcloud auth login"
    echo "gcloud auth application-default login"
    exit 1
fi

# 프로젝트 설정 확인
PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
if [[ -z "$PROJECT_ID" ]]; then
    error "GCP 프로젝트가 설정되지 않았습니다. 'gcloud config set project PROJECT_ID' 실행하세요."
fi

log "📋 사용 중인 GCP 프로젝트: $PROJECT_ID"

# Terraform 초기화
log "🔧 Terraform 초기화 중..."
terraform init

# Terraform 계획 및 적용
log "📝 Terraform 계획 확인 중..."
terraform plan -var="project_id=$PROJECT_ID"

read -p "계속하시겠습니까? (y/N): " -r
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log "작업이 취소되었습니다."
    exit 0
fi

log "🚀 Bootstrap 리소스 생성 중..."
terraform apply -var="project_id=$PROJECT_ID" -auto-approve

# 출력 정보 표시
log "✅ Bootstrap 완료!"
echo ""
echo "🔧 생성된 리소스:"
terraform output

# 백엔드 설정 파일 생성
BUCKET_NAME=$(terraform output -raw terraform_state_bucket)

log "📄 환경별 백엔드 설정 업데이트 중..."

# 각 환경의 backend.tf 업데이트
for env in dev test prod; do
    BACKEND_FILE="$PROJECT_ROOT/terraform/environments/$env/backend.tf"
    if [[ -f "$BACKEND_FILE" ]]; then
        cat > "$BACKEND_FILE" << EOF
# ========================================
# Terraform Backend Configuration
# 자동 생성됨 - 수정하지 마세요
# ========================================

terraform {
  backend "gcs" {
    bucket = "$BUCKET_NAME"
    prefix = "environments/$env"
  }
}
EOF
        log "✅ $env 환경 백엔드 설정 완료"
    fi
done

log "🎉 모든 Bootstrap 작업이 완료되었습니다!"
echo ""
echo "💡 다음 단계:"
echo "  1. 각 환경에서 'terraform init' 실행"
echo "  2. 'terraform plan' 및 'terraform apply' 실행"