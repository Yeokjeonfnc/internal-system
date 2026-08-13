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

# 인증이 필요한 경로는 토큰 없이 호출하면 401 이 정상이다. 그것을 확인해
# "게이트웨이가 백엔드까지 요청을 넘기고 있다"는 사실을 검증한다.
function Test-ExpectStatus {
    param(
        [string]$Name,
        [string]$Url,
        [int]$Expected
    )
    $status = $null
    try {
        $response = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 10
        $status = [int]$response.StatusCode
    } catch {
        if ($_.Exception.Response) {
            $status = [int]$_.Exception.Response.StatusCode
        } else {
            Write-Host "[FAIL] ${Name}: $($_.Exception.Message)"
            return
        }
    }
    if ($status -eq $Expected) {
        Write-Host "[OK] ${Name}: HTTP $status (expected)"
    } else {
        Write-Host "[FAIL] ${Name}: HTTP $status (expected $Expected)"
    }
}

Test-Get -Name 'Web' -Url 'http://127.0.0.1:8080/'
# 업무 엔드포인트(/api/stores)는 이제 로그인 토큰이 필요하다 — 인증 없이 호출 가능한
# /api/health 로 확인한다.
Test-Get -Name 'Backend health' -Url 'http://127.0.0.1:3001/api/health'

# 예전에는 admin/admin123 으로 실제 로그인을 시도했다. 이제 그렇게 하면 안 된다.
#  1) 비밀번호가 틀리면 매번 [FAIL] 로 보여 진짜 장애와 구분이 안 된다.
#  2) 로그인 10회 연속 실패 시 계정이 10분 잠기므로, 이 스크립트를 반복 실행하면
#     **admin 계정이 잠긴다.**
# 게이트웨이 확인은 인증이 필요한 경로가 401 을 돌려주는지로 대신한다.
Test-ExpectStatus -Name 'Web gateway -> backend (401 expected)' -Url 'http://127.0.0.1:8080/api/users' -Expected 401
