#requires -Version 5.1
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not [Runtime.InteropServices.RuntimeInformation]::IsOSPlatform(
    [Runtime.InteropServices.OSPlatform]::Windows
)) {
    throw 'This installer currently supports Windows x64 only.'
}
if ([Runtime.InteropServices.RuntimeInformation]::ProcessArchitecture -ne
    [Runtime.InteropServices.Architecture]::X64
) {
    throw 'This installer currently supports Windows x64 only.'
}

$toolsDirectory = Join-Path $env:LOCALAPPDATA 'DevFlutt/security-tools/bin'
$stageDirectory = Join-Path ([System.IO.Path]::GetTempPath()) (
    'devflutt-security-tools-' + [guid]::NewGuid().ToString('N')
)
New-Item -ItemType Directory -Force -Path $toolsDirectory, $stageDirectory | Out-Null

$gitleaksArchive = Join-Path $stageDirectory 'gitleaks.zip'
$osvScanner = Join-Path $stageDirectory 'osv-scanner.exe'
$gitleaksUrl = 'https://github.com/gitleaks/gitleaks/releases/download/v8.30.1/gitleaks_8.30.1_windows_x64.zip'
$osvScannerUrl = 'https://github.com/google/osv-scanner/releases/download/v2.7.0/osv-scanner_windows_amd64.exe'
$gitleaksSha256 = 'd29144deff3a68aa93ced33dddf84b7fdc26070add4aa0f4513094c8332afc4e'
$osvScannerSha256 = '9964ed64ec9a387391eb4cc006ad5c531154821aef29b793e02c448de4686438'

try {
    Write-Host 'Downloading Gitleaks 8.30.1...'
    Invoke-WebRequest -Uri $gitleaksUrl -OutFile $gitleaksArchive
    $actualGitleaksHash = (Get-FileHash -Path $gitleaksArchive -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($actualGitleaksHash -ne $gitleaksSha256) {
        throw "Gitleaks checksum mismatch: expected $gitleaksSha256, received $actualGitleaksHash."
    }

    Write-Host 'Downloading OSV-Scanner 2.7.0...'
    Invoke-WebRequest -Uri $osvScannerUrl -OutFile $osvScanner
    $actualOsvScannerHash = (Get-FileHash -Path $osvScanner -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($actualOsvScannerHash -ne $osvScannerSha256) {
        throw "OSV-Scanner checksum mismatch: expected $osvScannerSha256, received $actualOsvScannerHash."
    }

    $gitleaksDirectory = Join-Path $stageDirectory 'gitleaks'
    Expand-Archive -LiteralPath $gitleaksArchive -DestinationPath $gitleaksDirectory
    $stagedGitleaks = Join-Path $gitleaksDirectory 'gitleaks.exe'
    if (-not (Test-Path -LiteralPath $stagedGitleaks -PathType Leaf)) {
        throw 'The verified Gitleaks archive did not contain gitleaks.exe.'
    }

    Copy-Item -LiteralPath $stagedGitleaks -Destination (Join-Path $toolsDirectory 'gitleaks.exe') -Force
    Copy-Item -LiteralPath $osvScanner -Destination (Join-Path $toolsDirectory 'osv-scanner.exe') -Force

    $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    $pathEntries = @($userPath -split ';' | Where-Object { $_ })
    if (-not ($pathEntries | Where-Object { $_.TrimEnd('\') -ieq $toolsDirectory.TrimEnd('\') })) {
        $updatedPath = (@($pathEntries) + $toolsDirectory) -join ';'
        [Environment]::SetEnvironmentVariable('Path', $updatedPath, 'User')
        Write-Host "Added $toolsDirectory to the user PATH."
    }
    $currentPathEntries = @($env:Path -split ';' | Where-Object { $_ })
    $currentPathHasTools = @($currentPathEntries | Where-Object {
        $_.TrimEnd('\') -ieq $toolsDirectory.TrimEnd('\')
    })
    if ($currentPathHasTools.Count -eq 0) {
        $env:Path = "$toolsDirectory;$env:Path"
    }

    & (Join-Path $toolsDirectory 'gitleaks.exe') version
    if ($LASTEXITCODE -ne 0) {
        throw "Installed Gitleaks failed its version check (exit code $LASTEXITCODE)."
    }
    & (Join-Path $toolsDirectory 'osv-scanner.exe') --version
    if ($LASTEXITCODE -ne 0) {
        throw "Installed OSV-Scanner failed its version check (exit code $LASTEXITCODE)."
    }
    Write-Host "Security tools are installed in $toolsDirectory."
}
finally {
    if (Test-Path -LiteralPath $stageDirectory) {
        Remove-Item -LiteralPath $stageDirectory -Recurse -Force
    }
}
