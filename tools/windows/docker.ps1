# Docker Desktop lewat winget. Ini satu-satunya tool yang dipasang untuk seluruh
# komputer (butuh admin dan WSL2), jadi ditanyakan dulu kecuali --yes.

function Test-Tool_docker {
    if (-not (Test-Command docker)) { return $false }
    & docker compose version *> $null
    return ($LASTEXITCODE -eq 0)
}
function Get-ToolVersion_docker { (& docker --version) 2>$null }

function Install-Tool_docker {
    if (-not (Confirm-Step 'Docker Desktop dipasang untuk seluruh komputer dan butuh izin admin. Lanjut?')) {
        Write-Warn 'Docker dilewati atas pilihan user.'
        return $false
    }
    return (Install-WingetPackage 'Docker.DockerDesktop' -Machine)
}

function Get-ToolHint_docker {
    'Docker: restart Windows bila diminta, buka Docker Desktop sekali dan tunggu sampai statusnya running.'
}
