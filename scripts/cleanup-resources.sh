#!/bin/bash
# ========================================
# 스크립트 없는 리소스 정리 도구
# 순수 Terraform 명령어 기반 정리
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

# 사용법
usage() {
    cat << EOF
🧹 14-YG-CLOUD 리소스 정리 도구 (Script-Free)

사용법: $0 <environment> [options]

환경:
  test    - 테스트 환경 정리
  dev     - 개발 환경 정리  
  prod    - 프로덕션 환경 정리

옵션:
  --bootstrap-only    Bootstrap 리소스만 정리
  --env-only         환경 리소스만 정리
  --force           확인 없이 강제 실행
  --dry-run         실제 삭제 없이 계획만 확인

예시:
  $0 test                    # 테스트 환경 전체 정리
  $0 test --env-only         # 환경 리소스만 정리
  $0 test --bootstrap-only   # Bootstrap만 정리
  $0 test --force           # 확인 없이 정리
  $0 test --dry-run         # 정리 계획만 확인

⚠️  주의: Bootstrap 정리 시 Terraform 상태가 완전히 손실됩니다!
EOF
    exit 1
}

# 환경 인수 확인
if [[ $# -eq 0 ]]; then
    usage
fi

ENV="$1"
BOOTSTRAP_ONLY=false
ENV_ONLY=false
FORCE=false
DRY_RUN=false

# 옵션 파싱
shift
while [[ $# -gt 0 ]]; do
    case $1 in
        --bootstrap-only)
            BOOTSTRAP_ONLY=true
            shift
            ;;
        --env-only)
            ENV_ONLY=true
            shift
            ;;
        --force)
            FORCE=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        *)
            error "알 수 없는 옵션: $1"
            ;;
    esac
done

# 환경 검증
if [[ ! "$ENV" =~ ^(test|dev|prod)$ ]]; then
    error "지원되지 않는 환경: $ENV (test, dev, prod만 지원)"
fi

# 환경 경로 설정
ENV_DIR="$PROJECT_ROOT/terraform/environments/$ENV"
BOOTSTRAP_DIR="$PROJECT_ROOT/terraform/bootstrap"

if [[ ! -d "$ENV_DIR" ]]; then
    error "환경 디렉토리를 찾을 수 없습니다: $ENV_DIR"
fi

# 정리 계획 표시
show_cleanup_plan() {
    echo ""
    echo "🗂️  정리 계획:"
    
    if [[ "$BOOTSTRAP_ONLY" == "true" ]]; then
        echo "   • Bootstrap 리소스 (GCS 백엔드, KMS 키)"
    elif [[ "$ENV_ONLY" == "true" ]]; then
        echo "   • 환경 리소스 ($ENV)"
    else
        echo "   • 환경 리소스 ($ENV)"
        echo "   • Bootstrap 리소스 (GCS 백엔드, KMS 키)"
    fi
    
    echo "   • 로컬 Terraform 상태 파일"
    echo "   • Terraform 캐시 디렉토리"
    echo ""
}

# Dry run 실행
run_dry_run() {
    log "🔍 Dry Run 모드: 실제 삭제 없이 계획만 확인합니다"
    
    if [[ "$ENV_ONLY" != "true" && "$BOOTSTRAP_ONLY" != "true" ]] || [[ "$ENV_ONLY" == "true" ]]; then
        log "📋 환경 리소스 정리 계획 확인 중..."
        cd "$ENV_DIR"
        if [[ -d ".terraform" ]]; then
            terraform plan -destroy
        else
            warn "환경이 초기화되지 않음: $ENV_DIR"
        fi
    fi
    
    if [[ "$ENV_ONLY" != "true" ]] && [[ -d "$BOOTSTRAP_DIR" ]]; then
        log "📋 Bootstrap 리소스 정리 계획 확인 중..."
        cd "$BOOTSTRAP_DIR"
        if [[ -d ".terraform" ]]; then
            terraform plan -destroy
        else
            warn "Bootstrap이 초기화되지 않음: $BOOTSTRAP_DIR"
        fi
    fi
    
    log "✅ Dry Run 완료. 실제 정리를 원하면 --dry-run 옵션을 제거하세요."
    exit 0
}

