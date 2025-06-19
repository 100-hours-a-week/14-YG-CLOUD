variable "project_name" {
  description = "Project name"
  type        = string
}

variable "env" {
  description = "Environment name"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "asia-northeast3"
}

variable "subnet_cidr" {
  description = "CIDR block for the subnet"
  type        = string
  default     = "10.0.0.0/24"
}

variable "wireguard_cidr" {
  description = "CIDR block for WireGuard VPN"
  type        = string
  default     = "10.8.0.0/24"
}

variable "ssh_source_ranges" {
  description = "Source IP ranges allowed for SSH"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "shared_vpc_cidr" {
  description = "CIDR block for shared VPC (for jumpbox access)"
  type        = string
  default     = "10.100.0.0/24"
}
