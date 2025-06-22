#!/bin/bash

# setup-new-user.sh - 신규 사용자 환경 설정 스크립트
# 사용법: ./scripts/setup-new-user.sh

set -e  # 오류 발생 시 스크립트 중단

echo "🚀 신규 사용자 환경 설정을 시작합니다..."
echo "======================================================="

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 1. SSH 키 확인
print_status "1. SSH 키 확인 중..."
if [ ! -f ~/.ssh/lsh-study-key ]; then
    print_error "SSH 키가 없습니다!"
    echo "다음 명령으로 SSH 키를 생성하세요:"
    echo "ssh-keygen -t rsa -b 4096 -C 'your-email@example.com' -f ~/.ssh/lsh-study-key"
    echo "생성 후 ~/.ssh/lsh-study-key.pub 내용을 GCP Console > Compute Engine > Metadata > SSH Keys에 등록하세요."
    exit 1
else
    print_success "SSH 키 확인됨: ~/.ssh/lsh-study-key"
fi

# SSH 키 권한 확인
if [ "$(stat -f %A ~/.ssh/lsh-study-key)" != "600" ]; then
    print_warning "SSH 키 권한 수정 중..."
    chmod 600 ~/.ssh/lsh-study-key
    chmod 644 ~/.ssh/lsh-study-key.pub 2>/dev/null || true
fi

# 2. 필수 도구 확인
print_status "2. 필수 도구 확인 중..."

check_command() {
    if command -v $1 >/dev/null 2>&1; then
        print_success "$1 설치됨 ($(command -v $1))"
        return 0
    else
        print_error "$1이 설치되지 않음"
        return 1
    fi
}

MISSING_TOOLS=()

check_command "terraform" || MISSING_TOOLS+=("terraform")
check_command "ansible" || MISSING_TOOLS+=("ansible")
check_command "jq" || MISSING_TOOLS+=("jq")
check_command "curl" || MISSING_TOOLS+=("curl")

