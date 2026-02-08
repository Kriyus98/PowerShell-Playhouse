$configJson = Get-Content -path "./config.json" -Raw | ConvertFrom-JSON

$daysToDelete = $configJson.daysToDelete
$pathPatterns = $configJson.paths

Write-Host "Deleting files older than $daysToDelete days."

# Calculate the cutoff date
$cutoffDate = (Get-Date).AddDays(-$daysToDelete)

# Get all local users, excluding special accounts
$specialAccounts = @("Guest", "DefaultAccount", "WDAGUtilityAccount", "SYSTEM")
$allUsers = @(Get-LocalUser | Where-Object {
        $_.Enabled -eq $true -and 
        $_.Name -notin $specialAccounts
    })

if ($allUsers.Count -eq 0) {
    Write-Warning "No eligible users found on this machine."
    exit
}

Write-Host "Found $($allUsers.Count) eligible user(s): $($allUsers.Name -join ', ')`n"

# Track overall statistics
$totalFilesDeleted = 0
$totalSizeDeleted = 0
$usersToCleanupRecycleBin = @()

foreach ($user in $allUsers) {
    $username = $user.Name
    Write-Host "Processing user: $username" -ForegroundColor Cyan
    
    # Track statistics per user
    $userFilesDeleted = 0
    $userSizeDeleted = 0
    
    foreach ($pathPattern in $pathPatterns) {
        $folderPath = $pathPattern.folderPath -replace "\*", $username
        Write-Host "  Path: $folderPath"
        
        # Track statistics per path
        $pathFilesDeleted = 0
        $pathSizeDeleted = 0
        
        try {
            if (-not (Test-Path $folderPath)) {
                Write-Warning "    Path not found or inaccessible: $folderPath"
                continue
            }
            
            # Get all files older than cutoff date
            $oldFiles = @(Get-ChildItem -Path $folderPath -File -Recurse -ErrorAction SilentlyContinue | 
                Where-Object { $_.LastWriteTime -lt $cutoffDate })
            
            if ($oldFiles.Count -gt 0) {
                Write-Host "    Found $($oldFiles.Count) file(s) to delete"
                
                foreach ($file in $oldFiles) {
                    try {
                        $fileSize = $file.Length
                        Remove-Item -Path $file.FullName -Force -ErrorAction Stop
                        
                        $pathFilesDeleted++
                        $pathSizeDeleted += $fileSize
                    }
                    catch {
                        # Silently skip files that can't be deleted (in use, access denied, etc.)
                    }
                }
            }
            else {
                Write-Host "    No files older than $cutoffDate"
            }
        }
        catch {
            Write-Warning "    Error processing path '$folderPath`: $_"
        }
        
        # Add to user totals
        $userFilesDeleted += $pathFilesDeleted
        $userSizeDeleted += $pathSizeDeleted
        
        # Display path summary
        if ($pathFilesDeleted -gt 0) {
            $sizeMB = '{0:N2}' -f ($pathSizeDeleted / 1MB)
            $sizeGB = '{0:N2}' -f ($pathSizeDeleted / 1GB)
            Write-Host "    Summary: $pathFilesDeleted files, $sizeGB GB ($sizeMB MB)" -ForegroundColor Yellow
        }
    }
    
    # Display user summary
    if ($userFilesDeleted -gt 0) {
        $userSizeGB = '{0:N2}' -f ($userSizeDeleted / 1GB)
        Write-Host "  User Summary ($username): $userFilesDeleted files deleted, $userSizeGB GB" -ForegroundColor Green
        $totalFilesDeleted += $userFilesDeleted
        $totalSizeDeleted += $userSizeDeleted
    }
    
    # Add user to recycle bin cleanup list
    $usersToCleanupRecycleBin += $username
    Write-Host ""
}

# Clear recycle bin for all users
Write-Host "================================" -ForegroundColor Cyan
Write-Host "Clearing recycle bins..." -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan

foreach ($username in $usersToCleanupRecycleBin) {
    Write-Host "  Clearing recycle bin for $username..."
    try {
        $shell = New-Object -ComObject Shell.Application
        $recycleBin = $shell.NameSpace(10)
        
        # Get recycle bin item count before clearing
        $itemCount = $recycleBin.Items().Count
        
        if ($itemCount -gt 0) {
            $recycleBin.Items() | ForEach-Object { 
                Remove-Item $_.Path -Force -ErrorAction SilentlyContinue -Recurse
            }
            Write-Host "    Recycle bin cleared ($itemCount items removed)" -ForegroundColor Yellow
        }
        else {
            Write-Host "    Recycle bin already empty" -ForegroundColor Yellow
        }
        
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($shell) | Out-Null
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($recycleBin) | Out-Null
    }
    catch {
        Write-Warning "  Warning: Could not fully clear recycle bin: $_"
    }
}

# Display overall summary
Write-Host "================================" -ForegroundColor Green
Write-Host "CLEANUP COMPLETE!" -ForegroundColor Green
Write-Host "Total files deleted: $totalFilesDeleted" -ForegroundColor Green
$totalSizeGB = '{0:N2}' -f ($totalSizeDeleted / 1GB)
$totalSizeMB = '{0:N2}' -f ($totalSizeDeleted / 1MB)
Write-Host "Total size freed: $totalSizeGB GB ($totalSizeMB MB)" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Green