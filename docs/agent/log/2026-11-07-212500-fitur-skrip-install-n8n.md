# Log: skrip install n8n + Postgres dan cek kesehatan server

- Waktu: 2026-11-07 21:25 WITA
- Jenis: fitur
- Ringkasan: repo `server-toolkit` dibuat dari nol dengan skrip pasang otomatis (`install.sh`), cek kesehatan (`health-check.sh`), template Compose, dan soal latihan.

## Perubahan dan keputusan
- Docker dan Compose dipasang lewat dua perintah `apt` terpisah, lalu diverifikasi. Alasan: pada VPS uji, pemasangan gabungan sebelumnya hanya memasang Docker.
- n8n dibuka hanya di `127.0.0.1`; akses lewat tunnel SSH.
- Password dibatasi `[A-Za-z0-9._-]`, minimal 8 karakter, atau dibuatkan acak.
- Berkas `.gitattributes` memaksa akhiran baris LF untuk `*.sh` agar tidak rusak di Linux.

## Lokasi
`C:\Users\Ramaikn\code\server-toolkit` (README di akar, peta di `docs/agent/README.md`).

## Verifikasi
- `bash -n` lolos untuk ketiga skrip. Akhiran baris sudah LF.
- Belum diuji jalan di server. `shellcheck` tidak tersedia di PC ini. Uji di VPS Angkasaham dikerjakan user (task langkah 9); hasilnya dicatat di log baru.
- Repo belum di-commit dan belum dibuat di GitHub.
