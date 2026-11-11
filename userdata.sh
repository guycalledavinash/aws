#!/bin/bash
set -euo pipefail

echo "Updating package indexes..."
apt-get update

echo "Installing Nginx..."
DEBIAN_FRONTEND=noninteractive apt-get install -y nginx

echo "Writing the custom Nginx homepage..."
cat > /var/www/html/index.nginx-debian.html <<'EOF'
AVINASH - A
EOF

echo "Enabling and starting Nginx..."
systemctl enable --now nginx

echo "Verifying Nginx is active..."
if systemctl is-active --quiet nginx; then
    echo "Nginx is active and the EC2 bootstrap completed successfully."
else
    echo "Nginx is not active." >&2
    exit 1
fi
