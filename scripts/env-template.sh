# 신규 사용자 환경변수 설정 템플릿
# 이 파일을 복사하여 ~/.bashrc 또는 ~/.zshrc에 추가하세요

# ========================================
# 필수 환경변수
# ========================================

# GCP 서비스 계정 키 (Terraform용)
export GOOGLE_APPLICATION_CREDENTIALS="$HOME/.gcp/terraform-key.json"

# GCP 프로젝트 설정
export GOOGLE_PROJECT="your-gcp-project-id"
export GOOGLE_REGION="asia-northeast3"
export GOOGLE_ZONE="asia-northeast3-a"

# Ansible Vault 패스워드 파일 경로
export ANSIBLE_VAULT_PASSWORD_FILE="$HOME/.ansible_vault_pass"

# SSH 키 경로
export SSH_KEY_PATH="$HOME/.ssh/lsh-study-key"

# ========================================
# 선택적 환경변수
# ========================================

# Terraform 로그 레벨 (디버깅용)
# export TF_LOG=INFO
# export TF_LOG_PATH="$HOME/terraform.log"

# Ansible 로그 설정
# export ANSIBLE_LOG_PATH="$HOME/ansible.log"
# export ANSIBLE_DEBUG=1

# Docker 설정 (필요한 경우)
# export DOCKER_HOST="tcp://localhost:2376"

# ========================================
# 프로젝트별 별칭 (선택사항)
# ========================================

# 프로젝트 디렉토리로 빠르게 이동
alias cdcloud="cd $HOME/Documents/local/3tier-moongsan/14-YG-CLOUD"

# Terraform 명령어 별칭
alias tf="terraform"
alias tfi="terraform init"
alias tfp="terraform plan"
alias tfa="terraform apply"
alias tfd="terraform destroy"

# Ansible 명령어 별칭 (test 환경)
alias ap="ansible-playbook -i test.ini"
alias aping="ansible -i test.ini all -m ping"

# SSH 연결 별칭
alias sshjump="ssh -i ~/.ssh/lsh-study-key lsh@34.22.110.81"

# WireGuard 별칭
alias wgup="sudo wg-quick up"
alias wgdown="sudo wg-quick down"
alias wgstatus="sudo wg show"

# ========================================
# 유용한 함수들
# ========================================

# Ansible 상태 확인 함수
check_ansible() {
    echo "🔍 Ansible 연결 상태 확인 중..."
    cd ~/Documents/local/3tier-moongsan/14-YG-CLOUD/ansible
    ansible -i test.ini all -m ping
    cd - > /dev/null
}

# Terraform 상태 확인 함수
check_terraform() {
    echo "🔍 Terraform 상태 확인 중..."
    cd ~/Documents/local/3tier-moongsan/14-YG-CLOUD/terraform/environments/test
    terraform plan
    cd - > /dev/null
}

# 전체 서비스 상태 확인 함수
check_services() {
    echo "🔍 전체 서비스 상태 확인 중..."
    cd ~/Documents/local/3tier-moongsan/14-YG-CLOUD/ansible
    ansible -i test.ini all -m shell -a "docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'"
    cd - > /dev/null
}

# VPN 연결 확인 함수
check_vpn() {
    echo "🔍 VPN 연결 상태 확인 중..."
    if ping -c 3 10.0.0.2 >/dev/null 2>&1; then
        echo "✅ VPN 연결 정상 (database 서버 접근 가능)"
    else
        echo "❌ VPN 연결 실패 (WireGuard 설정 확인 필요)"
    fi
}

# ========================================
# 초기 설정 안내
# ========================================

# 이 설정을 적용하려면:
# 1. 이 파일의 내용을 ~/.zshrc (또는 ~/.bashrc)에 추가
# 2. source ~/.zshrc 실행
# 3. 각 환경변수를 개인 환경에 맞게 수정

# 예시:
# echo '# 3-Tier Cloud 프로젝트 설정' >> ~/.zshrc
# cat env-template.sh >> ~/.zshrc
# source ~/.zshrc
