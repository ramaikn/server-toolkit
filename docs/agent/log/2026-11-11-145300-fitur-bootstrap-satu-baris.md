# Bootstrap satu baris untuk PC baru

- Waktu: 2026-11-11 14:53 (UTC+08:00)
- Jenis: fitur
- Ringkasan: PC Windows/Linux baru cukup menempel satu perintah (`curl ... bootstrap.sh | bash` atau `irm ... bootstrap.ps1 | iex`) tanpa git terpasang dan tanpa pertanyaan.

## Perubahan dan keputusan
- `bootstrap.sh` dan `bootstrap.ps1`: pasang git bila belum ada, clone atau `git pull --ff-only` ke `~/code/server-toolkit`, jalankan setup dengan argumen yang diteruskan.
- Setup tidak lagi bertanya "Lanjutkan?"; konfirmasi hanya di `--interactive`. Konfirmasi Docker di Windows dihapus (dialog admin Windows tetap muncul).
- Docker/n8n tetap opsional lewat `--profile full` (keputusan user).
- `bootstrap.sh` mengarahkan stdin ke `/dev/tty` hanya jika benar-benar bisa dibuka; di sesi tanpa terminal `/dev/tty` ada tapi gagal dibuka (ditemukan saat uji).

## Berkas
`bootstrap.sh`, `bootstrap.ps1`, `setup.sh`, `setup.ps1`, `tools/windows/docker.ps1`, `README.md`, `docs/agent/knowledge/overview.md`.

## Verifikasi
- Ubuntu 24.04 container tanpa git: bootstrap lewat pipe memasang git, clone, menjalankan setup (`--dry-run`); jalan kedua memakai `git pull`.
- Windows: `bootstrap.ps1` dengan repo lokal ke folder sementara meng-clone dan menjalankan setup dengan argumen; setup baru tanpa `--yes` tidak bertanya. Gaya `irm | iex` tanpa argumen tidak diuji karena akan memasang sungguhan di PC pinjaman.
- Keterbatasan: perintah satu baris dari GitHub baru bisa dipakai setelah push; belum diuji di Windows dan macOS yang benar-benar baru.
