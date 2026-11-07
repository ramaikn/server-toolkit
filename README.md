# server-toolkit

Skrip untuk memasang dan memeriksa server yang menjalankan n8n + PostgreSQL dengan Docker. Dibuat untuk latihan dan pekerjaan sehari-hari: satu perintah pasang, satu perintah cek.

Target: Ubuntu 24.04 (atau Debian dengan `apt`). Dijalankan sebagai root atau dengan `sudo`.

## Cara pakai di server (4 baris)
```bash
git clone https://github.com/ramaikn/server-toolkit
cd server-toolkit
less install.sh        # baca dulu sebelum menjalankan (keluar dengan q)
sudo bash install.sh
```

Yang ditanyakan `install.sh`: password database (kosongkan agar dibuatkan acak), zona waktu, dan apakah n8n boleh dibuka dari jaringan. Sisanya otomatis.

Cek server kapan saja (hanya membaca):
```bash
bash health-check.sh
```

## Yang dilakukan install.sh, berurutan
1. Pastikan dijalankan sebagai root dan server memakai `apt`.
2. Pasang Docker dan Compose kalau belum ada.
3. Buat folder `/opt/n8n-stack`, salin `templates/compose.yaml`.
4. Buat `.env` (password, kunci enkripsi n8n, zona waktu). Izin file 600.
5. `docker compose up -d`, lalu menunggu n8n menjawab di `/healthz`.

Aman dijalankan ulang: kalau `.env` sudah ada, ditanya mau dipakai ulang (jawab `y` agar password dan kunci tidak berubah). Skrip tidak pernah menghapus data atau volume.

## Membuka n8n dari komputermu
n8n hanya terbuka di server itu sendiri (`127.0.0.1`). Dari komputermu pakai tunnel SSH:
```powershell
ssh -L 5678:localhost:5678 user@ip-server
```
Lalu buka `http://localhost:5678` di browser.

## Latihan: soal rusak
`lab/compose.broken.yaml` berisi n8n yang terus restart karena satu kesalahan. Jalankan, lalu cari penyebabnya dengan `docker compose ps` dan `docker compose logs --tail 30 n8n` sebelum membuka berkasnya. Petunjuk bersihkan ada di komentar atas berkas itu.

## Aturan keselamatan
- File `.env` berisi rahasia: jangan dikirim, jangan masuk Git (sudah di `.gitignore`).
- Jangan jalankan `docker compose down -v`, `docker system prune`, atau `rm -rf` di server kantor tanpa izin. `down -v` menghapus data database.
- Tanyakan izin sebelum memasang apa pun di server milik orang lain.

## Struktur
| Lokasi | Isi |
|---|---|
| `install.sh` | Pemasangan otomatis |
| `health-check.sh` | Cek kesehatan 5 langkah |
| `templates/compose.yaml` | Susunan layanan n8n + Postgres |
| `.env.example` | Contoh isi `.env` |
| `lib/common.sh` | Fungsi log dan prompt bersama |
| `lab/` | Soal latihan |
| `logs/` | Log skrip (tidak masuk Git) |
| `docs/agent/` | Dokumentasi untuk agen dan riwayat kerja |
