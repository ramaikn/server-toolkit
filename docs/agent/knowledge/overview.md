# Gambaran repo server-toolkit

## Tujuan
Memasang dan memeriksa server Linux yang menjalankan n8n + PostgreSQL dengan Docker secara cepat dan bisa dijelaskan. Dibuat sebagai alat latihan dan untuk pemakaian kerja nyata.

## Struktur
- `install.sh`: pemasangan interaktif. Berurutan: cek root/apt, pasang Docker + Compose, siapkan `/opt/n8n-stack`, tulis `.env`, `docker compose up -d`, tunggu `/healthz` n8n.
- `health-check.sh`: lima pemeriksaan (uptime, disk, memori, docker, port). Hanya membaca.
- `templates/compose.yaml`: db (postgres:16-alpine, healthcheck) dan n8n. Host DB n8n = nama layanan `db`.
- `lib/common.sh`: `log/info/warn/die`, `ask_yes_no`, `ask_value`. Log ke `logs/toolkit.log`.
- `lab/compose.broken.yaml`: soal latihan, n8n memakai host `127.0.0.1` sehingga restart terus.

## Keputusan penting
- Docker dan Compose dipasang dari paket Ubuntu `docker.io` dan `docker-compose-v2`, dua perintah terpisah lalu diverifikasi (pada VPS uji, pemasangan gabungan sebelumnya tidak memasang Compose).
- n8n dibuka hanya di `127.0.0.1` secara bawaan; akses dari komputer lewat tunnel SSH.
- Password dibatasi `[A-Za-z0-9._-]` agar aman di `.env`.
- Skrip tidak pernah menjalankan perintah yang menghapus data (`down -v`, `prune`, `rm -rf`).

## Menjalankan dan menguji
Server uji: VPS Angkasaham.id (Ubuntu 24.04, memori sekitar 1 GB). Jalankan `sudo bash install.sh`, lalu `bash health-check.sh`. Pemeriksaan sintaks: `bash -n install.sh health-check.sh lib/common.sh`.
