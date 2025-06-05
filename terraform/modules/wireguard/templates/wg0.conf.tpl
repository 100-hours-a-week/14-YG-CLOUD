[Interface]
Address = ${interface_address}
PrivateKey = ${private_key}
ListenPort = ${listen_port}
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE

%{ for client in clients ~}
# ${client.name}
[Peer]
PublicKey = ${client.public_key}
AllowedIPs = ${client.address}

%{ endfor ~}
