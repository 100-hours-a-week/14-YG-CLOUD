# 🔐 WireGuard 팀 키 관리

> **WireGuard VPN 클라이언트 키 및 설정 파일 관리**

## 📋 생성된 클라이언트 키

| 팀원 | VPN IP | 설정 파일 | 역할 |
|------|--------|-----------|------|
| admin | 10.8.0.10/32 | `admin-client.conf` | 시스템 관리자 |
| lucy | 10.8.0.20/32 | `lucy-client.conf` | Backend 개발자 |
| kane | 10.8.0.21/32 | `kane-client.conf` | Backend 개발자 |
| milo | 10.8.0.30/32 | `milo-client.conf` | AI 개발자 |
| tony | 10.8.0.31/32 | `tony-client.conf` | AI 개발자 |
| sally | 10.8.0.40/32 | `sally-client.conf` | 클라우드 엔지니어 |

## 🚀 사용법

### 클라이언트 배포
1. 각 팀원에게 개별 `.conf` 파일 전달
2. WireGuard 앱에서 설정 파일 임포트
3. VPN 연결 후 내부 서버 접근

### 연결 방법
```bash
# 설정 파일을 WireGuard 디렉토리에 복사
sudo cp admin-client.conf /etc/wireguard/wg0.conf
sudo chmod 600 /etc/wireguard/wg0.conf

# VPN 연결
sudo wg-quick up wg0

# 연결 상태 확인
sudo wg show
```

📚 **상세 가이드**: [deployment-guide.md](../docs/deployment-guide.md)
