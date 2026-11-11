# uv (installer resmi Astral, ke %USERPROFILE%\.local\bin) lalu Python 3.12 yang dikelola uv.

$script:PythonVersion = '3.12'

function Test-Tool_python {
    if (-not (Test-Command uv)) { return $false }
    & uv python find $script:PythonVersion *> $null
    return ($LASTEXITCODE -eq 0)
}

function Get-ToolVersion_python {
    $py = & uv python find $script:PythonVersion 2>$null
    "$(& uv --version 2>$null), $(& $py --version 2>$null)"
}

function Install-Tool_python {
    if (-not (Test-Command uv)) {
        # PATH diurus setup sendiri (Save-UserPaths), installer tidak perlu mengubahnya.
        if (-not (Invoke-RemoteScript 'https://astral.sh/uv/install.ps1' -Env @{ UV_NO_MODIFY_PATH = '1' })) { return $false }
        Update-SessionPath
    }
    return (Invoke-Logged uv @('python', 'install', $script:PythonVersion))
}
