# Bun lewat installer resmi, ke %USERPROFILE%\.bun (per-user).

function Test-Tool_bun { Test-Command bun }
function Get-ToolVersion_bun { "bun $(& bun --version 2>$null)" }
function Install-Tool_bun { Invoke-RemoteScript 'https://bun.sh/install.ps1' }
