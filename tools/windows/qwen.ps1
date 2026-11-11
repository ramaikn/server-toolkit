# Qwen Code. Cara pasang resmi lewat npm global (butuh tool node).
# Kuota gratis Qwen OAuth berakhir 15 April 2026; model dipakai lewat OpenRouter atau API key.

function Test-Tool_qwen { Test-Command qwen }
function Get-ToolVersion_qwen { "qwen $(& qwen --version 2>$null)" }
function Install-Tool_qwen { (Invoke-ToolRequire 'node') -and (Install-NpmGlobal '@qwen-code/qwen-code@latest') }
function Get-ToolHint_qwen { "Qwen Code: jalankan 'qwen' lalu atur provider (OpenRouter atau API key)." }
