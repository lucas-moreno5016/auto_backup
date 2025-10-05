# ===== CONFIGURATION =====
$adb = 'C:\Users\Mon PC\.adb\adb.exe'  # Path to adb.exe
$backupMap = @{
    '/storage/sdcard0/backup_test' = 'E:/phone_backup_test'
}

# ===== FUNCTIONS =====

function Format-Directory {
    param([string]$path)
    # Creates directory corresponding to path if doesn't exist
    if (-not (Test-Path $path)) {
        New-Item -ItemType Directory -Force -Path $path | Out-Null
    }
}

function Backup-Folder {
    param (
        [string]$remoteFolder,
        [string]$localFolder
    )

    Write-Host "`n  Scanning $remoteFolder..." -ForegroundColor Cyan

    $remoteFiles = & $adb shell find "`"$remoteFolder`"" -type f | ForEach-Object {
        $_.Trim()
    }

    foreach ($remoteFile in $remoteFiles){
        $relativePath = $remoteFile.Substring($remoteFolder.Length).TrimStart('/')
        $localPath = Join-Path $localFolder $relativePath
        $localDir = Split-Path $localPath

        Format-Directory $localDir

        if (-Not (Test-Path $localPath)) {
            Write-Host "  Copying: $relativePath"
            & $adb pull "`"$remoteFile`"" "`"$localPath`"" | Out-Null
        } else {
            Write-Host "  Skipped: $relativePath"
        }
    }
}

# ===== MAIN SCRIPT =====

if (-not (Test-Path $adb)) {
    Write-Error "adb not found at $adb"
    exit 1
}

foreach ($pair in $backupMap.GetEnumerator()) {
    Backup-Folder $pair.Key $pair.Value
}

Write-Host "`n  Backup completed." -ForegroundColor Green
