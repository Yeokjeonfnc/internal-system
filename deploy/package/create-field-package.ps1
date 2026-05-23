param(
    [string]$OutputRoot = 'C:\y-on\release',
    [string]$PackageName = 'yon-field-server',
    [string]$ApiBaseUrl = 'https://test.yeokjeon.com/api',
    [string]$KakaoMapJavaScriptKey = '3649c96a39bc8cff269119d8cffbe4e0',
    [switch]$Build
)

$ErrorActionPreference = 'Stop'

function Resolve-CommandOrFallback {
    param(
        [string[]]$Names,
        [string[]]$Fallbacks
    )

    foreach ($name in $Names) {
        $cmd = Get-Command $name -ErrorAction SilentlyContinue
        if ($cmd) {
            return $cmd.Source
        }
    }

    foreach ($fallback in $Fallbacks) {
        if (Test-Path -LiteralPath $fallback) {
            return $fallback
        }
    }

    throw "Required command not found: $($Names -join ', ')"
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Resolve-Path (Join-Path $scriptDir '..\..')
$repoRoot = $repoRoot.Path

if ($Build) {
    $javaHome = 'C:\Program Files\Eclipse Adoptium\jdk-17.0.19.10-hotspot'
    if (Test-Path -LiteralPath $javaHome) {
        $env:JAVA_HOME = $javaHome
        $env:Path = "$env:JAVA_HOME\bin;$env:Path"
    }

    $mvn = Resolve-CommandOrFallback `
        -Names @('mvn.cmd', 'mvn.exe', 'mvn') `
        -Fallbacks @('C:\tmp\apache-maven-3.9.16\bin\mvn.cmd', 'C:\tmp\apache-maven-3.9.16\bin\mvn.exe')

    $flutter = Resolve-CommandOrFallback `
        -Names @('flutter.bat', 'flutter.exe', 'flutter') `
        -Fallbacks @('C:\Users\PC\.puro\envs\stable\flutter\bin\flutter.bat')

    Push-Location (Join-Path $repoRoot 'backend')
    try {
        & $mvn -q -DskipTests package
    } finally {
        Pop-Location
    }

    Push-Location (Join-Path $repoRoot 'app_flutter')
    try {
        & $flutter build web --no-pub "--dart-define=API_BASE_URL=$ApiBaseUrl" "--dart-define=KAKAO_MAP_JAVASCRIPT_KEY=$KakaoMapJavaScriptKey"
    } finally {
        Pop-Location
    }
}

$jarPath = Join-Path $repoRoot 'backend\target\erp-backend-1.0.0.jar'
$webPath = Join-Path $repoRoot 'app_flutter\build\web'
$templatePath = Join-Path $scriptDir 'field-server'

if (-not (Test-Path -LiteralPath $jarPath)) {
    throw "Backend jar not found: $jarPath. Run this script with -Build first."
}
if (-not (Test-Path -LiteralPath (Join-Path $webPath 'index.html'))) {
    throw "Flutter web build not found: $webPath. Run this script with -Build first."
}
if (-not (Test-Path -LiteralPath $templatePath)) {
    throw "Package template not found: $templatePath"
}

$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$packageDir = Join-Path $OutputRoot "$PackageName-$stamp"
$zipPath = "$packageDir.zip"

New-Item -ItemType Directory -Force -Path $packageDir | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $packageDir 'backend') | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $packageDir 'web') | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $packageDir 'logs') | Out-Null

Copy-Item -LiteralPath $jarPath -Destination (Join-Path $packageDir 'backend\erp-backend-1.0.0.jar') -Force
Copy-Item -Path (Join-Path $webPath '*') -Destination (Join-Path $packageDir 'web') -Recurse -Force
Copy-Item -Path (Join-Path $templatePath '*') -Destination $packageDir -Recurse -Force

if (Test-Path -LiteralPath $zipPath) {
    Remove-Item -LiteralPath $zipPath -Force
}
Compress-Archive -Path (Join-Path $packageDir '*') -DestinationPath $zipPath -Force

Write-Host "[OK] Field server package created:"
Write-Host "     Folder: $packageDir"
Write-Host "     Zip:    $zipPath"
