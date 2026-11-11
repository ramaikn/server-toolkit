# Bootstrap satu baris untuk PC baru

Lanjutan dari `2026-11-11-134722-fitur-installer-lintas-os.md`. Tujuan: di Windows/Ubuntu baru cukup tempel satu perintah, tanpa git terpasang dan tanpa pertanyaan. Keputusan user: bootstrap + tanpa konfirmasi, Docker/n8n tetap opsional (profil `full`), lalu push.

1. [x] `bootstrap.sh`: pasang git/curl bila belum ada, clone atau pull ke `~/code/server-toolkit`, jalankan `setup.sh` dengan argumen yang diteruskan.
2. [x] `bootstrap.ps1`: pastikan winget, pasang Git, clone atau pull ke `%USERPROFILE%\code\server-toolkit`, jalankan `setup.ps1` di proses baru (Bypass). Tidak memakai `exit` agar terminal user tidak tertutup.
3. [x] `setup.sh`/`setup.ps1`: hapus konfirmasi "Lanjutkan?" bawaan dan konfirmasi Docker Windows; konfirmasi hanya di `--interactive`.
4. [x] Uji: Ubuntu container tanpa git (repo lokal lewat `TOOLKIT_REPO`, `--dry-run`), Windows dry-run. Gaya `irm | iex` tanpa argumen tidak diuji (akan memasang sungguhan di PC pinjaman).
5. [x] README, knowledge, log.
6. [x] Commit dan push ke `origin/master`.
