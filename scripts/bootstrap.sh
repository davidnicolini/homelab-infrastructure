#!/usr/bin/env bash
# ==============================================================================
# Idempotent Server Bootstrap Script (Debian / Ubuntu - On-Premises & Cloud)
# Author: David Nicolini (https://davidnicolini.com.br)
# ==============================================================================
set -euo pipefail

DOMAIN="davidnicolini.com.br"
WEB_ROOT="/var/www/${DOMAIN}"
PORTFOLIO_REPO="https://github.com/davidnicolini/davidnicolini.github.io.git"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ $EUID -ne 0 ]]; then
   echo "❌ Run this script as root (sudo ./scripts/bootstrap.sh)"
   exit 1
fi

echo "🚀 [1/6] Updating system packages & installing base dependencies..."
apt-get update -y && apt-get upgrade -y
apt-get install -y curl wget git ufw nginx ca-certificates gnupg lsb-release

echo "🐳 [2/6] Installing Docker Engine & Docker Compose plugin..."
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com | sh
    systemctl enable --now docker
else
    echo "   -> Docker already installed, skipping."
fi

echo "🌐 [3/6] Deploying web root and configuring Nginx..."
mkdir -p "${WEB_ROOT}"
if [ ! -d "${WEB_ROOT}/.git" ]; then
    git clone "${PORTFOLIO_REPO}" "${WEB_ROOT}" || echo "⚠️ Clone skipped (check repo URL/visibility)"
else
    git -C "${WEB_ROOT}" pull --ff-only
fi
chown -R www-data:www-data "${WEB_ROOT}"

cp "${REPO_DIR}/nginx/sites-available/davidnicolini.conf" "/etc/nginx/sites-available/${DOMAIN}"
ln -sf "/etc/nginx/sites-available/${DOMAIN}" "/etc/nginx/sites-enabled/${DOMAIN}"
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl reload nginx

echo "🔒 [4/6] Applying SSHD Hardening..."
cp "${REPO_DIR}/security/99-hardening.conf" /etc/ssh/sshd_config.d/99-hardening.conf
systemctl reload ssh || systemctl reload sshd

echo "🛡️  [5/6] Enforcing UFW Firewall rules..."
bash "${REPO_DIR}/security/ufw-rules.sh"

echo "☁️  [6/6] Checking Cloudflare Tunnel daemon (cloudflared)..."
if ! command -v cloudflared &> /dev/null; then
    curl -L --output /tmp/cloudflared.deb https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
    dpkg -i /tmp/cloudflared.deb
    rm -f /tmp/cloudflared.deb
    echo "   -> cloudflared installed. Authenticate with: cloudflared tunnel login"
else
    echo "   -> cloudflared already installed."
fi

echo "✅ Bootstrap complete! Running final healthcheck..."
bash "${REPO_DIR}/scripts/healthcheck.sh"
