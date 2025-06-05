#!/bin/bash
# ========================================
# 14-YG-CLOUD 통합 배포 스크립트 (Terraform Native)
# 간소화된 스크립트로 Terraform 중심 배포
# ========================================

set -e

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# 사용법
usage() {
    cat << EOF
🚀 14-YG-CLOUD 통합 배포 스크립트

사용법: $0 <environment> [options]

환경:
  dev     - 개발 환경 (기존 단일 VM)
  test    - 테스트 환경 (3-Tier 아키텍처)
  prod    - 프로덕션 환경

옵션:
  --terraform-only    Terraform만 실행
  --ansible-only      Ansible만 실행
  --skip-frontend     Frontend 배포 건너뛰기
  --cleanup           리소스 정리
  --help             도움말 표시

예시:
  $0 test                    # 전체 배포
  $0 test --terraform-only   # 인프라만
  $0 test --ansible-only     # 앱만
  $0 test --cleanup          # 정리
EOF
}

# 매개변수 확인
if [[ $# -eq 0 ]] || [[ "$1" == "--help" ]]; then
    usage
    exit 0
fi

ENV="$1"
shift

# 환경 유효성 검사
if [[ ! "$ENV" =~ ^(dev|test|prod)$ ]]; then
    error "잘못된 환경: $ENV"
fi

# 옵션 파싱
TERRAFORM_ONLY=false
ANSIBLE_ONLY=false
SKIP_FRONTEND=false
CLEANUP=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --terraform-only) TERRAFORM_ONLY=true; shift ;;
        --ansible-only) ANSIBLE_ONLY=true; shift ;;
        --skip-frontend) SKIP_FRONTEND=true; shift ;;
        --cleanup) CLEANUP=true; shift ;;
        *) error "알 수 없는 옵션: $1" ;;
    esac
done

# 경로 설정
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TERRAFORM_DIR="$PROJECT_ROOT/terraform/environments/$ENV"
ANSIBLE_DIR="$PROJECT_ROOT/ansible"

log "🚀 14-YG-CLOUD 배포 시작 - 환경: $ENV"

# ===========================================
# 사전 준비
# ===========================================

# WireGuard 키 생성 (test/prod만)
if [[ "$ENV" != "dev" ]] && [[ "$CLEANUP" == "false" ]]; then
    log "🔑 WireGuard 키 생성 중..."
    "$SCRIPT_DIR/generate-wireguard-keys.sh"
fi

# ===========================================
# Terraform 실행
# ===========================================

if [[ "$ANSIBLE_ONLY" == "false" ]]; then
    log "🏗️ Terraform 실행 중..."
    
    if [[ ! -d "$TERRAFORM_DIR" ]]; then
        error "Terraform 디렉토리 없음: $TERRAFORM_DIR"
    fi
    
    cd "$TERRAFORM_DIR"
    
    if [[ "$CLEANUP" == "true" ]]; then
        log "🧹 리소스 정리 중..."
        terraform destroy -auto-approve
        log "✅ 리소스 정리 완료"
        exit 0
    fi
    
    # Terraform 초기화 및 배포
    terraform init
    terraform plan
    
    read -p "계속하시겠습니까? (y/N): " -r
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log "배포가 취소되었습니다."
        exit 0
    fi
    
    terraform apply -auto-approve
    log "✅ Terraform 배포 완료"
    
    # 인프라 정보 출력
    echo ""
    log "📋 생성된 인프라 정보:"
    terraform output
fi

# ===========================================
# Ansible 실행
# ===========================================

if [[ "$TERRAFORM_ONLY" == "false" && "$CLEANUP" == "false" ]]; then
    log "⚙️ Ansible 설정 중..."
    
    cd "$ANSIBLE_DIR"
    
    # 인벤토리 파일 확인
    INVENTORY_FILE="inventory_${ENV}.ini"
    if [[ ! -f "$INVENTORY_FILE" ]]; then
        error "인벤토리 파일 없음: $INVENTORY_FILE"
    fi
    
    # Ansible 실행
    log "🔧 애플리케이션 배포 중..."
    ansible-playbook -i "$INVENTORY_FILE" playbooks/site.yml
    
    log "✅ Ansible 배포 완료"
fi

# ===========================================
# Frontend 배포 (test/prod만)
# ===========================================

if [[ "$ENV" != "dev" && "$SKIP_FRONTEND" == "false" && "$CLEANUP" == "false" ]]; then
    log "🌐 Frontend 배포 중..."
    "$SCRIPT_DIR/deploy-frontend.sh" "$ENV"
    log "✅ Frontend 배포 완료"
fi

# ===========================================
# 완료
# ===========================================

log "🎉 배포 완료!"
echo ""
log "📝 다음 단계:"
echo "  1. VPN 연결: WireGuard 클라이언트 설정"
echo "  2. 서비스 확인: 웹사이트 및 API 테스트"
echo "  3. 모니터링: Grafana 대시보드 확인"

# 변수 초기화
ENVIRONMENT=""
TERRAFORM_ONLY=false
ANSIBLE_ONLY=false
SKIP_VALIDATION=false

# 인자 파싱
while [[ $# -gt 0 ]]; do
    case $1 in
        dev|test|prod)
            ENVIRONMENT="$1"
            shift
            ;;
        --terraform-only)
            TERRAFORM_ONLY=true
            shift
            ;;
        --ansible-only)
            ANSIBLE_ONLY=true
            shift
            ;;
        --skip-validation)
            SKIP_VALIDATION=true
            shift
            ;;
        --help)
            usage
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# 환경 검증
if [[ -z "$ENVIRONMENT" ]]; then
    log_error "Environment must be specified"
    usage
    exit 1
