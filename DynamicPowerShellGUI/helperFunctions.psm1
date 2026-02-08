function Write-LogMessage {
    param(
        [string]$Message,
        [ValidateSet('INFO', 'WARN', 'ERROR', 'DEBUG')][string]$Level = 'INFO'
    )
    $timestamp = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
    $entry = "$timestamp [$Level] $Message"
    
    if ($global:state -and $global:state['LogFilePath']) {
        Add-Content -Path $global:state['LogFilePath'] -Value $entry
    }
    
    Write-Host $entry
}


Export-ModuleMember -Function Write-LogMessage