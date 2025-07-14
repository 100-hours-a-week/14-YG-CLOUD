# Backend CI/CD Pipeline 구성 가이드

> **파일 위치**: 14-YG-BE 레포지토리 루트에 추가해야 할 파일들

## 📁 추가할 파일들

### 1. Jenkinsfile (확장자 없이)
- **위치**: `14-YG-BE/Jenkinsfile`
- **내용**: 이 디렉토리의 `Jenkinsfile` 복사

### 2. Dockerfile  
- **위치**: `14-YG-BE/Dockerfile`
- **내용**: 이 디렉토리의 `Dockerfile` 복사

## 🚀 Jenkins 파이프라인 생성 단계

### Step 1: Jenkins 웹 UI 접속
```
http://jenkins.moongsan.com:8080
```

### Step 2: 새 파이프라인 생성
1. **New Item** 클릭
2. **Item name**: `Backend-GCP-Dev-Pipeline`
3. **Pipeline** 선택 → OK

### Step 3: 파이프라인 설정
**General 섹션**:
- ✅ GitHub project: `https://github.com/100-hours-a-week/14-YG-BE`

**Build Triggers 섹션**:
- ✅ GitHub hook trigger for GITScm polling

**Pipeline 섹션**:
- **Definition**: Pipeline script from SCM
- **SCM**: Git
- **Repository URL**: `https://github.com/100-hours-a-week/14-YG-BE.git`
- **Credentials**: Add → Username with password (GitHub 계정)
- **Branches to build**: `*/tmp/no-kafka`
- **Script Path**: `Jenkinsfile`

### Step 4: 필수 Credentials 설정

**A. Docker Hub Credentials**
1. **Manage Jenkins** → **Credentials** → **System** → **Global credentials**
2. **Add Credentials**:
   - **Kind**: Username with password
   - **Username**: Docker Hub 사용자명
   - **Password**: Docker Hub 비밀번호
   - **ID**: `dockerhub-credentials`

**B. GCP SSH Key**
1. **Add Credentials**:
   - **Kind**: SSH Username with private key
   - **Username**: `ubuntu`
   - **Private Key**: GCP 인스턴스 SSH private key
   - **ID**: `gcp-ssh-key`

## 🔧 파이프라인 단계별 설명

1. **🚀 Setup**: 환경 정보 출력 및 Git 상태 확인
2. **🔨 Build & Test**: Maven을 통한 빌드 및 테스트 실행
3. **🐳 Docker Build & Push**: Docker 이미지 빌드 후 Docker Hub 푸시
4. **🚀 Deploy to GCP Dev**: Ansible을 통한 GCP dev 환경 배포
5. **🔍 Health Check**: 배포 후 애플리케이션 상태 확인

## ⚠️ 주의사항

- **Jenkinsfile**: 반드시 확장자 없이 `Jenkinsfile`로 저장
- **브랜치**: `tmp/no-kafka` 브랜치에 파일들 추가
- **권한**: GitHub webhook 설정 필요 (저장소 설정에서)
- **네트워크**: Jenkins(AWS) → GCP dev 환경 접근 가능한지 확인
