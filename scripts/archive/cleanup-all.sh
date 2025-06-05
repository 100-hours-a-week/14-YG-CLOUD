#!/bin/bash
# ========================================
# 완전한 리소스 정리 스크립트
# 모든 Terraform 리소스를 순서대로 제거
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

# 스크립트 디렉토리 설정
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# 환경 인수 확인
if [[ $# -eq 0 ]]; then
    error "사용법: $0 <environment> [--force]"
fi

ENV="$1"
FORCE=false

if [[ "$2" == "--force" ]]; then
    FORCE=true
fi

# 경고 메시지
warn "⚠️  이 스크립트는 다음을 완전히 제거합니다:"
echo "   • 환경 리소스 ($ENV)"
echo "   • Bootstrap 리소스 (GCS 백엔드, KMS 키)"
echo "   • 모든 Terraform 상태 파일"
echo ""

if [[ "$FORCE" != "true" ]]; then
    read -p "정말로 계속하시겠습니까? (yes/no): " -r
    if [[ "$REPLY" != "yes" ]]; then
        log "정리가 취소되었습니다."
        exit 0
    fi
fi

# 1단계: 환경 리소스 정리
log "🗑️  1단계: 환경 리소스 정리 중..."
"$SCRIPT_DIR/deploy.sh" "$ENV" --cleanup

# 2단계: Bootstrap 리소스 정리
log "🗑️  2단계: Bootstrap 리소스 정리 중..."
cd "$PROJECT_ROOT/terraform/bootstrap"

if [[ -d ".terraform" ]]; then
    terraform destroy -auto-approve
    log "✅ Bootstrap 리소스 제거 완료"
else
    warn "Bootstrap이 초기화되지 않음. 건너뜀."
fi

# 3단계: 로컬 상태 파일 정리
log "🧹 3단계: 로컬 상태 파일 정리 중..."
find "$PROJECT_ROOT/terraform" -name "*.tfstate*" -delete 2>/dev/null || true
find "$PROJECT_ROOT/terraform" -name ".terraform.lock.hcl" -delete 2>/dev/null || true
find "$PROJECT_ROOT/terraform" -type d -name ".terraform" -exec rm -rf {} + 2>/dev/null || true

log "✅ 모든 리소스가 정리되었습니다!"
log "💡 다시 배포하려면: ./scripts/bootstrap.sh $ENV && ./scripts/deploy.sh $ENV"
