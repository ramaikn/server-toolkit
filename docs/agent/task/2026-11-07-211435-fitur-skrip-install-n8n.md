# Task: skrip install n8n + Postgres dan cek kesehatan server

Dibuat: 2026-11-07 21:14 WITA

1. [x] Buat struktur folder dan `git init` lokal.
2. [x] `lib/common.sh`: fungsi log, tanya, dan keluar dengan pesan jelas.
3. [x] `install.sh`: cek root dan apt, pasang Docker + Compose, minta password, tulis `.env`, jalankan stack, tunggu n8n sehat. (Sintaks diperiksa; uji jalan di server ada di langkah 9.)
4. [x] `health-check.sh`: uptime, disk, memori, docker, port (hanya membaca). (Sintaks diperiksa; uji jalan di langkah 9.)
5. [x] `templates/compose.yaml` dan `.env.example` (host database memakai nama layanan `db`).
6. [x] `lab/compose.broken.yaml`: soal latihan dengan satu kesalahan sengaja.
7. [x] `README.md` dan dokumen `docs/agent` (peta, knowledge).
8. [x] Periksa sintaks: `bash -n` pada semua skrip.
9. [ ] Uji `install.sh` dan `health-check.sh` di VPS Angkasaham (dikerjakan user, hasilnya dicatat di log baru).
