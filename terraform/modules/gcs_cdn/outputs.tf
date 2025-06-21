# GCS 모듈 출력 - load_balancer 모듈에서 사용할 정보들

output "bucket_name" {
  description = "GCS 버킷 이름"
  value       = google_storage_bucket.frontend_bucket.name
}

output "bucket_url" {
  description = "GCS 버킷 URL"
  value       = google_storage_bucket.frontend_bucket.url
}

output "bucket_self_link" {
  description = "GCS 버킷 self link"
  value       = google_storage_bucket.frontend_bucket.self_link
}

output "upload_instructions" {
  description = "프론트엔드 파일 업로드 방법"
  value       = "React 빌드 파일을 여기에 업로드: gs://${google_storage_bucket.frontend_bucket.name}/"
}
