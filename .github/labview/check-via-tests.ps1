Write-Host "=== Checking VI Analyzer test availability ==="

# Check all LabVIEW directories
Write-Host "`nAll NI LabVIEW directories:"
$niDir = "C:\Program Files\National Instruments"
if (Test-Path $niDir) {
    Get-ChildItem $niDir -Filter "LabVIEW*" -Directory | ForEach-Object {
        $hasExe = Test-Path (Join-Path $_.FullName "LabVIEW.exe")
        Write-Host "  $($_.FullName) - LabVIEW.exe: $hasExe"
    }
} else {
    Write-Host "  NI directory not found at $niDir"
}

# Search for VI Analyzer tests in ALL locations
Write-Host "`n=== Searching for VI Analyzer test LLBs ==="
$searchPaths = @(
    "C:\Program Files\National Instruments",
    "C:\Program Files (x86)\National Instruments"
)
foreach ($sp in $searchPaths) {
    if (Test-Path $sp) {
        Write-Host "`nSearching $sp for _VI Analyzer..."
        $found = Get-ChildItem $sp -Recurse -Directory -Filter "_VI Analyzer" -ErrorAction SilentlyContinue
        if ($found) {
            foreach ($f in $found) {
                Write-Host "  FOUND: $($f.FullName)"
                Get-ChildItem $f.FullName -Recurse -Filter "*.llb" -ErrorAction SilentlyContinue | ForEach-Object {
                    Write-Host "    LLB: $($_.FullName)"
                }
            }
        } else {
            Write-Host "  No _VI Analyzer directory found"
        }
    }
}

# List project directories
Write-Host "`n=== Checking project directories ==="
Get-ChildItem $niDir -Filter "LabVIEW*" -Directory -ErrorAction SilentlyContinue | ForEach-Object {
    $projDir = Join-Path $_.FullName "project"
    if (Test-Path $projDir) {
        Write-Host "`nProject folder found: $projDir"
        Get-ChildItem $projDir -Depth 3 -ErrorAction SilentlyContinue | ForEach-Object {
            Write-Host "  $($_.FullName)"
        }
    } else {
        Write-Host "`n$($_.Name): No project folder"
        Write-Host "  Top-level contents:"
        Get-ChildItem $_.FullName -Depth 0 -ErrorAction SilentlyContinue | ForEach-Object {
            Write-Host "    $($_.Name)"
        }
    }
}

# Check LabVIEWCLI
Write-Host "`n=== LabVIEWCLI ==="
$cli = Get-Command LabVIEWCLI -ErrorAction SilentlyContinue
if ($cli) {
    Write-Host "Found at: $($cli.Source)"
} else {
    Write-Host "Not found on PATH"
    $cliPath = "C:\Program Files (x86)\National Instruments\Shared\LabVIEW CLI\LabVIEWCLI.exe"
    if (Test-Path $cliPath) { Write-Host "Found at: $cliPath" }
}

# Also check RunVIAnalyzer operation
Write-Host "`n=== RunVIAnalyzer available operations ==="
try {
    & LabVIEWCLI -OperationName RunVIAnalyzer -Help 2>&1 | Select-Object -First 20 | ForEach-Object { Write-Host $_ }
} catch {
    Write-Host "Could not query RunVIAnalyzer help"
}
