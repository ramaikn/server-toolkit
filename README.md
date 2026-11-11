# server-toolkit

Satu perintah untuk menyiapkan komputer atau server baru agar siap vibe coding dengan coding agent: OpenCode, Claude Code, Gemini CLI, Qwen Code, plus Node.js, Bun, Python (uv), dan opsional Docker + n8n.

Skrip mendeteksi OS sendiri, melewati tool yang sudah ada, dan aman dijalankan ulang.

| OS | Perintah |
|---|---|
| Ubuntu, Debian, Fedora, RHEL, Arch, openSUSE, Alpine, WSL | `./setup.sh` |
| macOS | `./setup.sh` |
| Windows 10/11 | `setup.cmd` |

## Mulai
Linux, macOS, WSL:
```bash
git clone https://github.com/ramaikn/server-toolkit && cd server-toolkit && ./setup.sh
```

Windows (PowerShell atau CMD, bukan "Run as administrator"):
```powershell
git clone https://github.com/ramaikn/server-toolkit; cd server-toolkit; .\setup.cmd
```

Belum ada git? Di Windows: `winget install Git.Git`. Di Ubuntu: `sudo apt install -y git`. Di Alpine: `apk add git bash`.

Selesai memasang, buka terminal baru supaya PATH baru terbaca.

## Profil
| Profil | Isi |
|---|---|
| `minimal` | alat dasar + OpenCode |
| `coding` (bawaan) | alat dasar, Node.js, Bun, Python 3.12, OpenCode CLI + Desktop, Claude Code, Gemini CLI, Qwen Code |
| `full` | `coding` + Docker + n8n dengan PostgreSQL |

OpenCode Desktop hanya dipasang di Windows dan macOS. Di server Linux tanpa layar otomatis dilewati.

## Opsi
Sama untuk `setup.sh` dan `setup.cmd`.

| Opsi | Fungsi |
|---|---|
| `--profile full` | pilih profil |
| `--only claude,gemini` | pasang tool tertentu saja |
| `--skip qwen` | lewati tool tertentu |
| `--interactive` | pilih tool lewat menu bernomor |
| `--yes` | tanpa konfirmasi |
| `--dry-run` | tampilkan rencana, tidak memasang apa pun |
| `--check` | cek status semua tool |
| `--list` | daftar tool dan profil |

## Setelah terpasang
| Tool | Mulai pakai |
|---|---|
| OpenCode | `opencode` di folder proyek, lalu `/connect` untuk memilih model gratis |
| Gemini CLI | `gemini`, login dengan akun Google (ada kuota gratis harian) |
| Qwen Code | `qwen`, atur provider OpenRouter atau API key. Kuota gratis Qwen OAuth sudah berakhir sejak 15 April 2026 |
| Claude Code | `claude`, login dengan langganan Claude atau API key |
| n8n | `http://127.0.0.1:5678`. Dari laptop lain: `ssh -L 5678:localhost:5678 user@ip-server` |

## Cara kerja singkat
- Tool dipasang per-user di folder home (`~/.local/bin`, `~/.bun`, `~/.opencode`, fnm untuk Node), jadi tidak butuh admin kecuali paket sistem dan Docker.
- Installer yang dipakai adalah installer resmi tiap tool (skrip resmi, winget, Homebrew, atau npm untuk tool yang memang dirilis lewat npm).
- Di Linux/macOS, PATH ditambahkan lewat satu blok bertanda `# >>> server-toolkit >>>` di `~/.bashrc`, `~/.zshrc`, `~/.profile`. Di Windows lewat PATH User.
- n8n dipasang di `~/n8n-stack`. Password dan kunci enkripsi dibuat acak di `.env` (izin 600). Simpan salinannya, karena tanpa `N8N_ENCRYPTION_KEY` kredensial n8n tidak bisa dibuka setelah dipulihkan.
- Log tiap jalan ada di `logs/setup-*.log`.

## Menambah tool baru
1. Tambah nama dan keterangan di `config/profiles.conf`, lalu masukkan ke profil yang diinginkan.
2. Buat `tools/unix/<nama>.sh` berisi `<nama>_check` dan `<nama>_install`.
3. Buat `tools/windows/<nama>.ps1` berisi `Test-Tool_<nama>` dan `Install-Tool_<nama>`.

Tanda `-` di nama diganti `_` untuk nama fungsi. Kontrak lengkap ada di komentar `lib/unix/registry.sh` dan `lib/windows/Registry.ps1`.

## Struktur
| Lokasi | Isi |
|---|---|
| `setup.sh`, `setup.cmd`, `setup.ps1` | Pintu masuk |
| `config/profiles.conf` | Daftar tool dan profil, dipakai kedua OS |
| `lib/unix/`, `lib/windows/` | Log, deteksi OS, package manager, PATH, runner tool |
| `tools/unix/`, `tools/windows/` | Satu file per tool |
| `stacks/n8n/` | Compose n8n + PostgreSQL |
| `backup/legacy-n8n-toolkit/` | Versi lama (installer n8n, backup/restore, WAHA, template workflow) |
