#!/usr/bin/env bash
set -euo pipefail

SERVICES=("nginx" "cloudflared" "docker")

echo "=========================================="
echo " 🖥️  SERVER HEALTHCHECK - $(hostname)"
echo " 📅  $(date '+%Y-%m-%d %H:%M:%S')"
echo "=========================================="

for svc in "${SERVICES[@]}"; do
    if systemctl is-active --quiet "$svc" 2>/dev/null; then
        echo "✅ [ACTIVE]   $svc"
    else
        echo "⚠️  [INACTIVE] $svc"
    fi
done

echo "------------------------------------------"
echo "💾 Memory Usage:"
free -h | awk '/^Mem:/ {print "   Used: " $3 " / Total: " $2 " (Available: " $7 ")"}'

echo "💿 Disk Usage (/):"
df -h / | awk 'NR==2 {print "   Used: " $3 " / Total: " $2 " (" $5 ")"}'

echo "🌐 Local Nginx HTTP Check:"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1 || echo "000")
echo "   HTTP Status: $HTTP_CODE"
echo "=========================================="
