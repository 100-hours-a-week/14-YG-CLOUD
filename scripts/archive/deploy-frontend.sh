#!/bin/bash

# Frontend Build & Deploy Script for GCS + CDN
# 사용법: ./deploy-frontend.sh [environment] [build_path]

set -e

ENV=${1:-test}
BUILD_PATH=${2:-"../14-YG-FE/dist"}
PROJECT_NAME="moongsan"

echo "🚀 Frontend 배포 시작 - Environment: $ENV"

# 1. Terraform에서 bucket 정보 가져오기
cd terraform/environments/$ENV
BUCKET_NAME=$(terraform output -raw frontend_hosting | jq -r '.bucket_name')
CDN_IP=$(terraform output -raw frontend_hosting | jq -r '.cdn_ip')
FRONTEND_URL=$(terraform output -raw frontend_hosting | jq -r '.url')

echo "📦 Target Bucket: $BUCKET_NAME"
echo "🌐 CDN IP: $CDN_IP"
echo "🔗 Frontend URL: $FRONTEND_URL"

# 2. React 빌드 파일 업로드
if [ -d "$BUILD_PATH" ]; then
    echo "📤 Uploading build files to GCS..."
    gsutil -m rsync -r -d "$BUILD_PATH/" "gs://$BUCKET_NAME/"
    
    # 3. 캐시 무효화 (선택사항)
    echo "🔄 Invalidating CDN cache..."
    # gcloud compute url-maps invalidate-cdn-cache $PROJECT_NAME-$ENV-frontend-urlmap --path="/*" --async
    
    echo "✅ Frontend 배포 완료!"
    echo "🌍 Frontend URL: $FRONTEND_URL"
else
    echo "❌ Build directory not found: $BUILD_PATH"
    echo "Please build your React app first or specify correct build path"
    exit 1
fi
