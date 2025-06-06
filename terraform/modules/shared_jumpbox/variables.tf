variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "moongsan"
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "asia-northeast3"
}

variable "zone" {
  description = "GCP zone"
  type        = string
  default     = "asia-northeast3-a"
}

variable "machine_type" {
  description = "Machine type for jumpbox"
  type        = string
  default     = "e2-small"
}

variable "disk_size" {
  description = "Boot disk size in GB"
  type        = number
  default     = 20
}

variable "disk_type" {
  description = "Boot disk type"
  type        = string
  default     = "pd-standard"
}

variable "image" {
  description = "Boot disk image"
  type        = string
  default     = "ubuntu-os-cloud/ubuntu-2204-lts"
}

variable "management_vpc_cidr" {
  description = "CIDR block for management VPC"
  type        = string
  default     = "10.100.0.0/16"
}

variable "ssh_public_key" {
  description = "SSH public key"
  type        = string
}

variable "ssh_user" {
  description = "SSH username"
  type        = string
  default     = "lsh"
}

variable "ssh_source_ranges" {
  description = "Source IP ranges allowed for SSH"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "environment_vpc_cidrs" {
  description = "Map of environment names to their VPC CIDR blocks"
  type        = map(string)
  default = {
    dev  = "10.0.0.0/16"
    test = "10.1.0.0/16"
    prod = "10.2.0.0/16"
  }
}

variable "wireguard_port" {
  description = "WireGuard server port"
  type        = number
  default     = 51820
}

variable "tags" {
  description = "Resource tags"
  type        = list(string)
  default     = ["shared", "management", "jumpbox"]
}
