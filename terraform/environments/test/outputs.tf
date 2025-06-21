# Frontend hosting information (Option 4)
output "frontend_hosting" {
  description = "Frontend hosting information"
  value = {
    bucket_name    = module.frontend_hosting.bucket_name
    upload_cmd     = module.frontend_hosting.upload_instructions
    main_url       = module.load_balancer.frontend_url
    main_ip        = module.load_balancer.main_ip_address
  }
}

output "vpc_name" {
  description = "VPC network name"
  value       = module.network.vpc_name
}

output "subnet_name" {
  description = "Subnet name"
  value       = module.network.subnet_name
}

# VM 내부 IP 주소들
output "vm_internal_ips" {
  description = "Internal IP addresses of all VMs"
  value = {
    backend  = module.backend.internal_ip
    ai       = module.ai.internal_ip
    database = module.database.internal_ip
  }
}

# Load Balancer 정보 (Option 4)
output "load_balancer" {
  description = "Main Load Balancer information (Option 4)"
  value = {
    main_ip       = module.load_balancer.main_ip_address
    frontend_url  = module.load_balancer.frontend_url
    backend_url   = "${module.load_balancer.frontend_url}/api"
    ai_url        = "${module.load_balancer.frontend_url}/generation"
    ssl_cert_id   = module.load_balancer.ssl_certificate_id
  }
}

# Ansible 인벤토리를 위한 정보 - shared-jumpbox 사용
output "ansible_inventory" {
  description = "Ansible inventory information"
  value = {
    backend = {
      ansible_host = module.backend.internal_ip
      internal_ip  = module.backend.internal_ip
      role         = "backend"
    }
    ai = {
      ansible_host = module.ai.internal_ip
      internal_ip  = module.ai.internal_ip
      role         = "ai"
    }
    database = {
      ansible_host = module.database.internal_ip
      internal_ip  = module.database.internal_ip
      role         = "database"
    }
  }
}
