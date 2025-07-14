# Backend Service - Jenkins CI/CD Pipeline

## 🎯 Overview
This Jenkinsfile provides a complete CI/CD pipeline for the Backend service deployment to GCP dev environment.

## 🏗️ Pipeline Stages

### 1. Setup & Checkout
- Workspace cleanup
- Source code checkout from GitHub
- Branch: `tmp/no-kafka`

### 2. Code Quality & Security
- Static code analysis (준비 중)
- Security vulnerability scanning (준비 중)

### 3. Build & Test
- Maven build with test execution
- Test results publishing
- JAR artifact generation

### 4. Docker Build & Push
- Docker image build
- Push to Docker Hub registry
- Tag: `BUILD_NUMBER` and `latest`

### 5. Deploy to GCP Dev
- Ansible-based deployment
- Target: `moongsan-dev-vm` (GCP dev environment)
- Container orchestration

### 6. Health Check
- Post-deployment validation
- Health endpoint verification

## 🔧 Configuration

### Required Jenkins Credentials
- `dockerhub-credentials`: Docker Hub registry access
- `gcp-ssh-key`: GCP instance SSH access

### Environment Variables
```
BACKEND_REPO = 'https://github.com/100-hours-a-week/14-YG-BE.git'
BACKEND_BRANCH = 'tmp/no-kafka'
DOCKER_IMAGE = 'moongsan/backend'
TARGET_ENV = 'dev'
GCP_PROJECT = 'ktb-2-moongsan'
TARGET_INSTANCE = 'moongsan-dev-vm'
APP_PORT = '8080'
```

## 🚀 Deployment Flow

```
GitHub Push → Jenkins Trigger → Build & Test → Docker Build → Push to Registry → Deploy via Ansible → Health Check
```

## 📋 Prerequisites

### Jenkins Plugins Required
- Git Plugin
- Docker Pipeline Plugin
- Pipeline Plugin
- Ansible Plugin
- JUnit Plugin

### GCP Configuration
- Service account with appropriate permissions
- SSH key for instance access
- Compute Engine API enabled

### Ansible Configuration
- Inventory file: `ansible/inventory_dev.ini`
- Playbook: `ansible/playbooks/be_deploy.yml`
- Backend deployment role configured

## 🔍 Monitoring & Troubleshooting

### Health Check Endpoint
- URL: `http://localhost:8080/health`
- Expected Response: 200 OK

### Common Issues
1. **Build Failure**: Check Maven dependencies and test configurations
2. **Docker Push Failure**: Verify Docker Hub credentials
3. **Deployment Failure**: Check Ansible inventory and SSH connectivity
4. **Health Check Failure**: Verify application startup and configuration

## 📊 Pipeline Metrics
- Build Duration: ~5-10 minutes
- Docker Image Size: TBD
- Deployment Time: ~2-3 minutes
- Health Check Timeout: 30 seconds

## 🔄 Next Steps
1. Configure SonarQube integration for code quality
2. Add security scanning with SAST/DAST tools
3. Implement rollback mechanisms
4. Add notification integrations (Slack, Email)
5. Performance testing integration
