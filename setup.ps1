# Installer otomatis untuk Windows 10/11. Jalankan lewat setup.cmd supaya
# ExecutionPolicy tidak perlu diubah. Opsi sama dengan setup.sh:
#
#   setup.cmd                    pasang profil "coding" (bawaan)
#   setup.cmd --profile full     tambah Docker Desktop + n8n
#   setup.cmd --interactive      pilih tool satu per satu
#   setup.cmd --check            hanya cek yang sudah terpasang
#   setup.cmd --help             semua opsi
#
# Jalankan sebagai user biasa (bukan "Run as administrator"). Semua tool dipasang
# per-user bila bisa; yang butuh admin (Docker Desktop) memunculkan dialog sendiri.

# 'Continue', bukan 'Stop': di PowerShell 5.1 program native yang menulis ke stderr
# (git, winget, uv) akan dianggap error fatal kalau 'Stop'. Kegagalan dicek lewat exit code.
$ErrorActionPreference = 'Continue'
$script:ToolkitRoot = $PSScriptRoot

. (Join-Path $PSScriptRoot 'lib\windows\Log.ps1')
. (Join-Path $PSScriptRoot 'lib\windows\Platform.ps1')
. (Join-Path $PSScriptRoot 'lib\windows\Registry.ps1')
foreach ($toolFile in Get-ChildItem (Join-Path $PSScriptRoot 'tools\windows') -Filter '*.ps1') { . $toolFile.FullName }

$ProfileName = 'coding'
$Only = @()
$Skip = @()
$Interactive = $false
$Mode = 'install'

function Show-Usage {
    @"
Pemakaian: setup.cmd [opsi]

  -p, --profile NAMA   profil: $($script:Profiles.Keys -join ' ') (bawaan: coding)
      --only a,b       pasang hanya tool ini (abaikan profil)
      --skip a,b       lewati tool ini
  -i, --interactive    pilih tool lewat menu
  -y, --yes            jangan tanya konfirmasi
      --dry-run        tampilkan rencana tanpa memasang apa pun
      --check          cek status tool saja
      --list           daftar tool dan profil
  -h, --help           bantuan ini
"@ | Write-Host
}

function Show-ToolList {
    Write-Host 'Tool:'
    foreach ($k in $script:ToolDescs.Keys) { Write-Host ('  {0,-17} {1}' -f $k, $script:ToolDescs[$k]) }
    Write-Host ''; Write-Host 'Profil:'
    foreach ($k in $script:Profiles.Keys) { Write-Host ('  {0,-8} {1}' -f $k, $script:Profiles[$k]) }
}

# Argumen dibaca manual supaya gaya --opsi sama persis dengan setup.sh.
function Read-Arguments([string[]]$argv) {
    for ($i = 0; $i -lt $argv.Count; $i++) {
        $a = $argv[$i]
        $next = { if ($i + 1 -ge $argv.Count) { throw "Opsi $a butuh nilai." }; $argv[$i + 1] }
        switch -Regex ($a) {
            '^(-p|--?profile)$'      { $script:ProfileName = & $next; $i++ }
            '^--?only$'              { $script:Only = (& $next) -split ','; $i++ }
            '^--?skip$'              { $script:Skip = (& $next) -split ','; $i++ }
            '^(-i|--?interactive)$'  { $script:Interactive = $true }
            '^(-y|--?yes)$'          { $script:AssumeYes = $true }
            '^--?dry-?run$'          { $script:DryRun = $true }
            '^--?check$'             { $script:Mode = 'check' }
            '^--?list$'              { Show-ToolList; exit 0 }
            '^(-h|--?help|/\?)$'     { Show-Usage; exit 0 }
            default                  { Show-Usage; throw "Opsi tidak dikenal: $a" }
        }
    }
}

function Resolve-Tools {
    if ($script:Only.Count -gt 0) {
        $list = $script:Only
    } else {
        if (-not $script:Profiles.Contains($script:ProfileName)) { throw "Profil '$($script:ProfileName)' tidak ada. Pilihan: $($script:Profiles.Keys -join ', ')" }
        $list = $script:Profiles[$script:ProfileName] -split '\s+'
    }
    $result = @()
    foreach ($t in $list) {
        if (-not $t) { continue }
        if (-not $script:ToolDescs.Contains($t)) { throw "Tool '$t' tidak dikenal. Lihat: setup.cmd --list" }
        if ($script:Skip -contains $t) { continue }
        $result += $t
    }
    return , $result
}

