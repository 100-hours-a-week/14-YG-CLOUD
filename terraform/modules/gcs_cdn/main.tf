# GCS 모듈 - Frontend 정적 파일 저장소 (Option 4 구조)

# GCS 버킷 생성 - 실제 React 빌드 파일들이 저장되는 곳
resource "google_storage_bucket" "frontend_bucket" {
  name          = "${var.project_name}-${var.env}-frontend"
  location      = "ASIA"
  force_destroy = true
  
  uniform_bucket_level_access = true
  
  website {
    main_page_suffix = "index.html"
    not_found_page   = "index.html"
  }
  
  cors {
    origin          = ["*"]
    method          = ["GET", "HEAD", "PUT", "POST", "DELETE"]
    response_header = ["*"]
    max_age_seconds = 3600
  }
}

# 버킷을 public으로 설정
resource "google_storage_bucket_iam_member" "frontend_bucket_public" {
  bucket = google_storage_bucket.frontend_bucket.name
  role   = "roles/storage.objectViewer"
  member = "allUsers"
}
