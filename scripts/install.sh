#!/bin/bash
set -euo pipefail

echo "[AL2023-INSTALL] Updating system packages..."
sudo dnf update -y

echo "[AL2023-INSTALL] Installing required packages (Node.js, npm, git)..."
sudo dnf install -y nodejs git

# Copy app
echo "[AL2023-INSTALL] Deploying app to /opt/node-app..."
sudo mkdir -p /opt/node-app
sudo cp -r /tmp/node-app/* /opt/node-app/
sudo chown -R ec2-user:ec2-user /opt/node-app

# Install app dependencies
echo "[AL2023-INSTALL] Installing npm dependencies..."
cd /opt/node-app
npm ci --omit=dev || npm install --production

# Create systemd unit
echo "[AL2023-INSTALL] Creating systemd service..."
sudo tee /etc/systemd/system/node-app.service >/dev/null <<'EOF'
[Unit]
Description=Node App
After=network.target

[Service]
Type=simple
User=ec2-user
WorkingDirectory=/opt/node-app
ExecStart=/usr/bin/node /opt/node-app/index.js
Restart=on-failure
Environment=NODE_ENV=production PORT=3000

[Install]
WantedBy=multi-user.target
EOF

# Enable but don’t start now (we're baking an image)
sudo systemctl daemon-reload
sudo systemctl enable node-app

echo "[AL2023-INSTALL] Done."
exit 0
