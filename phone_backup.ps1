# ===== CONFIGURATION =====
$adb = "C:\Users\Mon PC\adb\adb.exe"  # Path to adb.exe
$backupMap = @{
    "/storage/sdcard0/backup_test" = "E:/phone_backup_test"
}

# ===== FUNCTIONS =====

function Format-Directory {
    param([string]$path)
    if (-not (Test-Path $path)) {
        New-Item -ItemType Directory -Force -Path $path | Out-Null
    }
}

function Backup-Folder {
    param (
        [string]$remoteFolder,
        [string]$localFolder
    )

    Write-Host "`n🔍 Scanning $remoteFolder..." -ForegroundColor Cyan

    # Get list of files on the phone
    $remoteFiles = & $adb shell find "`"$remoteFolder`"" -type f | ForEach-Object {
        $_.Trim()
    }

    foreach ($remoteFile in $remoteFiles) {
        # Convert remote file path to local equivalent
        $relativePath = $remoteFile.Substring($remoteFolder.Length).TrimStart('/')
        $localPath = Join-Path $localFolder $relativePath

        # Create directory if needed
        $localDir = Split-Path $localPath
        Format-Directory $localDir

        # Compare existence
        if (-Not (Test-Path $localPath)) {
            Write-Host "📥 Copying: $relativePath"
            & $adb pull "`"$remoteFile`"" "`"$localPath`"" | Out-Null
        } else {
            Write-Host "✅ Skipped: $relativePath"
        }
    }
}

# ===== MAIN SCRIPT =====

# Make sure ADB is available
if (-not (Test-Path $adb)) {
    Write-Error "adb not found at $adb"
    exit 1
}

# Loop through each folder pair
foreach ($pair in $backupMap.GetEnumerator()) {
    Backup-Folder $pair.Key $pair.Value
}

Write-Host "`n✅ Backup completed." -ForegroundColor Green
