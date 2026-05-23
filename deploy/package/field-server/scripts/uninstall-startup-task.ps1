$ErrorActionPreference = 'Stop'

$taskName = 'YON Field Server'
$task = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
if ($task) {
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
    Write-Host "[OK] Startup task removed: $taskName"
} else {
    Write-Host "[INFO] Startup task not found: $taskName"
}
