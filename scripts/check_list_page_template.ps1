# ListPageTemplate usage scan for list-style *_view.dart under app_flutter/lib/pages.
# Exceptions align with docs/ERP_PROJECT_GUIDE.md §4 (ListPageTemplate / list shells).
# Usage from repo root: powershell -ExecutionPolicy Bypass -File scripts/check_list_page_template.ps1
# Exit 1 if any non-allowed view lacks ListPageTemplate (for CI). Use -AllowMissing to always exit 0.

param(
    [switch]$AllowMissing
)

$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$pagesRoot = Join-Path $repoRoot 'app_flutter\lib\pages'

if (-not (Test-Path $pagesRoot)) {
    Write-Error "Missing path: $pagesRoot"
}

# Regex on full path (backslashes)
$allowedPatterns = @(
    '\\active\\act001\\act001_view_hub\.dart$'
    '\\active\\act001\\act001_view_status\.dart$'
    '\\active\\act001\\tabs\\'
    '\\active\\act002\\'
    '\\active\\act003\\'
    '\\dsh001\\'
    '\\mst002\\mst002_view\.dart$'
    '\\mst003\\mst003_view\.dart$'
    '\\mst004\\mst004_view\.dart$'
)

function Test-AllowedPath {
    param([string]$fullPath)
    $norm = $fullPath -replace '/', '\'
    foreach ($p in $allowedPatterns) {
        if ($norm -match $p) { return $true }
    }
    return $false
}

$views = Get-ChildItem -Path $pagesRoot -Recurse -Filter '*_view.dart' -File
$missing = New-Object System.Collections.Generic.List[string]

foreach ($v in $views) {
    $raw = Get-Content -LiteralPath $v.FullName -Raw
    if ($raw -notmatch 'ListPageTemplate') {
        if (-not (Test-AllowedPath $v.FullName)) {
            $rel = $v.FullName.Substring($repoRoot.Length + 1)
            [void]$missing.Add($rel)
        }
    }
}

Write-Host ("Views without ListPageTemplate (excluding allowlist): {0}" -f $missing.Count)
foreach ($m in $missing) {
    Write-Host ('  - ' + $m)
}

if ($missing.Count -gt 0 -and -not $AllowMissing) {
    exit 1
}
exit 0
