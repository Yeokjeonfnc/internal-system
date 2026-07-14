$ErrorActionPreference = 'Stop'

$ruleName = 'Y-ON Field HTTP 8080'
$existing = Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue
if ($existing) {
    Write-Host "[INFO] Firewall rule already exists: $ruleName"
    exit 0
}

New-NetFirewallRule `
    -DisplayName $ruleName `
    -Direction Inbound `
    -Protocol TCP `
    -LocalPort 8080 `
    -Action Allow | Out-Null

Write-Host "[OK] Firewall rule created: $ruleName"
