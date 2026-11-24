<#
.SYNOPSIS
    Local environment wrapper for running Flutter within the Mobile-Language-App project.
.DESCRIPTION
    Explicitly prepends the isolated .tools\flutter\bin directory to the active process
    environment variables and executes Flutter commands cleanly against local hardware.
#>

[CmdletBinding()]
param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$FlutterArgs = @("doctor")
)

$ProjectRoot = $PSScriptRoot
$LocalFlutterBin = Join-Path $ProjectRoot ".tools\flutter\bin"
$FlutterExe = Join-Path $LocalFlutterBin "flutter.bat"

if (-not (Test-Path $FlutterExe)) {
    Write-Host "[ERROR] Local Flutter SDK binary not found at: $FlutterExe" -ForegroundColor Red
    exit 1
}

# Explicitly prepend .tools/flutter/bin to active process PATH
$env:PATH = "$LocalFlutterBin;$env:PATH"
Write-Host "[LOCAL FLUTTER BRIDGE] Mapped PATH -> $LocalFlutterBin" -ForegroundColor Green

if ($FlutterArgs.Count -eq 0) {
    & $FlutterExe doctor
} else {
    & $FlutterExe @FlutterArgs
}
