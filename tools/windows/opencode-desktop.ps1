# OpenCode Desktop lewat winget (SST.OpenCodeDesktop). Dilewati di Windows Server.

function Test-ToolSupported_opencode_desktop {
    if ($script:Platform.IsServer) { return 'Windows Server tanpa desktop' }
    return $null
}
function Test-Tool_opencode_desktop { Test-WingetInstalled 'SST.OpenCodeDesktop' }
function Install-Tool_opencode_desktop { Install-WingetPackage 'SST.OpenCodeDesktop' }
function Get-ToolHint_opencode_desktop { 'OpenCode Desktop: buka dari Start menu.' }
