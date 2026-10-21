#requires -Version 5.1
# Local quality gate for the DevFlutt reference app.
#
# Prints every command, propagates every exit code, and writes per-command logs
# to build/verify-logs/. It never ends with an unconditional success message.
[CmdletBinding()]
param()

Set-StrictMode -Version Latest

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent (Split-Path -Parent $ScriptDir)
$LogDir = Join-Path $ProjectRoot 'build/verify-logs'
New-Item -ItemType Directory -Force -Path $LogDir | Out-Null

Set-Location $ProjectRoot

$script:Failed = 0

function Invoke-Check {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string]$Command,
        [Parameter(Mandatory = $true)][string[]]$Arguments
    )
    $log = Join-Path $LogDir "$Name.log"
    Write-Host "==> $Name`: $Command $($Arguments -join ' ')"
    & $Command @Arguments *> $log
    if ($LASTEXITCODE -eq 0) {
        Write-Host '    PASS'
    }
    else {
        Write-Host "    FAIL (exit $LASTEXITCODE). See $log"
        Get-Content $log
        $script:Failed++
    }
}

Invoke-Check -Name 'pub_get' -Command 'flutter' -Arguments @('pub', 'get')
Invoke-Check -Name 'format' -Command 'dart' -Arguments @('format', '--output=none', '--set-exit-if-changed', '.')
Invoke-Check -Name 'analyze' -Command 'flutter' -Arguments @('analyze', '--fatal-infos')
Invoke-Check -Name 'test' -Command 'flutter' -Arguments @('test')
Invoke-Check -Name 'apk_debug' -Command 'flutter' -Arguments @('build', 'apk', '--debug', '--flavor', 'dev')
Invoke-Check -Name 'apk_release' -Command 'flutter' -Arguments @('build', 'apk', '--release', '--flavor', 'prod')

Write-Host '==> release_permissions'
$ReleaseApk = Join-Path $ProjectRoot 'build/app/outputs/flutter-apk/app-prod-release.apk'
$Sdk = if ($env:ANDROID_HOME) { $env:ANDROID_HOME } else { $env:ANDROID_SDK_ROOT }
$Aapt2 = if ($Sdk) { (Get-ChildItem -Path (Join-Path $Sdk 'build-tools') -Directory | Sort-Object { [version]($_.Name -replace '[^0-9.]', '') } | Select-Object -Last 1 | ForEach-Object { Join-Path $_.FullName 'aapt2' }) } else { $null }
if (-not $Aapt2 -or -not (Test-Path $Aapt2)) {
    Write-Host '    SKIP (aapt2 not found; CI performs this check)'
}
else {
    $permLog = Join-Path $LogDir 'release-permissions.log'
    & $Aapt2 dump permissions $ReleaseApk *> $permLog
    if ($LASTEXITCODE -eq 0 -and -not (Select-String -Path $permLog -Pattern 'android.permission.INTERNET' -Quiet)) {
        Write-Host '    PASS'
    }
    else {
        Write-Host "    FAIL. See $permLog"
        Get-Content $permLog
        $script:Failed++
    }
}

Write-Host ''
if ($script:Failed -eq 0) {
    Write-Host 'All checks passed.'
    exit 0
}
else {
    Write-Host "$($script:Failed) check(s) failed. See $LogDir for details."
    exit 1
}
