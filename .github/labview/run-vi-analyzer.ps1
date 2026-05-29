param(
    [string]$WorkspaceRoot = "C:\workspace"
)

$LabVIEWPath = "C:\Program Files\National Instruments\LabVIEW 2026\LabVIEW.exe"
$ConfigFile = Join-Path $WorkspaceRoot ".github\labview\via-configs\via-config-default.viancfg"
$ResultsDir = Join-Path $WorkspaceRoot "vi-analyzer-results"
$ReportPath = Join-Path $ResultsDir "Results.txt"

if (-not (Test-Path -Path $ConfigFile)) {
    Write-Host "VI Analyzer configuration file not found at $ConfigFile" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path -Path $ResultsDir)) {
    New-Item -ItemType Directory -Path $ResultsDir -Force | Out-Null
}

Write-Host "Running LabVIEWCLI VI Analyzer with the following parameters:" -ForegroundColor Cyan
Write-Host "ConfigPath: $ConfigFile"
Write-Host "ReportPath: $ReportPath"

& LabVIEWCLI `
    -LogToConsole TRUE `
    -OperationName RunVIAnalyzer `
    -ConfigPath "$ConfigFile" `
    -ReportPath "$ReportPath" `
    -LabVIEWPath "$LabVIEWPath" `
    -Headless

if ($LASTEXITCODE -ne 0) {
    Write-Host "VI Analyzer returned exit code $LASTEXITCODE." -ForegroundColor Red
    if (Test-Path -Path $ReportPath) {
        Get-Content -Path $ReportPath | Write-Host
    }
    exit $LASTEXITCODE
}

if (Test-Path -Path $ReportPath) {
    Get-Content -Path $ReportPath | Write-Host
}

Write-Host "VI Analyzer completed successfully." -ForegroundColor Green
