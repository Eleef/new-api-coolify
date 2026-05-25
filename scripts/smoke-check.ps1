param(
    [Parameter(Mandatory = $true)]
    [string]$BaseUrl
)

$ErrorActionPreference = "Stop"
$base = $BaseUrl.TrimEnd("/")

$status = Invoke-RestMethod -Uri "$base/api/status" -Method Get -TimeoutSec 20
if (-not $status.success) {
    throw "Health endpoint did not return success=true."
}

$homeResponse = Invoke-WebRequest -Uri $base -Method Get -TimeoutSec 20
if ($homeResponse.StatusCode -lt 200 -or $homeResponse.StatusCode -ge 400) {
    throw "Homepage returned HTTP $($homeResponse.StatusCode)."
}

[PSCustomObject]@{
    BaseUrl    = $base
    ApiStatus  = "ok"
    Homepage   = $homeResponse.StatusCode
    CheckedAt  = (Get-Date).ToString("s")
}
