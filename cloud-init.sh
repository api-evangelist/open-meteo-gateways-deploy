#!/bin/bash
set -eux
exec > /var/log/weather-gw-userdata.log 2>&1

# Docker + compose plugin (Amazon Linux 2023, arm64)
dnf install -y docker git
systemctl enable --now docker
usermod -aG docker ec2-user
mkdir -p /usr/libexec/docker/cli-plugins
curl -fsSL https://github.com/docker/compose/releases/download/v2.29.7/docker-compose-linux-aarch64 \
  -o /usr/libexec/docker/cli-plugins/docker-compose
chmod +x /usr/libexec/docker/cli-plugins/docker-compose

# Deploy repo + the three gateway repos as siblings
cd /home/ec2-user
git clone https://github.com/api-evangelist/open-meteo-gateways-deploy.git
git clone https://github.com/api-evangelist/open-meteo-tyk-demo.git
git clone https://github.com/api-evangelist/open-meteo-krakend.git
git clone https://github.com/api-evangelist/open-meteo-agentgateway.git
chown -R ec2-user:ec2-user /home/ec2-user

# Bring the stack up. Caddy will retry ACME until the Elastic IP is attached
# and the subdomains resolve here.
cd /home/ec2-user/open-meteo-gateways-deploy
docker compose pull
docker compose up -d
touch /home/ec2-user/USERDATA_DONE
