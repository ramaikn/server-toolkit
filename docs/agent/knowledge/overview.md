# Gambaran repo server-toolkit

## Tujuan
Setelah `git clone`, satu perintah menyiapkan komputer/server baru untuk vibe coding: coding agent (OpenCode, Claude Code, Gemini CLI, Qwen Code) adalah prioritas, ditambah runtime (Node, Bun, Python/uv) dan opsional Docker + n8n. Harus jalan di Linux (berbagai distro), macOS, WSL, dan Windows.

Versi lama (installer n8n khusus Ubuntu, backup/restore, WAHA, template workflow) dipindah utuh ke `backup/legacy-n8n-toolkit/` pada 2026-11-11 dan tidak lagi dirawat.

## Struktur
- `setup.sh`: pintu masuk Linux/macOS/WSL (bash, kompatibel bash 3.2 macOS: tanpa associative array, tanpa mapfile).
- `setup.cmd` -> `setup.ps1`: pintu masuk Windows (PowerShell 5.1, ExecutionPolicy Bypass per proses).
- `config/profiles.conf`: sumber tunggal daftar tool (`[tools]`) dan profil (`[profiles]`). Urutan di profil = urutan pasang.
- `lib/unix/`: `log.sh` (log + `run` + `confirm`), `detect.sh` (OS_KIND, DISTRO_ID, ARCH, PKG_MGR, HAS_GUI, SUDO, `as_root`), `pkg.sh` (abstraksi apt/dnf/yum/pacman/zypper/apk/brew), `env.sh` (PATH, `run_remote_script`, `npm_global_install`), `registry.sh` (parser config, `tool_process`, `tool_require`).
- `lib/windows/`: `Log.ps1`, `Platform.ps1` (deteksi, PATH User, `Install-WingetPackage`, `Invoke-RemoteScript`, `Install-NpmGlobal`), `Registry.ps1` (parser config, `Invoke-Tool`, `Invoke-ToolRequire`).
- `tools/unix/<nama>.sh` dan `tools/windows/<nama>.ps1`: satu file per tool, kontrak fungsi check/install/supported/version/hint.
- `stacks/n8n/compose.yaml`: n8n + postgres:16-alpine, port hanya 127.0.0.1.

## Alur
1. Parse opsi (gaya `--opsi` sama di kedua OS).
2. Deteksi platform, segarkan PATH sesi dengan folder tool per-user.
3. Tentukan daftar tool dari profil/`--only`/`--skip`, opsional menu `--interactive`.
4. Konfirmasi sekali (lewati dengan `--yes`); di Linux minta sudo di awal bila ada `base`/`docker`, dijaga tetap aktif.
5. Per tool: supported? -> check (lewati bila ada) -> install -> check ulang. Dependensi lewat `tool_require`/`Invoke-ToolRequire` (gemini/qwen/opencode-windows butuh node, n8n butuh docker).
6. Simpan PATH permanen (blok bertanda di rc shell / PATH User), cetak ringkasan + langkah lanjutan. Exit 1 jika ada yang gagal.

## Keputusan penting
- Installer resmi tiap tool: opencode `opencode.ai/v2/install` (Unix) dan npm `@opencode/cli` (Windows, docs v2 tidak menyediakan winget), Claude `claude.ai/install.sh|ps1`, bun `bun.sh/install`, uv `astral.sh/uv`, fnm `fnm.vercel.app/install` / winget `Schniz.fnm`, Docker `get.docker.com` (Ubuntu/Debian/Fedora/RHEL) atau paket distro, Docker Desktop winget/brew cask, OpenCode Desktop winget `SST.OpenCodeDesktop` / brew cask `opencode-desktop`. Gemini dan Qwen hanya dirilis via npm.
- Node lewat fnm per-user; PATH memakai `$FNM_DIR/aliases/default` sehingga tidak perlu `fnm env`. Alpine (musl) memakai paket `nodejs npm` distro.
- Skrip installer diunduh ke file sementara dulu, bukan `curl | bash`.
- Windows: winget dicoba `--scope user` dulu, lalu tanpa scope. Docker Desktop satu-satunya yang machine-wide dan ditanya dulu.
- `sudo ./setup.sh` ditolak; jalankan sebagai user, sudo diminta sendiri. Root murni (VPS baru) diizinkan.
- Qwen OAuth gratis berakhir 15 April 2026; Qwen tetap dipasang atas pilihan user.
- `.env` n8n dibuat sekali (acak, izin 600) dan tidak pernah ditimpa. Di Windows TZ=UTC karena nama zona Windows tidak dikenal container.

## Menjalankan dan menguji
- Status saja: `./setup.sh --check` atau `setup.cmd --check`.
- Rencana tanpa memasang: `--dry-run --yes`.
- Uji Linux tanpa menyentuh host: `docker run --rm -v "<repo>:/src:ro" ubuntu:24.04 bash -c 'cp -r /src /root/tk && cd /root/tk && ./setup.sh --yes'`. Alpine butuh `apk add bash` dulu.
- Cek sintaks: `bash -n setup.sh lib/unix/*.sh tools/unix/*.sh`; PowerShell lewat `[Management.Automation.Language.Parser]::ParseFile`.
