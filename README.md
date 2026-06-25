# Immich S3 Backup

Backs up all Immich assets from S3-compatible storage to a local Windows directory using rclone.

## Prerequisites

1. [rclone](https://rclone.org/downloads/) — download the Windows installer or zip, add to `PATH`.

## One-time Setup

### 1. Configure rclone

Open PowerShell and run:

```powershell
rclone config
```

Follow the prompts:
- `n` → New remote
- Name: `immich-s3`
- Storage type: `s3`
- S3 provider: choose your provider (AWS / Ceph / Minio / Other S3-compatible)
- Access Key ID and Secret Access Key: your credentials
- Endpoint: the S3 endpoint URL (e.g. `https://s3.example.com`)
- Leave other settings at defaults unless you know otherwise

Test it works:
```powershell
# Use Ctrl+C to cancel listing
rclone ls immich-s3:your-immich-bucket
```

### 2. Create your config

```powershell
Copy-Item config.example.ps1 config.ps1
```

Then open `config.ps1` and set your values:

```powershell
$Remote     = "immich-s3"              # rclone remote name
$Bucket     = "your-immich-bucket"     # your actual bucket name
$LocalPath  = "D:\Backups\Immich"      # where to store files locally
```

`config.ps1` is gitignored and will never be committed.

### 3. Test a manual run

```powershell
powershell -ExecutionPolicy Bypass -File .\immich-backup.ps1
```

## Schedule with Task Scheduler

1. Open **Task Scheduler** → *Create Basic Task*
2. **Name**: `Immich S3 Backup`
3. **Trigger**: Daily at e.g. 02:00
4. **Action**: Start a program
   - Program: `powershell.exe`
   - Arguments: `-ExecutionPolicy Bypass -NonInteractive -File "C:\path\to\immich-backup.ps1"`
5. Under *General*, check **Run whether user is logged on or not** and tick **Run with highest privileges**
6. Under *Conditions*, uncheck "Start only if on AC power" if you want it to run on laptop battery too

## Logs

Each run appends to `_backup.log` inside your `$LocalPath`. The log records every file
transferred, errors, and timing.

## Behavior

- **Incremental**: only downloads files that are new or have changed (by checksum).
- **Non-destructive**: files deleted from S3 are NOT deleted locally — your backup grows over time as a full history. To mirror deletions add `--delete-during` to `$RcloneArgs` in the script (use with caution).
- **Safe to re-run**: running twice in a row will transfer nothing if nothing changed.
