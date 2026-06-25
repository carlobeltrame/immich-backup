# Copy this file to config.ps1 and fill in your values.
# config.ps1 is gitignored and never committed.

# rclone remote name (as configured with "rclone config")
$Remote = "immich-s3"

# S3 bucket name
$Bucket = "your-immich-bucket"

# Local directory where assets will be stored
$LocalPath = "D:\Backups\Immich"

# Number of parallel transfers (increase for fast connections, decrease if errors)
$Transfers = 8
