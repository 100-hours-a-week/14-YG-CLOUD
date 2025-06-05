# ☁️ GCS + CDN Frontend 호스팅 가이드

> **작성일**: 2025년 6월 5일  
> **목적**: Test/Prod 환경 Frontend 정적 웹사이트 호스팅 설정  
> **기술스택**: Google Cloud Storage + Cloud CDN + Global Load Balancer

## 📋 목차

1. [GCS + CDN 개요](#-gcs--cdn-개요)
2. [아키텍처 구성](#-아키텍처-구성)
3. [Terraform 자동 배포](#-terraform-자동-배포)
4. [수동 설정 방법](#-수동-설정-방법)
5. [Frontend 배포](#-frontend-배포)
6. [도메인 연결](#-도메인-연결)
7. [성능 최적화](#-성능-최적화)
8. [트러블슈팅](#-트러블슈팅)

---

## 🌐 GCS + CDN 개요

**Google Cloud Storage + Cloud CDN**을 이용한 정적 웹사이트 호스팅은 기존 VM 방식 대비 **70% 비용 절감**과 **글로벌 고성능**을 제공합니다.

### 주요 장점
- ✅ **비용 효율**: VM 대신 저렴한 스토리지 비용
- ✅ **글로벌 성능**: 전 세계 CDN 엣지 서버 활용
- ✅ **자동 확장**: 트래픽 급증에도 안정적 서비스
- ✅ **관리 간소화**: 서버 관리 불필요
- ✅ **HTTPS 자동**: SSL 인증서 자동 관리

### 기존 VM vs GCS+CDN 비교
| 항목 | VM 호스팅 | GCS + CDN | 개선 효과 |
|------|-----------|-----------|-----------|
| **월 비용** | ~$30 (e2-medium) | ~$5 (스토리지+CDN) | 83% 절감 |
| **글로벌 속도** | 단일 리전 | 전 세계 엣지 | 3-5배 빠름 |
| **가용성** | 99.5% (단일 VM) | 99.95% (다중화) | 안정성 향상 |
| **확장성** | 수동 스케일링 | 자동 무제한 | 완전 자동화 |
| **관리 복잡도** | 서버 관리 필요 | 관리 불요 | 운영비 절감 |

---

## 🏗️ 아키텍처 구성

### 전체 흐름도
```
사용자 요청 → DNS → Global Load Balancer → Cloud CDN → GCS 버킷
                                          ↓
                                     캐시된 응답 ← 엣지 서버
```

### 상세 아키텍처
```
┌─────────────────────────────────────────────────────────┐
│                      인터넷                             │
└─────────────────────┬───────────────────────────────────┘
                      │
              ┌───────▼───────┐
              │   사용자      │
              │ test.moongsan │ ← DNS 요청
              │     .com      │
              └───────┬───────┘
                      │
              ┌───────▼───────┐
              │Global Load    │
              │Balancer       │ ← HTTPS 종료
              │34.8.174.93    │
              └───────┬───────┘
                      │
              ┌───────▼───────┐
              │  Cloud CDN    │
              │ (Edge Servers)│ ← 캐시 레이어
              └───────┬───────┘
                      │
              ┌───────▼───────┐
              │   GCS 버킷    │
              │moongsan-test- │ ← 스토리지
              │  frontend     │
              └───────────────┘
```

### Test 환경 구성 요소
| 컴포넌트 | 이름 | 역할 | 접근 주소 |
|----------|------|------|-----------|
| **GCS 버킷** | `moongsan-test-frontend` | React 빌드 파일 저장 | gs:// 내부 접근 |
| **Backend Bucket** | `moongsan-test-frontend-backend` | CDN과 GCS 연결 | 내부 구성 요소 |
| **Global Load Balancer** | `moongsan-test-frontend-urlmap` | HTTPS 엔드포인트 | 34.8.174.93 |
| **Cloud CDN** | 자동 구성 | 글로벌 캐싱 | 전 세계 엣지 |
| **도메인** | `test.moongsan.com` | 사용자 접근 | CNAME → LB |

---

## 🚀 Terraform 자동 배포

### 1. GCS + CDN 모듈 구조
```bash
# Terraform 모듈 위치
terraform/modules/gcs_cdn/
├── main.tf          # 주요 리소스 정의
├── variables.tf     # 입력 변수
└── outputs.tf       # 출력 값
```

### 2. 모듈 주요 구성 요소

#### GCS 버킷 생성
```terraform
# GCS 버킷 생성
resource "google_storage_bucket" "frontend_bucket" {
  name          = "${var.project_name}-${var.env}-frontend"
  location      = "ASIA"
  force_destroy = true
  
  uniform_bucket_level_access = true
  
  website {
    main_page_suffix = "index.html"
    not_found_page   = "404.html"
  }
  
  cors {
    origin          = ["*"]
    method          = ["GET", "HEAD"]
    response_header = ["*"]
    max_age_seconds = 3600
  }
}
```

#### 퍼블릭 접근 설정
```terraform
# 버킷을 public으로 설정
resource "google_storage_bucket_iam_member" "frontend_bucket_public" {
  bucket = google_storage_bucket.frontend_bucket.name
  role   = "roles/storage.objectViewer"
  member = "allUsers"
}
```

#### Cloud CDN 설정
```terraform
# Cloud CDN을 위한 Backend Service
resource "google_compute_backend_bucket" "frontend_backend" {
  name        = "${var.project_name}-${var.env}-frontend-backend"
  bucket_name = google_storage_bucket.frontend_bucket.name
  enable_cdn  = true
  
  cdn_policy {
    cache_mode                   = "CACHE_ALL_STATIC"
    default_ttl                 = 3600     # 1시간
    max_ttl                     = 86400    # 24시간
    negative_caching            = true
    serve_while_stale           = 86400
  }
}
```

#### Global Load Balancer
```terraform
# Global HTTP(S) Load Balancer
resource "google_compute_url_map" "frontend_url_map" {
  name            = "${var.project_name}-${var.env}-frontend-urlmap"
  default_service = google_compute_backend_bucket.frontend_backend.self_link
}

# HTTPS 프록시
resource "google_compute_target_https_proxy" "frontend_https_proxy" {
  name             = "${var.project_name}-${var.env}-frontend-https-proxy"
  url_map          = google_compute_url_map.frontend_url_map.self_link
  ssl_certificates = [google_compute_managed_ssl_certificate.frontend_ssl.self_link]
}

# 글로벌 포워딩 규칙
resource "google_compute_global_forwarding_rule" "frontend_forwarding_rule" {
  name       = "${var.project_name}-${var.env}-frontend-forwarding-rule"
  target     = google_compute_target_https_proxy.frontend_https_proxy.self_link
  port_range = "443"
  ip_address = google_compute_global_address.frontend_ip.address
}
```

### 3. 자동 배포 실행
```bash
# Test 환경 전체 배포
cd terraform/environments/test
terraform init
terraform apply

# GCS + CDN만 배포
terraform apply -target=module.frontend_hosting

# 배포 결과 확인
terraform output
```

### 4. 배포 결과 확인
```bash
# 생성된 리소스 확인
gcloud storage buckets list --filter="name:moongsan-test-*"
gcloud compute backend-buckets list --filter="name:moongsan-test-*"
gcloud compute url-maps list --filter="name:moongsan-test-*"

# Load Balancer IP 확인
gcloud compute addresses list --global --filter="name:moongsan-test-*"
```

---

## 🔧 수동 설정 방법

### 1. GCS 버킷 생성
```bash
# 버킷 생성
gsutil mb -l asia gs://moongsan-test-frontend

# 웹사이트 설정
gsutil web set -m index.html -e 404.html gs://moongsan-test-frontend

# 퍼블릭 접근 허용
gsutil iam ch allUsers:objectViewer gs://moongsan-test-frontend
```

### 2. Backend Bucket 생성
```bash
# Backend Bucket 생성 및 CDN 활성화
gcloud compute backend-buckets create moongsan-test-frontend-backend \
  --gcs-bucket-name=moongsan-test-frontend \
  --enable-cdn \
  --cache-mode=CACHE_ALL_STATIC \
  --default-ttl=3600 \
  --max-ttl=86400
```

### 3. Global Load Balancer 설정
```bash
# URL Map 생성
gcloud compute url-maps create moongsan-test-frontend-urlmap \
  --default-backend-bucket=moongsan-test-frontend-backend

# 글로벌 IP 예약
gcloud compute addresses create moongsan-test-frontend-ip --global

# HTTPS 프록시 생성 (SSL 인증서 필요)
gcloud compute target-https-proxies create moongsan-test-frontend-https-proxy \
  --url-map=moongsan-test-frontend-urlmap \
  --ssl-certificates=moongsan-test-ssl-cert

# 포워딩 규칙 생성
gcloud compute forwarding-rules create moongsan-test-frontend-forwarding-rule \
  --global \
  --target-https-proxy=moongsan-test-frontend-https-proxy \
  --ports=443 \
  --address=moongsan-test-frontend-ip
```

---

## 📦 Frontend 배포

### 1. 자동 배포 스크립트 사용
```bash
# React 앱 빌드 및 배포 (한 번에)
cd /Users/lsh/Documents/local/3tier-moongsan/14-YG-CLOUD
./scripts/deploy-frontend.sh test ../14-YG-FE/dist

# 스크립트 내용:
# 1. React 빌드 파일을 GCS에 업로드
# 2. CDN 캐시 무효화
# 3. 배포 완료 확인
```

### 2. 수동 배포 과정

#### React 앱 빌드
```bash
# Frontend 프로젝트로 이동
cd ../14-YG-FE

# 의존성 설치
npm install

# Test 환경용 빌드
npm run build

# 빌드 결과 확인
ls -la dist/
```

#### GCS에 업로드
```bash
# 기존 파일 삭제 (선택사항)
gsutil -m rm gs://moongsan-test-frontend/**

# 새 빌드 파일 업로드
gsutil -m cp -r dist/* gs://moongsan-test-frontend/

# 업로드 확인
gsutil ls -la gs://moongsan-test-frontend/
```

#### 캐시 무효화
```bash
# CDN 캐시 무효화 (즉시 반영)
gcloud compute url-maps invalidate-cdn-cache moongsan-test-frontend-urlmap \
  --path "/*" \
  --global

# 무효화 상태 확인
gcloud compute operations list --global --filter="operationType:invalidateCache"
```

### 3. 배포 확인
```bash
# HTTP 응답 확인
curl -I https://34.8.174.93/

# 예상 출력:
# HTTP/2 200
# content-type: text/html
# cache-control: public, max-age=3600
# server: gws
```

---

## 🌐 도메인 연결

### 1. DNS 설정 (Cloud DNS)
```bash
# DNS Zone 생성 (이미 있다면 건너뛰기)
gcloud dns managed-zones create moongsan-zone \
  --dns-name=moongsan.com \
  --description="Moongsan domain zone"

# Test 서브도메인 A 레코드 추가
gcloud dns record-sets transaction start --zone=moongsan-zone

gcloud dns record-sets transaction add \
  --name=test.moongsan.com \
  --ttl=300 \
  --type=A \
  --zone=moongsan-zone \
  34.8.174.93

gcloud dns record-sets transaction execute --zone=moongsan-zone
```

### 2. SSL 인증서 자동 발급
```bash
# 관리형 SSL 인증서 생성
gcloud compute ssl-certificates create moongsan-test-ssl-cert \
  --domains=test.moongsan.com \
  --global

# 인증서 상태 확인
gcloud compute ssl-certificates describe moongsan-test-ssl-cert \
  --global \
  --format="value(managed.status)"
```

### 3. 도메인 연결 확인
```bash
# DNS 전파 확인
nslookup test.moongsan.com

# HTTPS 접근 테스트
curl -I https://test.moongsan.com/

# 브라우저에서 접근
open https://test.moongsan.com
```

---

## ⚡ 성능 최적화

### 1. CDN 캐시 설정 최적화
```bash
# Backend Bucket CDN 정책 수정
gcloud compute backend-buckets update moongsan-test-frontend-backend \
  --cache-mode=CACHE_ALL_STATIC \
  --default-ttl=7200 \      # 2시간
  --max-ttl=172800 \        # 48시간
  --client-ttl=3600 \       # 1시간
  --negative-caching \
  --negative-caching-policy="404=300,500=60"
```

### 2. 압축 설정
```bash
# GCS 객체에 압축 메타데이터 설정
gsutil -m setmeta -h "Content-Encoding:gzip" \
  gs://moongsan-test-frontend/*.js

gsutil -m setmeta -h "Content-Encoding:gzip" \
  gs://moongsan-test-frontend/*.css
```

### 3. 캐시 헤더 최적화
```bash
# 정적 자산별 캐시 정책
# JS/CSS: 1년 캐시
gsutil -m setmeta -h "Cache-Control:public, max-age=31536000" \
  gs://moongsan-test-frontend/assets/*.js

gsutil -m setmeta -h "Cache-Control:public, max-age=31536000" \
  gs://moongsan-test-frontend/assets/*.css

# HTML: 1시간 캐시
gsutil -m setmeta -h "Cache-Control:public, max-age=3600" \
  gs://moongsan-test-frontend/*.html
```

### 4. 성능 모니터링
```bash
# CDN 캐시 히트율 확인
gcloud logging read "resource.type=http_load_balancer AND 
jsonPayload.backendTargetName=moongsan-test-frontend-backend" \
  --format="value(jsonPayload.cacheResult)" \
  --limit=100
```

---

## 🛠️ 트러블슈팅

### 자주 발생하는 문제와 해결책

#### 1. 403 Forbidden 오류
```bash
# 문제: 버킷 접근 권한 없음
# 해결: 퍼블릭 읽기 권한 설정
gsutil iam ch allUsers:objectViewer gs://moongsan-test-frontend

# 권한 확인
gsutil iam get gs://moongsan-test-frontend
```

#### 2. 404 Not Found (파일 없음)
```bash
# 문제: index.html 파일이 루트에 없음
# 해결: 파일 업로드 확인
gsutil ls gs://moongsan-test-frontend/

# index.html 수동 업로드
gsutil cp dist/index.html gs://moongsan-test-frontend/
```

#### 3. 캐시 때문에 업데이트 반영 안됨
```bash
# 문제: CDN 캐시로 인한 이전 버전 서빙
# 해결: 캐시 무효화
gcloud compute url-maps invalidate-cdn-cache moongsan-test-frontend-urlmap \
  --path "/*" --global

# 강제 새로고침 (브라우저)
# Ctrl+F5 (Windows) 또는 Cmd+Shift+R (Mac)
```

#### 4. SSL 인증서 발급 실패
```bash
# 문제: 도메인 검증 실패
# 해결: DNS 설정 확인
nslookup test.moongsan.com

# SSL 인증서 상태 확인
gcloud compute ssl-certificates describe moongsan-test-ssl-cert --global

# 재발급 (필요시)
gcloud compute ssl-certificates delete moongsan-test-ssl-cert --global
# 다시 생성 후 대기 (최대 30분)
```

#### 5. 느린 로딩 속도
```bash
# 문제: CDN 캐시 미스 또는 압축 없음
# 해결 1: 파일 압축 확인
gsutil stat gs://moongsan-test-frontend/main.js

# 해결 2: CDN 캐시 상태 확인
curl -I https://test.moongsan.com/ | grep -i cache

# 해결 3: 압축 설정
gsutil -m setmeta -h "Content-Encoding:gzip" gs://moongsan-test-frontend/*.js
```

### 디버깅 명령어 모음

#### GCS 버킷 디버깅
```bash
# 버킷 상태 확인
gsutil ls -L gs://moongsan-test-frontend

# 객체 메타데이터 확인
gsutil stat gs://moongsan-test-frontend/index.html

# 권한 확인
gsutil iam get gs://moongsan-test-frontend
```

#### CDN 디버깅
```bash
# Backend Bucket 상태
gcloud compute backend-buckets describe moongsan-test-frontend-backend

# URL Map 상태
gcloud compute url-maps describe moongsan-test-frontend-urlmap

# CDN 캐시 무효화 기록
gcloud compute operations list --global --filter="operationType:invalidateCache"
```

#### Load Balancer 디버깅
```bash
# 글로벌 IP 확인
gcloud compute addresses list --global

# 포워딩 규칙 확인
gcloud compute forwarding-rules list --global

# SSL 인증서 상태
gcloud compute ssl-certificates list --global
```

#### 네트워크 디버깅
```bash
# DNS 전파 확인
dig test.moongsan.com
nslookup test.moongsan.com 8.8.8.8

# HTTP 응답 헤더 확인
curl -I https://test.moongsan.com/

# 연결 추적
traceroute test.moongsan.com
```

---

## 📊 비용 모니터링

### 1. 예상 비용 계산
```bash
# GCS 스토리지 비용 (월간)
# 1GB 스토리지: $0.020
# 10GB 네트워크 송신: $0.12
# 총 예상 비용: ~$5/월

# 기존 VM 비용 비교
# e2-medium VM: $24.67/월
# 절약 효과: ~$20/월 (80% 절감)
```

### 2. 비용 모니터링 설정
```bash
# Billing API 활성화
gcloud services enable cloudbilling.googleapis.com

# 비용 알림 설정 (Cloud Console에서)
# Billing > Budgets & Alerts
```

### 3. 사용량 확인
```bash
# GCS 사용량 확인
gsutil du -sh gs://moongsan-test-frontend

# CDN 대역폭 사용량 (Cloud Console)
# Network Services > Cloud CDN > Monitoring
```

---

## 🔄 CI/CD 연동

### GitHub Actions 배포 워크플로우
```yaml
# .github/workflows/deploy-frontend.yml
name: Deploy Frontend to GCS

on:
  push:
    branches: [ main, test ]
    paths: [ 'frontend/**' ]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2
    
    - name: Setup Node.js
      uses: actions/setup-node@v2
      with:
        node-version: '18'
        
    - name: Install dependencies
      run: |
        cd frontend
        npm ci
        
    - name: Build
      run: |
        cd frontend
        npm run build
        
    - name: Setup Google Cloud SDK
      uses: google-github-actions/setup-gcloud@v0
      with:
        service_account_key: ${{ secrets.GCP_SA_KEY }}
        project_id: ${{ secrets.GCP_PROJECT_ID }}
        
    - name: Deploy to GCS
      run: |
        gsutil -m rsync -r -d frontend/dist gs://moongsan-test-frontend
        
    - name: Invalidate CDN Cache
      run: |
        gcloud compute url-maps invalidate-cdn-cache moongsan-test-frontend-urlmap \
          --path "/*" --global
```

---

**문서 마지막 업데이트**: 2025년 6월 5일  
**작성자**: DevOps Team  
**관련 문서**: [아키텍처 통신 흐름](./architecture-communication-flow.md), [WireGuard VPN 설정](./wireguard-setup.md)