if [ ${#MISSING_TOOLS[@]} -gt 0 ]; then
    print_error "다음 도구들을 설치해주세요:"
    printf '%s\n' "${MISSING_TOOLS[@]}"
    echo ""
    echo "macOS에서 설치 명령:"
    echo "brew install terraform ansible jq curl"
    exit 1
fi

# 3. Ansible Vault 패스워드 확인
print_status "3. Ansible Vault 패스워드 확인 중..."
if [ ! -f ~/.ansible_vault_pass ]; then
    print_error "Ansible vault 패스워드 파일이 없습니다!"
    echo "다음 명령으로 생성하세요:"
    echo "echo 'your-vault-password' > ~/.ansible_vault_pass"
    echo "chmod 600 ~/.ansible_vault_pass"
    echo ""
    echo "관리자에게 현재 vault 패스워드를 문의하세요."
    exit 1
else
    print_success "Ansible vault 패스워드 파일 확인됨"
    if [ "$(stat -f %A ~/.ansible_vault_pass)" != "600" ]; then
        chmod 600 ~/.ansible_vault_pass
        print_warning "Vault 패스워드 파일 권한 수정됨 (600)"
    fi
fi

# 4. GCP 서비스 계정 키 확인
print_status "4. GCP 서비스 계정 키 확인 중..."
if [ -z "$GOOGLE_APPLICATION_CREDENTIALS" ]; then
    print_error "GCP 서비스 계정 키가 설정되지 않았습니다!"
    echo "다음 단계를 수행하세요:"
    echo "1. 관리자에게 서비스 계정 키 JSON 파일 요청"
    echo "2. mkdir -p ~/.gcp"
    echo "3. mv service-account-key.json ~/.gcp/terraform-key.json"
    echo "4. chmod 600 ~/.gcp/terraform-key.json"
    echo "5. echo 'export GOOGLE_APPLICATION_CREDENTIALS=~/.gcp/terraform-key.json' >> ~/.zshrc"
    echo "6. source ~/.zshrc"
    exit 1
elif [ ! -f "$GOOGLE_APPLICATION_CREDENTIALS" ]; then
    print_error "GCP 서비스 계정 키 파일이 존재하지 않습니다: $GOOGLE_APPLICATION_CREDENTIALS"
    exit 1
else
    print_success "GCP 서비스 계정 키 확인됨: $GOOGLE_APPLICATION_CREDENTIALS"
fi

# 5. WireGuard 연결 확인
print_status "5. WireGuard VPN 연결 확인 중..."
if ! ping -c 1 -W 3 10.0.0.2 >/dev/null 2>&1; then
    print_error "WireGuard VPN이 연결되지 않았습니다!"
    echo "다음 단계를 수행하세요:"
    echo "1. 관리자에게 개인 WireGuard 클라이언트 설정 파일 요청 (예: john-client.conf)"
    echo "2. brew install wireguard-tools (macOS)"
    echo "3. sudo wg-quick up /path/to/your-client.conf"
    echo "4. ping 10.0.0.2 로 연결 확인"
    exit 1
else
    print_success "WireGuard VPN 연결 확인됨 (10.0.0.2 접근 가능)"
fi

# 6. SSH Agent에 키 등록
print_status "6. SSH Agent에 키 등록 중..."
if ! ssh-add -l | grep -q "lsh-study-key"; then
    ssh-add ~/.ssh/lsh-study-key
    print_success "SSH 키가 SSH Agent에 등록됨"
else
    print_success "SSH 키가 이미 SSH Agent에 등록되어 있음"
fi

# 7. Terraform 초기화 테스트
print_status "7. Terraform 초기화 테스트 중..."
cd terraform/environments/test
if terraform init -input=false >/dev/null 2>&1; then
    print_success "Terraform 초기화 성공"
else
    print_error "Terraform 초기화 실패"
    echo "다음을 확인하세요:"
    echo "- GCP 서비스 계정 키 권한"
    echo "- 프로젝트 접근 권한"
    echo "- 네트워크 연결"
    exit 1
fi
cd - >/dev/null

# 8. Ansible 연결 테스트
print_status "8. Ansible 연결 테스트 중..."
cd ansible
if ansible -i test.ini all -m ping --vault-password-file ~/.ansible_vault_pass >/dev/null 2>&1; then
    print_success "Ansible 연결 테스트 성공"
else
    print_error "Ansible 연결 테스트 실패"
    echo "다음을 확인하세요:"
    echo "- WireGuard VPN 연결"
    echo "- SSH 키 GCP 등록"
    echo "- Ansible vault 패스워드"
    echo ""
    echo "상세 테스트를 위해 다음 명령을 실행하세요:"
    echo "ansible -i test.ini all -m ping --vault-password-file ~/.ansible_vault_pass -vvv"
    exit 1
fi
cd - >/dev/null

# 9. 환경 설정 파일 확인
print_status "9. 환경 설정 파일 확인 중..."
if [ ! -f "ansible/group_vars/test/all.yml" ]; then
    print_warning "Ansible 설정 파일이 없습니다."
    if [ -f "ansible/group_vars/test/all.yml.template" ]; then
        cp ansible/group_vars/test/all.yml.template ansible/group_vars/test/all.yml
        print_success "템플릿에서 설정 파일 생성됨"
        print_warning "ansible/group_vars/test/all.yml 파일을 개인 환경에 맞게 수정하세요."
    else
        print_error "템플릿 파일도 없습니다. 관리자에게 문의하세요."
    fi
else
    print_success "Ansible 설정 파일 확인됨"
fi

# 완료 메시지
echo ""
echo "======================================================="
print_success "🎉 모든 환경 설정이 완료되었습니다!"
echo ""
echo "이제 다음 명령으로 배포를 시작할 수 있습니다:"
echo ""
echo "  cd ansible"
echo "  ansible-playbook -i test.ini playbooks/main.yml"
echo ""
echo "전체 재배포가 필요한 경우:"
echo ""
echo "  # 1. 인프라 삭제"
echo "  cd terraform/environments/test"
echo "  terraform destroy"
echo ""
echo "  # 2. 인프라 재생성"
echo "  terraform apply"
echo ""
echo "  # 3. 서비스 배포"
echo "  cd ../../../ansible"
echo "  ansible-playbook -i test.ini playbooks/main.yml"
echo ""
print_success "행복한 배포되세요! 🚀"
