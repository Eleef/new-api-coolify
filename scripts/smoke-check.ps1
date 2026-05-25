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

$home = Invoke-WebRequest -Uri $base -Method Get -TimeoutSec 20
if ($home.StatusCode -lt 200 -or $home.StatusCode -ge 400) {
    throw "Homepage returned HTTP $($home.StatusCode)."
}

[PSCustomObject]@{
    BaseUrl    = $base
    ApiStatus  = "ok"
    Homepage   = $home.StatusCode
    CheckedAt  = (Get-Date).ToString("s")
}

