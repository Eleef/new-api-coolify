param(
    [int]$Bytes = 32
)

if ($Bytes -lt 16) {
    throw "Use at least 16 bytes for deployment secrets."
}

function New-HexSecret {
    param([int]$Length)

    $buffer = New-Object byte[] $Length
    [System.Security.Cryptography.RandomNumberGenerator]::Fill($buffer)
    return [System.Convert]::ToHexString($buffer).ToLowerInvariant()
}

[PSCustomObject]@{
    SERVICE_PASSWORD_POSTGRES = New-HexSecret -Length $Bytes
    SERVICE_PASSWORD_REDIS    = New-HexSecret -Length $Bytes
    SERVICE_PASSWORD_SESSION  = New-HexSecret -Length $Bytes
    SERVICE_PASSWORD_CRYPTO   = New-HexSecret -Length $Bytes
}

