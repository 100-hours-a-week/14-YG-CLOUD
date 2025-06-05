# 🔐 WireGuard 간단 사용 가이드

## 🤔 WireGuard가 뭔가요?

**WireGuard = 안전한 가상 터널**

🏠 집에서 → 🌐 인터넷 → 🔒 WireGuard 터널 → ☁️ 클라우드 내부

마치 집에서 회사 내부 네트워크에 직접 연결된 것처럼 만들어주는 기술입니다.

## 🎯 왜 필요한가요?

### 문제상황
```
❌ 직접 접근 불가능:
집 → Backend VM (10.0.0.2) ❌ 차단됨
집 → Database VM (10.0.0.3) ❌ 차단됨
집 → AI VM (10.0.0.4) ❌ 차단됨
```

### WireGuard 해결책
```
✅ WireGuard 사용 시:
집 → WireGuard → Jump Box → Backend VM (10.0.0.2) ✅ 접근 가능
집 → WireGuard → Jump Box → Database VM (10.0.0.3) ✅ 접근 가능
집 → WireGuard → Jump Box → AI VM (10.0.0.4) ✅ 접근 가능
```

## 🏗️ 현재 프로젝트 구조

```
                    🌐 인터넷
                       │
               ┌───────▼──────┐
               │  Jump Box    │ ← WireGuard 서버
               │ 34.64.179.41 │ ← 외부 IP
               │  10.0.0.5    │ ← 내부 IP
               │  10.8.0.1    │ ← VPN IP
               └───────┬──────┘
                       │
         ┌─────────────┼─────────────┐
         │      Private Network      │
         │       (10.0.0.0/24)       │
         │                           │
    ┌────▼────┐  ┌────▼────┐  ┌────▼────┐
    │Backend  │  │Database │  │   AI    │
    │10.0.0.2 │  │10.0.0.3 │  │10.0.0.4 │
    └─────────┘  └─────────┘  └─────────┘
```

## 🔑 키 파일 시스템

### 📁 키 위치
```
wireguard-keys/
├── server-keys.txt          # Jump Box용 서버 키
├── client-keys.txt          # 클라이언트용 키들 (4개)
├── terraform.tfvars.example # Terraform 설정 예시
└── test-frontend-client.conf # 실제 사용 중인 클라이언트 설정
```

### 🔐 키 종류
| 키 종류 | 용도 | 위치 |
|---------|------|------|
| **서버 키** | Jump Box WireGuard 서버용 | `server-keys.txt` |
| **클라이언트 키 1** | frontend 개발자용 | `client-keys.txt` |
| **클라이언트 키 2** | backend 개발자용 | `client-keys.txt` |
| **클라이언트 키 3** | ai 개발자용 | `client-keys.txt` |
| **클라이언트 키 4** | database 개발자용 | `client-keys.txt` |

## 🚀 사용법 (간단 버전)

### 1️⃣ **관리자 작업** (이미 완료됨)
```bash
# 키 생성
./scripts/generate-wireguard-keys.sh

# Terraform으로 Jump Box 배포 (WireGuard 자동 설치)
cd terraform/environments/test
terraform apply
```

### 2️⃣ **개발자 작업** (클라이언트 설정)

#### macOS 사용자
```bash
# WireGuard 설치
brew install wireguard-tools

# 설정 파일 사용
cp wireguard-keys/test-frontend-client.conf ~/.config/wireguard/
wg-quick up test-frontend-client
```

#### Windows 사용자
1. [WireGuard for Windows](https://www.wireguard.com/install/) 다운로드
2. `test-frontend-client.conf` 파일을 WireGuard 앱에 추가
3. 연결 버튼 클릭

### 3️⃣ **연결 확인**
```bash
# VPN 연결 상태 확인
wg show

# 내부 VM 접근 테스트
ping 10.0.0.2  # Backend VM
ping 10.0.0.3  # Database VM
ping 10.0.0.4  # AI VM
```

## 🔧 실제 사용 시나리오

### 🎯 **시나리오 1: Backend 개발**
```bash
# WireGuard 연결
wg-quick up test-frontend-client

# Backend VM에 직접 SSH 접속
ssh ubuntu@10.0.0.2

# Backend API 직접 테스트
curl http://10.0.0.2:8000/health
```

### 🎯 **시나리오 2: Database 관리**
```bash
# WireGuard 연결
wg-quick up test-frontend-client

# Database VM에 직접 접속
ssh ubuntu@10.0.0.3

# PostgreSQL 직접 접속
psql -h 10.0.0.3 -U postgres -d moongsan_db
```

### 🎯 **시나리오 3: AI 서비스 테스트**
```bash
# WireGuard 연결
wg-quick up test-frontend-client

# AI API 직접 호출
curl http://10.0.0.4:8000/predict
```

## 🛡️ 보안 특징

### ✅ **강점**
- **end-to-end 암호화**: ChaCha20 암호화 알고리즘
- **최소 권한**: 각 클라이언트별 독립적인 키
- **자동 연결**: 네트워크 변경 시 자동 재연결
- **빠른 속도**: 기존 VPN 대비 월등한 성능

### 🔒 **보안 규칙**
- 키 파일은 절대 Git에 커밋하지 않음 (`.gitignore`로 보호됨)
- 각 개발자별 독립적인 클라이언트 키 사용
- 서버 키는 Jump Box에서만 사용

## 📚 추가 정보

더 자세한 설정은 `docs/wireguard-setup.md`를 참조하세요.

## 🎉 정리

**WireGuard는 이렇게 생각하세요:**
- 🏠 **집에서** 
- 🔒 **안전한 터널**을 통해 
- ☁️ **클라우드 내부**에 
- 🎯 **직접 접근**할 수 있게 해주는 도구

**한 번만 설정하면, 마치 클라우드와 같은 네트워크에 있는 것처럼 편리하게 개발할 수 있습니다!** 🚀
