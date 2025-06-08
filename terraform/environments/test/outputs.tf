output "jumpbox_external_ip" {
  description = "Jump Box external IP address"
  value       = module.jumpbox_ip.ip_address
}

output "frontend_hosting" {
  description = "Frontend hosting information"
  value = {
    bucket_name = module.frontend_hosting.bucket_name
    cdn_ip      = module.frontend_hosting.cdn_ip_address
    url         = module.frontend_hosting.frontend_url
    upload_cmd  = module.frontend_hosting.upload_instructions
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
    jumpbox  = module.jumpbox.internal_ip
    backend  = module.backend.internal_ip
    ai       = module.ai.internal_ip
    database = module.database.internal_ip
  }
}

# WireGuard 클라이언트 설정 파일들 - Ansible로 관리됨
# output "wireguard_client_configs" {
#   description = "WireGuard client configuration files"
#   value       = module.wireguard.client_configs
#   sensitive   = true
# }

# Load Balancer 정보
output "load_balancer" {
  description = "Load Balancer information"
  value = {
    external_ip = module.load_balancer.load_balancer_ip
    backend_url = "http://${module.load_balancer.load_balancer_ip}/api"
    ai_url      = "http://${module.load_balancer.load_balancer_ip}/generation"
  }
}

# Ansible 인벤토리를 위한 정보
output "ansible_inventory" {
  description = "Ansible inventory information"
  value = {
    jumpbox = {
      ansible_host = module.jumpbox_ip.ip_address
      internal_ip  = module.jumpbox.internal_ip
      role         = "jumpbox"
    }
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
