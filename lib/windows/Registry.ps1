# Membaca config/profiles.conf dan menjalankan tool (versi Windows).
#
# Kontrak file tools/windows/<nama>.ps1 (Id = nama dengan '-' diganti '_'):
#   Test-Tool_<Id>          wajib. $true jika sudah terpasang.
#   Install-Tool_<Id>       wajib. $true jika pemasangan berhasil.
#   Test-ToolSupported_<Id> opsional. kembalikan teks alasan jika TIDAK cocok, $null jika cocok.
#   Get-ToolVersion_<Id>    opsional. teks versi singkat.
#   Get-ToolHint_<Id>       opsional. langkah lanjutan untuk user.

$script:ProfilesConf = Join-Path $script:ToolkitRoot 'config\profiles.conf'
$script:Results = [ordered]@{}
$script:Hints = New-Object System.Collections.Generic.List[string]

function Read-ConfSection([string]$Section) {
    $map = [ordered]@{}
    $current = ''
    foreach ($line in Get-Content $script:ProfilesConf) {
        $t = $line.Trim()
        if ($t -eq '' -or $t.StartsWith('#')) { continue }
        if ($t -match '^\[(.+)\]$') { $current = $Matches[1]; continue }
        if ($current -ne $Section) { continue }
        $i = $t.IndexOf('=')
        if ($i -gt 0) { $map[$t.Substring(0, $i).Trim()] = $t.Substring($i + 1).Trim() }
    }
    return $map
}

$script:ToolDescs = Read-ConfSection 'tools'
$script:Profiles = Read-ConfSection 'profiles'

function Get-ToolId([string]$Name) { $Name -replace '-', '_' }
function Test-FunctionExists([string]$Name) { [bool](Get-Command $Name -CommandType Function -ErrorAction SilentlyContinue) }

# File tool sudah dimuat semua oleh setup.ps1 di scope skrip; di sini cukup cek ada.
function Import-Tool([string]$Name) {
    if (Test-FunctionExists "Install-Tool_$(Get-ToolId $Name)") { return $true }
    Write-Err "Implementasi tool '$Name' tidak ditemukan di tools\windows."
    return $false
}

function Set-ToolResult([string]$Name, [string]$Status, [string]$Note = '') {
    $script:Results[$Name] = [pscustomobject]@{ Status = $Status; Note = $Note }
}

function Get-ToolVersionText([string]$Name) {
    $fn = "Get-ToolVersion_$(Get-ToolId $Name)"
    if (Test-FunctionExists $fn) { try { return [string](& $fn | Select-Object -First 1) } catch { return '' } }
    return ''
}

# Dipanggil dari Install-Tool_* untuk memastikan dependensi sudah ada lebih dulu.
function Invoke-ToolRequire([string]$Dep) {
    if (-not $script:Results.Contains($Dep)) { Invoke-Tool $Dep 'install' }
    if (@('sudah', 'dipasang', 'rencana') -contains $script:Results[$Dep].Status) { return $true }
    Write-Err "Butuh '$Dep' yang gagal dipasang."
    return $false
}

# Status: sudah | dipasang | gagal | dilewati | belum (mode check) | rencana (dry-run)
function Invoke-Tool([string]$Name, [string]$Mode) {
    $id = Get-ToolId $Name
    if (-not (Import-Tool $Name)) { Set-ToolResult $Name 'gagal' 'file tool tidak ada'; return }

    $supportFn = "Test-ToolSupported_$id"
    if (Test-FunctionExists $supportFn) {
        $reason = & $supportFn
        if ($reason) { Set-ToolResult $Name 'dilewati' $reason; Write-Info "${Name}: dilewati ($reason)"; return }
    }

    if (& "Test-Tool_$id") {
        Set-ToolResult $Name 'sudah' (Get-ToolVersionText $Name)
        Write-Ok "$Name sudah terpasang $($script:Results[$Name].Note)"
        return
    }

    if ($Mode -eq 'check') { Set-ToolResult $Name 'belum'; Write-Warn "$Name belum terpasang"; return }

    Write-Title "Memasang ${Name}: $($script:ToolDescs[$Name])"
    $installed = $false
    try { $installed = [bool](& "Install-Tool_$id") } catch { Write-LogFile ERROR "$Name : $($_.Exception.Message)" }
    if ($installed) {
        Update-SessionPath
        if ($script:DryRun) { Set-ToolResult $Name 'rencana' 'akan dipasang'; return }
        if (& "Test-Tool_$id") {
            Set-ToolResult $Name 'dipasang' (Get-ToolVersionText $Name)
            Write-Ok "$Name siap $($script:Results[$Name].Note)"
            $hintFn = "Get-ToolHint_$id"
            if (Test-FunctionExists $hintFn) { $script:Hints.Add((& $hintFn)) }
            return
        }
    }
    Set-ToolResult $Name 'gagal' 'lihat log'
    Write-Err "$Name gagal dipasang. Detail di $script:LogFile"
}
