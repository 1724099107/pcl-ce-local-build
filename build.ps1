#Requires -Version 5.1
<#
.SYNOPSIS
    Build PCL CE, optionally injecting the Microsoft OAuth client ID and other secrets.

.DESCRIPTION
    Some credentials used by PCL (the Microsoft OAuth client ID, CurseForge API key, ...)
    are not distributed with the source. They are written into the assembly at compile
    time by PCL.Core.SourceGenerators, which reads PCL_* environment variables when
    PCL_WRITE_SECRET is present.

    This script sets those variables and then invokes dotnet build. Because the source
    generator runs at compile time and MSBuild cannot detect changes to environment
    variables, a full rebuild is forced whenever a secret is injected.

.EXAMPLE
    .\build.ps1 -Configuration Release -MsClientId "11111111-2222-3333-4444-555555555555"
#>
param(
    [ValidateSet("Debug", "Release", "CI", "Beta")]
    [string]$Configuration = "Release",

    [ValidateSet("x64", "ARM64")]
    [string]$Platform = "x64",

    # Microsoft OAuth public client ID used by the device code flow.
    [string]$MsClientId = "",

    [string]$CurseForgeApiKey = "",
    [string]$NaidClientId = "",
    [string]$NaidClientSecret = "",

    # Location used by dotnet-install when dotnet is not on PATH.
    [string]$DotnetPath = "$env:LOCALAPPDATA\Microsoft\dotnet\dotnet.exe",

    # Force a full rebuild (enabled automatically when secrets are injected).
    [switch]$Rebuild
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $MyInvocation.MyCommand.Path

if (-not (Test-Path $DotnetPath)) {
    $found = Get-Command dotnet -ErrorAction SilentlyContinue
    if ($found) { $DotnetPath = $found.Source }
    else { throw "dotnet not found. Install the .NET 10 SDK or pass -DotnetPath." }
}

$env:DOTNET_CLI_TELEMETRY_OPTOUT = "1"
$env:DOTNET_NOLOGO = "1"

$injected = @{}
if ($MsClientId)       { $injected["PCL_MS_CLIENT_ID"]       = $MsClientId }
if ($CurseForgeApiKey) { $injected["PCL_CURSEFORGE_API_KEY"] = $CurseForgeApiKey }
if ($NaidClientId)     { $injected["PCL_NAID_CLIENT_ID"]     = $NaidClientId }
if ($NaidClientSecret) { $injected["PCL_NAID_CLIENT_SECRET"] = $NaidClientSecret }

if ($injected.Count -gt 0) {
    $env:PCL_WRITE_SECRET = "1"
    foreach ($k in $injected.Keys) { Set-Item -Path "env:$k" -Value $injected[$k] }
    Write-Host "Injected secrets: $($injected.Keys -join ', ')" -ForegroundColor Cyan
} else {
    Write-Host "No secrets supplied; the build uses the defaults in the source tree." -ForegroundColor Yellow
}

$rebuildArg = @()
if ($injected.Count -gt 0 -or $Rebuild) { $rebuildArg = @("-t:Rebuild") }

& $DotnetPath build (Join-Path $root "Plain Craft Launcher 2.slnx") `
    -c $Configuration -p:Platform=$Platform -v m @rebuildArg

if ($LASTEXITCODE -ne 0) { throw "Build failed with exit code $LASTEXITCODE." }

$out = Join-Path $root "Plain Craft Launcher 2\bin\$Configuration\net10.0-windows"
Write-Host ""
Write-Host "Build completed: $out\Plain Craft Launcher 2.exe" -ForegroundColor Green
