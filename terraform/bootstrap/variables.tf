variable "project_id" {
  description = "GCP Project ID"
  type        = string
  default     = "ktb-2-moongsan"
}

variable "region" {
  description = "GCP Region"
  type        = string
  default     = "asia-northeast3"
}

variable "zone" {
  description = "GCP Zone"
  type        = string
  default     = "asia-northeast3-a"
}

variable "enable_deletion_protection" {
  description = "Enable deletion protection for critical resources (GCS bucket, KMS key)"
  type        = bool
  default     = true
}

variable "environment" {
  description = "Environment name (dev, test, prod)"
  type        = string
  default     = "dev"
}