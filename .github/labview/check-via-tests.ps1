Write-Host "=== Checking VI Analyzer test availability ==="

# Check all LabVIEW directories
Write-Host "`nAll NI LabVIEW directories:"
$niDir = "C:\Program Files\National Instruments"
if (Test-Path $niDir) {
    Get-ChildItem $niDir -Filter "LabVIEW*" -Directory | ForEach-Object {
        $hasExe = Test-Path (Join-Path $_.FullName "LabVIEW.exe")
        Write-Host "  $($_.FullName) - LabVIEW.exe: $hasExe"
    }
}

# List ALL contents of _VI Analyzer directory
Write-Host "`n=== Full contents of _VI Analyzer directory ==="
$viaDir = "C:\Program Files\National Instruments\LabVIEW 2026\project\_VI Analyzer"
if (Test-Path $viaDir) {
    Get-ChildItem $viaDir -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
        $type = if ($_.PSIsContainer) { "DIR" } else { "FILE ($($_.Length) bytes)" }
        Write-Host "  $type  $($_.FullName)"
    }
} else {
    Write-Host "  NOT FOUND: $viaDir"
}

# Try LabVIEWCLI RunVIAnalyzer help
Write-Host "`n=== LabVIEWCLI RunVIAnalyzer Help ==="
try {
    $helpOutput = & LabVIEWCLI -OperationName RunVIAnalyzer -Help 2>&1
    $helpOutput | ForEach-Object { Write-Host $_ }
} catch {
    Write-Host "Help failed: $_"
}

# Try running without ConfigPath to see behavior
Write-Host "`n=== Trying RunVIAnalyzer without ConfigPath ==="
$testReportDir = "C:\workspace\vi-analyzer-test"
New-Item -ItemType Directory -Path $testReportDir -Force | Out-Null
$testReport = "$testReportDir\test.txt"
try {
    $output = & LabVIEWCLI -LogToConsole TRUE -OperationName RunVIAnalyzer -ReportPath $testReport -LabVIEWPath "C:\Program Files\National Instruments\LabVIEW 2026\LabVIEW.exe" -Headless 2>&1
    $output | ForEach-Object { Write-Host $_ }
    if (Test-Path $testReport) {
        Write-Host "`nTest report content:"
        Get-Content $testReport | ForEach-Object { Write-Host $_ }
    }
} catch {
    Write-Host "Error: $_"
}

# Search for ANY test-related LLBs or VIs
Write-Host "`n=== Searching for test-related files ==="
$searchDir = "C:\Program Files\National Instruments\LabVIEW 2026"
Get-ChildItem $searchDir -Recurse -ErrorAction SilentlyContinue | Where-Object {
    $_.Name -match "Broken VI|Platform Portability|Separate Compiled|Toolkit Usage|Error Cluster|vi.analyzer.*test|test.*analyzer"
} | ForEach-Object {
    Write-Host "  $($_.FullName)"
} | Select-Object -First 30
