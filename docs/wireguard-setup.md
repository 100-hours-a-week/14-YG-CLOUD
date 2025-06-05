# 🔐 WireGuard VPN 설정 가이드

> **작성일**: 2025년 6월 5일  
> **목적**: Test 환경 Private Network 접근을 위한 WireGuard VPN 설정  
> **적용 환경**: Test/Prod 환경의 보안 접근

## 📋 목차

1. [WireGuard 개요](#-wireguard-개요)
2. [네트워크 구성](#-네트워크-구성)
3. [서버 설정 (Jump Box)](#-서버-설정-jump-box)
4. [클라이언트 설정 (로컬)](#-클라이언트-설정-로컬)
5. [연결 및 테스트](#-연결-및-테스트)
6. [트러블슈팅](#-트러블슈팅)

---

## 🌐 WireGuard 개요

**WireGuard**는 현대적인 VPN 프로토콜로, 간단하고 빠르며 안전한 VPN 연결을 제공합니다.

### 주요 특징
- ✅ **빠른 성능**: 기존 VPN 대비 월등한 속도
- ✅ **간단한 설정**: 최소한의 설정으로 VPN 구성
- ✅ **강력한 암호화**: ChaCha20, Poly1305 암호화
- ✅ **크로스 플랫폼**: Linux, macOS, Windows, iOS, Android 지원

### 사용 목적
- 🔒 Private Network(10.0.0.0/24)에 안전하게 접근
- 🔒 Jump Box 없이도 내부 VM들에 직접 접근
- 🔒 개발자별 독립적인 VPN 클라이언트 관리

---

## 🌐 네트워크 구성

### IP 주소 체계
```
┌─────────────────────────────────────────────────────────┐
│                     인터넷                               │
└─────────────────────┬───────────────────────────────────┘
                      │
              ┌───────▼───────┐
              │   Jump Box    │
              │ 34.64.179.41  │ ← 외부 IP
              │  10.0.0.5     │ ← 내부 IP  
              │  10.8.0.1     │ ← WireGuard 서버 IP
              └───────┬───────┘
                      │
        ┌─────────────┼─────────────┐
        │         Private Network   │
        │        (10.0.0.0/24)      │
        │                           │
   ┌────▼────┐  ┌────▼────┐  ┌────▼────┐
   │Backend  │  │Database │  │   AI    │
   │10.0.0.2 │  │10.0.0.3 │  │10.0.0.4 │
   └─────────┘  └─────────┘  └─────────┘
```

### VPN 클라이언트 IP 할당
| 클라이언트 | VPN IP | 목적 | 키 |
|------------|--------|------|-----|
| **서버** | 10.8.0.1/24 | Jump Box WireGuard 서버 | 서버 키 |
| **frontend** | 10.8.0.10/32 | 개발자 로컬 접근 | 클라이언트 키 1 |
| **backend** | 10.8.0.20/32 | Backend 서비스 전용 | 클라이언트 키 2 |
| **ai** | 10.8.0.30/32 | AI 서비스 전용 | 클라이언트 키 3 |
| **database** | 10.8.0.40/32 | Database 전용 | 클라이언트 키 4 |

---

## 🖥️ 서버 설정 (Jump Box)

### 1. WireGuard 키 생성 (자동화)
```bash
# 키 생성 스크립트 실행
cd /Users/lsh/Documents/local/3tier-moongsan/14-YG-CLOUD
./scripts/generate-wireguard-keys.sh

# 생성된 키 확인
cat wireguard-keys/server-keys.txt
cat wireguard-keys/client-keys.txt
```

### 2. Terraform에 키 설정
```bash
# terraform.tfvars에 키 추가
cd terraform/environments/test
vi terraform.tfvars

# 내용 예시:
wireguard_private_key = "ALUrESr+UO6ekt1w9eZ25ImaHuBa6SwlswseI4AkX00="
wireguard_public_key  = "jYZ5fIVhu+AuBX2zttyWRJ3Xg80QktAHQRZH8zqk3FE="
```

### 3. Jump Box 배포
```bash
# Terraform으로 Jump Box 배포 (WireGuard 자동 설치)
terraform apply

# 배포 확인
gcloud compute instances list --filter="name:moongsan-test-jumpbox"
```

### 4. Jump Box WireGuard 서버 확인
```bash
# Jump Box 접속
gcloud compute ssh moongsan-test-jumpbox --zone=asia-northeast3-a

# WireGuard 상태 확인
sudo wg show
sudo systemctl status wg-quick@wg0

# 설정 파일 확인
sudo cat /etc/wireguard/wg0.conf
```

**예상 서버 설정 파일 (`/etc/wireguard/wg0.conf`)**:
```ini
[Interface]
Address = 10.8.0.1/24
PrivateKey = ALUrESr+UO6ekt1w9eZ25ImaHuBa6SwlswseI4AkX00=
ListenPort = 51820
PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -t nat -A POSTROUTING -o ens4 -j MASQUERADE
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -t nat -D POSTROUTING -o ens4 -j MASQUERADE

# Frontend 클라이언트
[Peer]
PublicKey = lqanLQIy2lySv+UYAJuxOcTuzC/ZAj4hMnvKCZNgr0A=
AllowedIPs = 10.8.0.10/32

# Backend 클라이언트
[Peer]
PublicKey = gHLPTxaAuGx/lGt3AnHCuTAWcBKb/d40rFsPbnOSZUo=
AllowedIPs = 10.8.0.20/32

# AI 클라이언트
[Peer]
PublicKey = wPsJIne46RLTreZWS7ycIzMIdsXG+khea359rXe03Qg=
AllowedIPs = 10.8.0.30/32

# Database 클라이언트
[Peer]
PublicKey = B1zX5qJanuoDJVYhcsMle/aVITEwdL9vYD/Ug3lNkk4=
AllowedIPs = 10.8.0.40/32
```

---

## 💻 클라이언트 설정 (로컬)

### 1. macOS WireGuard 클라이언트 설치
```bash
# Homebrew로 설치
brew install wireguard-tools

# 또는 App Store에서 WireGuard 앱 설치
```

### 2. 클라이언트 설정 파일 생성
```bash
# 설정 파일 디렉토리 생성
sudo mkdir -p /etc/wireguard

# frontend 클라이언트 설정 파일 생성
sudo vi /etc/wireguard/wg0.conf
```

**클라이언트 설정 파일 (`/etc/wireguard/wg0.conf`)**:
```ini
[Interface]
Address = 10.8.0.10/32
PrivateKey = WDH2pSl70zZVCdfSaddAMUDi6whPtB2ZMqDdKDeWGUc=
DNS = 8.8.8.8

[Peer]
PublicKey = jYZ5fIVhu+AuBX2zttyWRJ3Xg80QktAHQRZH8zqk3FE=
Endpoint = 34.64.179.41:51820
AllowedIPs = 10.8.0.0/24, 10.0.0.0/24
PersistentKeepalive = 25
```

### 3. 자동 생성된 클라이언트 파일 사용
```bash
# Terraform이 생성한 클라이언트 설정 파일 사용
cp wireguard-keys/test-frontend-client.conf /etc/wireguard/wg0.conf

# 파일 권한 설정
sudo chmod 600 /etc/wireguard/wg0.conf
```

---

## 🔗 연결 및 테스트

### 1. VPN 연결
```bash
# WireGuard VPN 연결
sudo wg-quick up wg0

# 연결 상태 확인
sudo wg show

# 예상 출력:
# interface: wg0
#   public key: lqanLQIy2lySv+UYAJuxOcTuzC/ZAj4hMnvKCZNgr0A=
#   private key: (hidden)
#   listening port: 51820
#   
# peer: jYZ5fIVhu+AuBX2zttyWRJ3Xg80QktAHQRZH8zqk3FE=
#   endpoint: 34.64.179.41:51820
#   allowed ips: 10.8.0.0/24, 10.0.0.0/24
#   latest handshake: 1 minute, 23 seconds ago
#   transfer: 2.84 KiB received, 3.22 KiB sent
```

### 2. 네트워크 연결 테스트
```bash
# Jump Box VPN IP로 ping
ping -c 3 10.8.0.1

# 내부 VM들로 ping
ping -c 3 10.0.0.2  # Backend VM
ping -c 3 10.0.0.3  # Database VM  
ping -c 3 10.0.0.4  # AI VM

# 성공 예시:
# PING 10.0.0.2 (10.0.0.2): 56 data bytes
# 64 bytes from 10.0.0.2: icmp_seq=0 ttl=64 time=45.123 ms
# 64 bytes from 10.0.0.2: icmp_seq=1 ttl=64 time=44.567 ms
```

### 3. SSH 직접 접근 테스트
```bash
# VPN을 통한 직접 SSH 접근
ssh lsh@10.0.0.2  # Backend VM
ssh lsh@10.0.0.3  # Database VM
ssh lsh@10.0.0.4  # AI VM

# 접근 성공 시:
# Welcome to Ubuntu 20.04.6 LTS (GNU/Linux 5.15.0-1051-gcp x86_64)
```

### 4. VPN 연결 해제
```bash
# VPN 연결 해제
sudo wg-quick down wg0

# 연결 해제 확인
sudo wg show
# (출력 없음 = 연결 해제됨)
```

---

## 🛠️ 트러블슈팅

### 자주 발생하는 문제와 해결책

#### 1. VPN 연결 실패 (`handshake` 실패)
```bash
# 문제: peer와 handshake가 안됨
# 원인: 방화벽 차단 또는 키 불일치

# 해결 1: 방화벽 규칙 확인
gcloud compute firewall-rules describe moongsan-test-allow-wireguard

# 해결 2: Jump Box WireGuard 재시작
gcloud compute ssh moongsan-test-jumpbox --zone=asia-northeast3-a \
  --command="sudo systemctl restart wg-quick@wg0"
```

#### 2. 내부 VM ping 실패
```bash
# 문제: VPN 연결됐지만 내부 VM 접근 안됨
# 원인: 라우팅 또는 ICMP 방화벽 규칙

# 해결: ICMP 방화벽 규칙 확인/생성
gcloud compute firewall-rules list --filter="name:*icmp*"

# ICMP 규칙이 없으면 생성
gcloud compute firewall-rules create moongsan-test-allow-icmp \
  --network=moongsan-test-vpc \
  --allow=icmp \
  --source-ranges=10.0.0.0/24,10.8.0.0/24 \
  --target-tags=internal
```

#### 3. SSH 키 인증 실패
```bash
# 문제: SSH 연결 시 Permission denied
# 원인: SSH 키가 VM에 등록되지 않음

# 해결: SSH 키 메타데이터 확인
gcloud compute instances describe moongsan-test-backend \
  --zone=asia-northeast3-a \
  --format="value(metadata.items[ssh-keys])"

# SSH 키 재등록 (Terraform 재배포)
cd terraform/environments/test
terraform apply -target=module.backend
```

#### 4. DNS 해석 문제
```bash
# 문제: VPN 연결 후 인터넷 DNS가 안됨
# 원인: DNS 설정 문제

# 해결: 클라이언트 설정에서 DNS 확인
sudo vi /etc/wireguard/wg0.conf

# DNS 라인 추가/수정
[Interface]
DNS = 8.8.8.8, 1.1.1.1
```

#### 5. WireGuard 서비스 시작 실패
```bash
# 문제: Jump Box에서 WireGuard 시작 안됨
# 해결: 수동으로 서비스 시작

gcloud compute ssh moongsan-test-jumpbox --zone=asia-northeast3-a

# WireGuard 설치 확인
sudo apt update && sudo apt install -y wireguard

# 설정 파일 확인
sudo ls -la /etc/wireguard/

# 서비스 수동 시작
sudo wg-quick up wg0
sudo systemctl enable wg-quick@wg0
```

### 디버깅 명령어 모음

#### Jump Box (서버) 디버깅
```bash
# WireGuard 상태 확인
sudo wg show
sudo systemctl status wg-quick@wg0

# 네트워크 인터페이스 확인
ip addr show wg0

# 방화벽 설정 확인 (iptables)
sudo iptables -L
sudo iptables -t nat -L

# 로그 확인
sudo journalctl -u wg-quick@wg0 -f
```

#### 클라이언트 (로컬) 디버깅
```bash
# VPN 연결 상태 확인
sudo wg show

# 라우팅 테이블 확인
netstat -rn | grep 10.8
netstat -rn | grep 10.0

# 네트워크 인터페이스 확인
ifconfig wg0

# 연결 테스트 (상세)
ping -c 5 10.8.0.1
traceroute 10.0.0.2
```

---

## 📚 추가 설정

### 자동 연결 설정 (macOS)
```bash
# 부팅 시 자동 연결 (선택사항)
sudo launchctl load /Library/LaunchDaemons/wg-quick@wg0.plist

# 수동 연결/해제 alias 설정
echo 'alias vpn-up="sudo wg-quick up wg0"' >> ~/.zshrc
echo 'alias vpn-down="sudo wg-quick down wg0"' >> ~/.zshrc
echo 'alias vpn-status="sudo wg show"' >> ~/.zshrc
source ~/.zshrc
```

### GUI 클라이언트 사용 (App Store)
1. **App Store**에서 "WireGuard" 앱 설치
2. **Import from File** → `/etc/wireguard/wg0.conf` 선택
3. **Activate** 버튼으로 연결/해제

### 여러 환경 관리
```bash
# 환경별 설정 파일 분리
/etc/wireguard/
├── test-wg0.conf     # Test 환경
├── prod-wg0.conf     # Prod 환경
└── dev-wg0.conf      # Dev 환경

# 환경별 연결
sudo wg-quick up test-wg0   # Test 환경 VPN
sudo wg-quick up prod-wg0   # Prod 환경 VPN
```

---

## 🔒 보안 고려사항

### 키 관리
- ✅ Private Key는 절대 공유하지 않기
- ✅ 키 파일 권한을 600으로 제한
- ✅ Git에 키 파일 커밋하지 않기 (`.gitignore` 추가)
- ✅ 정기적으로 키 로테이션 고려

### 네트워크 보안
- ✅ AllowedIPs를 최소한으로 제한
- ✅ 필요없는 클라이언트는 서버에서 제거
- ✅ 방화벽 규칙으로 포트 접근 제한
- ✅ VPN 연결 로그 모니터링

### 접근 제어
- ✅ 개발자별 개별 클라이언트 키 발급
- ✅ 퇴사자 키는 즉시 서버에서 제거
- ✅ VPN 접근 기록 주기적 확인

---

**문서 마지막 업데이트**: 2025년 6월 5일  
**작성자**: DevOps Team  
**관련 문서**: [아키텍처 통신 흐름](./architecture-communication-flow.md)
