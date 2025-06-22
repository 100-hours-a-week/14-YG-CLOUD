# ========================================
# Production Environment Outputs
# ========================================

output "environment" {
  description = "Environment name"
  value       = var.environment
}

output "region" {
  description = "GCP region"
  value       = var.region
}

output "zone" {
  description = "GCP zone"
  value       = var.zone
}

# VPC 정보
output "vpc_name" {
  description = "VPC network name"
  value       = google_compute_network.prod_vpc.name
}

output "vpc_id" {
  description = "VPC network ID"
  value       = google_compute_network.prod_vpc.id
}

output "subnet_name" {
  description = "Subnet name"
  value       = google_compute_subnetwork.prod_subnet.name
}

output "vpc_cidr" {
  description = "VPC CIDR range"
  value       = google_compute_subnetwork.prod_subnet.ip_cidr_range
}

# VM 정보
output "vm_ips" {
  description = "VM internal IP addresses"
  value = {
    database = google_compute_instance.prod_database.network_interface[0].network_ip
    backend  = google_compute_instance.prod_backend.network_interface[0].network_ip
    ai       = google_compute_instance.prod_ai.network_interface[0].network_ip
  }
}

output "vm_names" {
  description = "VM instance names"
  value = {
    database = google_compute_instance.prod_database.name
    backend  = google_compute_instance.prod_backend.name
    ai       = google_compute_instance.prod_ai.name
  }
}

output "vm_zones" {
  description = "VM instance zones"
  value = {
    database = google_compute_instance.prod_database.zone
    backend  = google_compute_instance.prod_backend.zone
    ai       = google_compute_instance.prod_ai.zone
  }
}

# 로드밸런서/네트워킹 정보
output "load_balancer_ip" {
  description = "Global load balancer IP address"
  value       = google_compute_global_forwarding_rule.prod_forwarding_rule.ip_address
}

output "domain" {
  description = "Production domain"
  value       = var.domain
}

output "ssl_certificate_name" {
  description = "SSL certificate name"  
  value       = google_compute_managed_ssl_certificate.prod_ssl_cert.name
}

# 프론트엔드 정보
output "frontend_bucket" {
  description = "Frontend GCS bucket name"
  value       = google_storage_bucket.prod_frontend.name
}

output "frontend_bucket_url" {
  description = "Frontend GCS bucket URL"
  value       = google_storage_bucket.prod_frontend.url
}

output "cdn_backend_name" {
  description = "CDN backend bucket name"
  value       = google_compute_backend_bucket.prod_cdn_backend.name
}

# 서비스 엔드포인트
output "backend_service_name" {
  description = "Backend service name"
  value       = google_compute_backend_service.prod_backend_service.name
}

output "ai_service_name" {
  description = "AI service name"
  value       = google_compute_backend_service.prod_ai_service.name
}

# VPC 피어링 정보
output "vpc_peering_status" {
  description = "VPC peering status"
  value = {
    prod_to_shared = google_compute_network_peering.prod_to_shared.name
    shared_to_prod = google_compute_network_peering.shared_to_prod.name
  }
}

# Ansible 변수용 출력
output "ansible_inventory_data" {
  description = "Data for Ansible inventory"
  value = {
    internal_ips = {
      database = google_compute_instance.prod_database.network_interface[0].network_ip
      backend  = google_compute_instance.prod_backend.network_interface[0].network_ip
      ai       = google_compute_instance.prod_ai.network_interface[0].network_ip
    }
    jumpbox_ip = "34.22.110.81"  # Shared jumpbox IP
    domain     = var.domain
    environment = var.environment
  }
}

# 비용 추정 정보
output "estimated_monthly_cost" {
  description = "Estimated monthly cost breakdown (USD)"
  value = {
    database_vm     = "53.54"   # e2-standard-2
    backend_vm      = "53.54"   # e2-standard-2  
    ai_vm          = "80.96"   # e2-highmem-2
    disk_storage   = "15.00"   # Estimated disk costs
    network_egress = "10.00"   # Estimated network costs
    load_balancer  = "18.00"   # Global load balancer
    gcs_storage    = "2.00"    # Frontend storage
    ssl_certificate = "0.00"   # Managed SSL (free)
    total_estimated = "233.04"
  }
}
