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
            # if file does not exist in back up, paste it there
            Write-Host "    $relativePath not in backup. Adding to backup."  -ForegroundColor Green
            & $adb pull "`"$remoteFile`"" "`"$localPath`"" *> $null
        } else {
            # if file exists in backup, compare hashes of remote and backup file.
            # We compare the file hashes. If different, files are different (statistically garanted)
            $remoteHash = (& $adb shell md5sum "`"$remoteFile`"" | ForEach-Object { ($_ -split ' ')[0].Trim() })
            $localHash  = (Get-FileHash $localPath -Algorithm MD5).Hash.ToLower()
            if (-Not ($remoteHash -eq $localHash)){
                Write-Host "    $relativePath edited since last backup. Editing backup." -ForegroundColor DarkYellow
                & $adb pull "`"$remoteFile`"" "`"$localPath`"" *> $null
            } else {
            Write-Host "     $relativePath already in backup. Skipped" -ForegroundColor DarkGray
            }
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

Write-Host "`nBackup completed." -ForegroundColor Green