# 환경 리소스 정리
cleanup_environment() {
    log "🗑️  환경 리소스 정리 중: $ENV"
    
    cd "$ENV_DIR"
    
    if [[ ! -d ".terraform" ]]; then
        warn "환경이 초기화되지 않음. 건너뜀: $ENV"
        return
    fi
    
    log "Terraform destroy 실행 중..."
    terraform destroy -auto-approve
    
    log "✅ 환경 리소스 정리 완료: $ENV"
}

# Bootstrap 리소스 정리
cleanup_bootstrap() {
    log "🗑️  Bootstrap 리소스 정리 중..."
    
    if [[ ! -d "$BOOTSTRAP_DIR" ]]; then
        warn "Bootstrap 디렉토리가 없습니다: $BOOTSTRAP_DIR"
        return
    fi
    
    cd "$BOOTSTRAP_DIR"
    
    if [[ ! -d ".terraform" ]]; then
        warn "Bootstrap이 초기화되지 않음. 건너뜀."
        return
    fi
    
    log "prevent_destroy 보호 해제를 위해 삭제 허용 모드로 실행 중..."
    
    # prevent_destroy를 false로 설정하여 삭제 허용
    if terraform destroy -auto-approve -var="enable_deletion_protection=false"; then
        log "✅ Bootstrap 리소스 정리 완료"
    else
        error "Bootstrap 정리 실패. 수동으로 GCP 콘솔에서 확인하세요."
    fi
}

# 로컬 파일 정리
cleanup_local_files() {
    log "🧹 로컬 Terraform 파일 정리 중..."
    
    # Terraform 상태 파일 정리
    find "$PROJECT_ROOT/terraform" -name "*.tfstate*" -delete 2>/dev/null || true
    log "   • *.tfstate* 파일 삭제됨"
    
    # Terraform 락 파일 정리
    find "$PROJECT_ROOT/terraform" -name ".terraform.lock.hcl" -delete 2>/dev/null || true
    log "   • .terraform.lock.hcl 파일 삭제됨"
    
    # Terraform 캐시 디렉토리 정리
    find "$PROJECT_ROOT/terraform" -type d -name ".terraform" -exec rm -rf {} + 2>/dev/null || true
    log "   • .terraform/ 디렉토리 삭제됨"
    
    log "✅ 로컬 파일 정리 완료"
}

# 메인 실행
main() {
    log "🚀 14-YG-CLOUD 리소스 정리 시작"
    
    # 정리 계획 표시
    show_cleanup_plan
    
    # Dry run 체크
    if [[ "$DRY_RUN" == "true" ]]; then
        run_dry_run
    fi
    
    # 확인 프롬프트 (force 옵션이 아닌 경우)
    if [[ "$FORCE" != "true" ]]; then
        echo "⚠️  위의 리소스들이 완전히 삭제됩니다!"
        read -p "정말로 계속하시겠습니까? (yes/no): " -r
        if [[ "$REPLY" != "yes" ]]; then
            log "정리가 취소되었습니다."
            exit 0
        fi
    fi
    
    # 실행 단계
    if [[ "$BOOTSTRAP_ONLY" == "true" ]]; then
        cleanup_bootstrap
    elif [[ "$ENV_ONLY" == "true" ]]; then
        cleanup_environment
    else
        # 환경 → Bootstrap 순서로 정리
        cleanup_environment
        cleanup_bootstrap
    fi
    
    # 로컬 파일 정리
    cleanup_local_files
    
    log "🎉 모든 리소스 정리가 완료되었습니다!"
    echo ""
    log "💡 다시 배포하려면 Script-Free 가이드를 참조하세요:"
    log "   docs/script-free-deployment-guide.md"
}

# 실행
main
