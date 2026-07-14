# 매일 DB 자동 백업 작업 해제.
$ErrorActionPreference = 'Stop'

$taskName = 'YON Field DB Backup'
Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue
Write-Host "[OK] Backup task removed: $taskName"
