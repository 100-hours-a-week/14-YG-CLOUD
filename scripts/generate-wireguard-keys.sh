#!/bin/bash
# WireGuard 키 생성 스크립트

set -e

echo "🔐 WireGuard 키 생성 시작..."

# WireGuard 설치 확인
if ! command -v wg &> /dev/null; then
    echo "WireGuard가 설치되어 있지 않습니다."
    echo "macOS에서 설치: brew install wireguard-tools"
    echo "Ubuntu에서 설치: sudo apt-get install wireguard-tools"
    exit 1
fi

# 키 디렉토리 생성 (프로젝트 루트의 wireguard-keys 사용)
KEYS_DIR="../wireguard-keys"
mkdir -p "$KEYS_DIR"

# 서버 키 생성
echo "📡 서버 키 생성 중..."
SERVER_PRIVATE_KEY=$(wg genkey)
SERVER_PUBLIC_KEY=$(echo "$SERVER_PRIVATE_KEY" | wg pubkey)

echo "Server Private Key: $SERVER_PRIVATE_KEY" > "$KEYS_DIR/server-keys.txt"
echo "Server Public Key: $SERVER_PUBLIC_KEY" >> "$KEYS_DIR/server-keys.txt"

# 클라이언트 키 생성
CLIENTS=("frontend" "backend" "ai" "database")
ADDRESSES=("10.8.0.10/32" "10.8.0.20/32" "10.8.0.30/32" "10.8.0.40/32")

echo "" > "$KEYS_DIR/client-keys.txt"

for i in "${!CLIENTS[@]}"; do
    CLIENT="${CLIENTS[$i]}"
    ADDRESS="${ADDRESSES[$i]}"
    
    echo "💻 $CLIENT 클라이언트 키 생성 중..."
    
    CLIENT_PRIVATE_KEY=$(wg genkey)
    CLIENT_PUBLIC_KEY=$(echo "$CLIENT_PRIVATE_KEY" | wg pubkey)
    
    echo "=== $CLIENT ===" >> "$KEYS_DIR/client-keys.txt"
    echo "Address: $ADDRESS" >> "$KEYS_DIR/client-keys.txt"
    echo "Private Key: $CLIENT_PRIVATE_KEY" >> "$KEYS_DIR/client-keys.txt"
    echo "Public Key: $CLIENT_PUBLIC_KEY" >> "$KEYS_DIR/client-keys.txt"
    echo "" >> "$KEYS_DIR/client-keys.txt"
done

# terraform.tfvars 예제 생성
cat > "$KEYS_DIR/terraform.tfvars.example" << EOF
# WireGuard 서버 설정
wireguard_private_key = "$SERVER_PRIVATE_KEY"
wireguard_public_key  = "$SERVER_PUBLIC_KEY"

# WireGuard 클라이언트 설정
wireguard_clients = [
EOF

for i in "${!CLIENTS[@]}"; do
    CLIENT="${CLIENTS[$i]}"
    ADDRESS="${ADDRESSES[$i]}"
    
    # 클라이언트 키 다시 생성 (파일에서 읽기)
    CLIENT_PRIVATE_KEY=$(wg genkey)
    CLIENT_PUBLIC_KEY=$(echo "$CLIENT_PRIVATE_KEY" | wg pubkey)
    
    cat >> "$KEYS_DIR/terraform.tfvars.example" << EOF
  {
    name        = "$CLIENT"
    address     = "$ADDRESS"
    private_key = "$CLIENT_PRIVATE_KEY"
    public_key  = "$CLIENT_PUBLIC_KEY"
  }$([ $i -lt $((${#CLIENTS[@]} - 1)) ] && echo "," || echo "")
EOF
done

echo "]" >> "$KEYS_DIR/terraform.tfvars.example"

echo ""
echo "✅ 키 생성 완료!"
echo "📁 생성된 파일들:"
echo "   - $KEYS_DIR/server-keys.txt"
echo "   - $KEYS_DIR/client-keys.txt"
echo "   - $KEYS_DIR/terraform.tfvars.example"
echo ""
echo "🔧 다음 단계:"
echo "1. terraform.tfvars.example을 terraform/environments/test/terraform.tfvars로 복사"
echo "2. 필요한 경우 키 값들을 수정"
echo "3. terraform apply 실행"
echo ""
echo "⚠️  보안 주의사항:"
echo "   - 생성된 키 파일들을 안전한 곳에 보관하세요"
echo "   - Private Key는 절대 공개 저장소에 올리지 마세요"
