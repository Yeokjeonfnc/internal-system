$ErrorActionPreference = 'Stop'
$base = Join-Path $PSScriptRoot 'src\main\java\com\yeokjeon\erp'

function Move-Tree {
    param([string]$relSrc, [string]$relDstRoot)
    $fullSrc = Join-Path $base $relSrc
    if (-not (Test-Path $fullSrc)) {
        Write-Host "skip missing $relSrc"
        return
    }
    Get-ChildItem -Path $fullSrc -Recurse -Filter *.java | ForEach-Object {
        $suffix = $_.FullName.Substring($fullSrc.Length).TrimStart('\')
        $parent = Split-Path $suffix -Parent
        if ([string]::IsNullOrEmpty($parent)) {
            $destDir = Join-Path $base $relDstRoot
        } else {
            $destDir = Join-Path (Join-Path $base $relDstRoot) $parent
        }
        if (-not (Test-Path $destDir)) {
            New-Item -ItemType Directory -Path $destDir -Force | Out-Null
        }
        $destFile = Join-Path $destDir (Split-Path $suffix -Leaf)
        if (Test-Path $destFile) {
            throw "Conflict: $destFile"
        }
        Move-Item -LiteralPath $_.FullName -Destination $destFile
    }
}

Move-Tree 'active\act001' 'active'
Move-Tree 'active\act002' 'active'
Move-Tree 'development\dev001' 'development'
Move-Tree 'development\dev002' 'development'
Move-Tree 'franchise\str001' 'franchise'
Move-Tree 'master\mst001' 'master'
Move-Tree 'master\mst002' 'master'

@(
    'active\act001',
    'active\act002',
    'development\dev001',
    'development\dev002',
    'franchise\str001',
    'master\mst001',
    'master\mst002'
) | ForEach-Object {
    $p = Join-Path $base $_
    if (Test-Path $p) {
        Remove-Item -LiteralPath $p -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Write-Host 'Moves done.'
