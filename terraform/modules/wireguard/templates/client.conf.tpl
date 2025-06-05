[Interface]
PrivateKey = ${client_private_key}
Address = ${client_address}
DNS = 8.8.8.8

[Peer]
PublicKey = ${server_public_key}
Endpoint = ${server_endpoint}
AllowedIPs = ${allowed_ips}
PersistentKeepalive = 25
