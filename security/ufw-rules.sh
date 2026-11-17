#!/usr/bin/env bash
set -euo pipefail

echo "[*] Applying Zero-Trust host firewall rules..."
ufw --force reset
ufw default deny incoming
ufw default allow outgoing

# Restrict SSH strictly to private RFC1918 LAN subnets
ufw allow from 192.168.0.0/16 to any port 22 proto tcp comment 'LAN SSH Admin'
ufw allow from 10.0.0.0/8 to any port 22 proto tcp comment 'VPN/Internal SSH Admin'

# Ports 80/443 remain CLOSED publicly (traffic enters via outbound Cloudflare Tunnel)
ufw --force enable
ufw status verbose
