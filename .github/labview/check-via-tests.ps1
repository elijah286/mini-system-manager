Write-Host "=== Checking VI Analyzer test availability ==="

Write-Host "All LabVIEW directories:"
$allLvDirs = Get-ChildItem "C:\Program Files\National Instruments" -Filter "LabVIEW*" -Directory -ErrorAction SilentlyContinue
foreach ($d in $allLvDirs) {
    $hasExe = Test-Path (Join-Path $d.FullName "LabVIEW.exe")
    Write-Host "  $($d.FullName) - LabVIEW.exe: $hasExe"
}

foreach ($lvDir in $allLvDirs) {
    Write-Host ""
    Write-Host "=== Checking $($lvDir.FullName) ==="

    $testsPath = Join-Path $lvDir.FullName "project\_VI Analyzer\_tests"
    if (Test-Path $testsPath) {
        Write-Host "VI Analyzer tests found at: $testsPath"
        Get-ChildItem $testsPath -Recurse -Filter "*.llb" | ForEach-Object { Write-Host "  $($_.FullName)" }
    } else {
        Write-Host "No VI Analyzer tests at: $testsPath"
        $projPath = Join-Path $lvDir.FullName "project"
        if (Test-Path $projPath) {
            Write-Host "Contents of project folder:"
            Get-ChildItem $projPath -Recurse -Depth 3 | ForEach-Object { Write-Host "  $($_.FullName)" }
        } else {
            Write-Host "No project folder. Top-level contents:"
            Get-ChildItem $lvDir.FullName -Depth 1 | ForEach-Object { Write-Host "  $($_.FullName)" }
        }
    }
}

Write-Host ""
Write-Host "=== Checking LabVIEWCLI ==="
$cli = Get-Command LabVIEWCLI -ErrorAction SilentlyContinue
if ($cli) {
    Write-Host "LabVIEWCLI found at: $($cli.Source)"
} else {
    Write-Host "LabVIEWCLI not found on PATH"
}