fi

if [[ ! "$ENVIRONMENT" =~ ^(dev|test|prod)$ ]]; then
    log_error "Invalid environment: $ENVIRONMENT"
    usage
    exit 1
fi

# 프로젝트 루트 디렉토리 설정
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TERRAFORM_DIR="$PROJECT_ROOT/terraform/environments/$ENVIRONMENT"
ANSIBLE_DIR="$PROJECT_ROOT/ansible"

log_info "Starting deployment for environment: $ENVIRONMENT"
log_info "Project root: $PROJECT_ROOT"

# 1. Terraform 배포
deploy_terraform() {
    log_info "=== Terraform Deployment ==="
    
    if [[ ! -d "$TERRAFORM_DIR" ]]; then
        log_error "Terraform directory not found: $TERRAFORM_DIR"
        exit 1
    fi
    
    cd "$TERRAFORM_DIR"
    
    # Terraform 초기화
    log_info "Initializing Terraform..."
    terraform init
    
    # 검증 (선택적)
    if [[ "$SKIP_VALIDATION" != true ]]; then
        log_info "Validating Terraform configuration..."
        terraform validate
        log_success "Terraform validation passed"
    fi
    
    # 계획 확인
    log_info "Planning Terraform changes..."
    terraform plan -out=tfplan
    
    # 사용자 확인
    echo ""
    read -p "Do you want to apply these changes? (y/N): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_warning "Terraform deployment cancelled"
        return 1
    fi
    
    # 적용
    log_info "Applying Terraform changes..."
    terraform apply tfplan
    log_success "Terraform deployment completed"
    
    # 출력 값 저장 (Ansible에서 사용)
    log_info "Saving Terraform outputs..."
    terraform output -json > "$ANSIBLE_DIR/terraform_outputs.json"
    log_success "Terraform outputs saved to ansible/terraform_outputs.json"
}

# 2. Ansible 설정
deploy_ansible() {
    log_info "=== Ansible Configuration ==="
    
    if [[ ! -d "$ANSIBLE_DIR" ]]; then
        log_error "Ansible directory not found: $ANSIBLE_DIR"
        exit 1
    fi
    
    cd "$ANSIBLE_DIR"
    
    # 인벤토리 파일 확인
    if [[ ! -f "inventory.ini" ]]; then
        log_error "Ansible inventory file not found: inventory.ini"
        log_info "Please create inventory file with your server IPs"
        exit 1
    fi
    
    # 연결 테스트
    log_info "Testing Ansible connectivity..."
    if ansible all -m ping; then
        log_success "Ansible connectivity test passed"
    else
        log_warning "Some hosts may not be reachable. Continuing anyway..."
    fi
    
    # 플레이북 실행
    log_info "Running Ansible playbook..."
    echo ""
    log_info "Available tags:"
    log_info "  base        - Base system setup"
    log_info "  common      - Common configurations"
    log_info "  database    - Database setup"
    log_info "  backend     - Backend application"
    log_info "  ai          - AI service"
    log_info "  nginx       - Nginx configuration"
    log_info "  monitoring  - Monitoring setup"
    echo ""
    
    read -p "Enter tags to run (or press Enter for all): " TAGS
    
    if [[ -n "$TAGS" ]]; then
        ansible-playbook playbooks/site.yml --tags "$TAGS"
    else
        ansible-playbook playbooks/site.yml
    fi
    
    log_success "Ansible configuration completed"
}

# 3. 배포 검증
verify_deployment() {
    log_info "=== Deployment Verification ==="
    
    cd "$ANSIBLE_DIR"
    
    # 기본 서비스 상태 확인
    log_info "Checking service status..."
    ansible all -m shell -a "systemctl is-active docker" || true
    
    # 네트워크 연결 확인
    log_info "Checking network connectivity..."
    ansible all -m ping || true
    
    log_success "Deployment verification completed"
}

# 메인 배포 로직
main() {
    # 배포 시작 시간 기록
    START_TIME=$(date +%s)
    
    if [[ "$ANSIBLE_ONLY" == true ]]; then
        deploy_ansible
        verify_deployment
    elif [[ "$TERRAFORM_ONLY" == true ]]; then
        deploy_terraform
    else
        # 전체 배포: Terraform → Ansible → 검증
        deploy_terraform
        
        # Terraform이 성공했으면 Ansible 실행 여부 확인
        echo ""
        read -p "Terraform deployment successful. Continue with Ansible? (Y/n): " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Nn]$ ]]; then
            log_warning "Ansible deployment skipped"
            exit 0
        fi
        
        deploy_ansible
        verify_deployment
    fi
    
    # 배포 완료 시간 계산
    END_TIME=$(date +%s)
    DURATION=$((END_TIME - START_TIME))
    
    echo ""
    log_success "🎉 Deployment completed successfully!"
    log_info "Environment: $ENVIRONMENT"
    log_info "Duration: ${DURATION} seconds"
    echo ""
    log_info "Next steps:"
    log_info "1. Check service status: ansible all -m shell -a 'systemctl status docker'"
    log_info "2. View logs: ansible all -m shell -a 'journalctl -u docker --since today'"
    log_info "3. Access services through WireGuard VPN"
}

# 스크립트 실행
main
