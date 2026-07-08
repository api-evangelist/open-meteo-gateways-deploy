#!/usr/bin/env bash
# Bootstrap the Open-Meteo gateways host from scratch.
#
# Clones the three sibling demo repos next to this one and brings the whole
# stack (3 gateways + Caddy) up. Safe to re-run: existing clones are pulled.
#
# Prereqs on the host: git, docker, docker compose. DNS for
# weather-{tyk,krakend,agentgateway}.apievangelist.com must already point at
# this host, and ports 80/443 must be open, for Caddy to get certificates.
set -euo pipefail

ORG="https://github.com/api-evangelist"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARENT="$(dirname "$HERE")"

for repo in open-meteo-tyk-demo open-meteo-krakend open-meteo-agentgateway; do
  dest="$PARENT/$repo"
  if [ -d "$dest/.git" ]; then
    echo "==> updating $repo"
    git -C "$dest" pull --ff-only
  else
    echo "==> cloning $repo"
    git clone "$ORG/$repo.git" "$dest"
  fi
done

echo "==> starting stack"
cd "$HERE"
docker compose pull
docker compose up -d

echo
echo "Up. Caddy will fetch/renew TLS certs on first request. Verify:"
echo "  curl -s https://weather-tyk.apievangelist.com/weather/forecast?latitude=40.7128\&longitude=-74.006\&current=temperature_2m\&timezone=auto"
