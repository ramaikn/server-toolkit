# server-toolkit

Skrip untuk memasang, memeriksa, dan mencadangkan server yang menjalankan n8n + PostgreSQL dengan Docker, dengan WhatsApp gateway (WAHA) opsional dan template alur n8n. Satu perintah pasang, satu perintah cek, satu perintah backup.

Target: Ubuntu 24.04 (atau Debian dengan `apt`). Dijalankan sebagai root atau dengan `sudo`.

## Cara pakai di server (4 baris)
```bash
git clone https://github.com/ramaikn/server-toolkit
cd server-toolkit
less install.sh        # baca dulu sebelum menjalankan (keluar dengan q)
sudo bash install.sh
```

Yang ditanyakan `install.sh`: password database (kosongkan agar dibuatkan acak), zona waktu, apakah n8n boleh dibuka dari jaringan, dan apakah WAHA (WhatsApp) dipasang. Sisanya otomatis.

## Perintah harian
| Perintah | Fungsi |
|---|---|
| `bash health-check.sh` | Cek kesehatan 5 langkah (uptime, disk, memori, docker, port). Hanya membaca. |
| `sudo bash backup.sh` | Cadangkan database n8n + salinan `.env`. Menyimpan 7 terbaru. |
| `sudo bash restore.sh` | Lihat daftar backup. |
| `sudo bash restore.sh <file>` | Pulihkan dari file itu. Meminta ketik `RESTORE` dan membuat backup pengaman dulu. |

## Yang dilakukan install.sh, berurutan
1. Pastikan dijalankan sebagai root dan server memakai `apt`.
2. Pasang Docker dan Compose kalau belum ada.
3. Buat folder `/opt/n8n-stack`, salin `templates/compose.yaml`.
4. Buat `.env` (password, kunci enkripsi n8n, zona waktu, opsi WAHA). Izin file 600.
5. `docker compose up -d`, lalu menunggu n8n menjawab di `/healthz`.

Aman dijalankan ulang: kalau `.env` sudah ada, ditanya mau dipakai ulang (jawab `y` agar password dan kunci tidak berubah). `install.sh` tidak pernah menghapus data atau volume.

## Membuka n8n dari komputermu
n8n hanya terbuka di server itu sendiri (`127.0.0.1`). Dari komputermu pakai tunnel SSH:
```powershell
ssh -L 5678:localhost:5678 user@ip-server
```
Lalu buka `http://localhost:5678` di browser. Dengan WAHA, dashboard WhatsApp di port 3000 dengan cara yang sama (`-L 3000:localhost:3000`).

## Backup dan restore
- Backup disimpan di `/opt/n8n-stack/backups/` (folder 700, file 600): `n8n-db-TANGGAL.sql.gz` dan `env-TANGGAL.bak`.
- `.env` ikut dicadangkan karena berisi `N8N_ENCRYPTION_KEY`. Tanpa kunci itu, kredensial di dalam n8n tidak bisa dibuka setelah dipulihkan.
- Salin backup juga ke tempat lain (komputer lain atau cloud). Backup di server yang sama tidak menolong kalau diskinya rusak.
- Jadwal harian lewat cron: `0 2 * * * cd /lokasi/server-toolkit && bash backup.sh >/dev/null 2>&1`
- Backup lama yang melebihi `BACKUP_KEEP` (bawaan 7) dihapus otomatis, hanya file dengan nama pola backup. Isi `BACKUP_KEEP=0` untuk menonaktifkan penghapusan.

## WhatsApp (WAHA, opsional)
- Pilih `y` saat `install.sh` menanyakan WAHA. Layanan `waha` jalan di port 3000 (hanya `127.0.0.1`), kunci API dan password dashboard dibuat acak di `.env`.
- Dari n8n, alamat WAHA adalah `http://waha:3000` (nama layanan, bukan `localhost`).
- Peringatan: WAHA tidak resmi. Nomor bisa diblokir WhatsApp, terutama kalau mengirim massal. Untuk produksi, pertimbangkan WhatsApp Business Cloud API resmi.
- Setelah dipasang, buka dashboard WAHA lewat tunnel, mulai sesi `default`, lalu scan QR dari WhatsApp di HP.

## Template alur n8n (`workflows/`)
Impor lewat n8n: menu Workflows, Import from File.
| Berkas | Fungsi | Yang diganti setelah impor |
|---|---|---|
| `wa-masuk-ke-sheets.json` | Webhook menerima pesan WA, dirapikan, dicatat ke Google Sheets. | ID spreadsheet, nama tab, kredensial Google. Webhook WAHA diarahkan ke Production URL. |
| `sheets-ke-wa.json` | Tiap 5 menit baca Sheets, kirim WA untuk baris yang kolom `Terkirim` kosong, lalu isi `Ya`. | ID spreadsheet, nama tab, kredensial Google, kunci API WAHA. Kolom wajib: `Nomor`, `Pesan`, `Terkirim`. |

Format kolom `Nomor`: `628123456789` (tanpa `+` dan tanpa `0` di depan). Template ini belum diuji impor langsung di n8n; kalau ada node yang merah setelah impor, cek nama field di Output node sebelumnya.

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
| `backup.sh`, `restore.sh` | Cadangkan dan pulihkan database n8n |
| `templates/compose.yaml` | Susunan layanan n8n + Postgres (+ WAHA) |
| `workflows/` | Template alur n8n siap impor |
| `.env.example` | Contoh isi `.env` |
| `lib/common.sh` | Fungsi log, prompt, dan pemeriksaan bersama |
| `lab/` | Soal latihan |
| `logs/` | Log skrip (tidak masuk Git) |
| `docs/agent/` | Dokumentasi untuk agen dan riwayat kerja |
