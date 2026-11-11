# Gemini CLI. Cara pasang resmi lewat npm global (butuh tool node).

function Test-Tool_gemini { Test-Command gemini }
function Get-ToolVersion_gemini { "gemini $(& gemini --version 2>$null)" }
function Install-Tool_gemini { (Invoke-ToolRequire 'node') -and (Install-NpmGlobal '@google/gemini-cli') }
function Get-ToolHint_gemini { "Gemini CLI: jalankan 'gemini' lalu login dengan akun Google (kuota gratis harian)." }
