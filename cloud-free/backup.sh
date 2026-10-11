#!/usr/bin/env bash
# Dump the Paperclip database from the container to ./backups/<date>.sql.gz
# Add to cron, e.g.:  0 3 * * * /home/ubuntu/paperclip-cloud/cloud-free/backup.sh
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p backups
docker compose exec -T paperclip node /app/cli/dist/index.js instance database-backup >/dev/null
docker compose cp paperclip:/paperclip/instances/default/data/backups/. ./backups/
ls -t backups | head -1
