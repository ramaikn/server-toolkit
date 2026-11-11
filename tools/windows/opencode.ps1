# OpenCode CLI. Dokumentasi resmi v2 tidak menyediakan winget/scoop untuk Windows,
# jadi dipasang lewat paket npm resmi @opencode/cli (butuh tool node).

function Test-Tool_opencode { Test-Command opencode }
function Get-ToolVersion_opencode { "opencode $(& opencode --version 2>$null)" }
function Install-Tool_opencode { (Invoke-ToolRequire 'node') -and (Install-NpmGlobal '@opencode/cli') }
function Get-ToolHint_opencode { "OpenCode: jalankan 'opencode' di folder proyek, lalu '/connect' untuk memilih model gratis." }
