# Docker Desktop lewat winget. Satu-satunya tool yang dipasang untuk seluruh komputer
# (butuh admin dan WSL2). Hanya ada di profil full, dan Windows sendiri memunculkan
# dialog izin admin, jadi tidak ditanya lagi di sini.

function Test-Tool_docker {
    if (-not (Test-Command docker)) { return $false }
    & docker compose version *> $null
    return ($LASTEXITCODE -eq 0)
}
function Get-ToolVersion_docker { (& docker --version) 2>$null }

function Install-Tool_docker {
    Write-Info 'Docker Desktop dipasang untuk seluruh komputer; setujui dialog izin admin bila muncul.'
    return (Install-WingetPackage 'Docker.DockerDesktop' -Machine)
}

function Get-ToolHint_docker {
    'Docker: restart Windows bila diminta, buka Docker Desktop sekali dan tunggu sampai statusnya running.'
}
