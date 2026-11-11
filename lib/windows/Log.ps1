# Logging dan eksekusi perintah untuk Windows. Output perintah masuk ke file log,
# layar hanya berisi pesan ringkas.

$script:LogDir = Join-Path $script:ToolkitRoot 'logs'
New-Item -ItemType Directory -Force -Path $script:LogDir | Out-Null
$script:LogFile = Join-Path $script:LogDir ("setup-{0}.log" -f (Get-Date -Format 'yyyyMMdd-HHmmss'))
$script:DryRun = $false
$script:AssumeYes = $false

function Write-LogFile([string]$Level, [string]$Message) {
    $line = '{0} [{1}] {2}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Level, $Message
    # UTF-8 eksplisit: bawaan PowerShell 5.1 menulis UTF-16
    [IO.File]::AppendAllText($script:LogFile, $line + [Environment]::NewLine, (New-Object Text.UTF8Encoding($false)))
}

function Write-Info([string]$m)  { Write-LogFile INFO $m;  Write-Host "  $m" }
function Write-Ok([string]$m)    { Write-LogFile INFO $m;  Write-Host '  OK  ' -ForegroundColor Green -NoNewline; Write-Host $m }
function Write-Warn([string]$m)  { Write-LogFile WARN $m;  Write-Host '  !   ' -ForegroundColor Yellow -NoNewline; Write-Host $m }
function Write-Err([string]$m)   { Write-LogFile ERROR $m; Write-Host '  X   ' -ForegroundColor Red -NoNewline; Write-Host $m }
function Write-Title([string]$m) { Write-LogFile INFO "== $m =="; Write-Host ''; Write-Host $m -ForegroundColor White }

# Jalankan program eksternal, output ke log. Return $true jika exit code termasuk $OkCodes.
function Invoke-Logged {
    param([string]$File, [string[]]$Arguments = @(), [int[]]$OkCodes = @(0))
    $display = "$File $($Arguments -join ' ')"
    if ($script:DryRun) { Write-Host "  [dry-run] $display" -ForegroundColor DarkGray; return $true }
    Write-LogFile CMD $display
    # Stderr program native dianggap error oleh PS 5.1; Continue supaya tidak menghentikan skrip.
    $prev = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        & $File @Arguments 2>&1 | ForEach-Object { Write-LogFile OUT "$_" }
        $code = $LASTEXITCODE
    } catch {
        Write-LogFile ERROR $_.Exception.Message
        $code = -1
    } finally {
        $ErrorActionPreference = $prev
    }
    Write-LogFile CMD "exit $code"
    return ($OkCodes -contains $code)
}

function Test-Command([string]$Name) { [bool](Get-Command $Name -ErrorAction SilentlyContinue) }

function Confirm-Step([string]$Prompt) {
    if ($script:AssumeYes) { return $true }
    $r = Read-Host "  $Prompt [Y/n]"
    return ($r -eq '' -or $r -match '^[Yy]')
}
