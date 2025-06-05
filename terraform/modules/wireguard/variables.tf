variable "wireguard_server_ip" {
  description = "WireGuard server IP address"
  type        = string
  default     = "10.8.0.1/24"
}

variable "wireguard_port" {
  description = "WireGuard listen port"
  type        = number
  default     = 51820
}

variable "wireguard_private_key" {
  description = "WireGuard server private key"
  type        = string
  sensitive   = true
}

variable "wireguard_public_key" {
  description = "WireGuard server public key"
  type        = string
}

variable "wireguard_server_endpoint" {
  description = "WireGuard server endpoint (public IP)"
  type        = string
}

variable "wireguard_clients" {
  description = "List of WireGuard clients"
  type = list(object({
    name        = string
    address     = string
    private_key = string
    public_key  = string
  }))
  default = []
}

variable "allowed_ips" {
  description = "Allowed IPs for clients"
  type        = string
  default     = "10.8.0.0/24,10.0.0.0/24"
}
