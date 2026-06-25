# Immich S3 Backup Script
# Syncs all assets from S3-compatible storage to a local directory.
# Requires rclone: https://rclone.org/downloads/
#
# SETUP (run once):
#   1. Install rclone and add it to PATH.
#   2. Run: rclone config
#      - New remote -> name it "immich-s3"
#      - Type: s3
#      - Provider: choose your provider (or "Other" for generic S3-compatible)
#      - Enter your Access Key ID, Secret Access Key, Endpoint URL
#   3. Copy config.example.ps1 to config.ps1 and fill in your values.
#   4. Schedule via Task Scheduler (see README).

# ── Configuration ────────────────────────────────────────────────────────────

$ConfigFile = "$PSScriptRoot\config.ps1"
if (-not (Test-Path $ConfigFile)) {
    Write-Error "config.ps1 not found. Copy config.example.ps1 to config.ps1 and fill in your values."
    exit 1
}
. $ConfigFile

$LogFile = "$PSScriptRoot\backup.log"

# ── Script ───────────────────────────────────────────────────────────────────

$ErrorActionPreference = "Stop"
$StartTime = Get-Date

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $Line = "[$Timestamp] [$Level] $Message"
    Write-Host $Line
    Add-Content -Path $LogFile -Value $Line
}

# Ensure local directory exists
if (-not (Test-Path $LocalPath)) {
    New-Item -ItemType Directory -Path $LocalPath -Force | Out-Null
}

Write-Log "=== Immich backup started ==="
Write-Log "Source: ${Remote}:${Bucket}"
Write-Log "Destination: $LocalPath"

# Check rclone is available
if (-not (Get-Command rclone -ErrorAction SilentlyContinue)) {
    Write-Log "rclone not found in PATH. Install from https://rclone.org/downloads/" "ERROR"
    exit 1
}

# Run the sync
# --fast-list    : fewer API calls (better for most S3 providers)
# --checksum     : verify integrity on transfer
# --transfers N  : parallel transfers
# --log-level    : INFO shows files transferred; use DEBUG for verbose
$RcloneArgs = @(
    "copy",
    "${Remote}:${Bucket}",
    $LocalPath,
    "--fast-list",
    "--checksum",
    "--transfers", $Transfers,
    "--log-level", "INFO",
    "--log-file", $LogFile,
    "--stats", "1m"
)

Write-Log "Running: rclone $($RcloneArgs -join ' ')"

& rclone @RcloneArgs
$ExitCode = $LASTEXITCODE

$Duration = (Get-Date) - $StartTime
$DurationStr = "{0:hh\:mm\:ss}" -f $Duration

if ($ExitCode -eq 0) {
    Write-Log "=== Backup completed successfully in $DurationStr ==="
} else {
    Write-Log "=== Backup FAILED (rclone exit code $ExitCode) after $DurationStr ===" "ERROR"
    exit $ExitCode
}
