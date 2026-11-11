# Claude Code lewat installer native resmi, ke %USERPROFILE%\.local\bin. Update otomatis.

function Test-Tool_claude { Test-Command claude }
function Get-ToolVersion_claude { (& claude --version) 2>$null }
function Install-Tool_claude { Invoke-RemoteScript 'https://claude.ai/install.ps1' }
function Get-ToolHint_claude { "Claude Code: jalankan 'claude' lalu login (butuh langganan Claude atau API key)." }
