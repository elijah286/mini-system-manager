Write-Host "=== Checking VI Analyzer test availability ==="

$lvDir = Get-ChildItem "C:\Program Files\National Instruments" -Filter "LabVIEW*" -Directory | Select-Object -First 1
if (-not $lvDir) {
    Write-Host "ERROR: No LabVIEW directory found under C:\Program Files\National Instruments" -ForegroundColor Red
    Get-ChildItem "C:\Program Files\National Instruments" | ForEach-Object { Write-Host "  $_" }
    exit 1
}

Write-Host "LabVIEW directory: $($lvDir.FullName)"
Write-Host "LabVIEW.exe exists: $(Test-Path (Join-Path $lvDir.FullName 'LabVIEW.exe'))"

$testsPath = Join-Path $lvDir.FullName "project\_VI Analyzer\_tests"
if (Test-Path $testsPath) {
    Write-Host "VI Analyzer tests found at: $testsPath"
    Get-ChildItem $testsPath -Recurse -Filter "*.llb" | ForEach-Object { Write-Host "  $($_.FullName)" }
} else {
    Write-Host "WARNING: VI Analyzer tests NOT found at: $testsPath" -ForegroundColor Yellow
    $projPath = Join-Path $lvDir.FullName "project"
    if (Test-Path $projPath) {
        Write-Host "Contents of project folder:"
        Get-ChildItem $projPath -Recurse -Depth 3 | ForEach-Object { Write-Host "  $($_.FullName)" }
    } else {
        Write-Host "No project folder exists at: $projPath"
        Write-Host "Top-level LabVIEW directory contents:"
        Get-ChildItem $lvDir.FullName -Depth 1 | ForEach-Object { Write-Host "  $($_.FullName)" }
    }
}

Write-Host ""
Write-Host "=== Checking LabVIEWCLI ==="
$cli = Get-Command LabVIEWCLI -ErrorAction SilentlyContinue
if ($cli) {
    Write-Host "LabVIEWCLI found at: $($cli.Source)"
} else {
    Write-Host "LabVIEWCLI not found on PATH"
    $cliPath = Join-Path $lvDir.FullName "LabVIEWCLI.exe"
    Write-Host "Checking $cliPath : $(Test-Path $cliPath)"
}
