# ========================================
# Terraform Backend Configuration
# Bootstrap 실행 후 자동 생성됨
# ========================================

# 주석: Bootstrap 실행 후 아래 설정이 자동으로 업데이트됩니다
terraform {
  backend "gcs" {
    bucket = "ktb-2-moongsan-terraform-state"
    prefix = "environments/test"
  }
}