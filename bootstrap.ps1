# Perintah satu baris untuk Windows baru yang belum punya git (PowerShell biasa, bukan admin):
#
#   irm https://raw.githubusercontent.com/ramaikn/server-toolkit/master/bootstrap.ps1 | iex
#
# Dengan argumen untuk setup (mis. profil full):
#   & ([scriptblock]::Create((irm https://raw.githubusercontent.com/ramaikn/server-toolkit/master/bootstrap.ps1))) --profile full
#
# Memasang Git bila perlu, clone (atau update) repo ke %USERPROFILE%\code\server-toolkit,
# lalu menjalankan setup.ps1. Variabel opsional: TOOLKIT_REPO, TOOLKIT_DIR.
# Sengaja tanpa "exit": skrip ini berjalan di terminal user lewat iex.

& {
    $repo = if ($env:TOOLKIT_REPO) { $env:TOOLKIT_REPO } else { 'https://github.com/ramaikn/server-toolkit.git' }
    $dir = if ($env:TOOLKIT_DIR) { $env:TOOLKIT_DIR } else { Join-Path $env:USERPROFILE 'code\server-toolkit' }

    function Update-SessionPath {
        $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [Environment]::GetEnvironmentVariable('Path', 'User')
    }

    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
            Write-Host "  X   winget tidak ada. Pasang 'App Installer' dari Microsoft Store, lalu jalankan lagi." -ForegroundColor Red
            return
        }
        Write-Host '  Memasang Git (mungkin muncul dialog izin admin).'
        $common = @('install', '--id', 'Git.Git', '-e', '--silent', '--accept-package-agreements', '--accept-source-agreements', '--disable-interactivity')
        winget @common --scope user | Out-Null
        if ($LASTEXITCODE -ne 0) { winget @common | Out-Null }
        Update-SessionPath
        if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
            Write-Host '  X   Git gagal dipasang. Pasang manual: winget install Git.Git' -ForegroundColor Red
            return
        }
    }

    if (Test-Path (Join-Path $dir '.git')) {
        Write-Host "  Memperbarui $dir"
        git -C $dir pull --ff-only --quiet
        if ($LASTEXITCODE -ne 0) { Write-Host '  Gagal update (ada perubahan lokal?), memakai versi yang ada.' }
    } else {
        Write-Host "  Mengunduh server-toolkit ke $dir"
        New-Item -ItemType Directory -Force -Path (Split-Path $dir) | Out-Null
        git clone --quiet $repo $dir
        if ($LASTEXITCODE -ne 0) { Write-Host '  X   Gagal clone repo.' -ForegroundColor Red; return }
    }

    # Proses baru dengan Bypass: ExecutionPolicy bawaan Windows memblokir file .ps1.
    powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $dir 'setup.ps1') @args
} @args
