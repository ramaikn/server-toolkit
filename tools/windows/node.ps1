# Node.js LTS lewat fnm (winget, per-user). PATH memakai folder alias "default"
# milik fnm, jadi node dan npm terbaca di semua terminal tanpa "fnm env".
# Paket npm global masuk ke %APPDATA%\npm (bawaan npm di Windows).

function Test-Tool_node { ((Get-NodeMajor) -ge 20) -and (Test-Command npm) }
function Get-ToolVersion_node { "node $(& node -v 2>$null), npm $(& npm.cmd -v 2>$null)" }

function Install-Tool_node {
    if (-not (Test-Command fnm)) {
        if (-not (Install-WingetPackage 'Schniz.fnm')) { return $false }
        Update-SessionPath
    }
    if ($script:DryRun) { return (Invoke-Logged fnm @('install', '--lts')) }
    if (-not (Test-Command fnm)) { Write-Err 'fnm terpasang tapi belum terbaca di PATH.'; return $false }

    # Versi LTS terbaru diambil eksplisit supaya alias default jelas.
    $latest = (& fnm ls-remote --lts 2>$null | Select-Object -Last 1)
    if (-not $latest) { Write-Err 'Tidak bisa membaca daftar versi Node dari fnm.'; return $false }
    $version = ($latest.Trim() -split '\s+')[0]
    return ((Invoke-Logged fnm @('install', $version)) -and (Invoke-Logged fnm @('default', $version)))
}
