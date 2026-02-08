
Import-Module -Name (Join-Path $PSScriptRoot 'helperFunctions.psm1') -Force
Import-Module -Name (Join-Path $PSScriptRoot 'gui.psm1') -Force
Import-Module -Name (Join-Path $PSScriptRoot 'serviceFunctions.psm1') -Force

# Ensure logs directory and daily log file exist
$logDir = Join-Path $PSScriptRoot 'logs'
if (-not (Test-Path $logDir -PathType Container -ErrorAction SilentlyContinue)) {
    New-Item -Path $logDir -ItemType Directory | Out-Null
}

$logFileName = "DynamicGuiLog_$((Get-Date).ToString('yyyy-MM-dd')).log"
$logPath = Join-Path $logDir $logFileName
if (-not (Test-Path $logPath -PathType Leaf -ErrorAction SilentlyContinue)) {
    New-Item -Path $logPath -ItemType File | Out-Null
}

# Initialize global state before any logging
$global:state = [hashtable]::Synchronized(@{
        LogFilePath   = $logPath
        ParamControls = @()
        form          = New-GUI
    })

Write-LogMessage -Message "Application started" -Level 'INFO'

$global:state.form.ShowDialog()

Write-LogMessage -Message "Application Closed" -Level 'INFO'