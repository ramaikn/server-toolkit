# Deteksi Windows, PATH per-user, winget, unduhan installer resmi, dan npm global.
# Semua perubahan PATH hanya di scope User, tidak menyentuh setelan mesin.

$script:Platform = $null

function Get-PlatformInfo {
    $os = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
    $arch = switch ($env:PROCESSOR_ARCHITECTURE) { 'AMD64' { 'x64' } 'ARM64' { 'arm64' } default { $env:PROCESSOR_ARCHITECTURE } }
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    $script:Platform = [pscustomobject]@{
        Name     = if ($os) { "$($os.Caption) $($os.Version)" } else { 'Windows' }
        Arch     = $arch
        IsServer = ($os -and $os.ProductType -ne 1)
        HasWinget = (Test-Command winget)
        IsAdmin  = $isAdmin
    }
    Write-LogFile INFO ("platform {0} arch={1} server={2} winget={3} admin={4}" -f $script:Platform.Name, $arch, $script:Platform.IsServer, $script:Platform.HasWinget, $isAdmin)
}

function Show-PlatformSummary {
    Write-Host ("  Sistem   : {0} ({1})" -f $script:Platform.Name, $script:Platform.Arch)
    Write-Host ("  Paket    : {0}" -f $(if ($script:Platform.HasWinget) { 'winget' } else { 'winget tidak ada' }))
}

# Folder tool per-user. Urutan = prioritas di PATH.
$env:FNM_DIR = if ($env:FNM_DIR) { $env:FNM_DIR } else { Join-Path $env:APPDATA 'fnm' }
$script:UserBinDirs = @(
    (Join-Path $env:USERPROFILE '.local\bin'),
    (Join-Path $env:USERPROFILE '.bun\bin'),
    (Join-Path $env:FNM_DIR 'aliases\default'),
    (Join-Path $env:APPDATA 'npm'),
    (Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Links')
)

# Baca ulang PATH dari registry + folder tool supaya yang baru dipasang langsung terpakai.
function Update-SessionPath {
    $machine = [Environment]::GetEnvironmentVariable('Path', 'Machine')
    $user = [Environment]::GetEnvironmentVariable('Path', 'User')
    $parts = @($script:UserBinDirs) + ("$machine;$user" -split ';') + ($env:Path -split ';')
    $seen = @{}
    $clean = foreach ($p in $parts) {
        if ($p -and -not $seen.ContainsKey($p.ToLower())) { $seen[$p.ToLower()] = $true; $p }
    }
    $env:Path = $clean -join ';'
}

# Tambah folder ke PATH User secara permanen (sekali saja).
function Add-UserPath([string]$Dir) {
    $user = [Environment]::GetEnvironmentVariable('Path', 'User')
    $items = @($user -split ';' | Where-Object { $_ })
    if ($items | Where-Object { $_.TrimEnd('\') -ieq $Dir.TrimEnd('\') }) { return }
    if ($script:DryRun) { Write-Host "  [dry-run] tambah $Dir ke PATH User" -ForegroundColor DarkGray; return }
    [Environment]::SetEnvironmentVariable('Path', (($items + $Dir) -join ';'), 'User')
    Write-LogFile INFO "PATH User + $Dir"
}

function Save-UserPaths {
    foreach ($d in $script:UserBinDirs) { Add-UserPath $d }
    if (-not $script:DryRun) { [Environment]::SetEnvironmentVariable('FNM_DIR', $env:FNM_DIR, 'User') }
}

# winget per-user dulu; kalau paket tidak punya installer per-user, ulangi tanpa scope
# (bisa memunculkan dialog admin/UAC). -Machine langsung tanpa scope.
function Install-WingetPackage {
    param([string]$Id, [switch]$Machine)
    if (-not $script:Platform.HasWinget) {
        Write-Err "winget tidak ada. Pasang 'App Installer' dari Microsoft Store, lalu jalankan ulang."
        return $false
    }
    # -1978335189 = sudah terpasang dan tidak ada pembaruan
    $ok = @(0, -1978335189)
    $base = @('install', '--id', $Id, '-e', '--silent', '--accept-package-agreements', '--accept-source-agreements', '--disable-interactivity')
    if (-not $Machine) {
        if (Invoke-Logged winget ($base + @('--scope', 'user')) $ok) { return $true }
        Write-Info "$Id tidak tersedia per-user, mencoba installer biasa (mungkin muncul dialog admin)."
    }
    return (Invoke-Logged winget $base $ok)
}

function Test-WingetInstalled([string]$Id) {
    if (-not $script:Platform.HasWinget) { return $false }
    $out = winget list --id $Id -e --accept-source-agreements --disable-interactivity 2>$null | Out-String
    return ($LASTEXITCODE -eq 0 -and $out -match [regex]::Escape($Id))
}

# Unduh installer .ps1 resmi ke file sementara lalu jalankan di proses terpisah,
# supaya "exit" di dalam installer tidak menutup setup ini.
# Ulangi aksi sampai $true. Jaringan sering putus di tengah unduhan installer.
function Invoke-WithRetry([scriptblock]$Action, [int]$Max = 3) {
    for ($n = 1; $n -le $Max; $n++) {
        if (& $Action) { return $true }
        if ($n -lt $Max) {
            Write-Warn "Gagal (percobaan $n dari $Max), mencoba lagi dalam $($n * 5) detik."
            Start-Sleep -Seconds ($n * 5)
        }
    }
    return $false
}

function Invoke-RemoteScript {
    param([string]$Url, [string[]]$Arguments = @(), [hashtable]$Env = @{})
    if ($script:DryRun) { Write-Host "  [dry-run] unduh $Url lalu jalankan" -ForegroundColor DarkGray; return $true }
    return (Invoke-WithRetry { Invoke-RemoteScriptOnce -Url $Url -Arguments $Arguments -Env $Env })
}

function Invoke-RemoteScriptOnce {
    param([string]$Url, [string[]]$Arguments = @(), [hashtable]$Env = @{})
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $tmp = Join-Path $env:TEMP ("server-toolkit-{0}.ps1" -f [guid]::NewGuid())
    try {
        Invoke-WebRequest -Uri $Url -OutFile $tmp -UseBasicParsing -ErrorAction Stop
    } catch {
        Write-Err "Gagal mengunduh $Url"
        Write-LogFile ERROR $_.Exception.Message
        return $false
    }
    $saved = @{}
    foreach ($k in $Env.Keys) { $saved[$k] = [Environment]::GetEnvironmentVariable($k); Set-Item "env:$k" $Env[$k] }
    try {
        return (Invoke-Logged powershell (@('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $tmp) + $Arguments))
    } finally {
        foreach ($k in $saved.Keys) { if ($null -eq $saved[$k]) { Remove-Item "env:$k" -ErrorAction SilentlyContinue } else { Set-Item "env:$k" $saved[$k] } }
        Remove-Item $tmp -Force -ErrorAction SilentlyContinue
    }
}

function Install-NpmGlobal([string]$Package) {
    if (-not $script:DryRun -and -not (Test-Command npm)) { Write-Err 'npm belum ada. Pasang tool node dulu.'; return $false }
    return (Invoke-WithRetry { Invoke-Logged 'npm.cmd' @('install', '-g', $Package) })
}

function Get-NodeMajor {
    if (-not (Test-Command node)) { return 0 }
    $v = (& node -v 2>$null) -replace '^v', ''
    try { return [int]($v.Split('.')[0]) } catch { return 0 }
}
