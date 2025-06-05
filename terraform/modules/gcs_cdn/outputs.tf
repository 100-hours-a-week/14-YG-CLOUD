output "bucket_name" {
  description = "Name of the GCS bucket"
  value       = google_storage_bucket.frontend_bucket.name
}

output "bucket_url" {
  description = "GS URL of the bucket"
  value       = google_storage_bucket.frontend_bucket.url
}

output "cdn_ip_address" {
  description = "Static IP address for the CDN"
  value       = google_compute_global_address.frontend_ip.address
}

output "frontend_url" {
  description = "Frontend URL"
  value       = "https://${var.domain_name}"
}

output "upload_instructions" {
  description = "Instructions for uploading frontend files"
  value       = "Upload your React build files to: gs://${google_storage_bucket.frontend_bucket.name}/"
}
