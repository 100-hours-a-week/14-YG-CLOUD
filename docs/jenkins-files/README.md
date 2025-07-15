# Backend CI/CD Pipeline 구성 가이드

> **파일 위치**: 14-YG-BE 레포지토리 루트에 추가해야 할 파일

## 📁 추가할 파일

### 1. Jenkinsfile (확장자 없이)
- **위치**: `14-YG-BE/Jenkinsfile`
- **내용**: 이 디렉토리의 `Jenkinsfile` 복사

## 🏗️ 빌드 시스템 특징

### Gradle 기반 빌드
- **빌드 도구**: Gradle (gradlew 사용)
- **테스트**: `./gradlew clean test --info`
- **빌드**: `./gradlew build -x test --info`

### Docker 빌드 전략
- **Dockerfile**: Ansible 템플릿(`be_deploy/templates/Dockerfile.j2`)에서 관리
- **빌드 위치**: GCP dev 서버에서 직접 빌드
- **이미지 푸시**: 빌드 후 Docker Hub 자동 푸시

## 🚀 파이프라인 단계별 설명

1. **🚀 Setup**: 환경 정보 출력 및 Git 상태 확인
2. **🔨 Build & Test**: Gradle을 통한 빌드 및 테스트 실행
3. **🚀 Deploy to GCP Dev**: 
   - Ansible을 통한 Backend 소스 클론
   - Dockerfile 템플릿 생성
   - Docker 이미지 빌드 및 푸시
   - 컨테이너 배포
4. **🔍 Health Check**: 배포 후 애플리케이션 상태 확인

## � Jenkins 파이프라인 생성 단계

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

**A. GCP SSH Key**
1. **Manage Jenkins** → **Credentials** → **System** → **Global credentials**
2. **Add Credentials**:
   - **Kind**: SSH Username with private key
   - **Username**: `ubuntu`
   - **Private Key**: GCP 인스턴스 SSH private key
   - **ID**: `gcp-ssh-key`

## ⚠️ 주의사항

- **Jenkinsfile**: 반드시 확장자 없이 `Jenkinsfile`로 저장
- **브랜치**: `tmp/no-kafka` 브랜치에 파일 추가
- **Docker 빌드**: GCP dev 서버에서 실행 (Jenkins 서버가 아님)
- **Dockerfile**: Ansible 템플릿으로 관리됨 (별도 Dockerfile 불필요)
- **네트워크**: Jenkins(AWS) → GCP dev 환경 SSH 접근 필요
