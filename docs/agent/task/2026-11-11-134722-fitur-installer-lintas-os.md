# Installer server lintas OS untuk vibe coding

Tujuan: setelah `git clone`, satu perintah memasang semua alat coding agent dan pendukungnya di Linux, macOS, WSL, dan Windows.

Keputusan user (2026-11-11): kode lama dipindah ke `backup/legacy-n8n-toolkit/`, `docs/agent` tetap. Agent: OpenCode (CLI + Desktop di Windows/macOS), Claude Code, Gemini CLI, Qwen Code. Mode: profil (`coding` default) + flag + menu interaktif opsional. n8n lewat Docker + Postgres, hanya di profil `full`.

Tertunda dari task lama: `2026-11-07-213031-fitur-backup-waha-workflow.md` poin 9 (uji backup/restore/WAHA di server nyata). Kode itu kini di folder backup; tetap terbuka.

1. [x] Pindahkan kode lama ke `backup/legacy-n8n-toolkit/` (termasuk perubahan yang belum di-commit).
2. [x] Daftar tool dan profil bersama di `config/profiles.conf`.
3. [x] Unix: `setup.sh`, `lib/unix/` (log, deteksi OS, package manager, runner), `tools/unix/<tool>.sh`.
4. [x] Windows: `setup.cmd`, `setup.ps1`, `lib/windows/`, `tools/windows/<tool>.ps1`.
5. [x] Stack n8n: `stacks/n8n/compose.yaml` + pembuatan `.env` acak, dipakai kedua OS.
6. [x] Uji: `bash -n` semua skrip, `--dry-run` dan `--check` di Git Bash; parse PowerShell + `-DryRun`/`-Check` di Windows ini (tanpa memasang apa pun).
7. [x] README, `knowledge/overview.md`, peta docs, log.
8. [ ] Uji pemasangan nyata di Ubuntu baru, Windows baru, dan macOS (dikerjakan user, hasil dicatat di log baru). Prioritas: pastikan opencode dan claude selesai terpasang lewat setup.sh (di uji container gagal karena unduhan putus).
