param(
    [string]$WorkspaceRoot = "C:\workspace"
)

$LabVIEWPath = "C:\Program Files\National Instruments\LabVIEW 2026\LabVIEW.exe"
$AdditionalOpDir = $PSScriptRoot
$OutputDir = Join-Path $WorkspaceRoot "vi-snapshots"

if (-not (Test-Path -Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

# Find all .vi and .ctl files, excluding CI/build artifacts
$viFiles = Get-ChildItem -Path $WorkspaceRoot -Recurse -Include "*.vi","*.ctl" |
    Where-Object {
        $_.FullName -notlike "*\.github\*" -and
        $_.FullName -notlike "*vi-snapshots*" -and
        $_.FullName -notlike "*vidiff-reports*" -and
        $_.FullName -notlike "*masscompile-results*"
    }

Write-Host "Found $($viFiles.Count) VI/CTL files to snapshot." -ForegroundColor Cyan

$succeeded = 0
$failed = 0
$manifest = @()

foreach ($vi in $viFiles) {
    $relativePath = $vi.FullName.Substring($WorkspaceRoot.Length + 1)
    # Preserve directory structure in output
    $relativeDir = [System.IO.Path]::GetDirectoryName($relativePath)
    $outputSubDir = Join-Path $OutputDir $relativeDir
    if ($relativeDir -and -not (Test-Path -Path $outputSubDir)) {
        New-Item -ItemType Directory -Path $outputSubDir -Force | Out-Null
    }

    $outputFile = Join-Path $OutputDir "$relativePath.html"

    Write-Host "Snapshotting: $relativePath" -ForegroundColor White

    & LabVIEWCLI `
        -OperationName PrintToSingleFileHtml `
        -LabVIEWPath "$LabVIEWPath" `
        -AdditionalOperationDirectory "$AdditionalOpDir" `
        -LogToConsole TRUE `
        -VI "$($vi.FullName)" `
        -OutputPath "$outputFile" `
        -o -c `
        -Headless

    if ($LASTEXITCODE -ne 0 -or -not (Test-Path -Path $outputFile)) {
        Write-Host "  FAILED (exit code $LASTEXITCODE)" -ForegroundColor Red
        $failed++
    } else {
        Write-Host "  OK" -ForegroundColor Green
        $succeeded++
        $manifest += @{
            path = $relativePath
            html = "$relativePath.html"
        }
    }
}

# Write manifest JSON for the gallery page generator
$manifest | ConvertTo-Json -Depth 3 | Out-File -FilePath (Join-Path $OutputDir "manifest.json") -Encoding UTF8

Write-Host ""
Write-Host "Snapshot summary: $($viFiles.Count) total, $succeeded succeeded, $failed failed." -ForegroundColor Cyan

if ($failed -gt 0) {
    Write-Host "Some snapshots failed. See above for details." -ForegroundColor Yellow
}
