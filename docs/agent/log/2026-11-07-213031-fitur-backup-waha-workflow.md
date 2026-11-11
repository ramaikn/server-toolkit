# Log: backup/restore, WAHA opsional, template alur n8n

- Waktu: 2026-11-07 21:30 WITA
- Jenis: fitur
- Ringkasan: repo `server-toolkit` ditambah `backup.sh`, `restore.sh`, layanan WAHA opsional di compose (dipilih saat `install.sh`), dua template alur n8n di `workflows/`, dan README/knowledge diperbarui.

## Perubahan dan keputusan
- `INSTALL_DIR` dan `require_stack` dipindah ke `lib/common.sh` agar dipakai semua skrip.
- Backup menyertakan salinan `.env` karena kunci enkripsi n8n ada di sana. Rotasi menyimpan `BACKUP_KEEP` (bawaan 7) terbaru.
- `restore.sh` menimpa database: wajib ketik `RESTORE` dan selalu membuat backup pengaman dulu.
- WAHA memakai profile Compose `waha`, engine NOWEB (lebih ringan), dan port terikat `127.0.0.1` terpisah dari n8n.
- Template alur memakai format payload WAHA (`body.payload.from`/`body.payload.body`) dan nama field harus dicek ulang di Output node setelah impor.

## Lokasi
`backup.sh`, `restore.sh`, `workflows/`, `templates/compose.yaml`, `install.sh`, `lib/common.sh`, `README.md`.

## Verifikasi
- `bash -n` lolos untuk lima skrip; akhiran baris LF.
- YAML kedua compose dan JSON kedua workflow valid; semua sambungan node merujuk node yang ada.
- Uji lokal: rotasi backup (10 file, tersisa 7 terbaru) dan regex password (menolak `abc`, spasi, `$`).
- Belum diuji: eksekusi di server, Docker, impor ke n8n, dan WAHA. Docker tidak ada di PC ini. Repo belum di-commit untuk perubahan ini.
