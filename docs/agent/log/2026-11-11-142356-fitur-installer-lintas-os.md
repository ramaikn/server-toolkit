# Installer lintas OS untuk vibe coding

- Waktu: 2026-11-11 14:23 (UTC+08:00)
- Jenis: fitur
- Ringkasan: repo diganti total menjadi installer satu perintah (`setup.sh` / `setup.cmd`) yang mendeteksi OS dan memasang coding agent serta runtime. Kode lama dipindah ke `backup/legacy-n8n-toolkit/`.

## Perubahan dan keputusan
- Kode lama (installer n8n Ubuntu, backup/restore, WAHA, workflows, lab) dipindah utuh termasuk perubahan yang belum di-commit. `docs/agent` tetap di tempat.
- Profil `minimal`, `coding` (bawaan), `full` di `config/profiles.conf`, dibaca oleh kedua OS.
- Tool: base, node (fnm), bun, python (uv + 3.12), docker, opencode, opencode-desktop (Windows/macOS), claude, gemini, qwen, n8n (Docker + Postgres).
- Installer resmi tiap tool; unduhan installer dan npm dicoba ulang 3 kali karena jaringan sering putus di tengah unduhan.
- OpenCode memakai v2 (`opencode.ai/v2/install`, npm `@opencode/cli` di Windows) sesuai dokumentasi resmi saat ini.
- Qwen OAuth gratis sudah berakhir 15 April 2026; tetap dipasang atas pilihan user, dicatat di README.

## Berkas
`setup.sh`, `setup.cmd`, `setup.ps1`, `config/profiles.conf`, `lib/unix/`, `lib/windows/`, `tools/unix/`, `tools/windows/`, `stacks/n8n/compose.yaml`, `README.md`, `.gitattributes` (`.cmd`/`.ps1` CRLF).

## Verifikasi
- `bash -n` semua skrip Unix dan parser PowerShell untuk semua `.ps1`: lolos.
- Windows 11 (PC ini): `--check`, `--dry-run`, `--list`, tool tidak dikenal: sesuai. Tidak ada yang dipasang di PC ini.
- Dry-run Fedora 41 dan Alpine 3.22 (container): rencana benar, desktop dilewati.
- Pemasangan nyata Ubuntu 24.04 (container, root): base, node, bun, python, gemini, qwen terpasang, dan terbaca di login shell baru; jalan ulang mendeteksi "sudah ada".
- Keterbatasan: OpenCode dan Claude gagal di uji container karena unduhan biner putus (curl partial file / SSL reset saat Docker Desktop di PC ini restart). Installer OpenCode yang dijalankan manual setelahnya berhasil dan host Claude bisa dijangkau, tapi `setup.sh` belum terbukti memasang keduanya sampai selesai. macOS, Windows bersih, dan Docker/n8n nyata belum diuji.