# Ketik nomor untuk mencentang/membatalkan, Enter untuk lanjut. Urutan mengikuti config.
function Show-InteractiveMenu([string[]]$Selected) {
    $all = @($script:ToolDescs.Keys)
    $chosen = New-Object System.Collections.Generic.HashSet[string]
    foreach ($s in $Selected) { [void]$chosen.Add($s) }
    while ($true) {
        Write-Host ''
        for ($n = 0; $n -lt $all.Count; $n++) {
            $mark = if ($chosen.Contains($all[$n])) { 'x' } else { ' ' }
            Write-Host ('  {0,2}. [{1}] {2,-17} {3}' -f ($n + 1), $mark, $all[$n], $script:ToolDescs[$all[$n]])
        }
        $answer = Read-Host '  Nomor untuk mengubah pilihan (pisah spasi), Enter untuk lanjut'
        if (-not $answer) { break }
        foreach ($tok in ($answer -split '\s+')) {
            $num = 0
            if ([int]::TryParse($tok, [ref]$num) -and $num -ge 1 -and $num -le $all.Count) {
                $t = $all[$num - 1]
                if (-not $chosen.Remove($t)) { [void]$chosen.Add($t) }
            }
        }
    }
    return , @($all | Where-Object { $chosen.Contains($_) })
}

function Show-Summary([string[]]$Selected) {
    Write-Title 'Ringkasan'
    $failed = $false
    foreach ($t in $Selected) {
        $r = $script:Results[$t]
        $status = if ($r) { $r.Status } else { 'gagal' }
        $color = switch ($status) { 'sudah' { 'Green' } 'dipasang' { 'Green' } 'rencana' { 'Cyan' } 'dilewati' { 'DarkGray' } 'belum' { 'Yellow' } default { 'Red' } }
        if ($status -eq 'gagal') { $failed = $true }
        Write-Host ('  {0,-17} ' -f $t) -NoNewline
        Write-Host ('{0,-9}' -f $status) -ForegroundColor $color -NoNewline
        Write-Host "  $(if ($r) { $r.Note })"
    }
    if ($script:Hints.Count -gt 0) {
        Write-Title 'Langkah berikutnya'
        foreach ($h in $script:Hints) { if ($h) { Write-Host "  - $h" } }
    }
    if ($script:Mode -eq 'install' -and -not $script:DryRun) {
        Write-Host ''
        Write-Host '  Tutup lalu buka lagi terminal supaya PATH baru terbaca.'
    }
    Write-Host "  Log lengkap: $script:LogFile"
    return $failed
}

function Invoke-Main([string[]]$argv) {
    Read-Arguments $argv
    Write-Title 'server-toolkit setup'
    Get-PlatformInfo
    Show-PlatformSummary
    if ($script:Platform.IsAdmin) { Write-Warn 'Berjalan sebagai Administrator. Disarankan terminal biasa agar tool terpasang per-user.' }
    Update-SessionPath

    $selected = Resolve-Tools
    if ($script:Interactive) { $selected = Show-InteractiveMenu $selected }
    if ($selected.Count -eq 0) { throw 'Tidak ada tool yang dipilih.' }

    if ($script:Mode -eq 'install') {
        $label = if ($script:Only.Count -gt 0) { 'kustom' } else { $script:ProfileName }
        Write-Host "  Profil   : $label"
        Write-Host "  Dipasang : $($selected -join ' ')"
        if ($script:DryRun) { Write-Info 'Mode dry-run: tidak ada yang dipasang.' }
        if (-not (Confirm-Step 'Lanjutkan?')) { throw 'Dibatalkan.' }
    }

    Write-Title $(if ($script:Mode -eq 'check') { 'Memeriksa tool' } else { 'Memasang tool' })
    foreach ($t in $selected) { Invoke-Tool $t $script:Mode }

    if ($script:Mode -eq 'install') { Save-UserPaths }
    if (Show-Summary $selected) { exit 1 }
}

try {
    Invoke-Main $args
} catch {
    Write-Err $_.Exception.Message
    Write-LogFile ERROR ($_ | Out-String)
    exit 1
}
