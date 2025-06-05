#!/bin/bash
set -e

# Update system
apt-get update

# Install WireGuard
apt-get install -y wireguard

# Enable IP forwarding
echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf
sysctl -p

# Create WireGuard configuration
echo "${server_config}" | base64 -d > /etc/wireguard/wg0.conf

# Set proper permissions
chmod 600 /etc/wireguard/wg0.conf

# Enable and start WireGuard
systemctl enable wg-quick@wg0
systemctl start wg-quick@wg0

# Allow WireGuard through UFW if enabled
if command -v ufw &> /dev/null; then
    ufw allow 51820/udp
fi

echo "WireGuard installation and configuration completed"
