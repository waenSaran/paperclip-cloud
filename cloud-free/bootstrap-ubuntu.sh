#!/usr/bin/env bash
# One-time server prep for Ubuntu 22.04/24.04 (x86_64 or ARM64, e.g. Oracle
# Cloud Always Free). Run as a normal user with sudo:
#
#   bash bootstrap-ubuntu.sh
#
# Installs Docker from Ubuntu's own packages (no curl | sh), opens ports 80/443
# in the OS firewall (Oracle images block them by default), and adds you to the
# docker group. Log out and back in afterwards.
set -euo pipefail

sudo apt-get update
sudo apt-get install -y docker.io docker-compose-v2 git curl

sudo systemctl enable --now docker
sudo usermod -aG docker "$USER"

# Oracle Cloud Ubuntu images ship iptables rules that drop everything except SSH.
if command -v iptables >/dev/null 2>&1; then
  for port in 80 443; do
    sudo iptables -C INPUT -p tcp --dport "$port" -j ACCEPT 2>/dev/null \
      || sudo iptables -I INPUT 6 -p tcp --dport "$port" -j ACCEPT
  done
  if command -v netfilter-persistent >/dev/null 2>&1; then
    sudo netfilter-persistent save
  else
    sudo apt-get install -y iptables-persistent >/dev/null 2>&1 || true
    sudo netfilter-persistent save 2>/dev/null || true
  fi
fi

echo
echo "Docker $(docker --version | cut -d, -f1) ready. Log out and back in, then:"
echo "  git clone https://github.com/waenSaran/paperclip-cloud.git ~/paperclip-cloud"
echo "  cd ~/paperclip-cloud/cloud-free && cp .env.example .env && nano .env"
echo "  docker compose up -d"
