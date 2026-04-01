# Loads Visual Studio compiler environment variables into the current PowerShell session.
# Example vcvars path:
#   C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars64.bat
#
# Usage:
#   .\scripts\windows\load_vcvars.ps1 "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars64.bat"

param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$VcvarsPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$resolvedVcvarsPath = (Resolve-Path -LiteralPath $VcvarsPath).ProviderPath

if (-not (Test-Path -LiteralPath $resolvedVcvarsPath -PathType Leaf)) {
    throw "vcvars script not found: $VcvarsPath"
}

$vcvarsOutput = cmd /c "`"$resolvedVcvarsPath`" && set"

if ($LASTEXITCODE -ne 0) {
    throw "Failed to load Visual Studio environment from: $resolvedVcvarsPath"
}

foreach ($line in $vcvarsOutput) {
    if ($line -match "^(.*?)=(.*)$") {
        Set-Item -Path "Env:$($matches[1])" -Value $matches[2]
    }
}
