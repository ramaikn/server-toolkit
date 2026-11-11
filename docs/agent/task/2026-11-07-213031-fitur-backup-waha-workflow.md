# Task: backup/restore, WAHA opsional, template alur n8n

Dibuat: 2026-11-07 21:30 WITA. Lanjutan dari `2026-11-07-211435-fitur-skrip-install-n8n.md` (uji jalan di server masih terbuka di sana).

1. [x] `lib/common.sh`: `INSTALL_DIR` bersama dan `require_stack`.
2. [x] `backup.sh`: dump + salinan `.env`, verifikasi file, rotasi. Rotasi diuji dengan folder sementara.
3. [x] `restore.sh`: daftar, konfirmasi `RESTORE`, backup pengaman, pulihkan. (Sintaks diperiksa; belum dijalankan terhadap database nyata.)
4. [x] `templates/compose.yaml`: layanan `waha` dengan profile; `.env.example` diperbarui.
5. [x] `install.sh`: pertanyaan WAHA dan kunci acak di `.env`.
6. [x] `workflows/`: dua template n8n. JSON valid dan sambungan node konsisten; belum diuji impor di n8n.
7. [x] README dan `knowledge/overview.md` diperbarui.
8. [x] Verifikasi lokal: `bash -n`, parse YAML dan JSON, uji regex password dan rotasi.
9. [ ] Uji `backup.sh`, `restore.sh`, WAHA, dan impor workflow di server nyata (dikerjakan user nanti, hasil dicatat di log baru).
