# WireGuard 모듈 - VPN 서버 및 클라이언트 설정

# WireGuard 서버 설정 파일 생성
locals {
  wireguard_server_config = templatefile("${path.module}/templates/wg0.conf.tpl", {
    interface_address = var.wireguard_server_ip
    private_key       = var.wireguard_private_key
    listen_port       = var.wireguard_port
    clients           = var.wireguard_clients
  })

  wireguard_client_configs = {
    for client in var.wireguard_clients : client.name => templatefile("${path.module}/templates/client.conf.tpl", {
      client_private_key = client.private_key
      client_address     = client.address
      server_public_key  = var.wireguard_public_key
      server_endpoint    = "${var.wireguard_server_endpoint}:${var.wireguard_port}"
      allowed_ips        = var.allowed_ips
    })
  }

  wireguard_startup_script = templatefile("${path.module}/templates/install_wireguard.sh.tpl", {
    server_config = base64encode(local.wireguard_server_config)
  })
}
