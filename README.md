# paperclip-cloud

Deploy [Paperclip](https://paperclip.ing) (the open-source app for running AI agent teams) on a free always-on cloud VM with automatic HTTPS.

- `CLOUD-FREE.th.md` — step-by-step guide in Thai (Oracle Cloud Always Free + DuckDNS + Caddy)
- `cloud-free/docker-compose.yml` — official Paperclip image in authenticated/public mode behind Caddy
- `cloud-free/docker-compose.external-db.yml` — optional overlay for a hosted Postgres (Neon / Supabase)
- `cloud-free/bootstrap-ubuntu.sh` — one-time server prep (Docker, firewall ports 80/443)
- `cloud-free/backup.sh` — database dump to `cloud-free/backups/`

Quick start on the server:

```bash
git clone https://github.com/waenSaran/paperclip-cloud.git ~/paperclip-cloud
bash ~/paperclip-cloud/cloud-free/bootstrap-ubuntu.sh   # then log out / in
cd ~/paperclip-cloud/cloud-free
cp .env.example .env && nano .env                         # domain + two secrets
docker compose up -d
docker compose logs paperclip | grep -i board-claim       # first-admin link
```

Local laptop install follows the official docs instead: `npx paperclipai onboard --yes` (data in `~/.paperclip`).
