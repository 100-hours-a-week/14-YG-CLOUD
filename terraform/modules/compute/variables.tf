variable "project_name" {
  description = "Project name"
  type        = string
}

variable "env" {
  description = "Environment name"
  type        = string
}

variable "vm_name" {
  description = "VM instance name"
  type        = string
}

variable "vm_role" {
  description = "VM role (frontend, backend, database, jumpbox)"
  type        = string
}

variable "tier" {
  description = "Application tier (web, app, data)"
  type        = string
}

variable "machine_type" {
  description = "GCP machine type"
  type        = string
  default     = "e2-medium"
}

variable "zone" {
  description = "GCP zone"
  type        = string
  default     = "asia-northeast3-a"
}

variable "image" {
  description = "Boot disk image"
  type        = string
  default     = "ubuntu-os-cloud/ubuntu-2204-lts"
}

variable "disk_size" {
  description = "Boot disk size in GB"
  type        = number
  default     = 50
}

variable "disk_type" {
  description = "Boot disk type"
  type        = string
  default     = "pd-standard"
}

variable "network_name" {
  description = "VPC network name"
  type        = string
}

variable "subnet_name" {
  description = "Subnet name"
  type        = string
}

variable "network_ip" {
  description = "Internal IP address for the VM (optional)"
  type        = string
  default     = null
}

variable "assign_external_ip" {
  description = "Whether to assign external IP"
  type        = bool
  default     = false
}

variable "external_ip_address" {
  description = "External IP address (if assigned)"
  type        = string
  default     = null
}

variable "network_tags" {
  description = "Network tags for firewall rules"
  type        = list(string)
  default     = []
}

variable "ssh_user" {
  description = "SSH username"
  type        = string
  default     = "ubuntu"
}

variable "ssh_public_key_path" {
  description = "Path to SSH public key"
  type        = string
}

variable "service_account_email" {
  description = "Service account email"
  type        = string
  default     = null
}

variable "service_account_scopes" {
  description = "Service account scopes"
  type        = list(string)
  default     = ["cloud-platform"]
}
