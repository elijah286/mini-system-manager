param(
    [string]$WorkspaceRoot = "C:\workspace"
)

$LabVIEWPath = "C:\Program Files\National Instruments\LabVIEW 2026\LabVIEW.exe"
$AnalysisTarget = $WorkspaceRoot
$ResultsDir = Join-Path $WorkspaceRoot "vi-analyzer-results"
$ReportPath = Join-Path $ResultsDir "vi-analyzer-report.html"

if (-not (Test-Path -Path $ResultsDir)) {
    New-Item -ItemType Directory -Path $ResultsDir -Force | Out-Null
}

Write-Host "Running LabVIEWCLI VI Analyzer with default tests:" -ForegroundColor Cyan
Write-Host "  ConfigPath (target): $AnalysisTarget"
Write-Host "  ReportPath: $ReportPath"
Write-Host "  ReportSaveType: HTML"
Write-Host ""

& LabVIEWCLI `
    -LogToConsole TRUE `
    -OperationName RunVIAnalyzer `
    -ConfigPath "$AnalysisTarget" `
    -ReportPath "$ReportPath" `
    -ReportSaveType "HTML" `
    -LabVIEWPath "$LabVIEWPath" `
    -Headless

$exitCode = $LASTEXITCODE

if (Test-Path -Path $ReportPath) {
    Write-Host ""
    Write-Host "HTML report generated at: $ReportPath" -ForegroundColor Green
    $fileSize = (Get-Item $ReportPath).Length
    Write-Host "Report size: $fileSize bytes"
} else {
    Write-Host "WARNING: No HTML report was generated at $ReportPath" -ForegroundColor Yellow
}

if ($exitCode -ne 0) {
    Write-Host "VI Analyzer returned exit code $exitCode." -ForegroundColor Red
    exit $exitCode
}

Write-Host "VI Analyzer completed successfully." -ForegroundColor Green
