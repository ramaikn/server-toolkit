# Alat dasar: Git for Windows (juga memberi Git Bash untuk coding agent),
# ripgrep dan jq (dipakai agent untuk mencari dan membaca data).

function Test-Tool_base { (Test-Command git) -and (Test-Command rg) -and (Test-Command jq) }
function Get-ToolVersion_base { (& git --version) 2>$null }

function Install-Tool_base {
    $ok = $true
    if (-not (Test-Command git)) { $ok = (Install-WingetPackage 'Git.Git') -and $ok }
    if (-not (Test-Command rg))  { $ok = (Install-WingetPackage 'BurntSushi.ripgrep.MSVC') -and $ok }
    if (-not (Test-Command jq))  { $ok = (Install-WingetPackage 'jqlang.jq') -and $ok }
    return $ok
}
