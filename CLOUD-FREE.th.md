# เอา Paperclip ขึ้น cloud แบบฟรี

เป้าหมาย: มี Paperclip บน cloud ที่เปิดได้จากทุกเครื่องผ่าน `https://<โดเมน>` โดยไม่เสียค่าเช่าเครื่อง ชุดนี้เป็น **instance แยก** จากเครื่องโน้ตบุ๊ก (`~/.paperclip`) ไม่ได้ย้ายข้อมูลข้ามกัน

## ทำไมถึงเลือก Oracle Cloud

ผู้ให้บริการที่ "ฟรีตลอด" และมีดิสก์เก็บข้อมูลถาวรแบบที่ Paperclip ต้องใช้ ตอนนี้เหลือ Oracle Cloud (Always Free) เจ้าเดียว:

| บริการ | ฟรีจริงไหม | เหมาะกับ Paperclip |
| --- | --- | --- |
| Oracle Cloud Always Free | ฟรีตลอด เครื่อง ARM 2 CPU / RAM 12 GB / ดิสก์ 200 GB | เหมาะ (image ของ Paperclip รองรับ ARM) |
| Railway | เครดิตทดลอง 5 ดอลลาร์แล้วหมด ต้องผูกบัตร | ไม่ฟรี ประมาณ 5-15 ดอลลาร์/เดือน |
| Fly.io | ไม่มีแพ็กเกจฟรีแล้ว | ประมาณ 5-10 ดอลลาร์/เดือน |
| Render / Koyeb ฟรี | RAM 256-512 MB และไม่มีดิสก์ถาวร | เล็กเกินไป ข้อมูลหายเมื่อ restart |

ข้อควรรู้ของ Oracle: ตอนสมัครต้องใส่บัตรเครดิตเพื่อยืนยันตัวตน (ไม่ตัดเงิน) และบางช่วงเครื่อง ARM ในภูมิภาคที่เลือกอาจเต็ม ต้องลองกดสร้างใหม่ภายหลัง

## สิ่งที่ต้องทำเอง (ฉันทำแทนไม่ได้)

1. สมัคร Oracle Cloud ที่ <https://www.oracle.com/cloud/free/> เลือก Home Region ใกล้ไทย (Singapore หรือ Tokyo)
2. สร้างเครื่อง: Compute → Instances → Create
   - Image: **Ubuntu 24.04** (เลือก aarch64)
   - Shape: **VM.Standard.A1.Flex** 2 OCPU / 12 GB (อยู่ในโควตา Always Free)
   - Boot volume: 50-100 GB
   - ใส่ SSH public key ของเครื่องคุณ (`~/.ssh/id_ed25519.pub`)
3. เปิดพอร์ตใน Oracle: Networking → Virtual Cloud Networks → Security List ของ subnet → Add Ingress Rules
   - Source `0.0.0.0/0`, TCP, Destination port `80`
   - Source `0.0.0.0/0`, TCP, Destination port `443`
4. ตั้งชื่อโดเมนฟรีที่ <https://www.duckdns.org> (เช่น `my-paperclip.duckdns.org`) ชี้ไปที่ Public IP ของเครื่อง (ถ้ามีโดเมนของบริษัทอยู่แล้ว ใช้ A record ก็ได้)
5. ส่ง Public IP กับชื่อโดเมนให้ฉัน หรือทำขั้นตอนถัดไปเอง

## ขั้นตอนบนเครื่อง cloud (ฉันทำให้ได้ถ้ามี SSH)

```bash
ssh ubuntu@<PUBLIC_IP>
git clone https://github.com/waenSaran/paperclip-cloud.git ~/paperclip-cloud
bash ~/paperclip-cloud/cloud-free/bootstrap-ubuntu.sh
exit   # ออกแล้ว ssh เข้าใหม่ เพื่อให้สิทธิ์ docker มีผล
```

```bash
cd ~/paperclip-cloud/cloud-free
cp .env.example .env
openssl rand -hex 32   # ใส่เป็น BETTER_AUTH_SECRET
openssl rand -hex 32   # ใส่เป็น PAPERCLIP_AGENT_JWT_SECRET
nano .env              # ใส่ PAPERCLIP_DOMAIN และ secret สองค่า
docker compose up -d
docker compose logs -f paperclip   # รอจนขึ้น health ok (ครั้งแรก 1-2 นาที)
```

เปิด `https://<โดเมน>` ได้เลย Caddy ขอใบรับรอง HTTPS ให้อัตโนมัติ

## เข้าใช้ครั้งแรก (โหมดต้องล็อกอิน)

บน cloud ตั้งเป็นโหมด `authenticated` ทุกคนต้องล็อกอิน ครั้งแรกระบบพิมพ์ลิงก์ "board-claim" ไว้ใน log:

```bash
docker compose logs paperclip | grep -i board-claim
```

เปิดลิงก์นั้นในเบราว์เซอร์ → สมัครบัญชีของคุณ → กด **Claim ownership** คุณจะเป็น admin ของ instance ลิงก์ใช้ได้ครั้งเดียว ถ้าหมดอายุให้ `docker compose restart paperclip` แล้วดู log ใหม่

ชวนเพื่อนร่วมทีม: ในเว็บไปที่ Settings → Members → Invites

## หลังล็อกอิน

สร้าง company และ agent ได้จากหน้าเว็บโดยตรง ใส่ API key ของ Anthropic/OpenAI ที่ Settings → Secrets

## สำรองข้อมูล

```bash
./backup.sh          # ได้ไฟล์ .sql.gz ใน cloud-free/backups
```

ตั้ง cron ให้รันทุกคืน และ copy โฟลเดอร์ `backups` กลับมาเก็บที่เครื่องตัวเองเป็นระยะ ไฟล์กุญแจ `secrets/master.key` อยู่ใน volume `paperclip-data` ดึงออกมาเก็บด้วย:

```bash
docker compose cp paperclip:/paperclip/instances/default/secrets/master.key ./master.key.backup
```

## อัปเดตเวอร์ชัน

แก้ `PAPERCLIP_IMAGE_TAG` ใน `.env` แล้ว:

```bash
./backup.sh && docker compose pull && docker compose up -d
```

## ถ้าอยากใช้ฐานข้อมูลภายนอก

ค่าเริ่มต้นใช้ Postgres ที่ฝังมาในภาพ Docker (เก็บใน volume) พอสำหรับทีมเล็ก ถ้าอยากแยกฐานข้อมูลไปไว้ที่ Neon หรือ Supabase (มีแพ็กเกจฟรี) ใส่ `DATABASE_URL` ใน `.env` แล้วรัน:

```bash
docker compose -f docker-compose.yml -f docker-compose.external-db.yml up -d
```
