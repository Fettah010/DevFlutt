#requires -Version 5.1
# Local quality gate for the DevFlutt repository.
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
        [Parameter(Mandatory = $true)][string[]]$Arguments,
        [string]$WorkingDirectory = $ProjectRoot
    )
    $log = Join-Path $LogDir "$Name.log"
    Write-Host "==> $Name`: $Command $($Arguments -join ' ')"
    Push-Location $WorkingDirectory
    try {
        & $Command @Arguments *> $log
        $code = $LASTEXITCODE
    }
    finally {
        Pop-Location
    }
    if ($code -eq 0) {
        Write-Host '    PASS'
    }
    else {
        Write-Host "    FAIL (exit $code). See $log"
        Get-Content $log
        $script:Failed++
    }
}

$GeneratorDir = Join-Path $ProjectRoot 'tool/ftemplate_cli'
$ModuleDependencyAuditDir = Join-Path $ProjectRoot 'tool/module_dependency_audit'
$SecurityToolsDir = Join-Path $env:LOCALAPPDATA 'DevFlutt/security-tools/bin'

function Resolve-SecurityTool {
    param([Parameter(Mandatory = $true)][string]$Name)
    $installedCommand = Get-Command $Name -ErrorAction SilentlyContinue
    if ($installedCommand) {
        return $installedCommand.Source
    }
    $userInstalledCommand = Join-Path $SecurityToolsDir "$Name.exe"
    if (Test-Path -LiteralPath $userInstalledCommand -PathType Leaf) {
        return $userInstalledCommand
    }
    return $null
}

Invoke-Check -Name 'pub_get' -Command 'flutter' -Arguments @('pub', 'get')
Invoke-Check -Name 'format' -Command 'dart' -Arguments @('format', '--output=none', '--set-exit-if-changed', 'lib', 'test')
Invoke-Check -Name 'analyze' -Command 'flutter' -Arguments @('analyze', '--fatal-infos')
Invoke-Check -Name 'test' -Command 'flutter' -Arguments @('test')
Invoke-Check -Name 'apk_debug' -Command 'flutter' -Arguments @('build', 'apk', '--debug', '--flavor', 'dev')
Invoke-Check -Name 'apk_release' -Command 'flutter' -Arguments @('build', 'apk', '--release', '--flavor', 'prod')

Invoke-Check -Name 'generator_pub_get' -Command 'dart' -Arguments @('pub', 'get') -WorkingDirectory $GeneratorDir
Invoke-Check -Name 'generator_format' -Command 'dart' -Arguments @('format', '--output=none', '--set-exit-if-changed', '.') -WorkingDirectory $GeneratorDir
Invoke-Check -Name 'generator_analyze' -Command 'dart' -Arguments @('analyze', '--fatal-infos') -WorkingDirectory $GeneratorDir
Invoke-Check -Name 'generator_test' -Command 'dart' -Arguments @('test') -WorkingDirectory $GeneratorDir

Invoke-Check -Name 'module_dependency_audit_pub_get' -Command 'flutter' -Arguments @('pub', 'get') -WorkingDirectory $ModuleDependencyAuditDir

Invoke-Check -Name 'license_inventory' -Command 'dart' -Arguments @('run', 'tool/ftemplate_cli/tool/license_inventory.dart', '--check')

$Gitleaks = Resolve-SecurityTool -Name 'gitleaks'
if ($Gitleaks) {
    Invoke-Check -Name 'secret_scan_history' -Command $Gitleaks -Arguments @('git', '--redact', '--verbose', '--report-format', 'json', '--report-path', (Join-Path $LogDir 'gitleaks-history.json'), '.')
    Invoke-Check -Name 'secret_scan_worktree' -Command $Gitleaks -Arguments @('dir', '--redact', '--verbose', '--report-format', 'json', '--report-path', (Join-Path $LogDir 'gitleaks-worktree.json'), '.')
}
else {
    Write-Host '==> secret_scan`: FAIL (Run .\tool\setup\install-security-tools.ps1 to install the pinned scanners.)'
    $script:Failed++
}
$OsvScanner = Resolve-SecurityTool -Name 'osv-scanner'
if ($OsvScanner) {
    $OsvReport = Join-Path $LogDir 'osv-scanner.json'
    $OsvLog = Join-Path $LogDir 'dependency_audit.log'
    Write-Host "==> dependency_audit`: osv-scanner scan source --lockfile pubspec.lock --lockfile tool/ftemplate_cli/pubspec.lock --lockfile tool/module_dependency_audit/pubspec.lock --format json --output-file $OsvReport"
    & $OsvScanner scan source --lockfile pubspec.lock --lockfile tool/ftemplate_cli/pubspec.lock --lockfile tool/module_dependency_audit/pubspec.lock --format json --output-file $OsvReport 1> $null 2> $OsvLog
    $OsvExitCode = $LASTEXITCODE
    if ($OsvExitCode -eq 0) {
        Write-Host '    PASS'
    }
    else {
        Write-Host "    FAIL (exit $OsvExitCode). See $OsvLog and $OsvReport"
        Get-Content $OsvLog
        if (Test-Path -LiteralPath $OsvReport) {
            Get-Content $OsvReport
        }
        $script:Failed++
    }
}
else {
    Write-Host '==> dependency_audit`: FAIL (Run .\tool\setup\install-security-tools.ps1 to install the pinned scanners.)'
    $script:Failed++
}

Write-Host '==> release_permissions'
$ReleaseApk = Join-Path $ProjectRoot 'build/app/outputs/flutter-apk/app-prod-release.apk'
$Sdk = if ($env:ANDROID_HOME) { $env:ANDROID_HOME } else { $env:ANDROID_SDK_ROOT }
# The build tools ship an executable that is named `aapt2.exe` on Windows and
# `aapt2` elsewhere. Resolving only one of the two made this check skip on
# Windows, so it never ran locally.
$Aapt2 = $null
if ($Sdk) {
    $BuildTools = Get-ChildItem -Path (Join-Path $Sdk 'build-tools') -Directory -ErrorAction SilentlyContinue |
        Sort-Object { [version]($_.Name -replace '[^0-9.]', '') } |
        Select-Object -Last 1
    if ($BuildTools) {
        foreach ($Candidate in @('aapt2.exe', 'aapt2')) {
            $Path = Join-Path $BuildTools.FullName $Candidate
            if (Test-Path $Path) {
                $Aapt2 = $Path
                break
            }
        }
    }
}
if (-not $Aapt2) {
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
