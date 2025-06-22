# ========================================
# Terraform Backend Configuration - Production
# Bootstrap 실행 후 활성화
# ========================================

# Bootstrap 완료 후 주석을 해제하세요
terraform {
  backend "gcs" {
    bucket = "ktb-2-moongsan-terraform-state"
    prefix = "environments/prod"
  }
}