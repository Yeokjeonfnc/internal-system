$ErrorActionPreference = 'Continue'

$checks = @(
    @{ Name = 'Web'; Url = 'http://127.0.0.1:8080/' },
    @{ Name = 'Backend stores'; Url = 'http://127.0.0.1:3001/api/stores' }
)

foreach ($check in $checks) {
    try {
        $response = Invoke-WebRequest -Uri $check.Url -UseBasicParsing -TimeoutSec 10
        Write-Host "[OK] $($check.Name): HTTP $($response.StatusCode)"
    } catch {
        $status = $null
        if ($_.Exception.Response) {
            $status = [int]$_.Exception.Response.StatusCode
        }
        if ($status) {
            Write-Host "[FAIL] $($check.Name): HTTP $status"
        } else {
            Write-Host "[FAIL] $($check.Name): $($_.Exception.Message)"
        }
    }
}
