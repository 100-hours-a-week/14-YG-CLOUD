# Scripts 디렉토리 정리 계획

## 🎯 목적
스크립트 의존성을 제거하고 순수한 Terraform/Ansible 명령어 기반 배포로 전환

## 📋 현재 스크립트 분석

### 유지할 스크립트 (2개)
1. **`generate-wireguard-keys.sh`** - WireGuard 키 생성 유틸리티
   - 이유: 수동으로 WireGuard 키를 생성하는 것은 번거로움
   - 용도: 독립적인 유틸리티로 사용
   
2. **`cleanup-all.sh`** - 완전한 리소스 정리 (수정 필요)
   - 이유: Bootstrap 리소스까지 안전하게 정리하는 복잡한 로직 필요
   - 수정: 스크립트 의존성 제거하고 순수 terraform 명령어로 변경

### 아카이브할 스크립트 (4개)
1. **`bootstrap.sh`** → `docs/script-free-deployment-guide.md`로 대체
2. **`deploy.sh`** → 수동 배포 가이드로 대체  
3. **`deploy-frontend.sh`** → GCS 업로드 명령어로 대체
4. **`setup-terraform-backend.sh`** → Bootstrap 가이드로 대체

## 🗂️ 아카이브 계획
```
scripts/
├── generate-wireguard-keys.sh       # 유지
├── cleanup-resources.sh             # cleanup-all.sh 개선 버전
└── archive/                         # 아카이브된 스크립트들
    ├── bootstrap.sh
    ├── deploy.sh  
    ├── deploy-frontend.sh
    └── setup-terraform-backend.sh
```

## ✅ 실행 단계
1. archive 디렉토리 생성
2. 불필요한 스크립트들 이동
3. cleanup-all.sh를 cleanup-resources.sh로 개선
4. README.md 업데이트 (스크립트 없는 방식 우선 권장)
