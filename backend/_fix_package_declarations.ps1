$ErrorActionPreference = 'Stop'
$backend = $PSScriptRoot
$roots = @(
    (Join-Path $backend 'src\main\java'),
    (Join-Path $backend 'src\test\java')
) | Where-Object { Test-Path $_ }

$repoRoot = Split-Path $backend -Parent
$extraDocs = @(
    (Join-Path $repoRoot 'docs\ERP_PROJECT_GUIDE.md')
)

$replacements = @(
    @{ From = 'com.yeokjeon.erp.active.act001.'; To = 'com.yeokjeon.erp.active.' }
    @{ From = 'com.yeokjeon.erp.active.act002.'; To = 'com.yeokjeon.erp.active.' }
    @{ From = 'com.yeokjeon.erp.development.dev001.'; To = 'com.yeokjeon.erp.development.' }
    @{ From = 'com.yeokjeon.erp.development.dev002.'; To = 'com.yeokjeon.erp.development.' }
    @{ From = 'com.yeokjeon.erp.franchise.str001.'; To = 'com.yeokjeon.erp.franchise.' }
    @{ From = 'com.yeokjeon.erp.master.mst001.'; To = 'com.yeokjeon.erp.master.' }
    @{ From = 'com.yeokjeon.erp.master.mst002.'; To = 'com.yeokjeon.erp.master.' }
)

function Apply-Replacements([string]$text) {
    $out = $text
    foreach ($r in $replacements) {
        $out = $out.Replace($r.From, $r.To)
    }
    return $out
}

foreach ($root in $roots) {
    Get-ChildItem -Path $root -Recurse -Filter *.java -File | ForEach-Object {
        $raw = [System.IO.File]::ReadAllText($_.FullName)
        $next = Apply-Replacements $raw
        if ($next -ne $raw) {
            $utf8NoBom = New-Object System.Text.UTF8Encoding $false
            [System.IO.File]::WriteAllText($_.FullName, $next, $utf8NoBom)
        }
    }
}

foreach ($f in $extraDocs) {
    if (-not (Test-Path $f)) { continue }
    $raw = [System.IO.File]::ReadAllText($f)
    $next = Apply-Replacements $raw
    if ($next -ne $raw) {
        $utf8NoBom = New-Object System.Text.UTF8Encoding $false
        [System.IO.File]::WriteAllText($f, $next, $utf8NoBom)
    }
}

Write-Host 'Package string replacements done.'
