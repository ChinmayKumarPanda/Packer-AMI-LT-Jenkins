#!/bin/bash
set -euo pipefail

LOG_PREFIX="[AL2023-INSTALL]"

echo "$LOG_PREFIX Updating system packages..."
sudo dnf update -y

echo "$LOG_PREFIX Installing required packages (Node.js, npm, git, tar, gzip)..."
# AL2023 repos include Node.js (currently 18.x in most channels). If you need a newer version, see NodeSource block below.
sudo dnf install -y nodejs npm git tar gzip

# --- OPTIONAL: Install Node.js from NodeSource (uncomment if you need a newer LTS than repo provides) ---
# curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash -
# sudo dnf install -y nodejs

echo "$LOG_PREFIX Installing PM2 globally..."
sudo npm install -g pm2

echo "$LOG_PREFIX Creating /opt/node-app and copying application files..."
sudo mkdir -p /opt/node-app
sudo cp -r /tmp/node-app/. /opt/node-app/
sudo chown -R ec2-user:ec2-user /opt/node-app

echo "$LOG_PREFIX Installing app dependencies (production)..."
cd /opt/node-app
# Use sudo -u ec2-user so node_modules are owned by the normal login user
sudo -u ec2-user npm install --production || sudo -u ec2-user npm install

# ----------------------------------------------------------------
# PM2 APP STARTUP
# ----------------------------------------------------------------
APP_ENTRY="index.js"   # change if your main file is different (e.g., server.js, app.js)
if [[ ! -f "$APP_ENTRY" ]]; then
  echo "$LOG_PREFIX WARNING: $APP_ENTRY not found in /opt/node-app. Listing files:"
  ls -al
fi

echo "$LOG_PREFIX Starting app under PM2..."
# Start as ec2-user so PM2 home is in that user’s path
sudo -u ec2-user pm2 start "$APP_ENTRY" --name node-app || true

echo "$LOG_PREFIX Generating PM2 startup systemd unit..."
# This generates a systemd unit that runs PM2 for ec2-user
sudo -u ec2-user pm2 startup systemd -u ec2-user --hp /home/ec2-user

echo "$LOG_PREFIX Saving PM2 process list..."
sudo -u ec2-user pm2 save

# After pm2 startup generates instructions, it usually prints a command to run as root.
# We’ll auto-detect & execute it if present in pm2 logs (best effort). Safe to ignore if it fails.
PM2_CMD=$(sudo -u ec2-user pm2 startup systemd -u ec2-user --hp /home/ec2-user | grep 'sudo' || true)
if [[ -n "$PM2_CMD" ]]; then
  echo "$LOG_PREFIX Running PM2 root setup command..."
  eval "$PM2_CMD" || true
fi

echo "$LOG_PREFIX Enabling and starting systemd user service (if created)..."
# In many cases pm2 startup already did this. We'll be defensive:
sudo systemctl daemon-reload || true
sudo systemctl enable pm2-ec2-user || true
sudo systemctl start pm2-ec2-user || true

echo "$LOG_PREFIX Done."
