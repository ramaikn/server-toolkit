# n8n + PostgreSQL di Docker Desktop. Stack dari stacks\n8n disalin ke %USERPROFILE%\n8n-stack,
# .env dengan password dan kunci acak dibuat sekali lalu dipakai ulang. Tidak menghapus data.

$script:N8nDir = Join-Path $env:USERPROFILE 'n8n-stack'

function Get-N8nPort {
    $envFile = Join-Path $script:N8nDir '.env'
    if (Test-Path $envFile) {
        $line = Select-String -Path $envFile -Pattern '^N8N_PORT=(\d+)' | Select-Object -First 1
        if ($line) { return $line.Matches[0].Groups[1].Value }
    }
    return '5678'
}

function Test-Tool_n8n {
    try {
        $r = Invoke-WebRequest -Uri "http://127.0.0.1:$(Get-N8nPort)/healthz" -UseBasicParsing -TimeoutSec 3
        return ($r.StatusCode -eq 200)
    } catch { return $false }
}
function Get-ToolVersion_n8n { "http://127.0.0.1:$(Get-N8nPort)" }

function New-RandomHex([int]$Bytes) {
    $buf = New-Object byte[] $Bytes
    [Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($buf)
    return (($buf | ForEach-Object { $_.ToString('x2') }) -join '')
}

function Write-N8nEnv {
    $tz = try { (Get-TimeZone).Id } catch { 'UTC' }
    $content = @(
        '# Dibuat otomatis oleh setup.ps1. Simpan salinan file ini: tanpa N8N_ENCRYPTION_KEY,'
        '# kredensial di n8n tidak bisa dibuka setelah dipulihkan.'
        "POSTGRES_PASSWORD=$(New-RandomHex 16)"
        "N8N_ENCRYPTION_KEY=$(New-RandomHex 24)"
        # Zona waktu Windows (mis. "SE Asia Standard Time") tidak dikenal container; pakai UTC.
        'TZ=UTC'
        'N8N_BIND_ADDRESS=127.0.0.1'
        'N8N_PORT=5678'
    ) -join "`n"
    # Tanpa BOM: docker compose salah membaca baris pertama kalau ada BOM.
    [IO.File]::WriteAllText((Join-Path $script:N8nDir '.env'), $content + "`n", (New-Object Text.UTF8Encoding($false)))
    Write-LogFile INFO "n8n .env dibuat (zona waktu Windows: $tz)"
    Write-Info ".env baru dibuat di $script:N8nDir\.env"
}

function Install-Tool_n8n {
    if (-not (Invoke-ToolRequire 'docker')) { return $false }
    if ($script:DryRun) {
        Write-Info "[dry-run] salin stacks\n8n ke $script:N8nDir, buat .env bila belum ada, docker compose up -d"
        return $true
    }
    & docker info *> $null
    if ($LASTEXITCODE -ne 0) {
        Write-Err 'Docker Desktop belum berjalan. Buka Docker Desktop, tunggu sampai running, lalu jalankan ulang setup.'
        return $false
    }
    New-Item -ItemType Directory -Force -Path $script:N8nDir | Out-Null
    Copy-Item (Join-Path $script:ToolkitRoot 'stacks\n8n\compose.yaml') (Join-Path $script:N8nDir 'compose.yaml') -Force
    if (Test-Path (Join-Path $script:N8nDir '.env')) {
        Write-Info 'Memakai .env yang sudah ada (password dan kunci tidak berubah).'
    } else {
        Write-N8nEnv
    }

    Write-Info 'Menjalankan n8n (unduhan pertama bisa beberapa menit).'
    Push-Location $script:N8nDir
    try { $up = Invoke-Logged docker @('compose', 'up', '-d') } finally { Pop-Location }
    if (-not $up) { return $false }

    for ($i = 0; $i -lt 24; $i++) {
        if (Test-Tool_n8n) { return $true }
        Start-Sleep -Seconds 5
    }
    Write-Err "n8n belum menjawab setelah 2 menit. Cek: cd $script:N8nDir; docker compose logs --tail 50 n8n"
    return $false
}

function Get-ToolHint_n8n { "n8n: buka http://127.0.0.1:$(Get-N8nPort) di browser." }
