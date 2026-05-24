$ErrorActionPreference = 'Continue'

function Test-Get {
    param(
        [string]$Name,
        [string]$Url
    )
    try {
        $response = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 10
        Write-Host "[OK] ${Name}: HTTP $($response.StatusCode)"
    } catch {
        $status = $null
        if ($_.Exception.Response) {
            $status = [int]$_.Exception.Response.StatusCode
        }
        if ($status) {
            Write-Host "[FAIL] ${Name}: HTTP $status"
        } else {
            Write-Host "[FAIL] ${Name}: $($_.Exception.Message)"
        }
    }
}

function Test-PostJson {
    param(
        [string]$Name,
        [string]$Url,
        [string]$Body
    )
    try {
        $response = Invoke-WebRequest -Uri $Url -Method POST -ContentType 'application/json' -Body $Body -UseBasicParsing -TimeoutSec 10
        Write-Host "[OK] ${Name}: HTTP $($response.StatusCode)"
    } catch {
        $status = $null
        if ($_.Exception.Response) {
            $status = [int]$_.Exception.Response.StatusCode
        }
        if ($status) {
            Write-Host "[FAIL] ${Name}: HTTP $status"
        } else {
            Write-Host "[FAIL] ${Name}: $($_.Exception.Message)"
        }
    }
}

$loginBody = @{ userId = 'admin'; userPassword = 'admin123' } | ConvertTo-Json

Test-Get -Name 'Web' -Url 'http://127.0.0.1:8080/'
Test-Get -Name 'Backend stores' -Url 'http://127.0.0.1:3001/api/stores'
Test-PostJson -Name 'Web gateway login API' -Url 'http://127.0.0.1:8080/api/auth/login' -Body $loginBody
