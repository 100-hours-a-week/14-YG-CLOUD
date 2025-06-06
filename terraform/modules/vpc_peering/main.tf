# VPC 피어링 모듈 - 공통 관리 VPC와 환경별 VPC 연결

# 공통 관리 VPC에서 환경별 VPC로의 피어링
resource "google_compute_network_peering" "management_to_environments" {
  for_each = var.environment_vpcs

  name         = "${var.project_name}-mgmt-to-${each.key}"
  network      = var.management_vpc_self_link
  peer_network = each.value

  # Import/Export 커스텀 라우트 허용
  import_custom_routes = true
  export_custom_routes = true

  # 서브넷 라우트 Import/Export 허용  
  import_subnet_routes_with_public_ip = false
  export_subnet_routes_with_public_ip = false
}

# 환경별 VPC에서 공통 관리 VPC로의 피어링 (양방향)
resource "google_compute_network_peering" "environments_to_management" {
  for_each = var.environment_vpcs

  name         = "${var.project_name}-${each.key}-to-mgmt"
  network      = each.value
  peer_network = var.management_vpc_self_link

  # Import/Export 커스텀 라우트 허용
  import_custom_routes = true
  export_custom_routes = true

  # 서브넷 라우트 Import/Export 허용
  import_subnet_routes_with_public_ip = false
  export_subnet_routes_with_public_ip = false

  # 피어링 의존성 설정
  depends_on = [google_compute_network_peering.management_to_environments]
}

# 라우트 추가 (VPC 피어링이 자동으로 처리하므로 불필요)
# resource "google_compute_route" "management_to_environment_routes" {
#   for_each = var.environment_networks
#
#   name             = "${var.project_name}-mgmt-to-${each.key}-route"
#   dest_range       = each.value
#   network          = var.management_vpc_self_link
#   next_hop_gateway = "default-internet-gateway"
#   priority         = 1000
#
#   depends_on = [google_compute_network_peering.management_to_environments]
# }
