param(
    [string]$WorkspaceRoot = "C:\workspace"
)

$LabVIEWPath = "C:\Program Files\National Instruments\LabVIEW 2026\LabVIEW.exe"
$MassCompileDir = $WorkspaceRoot

Write-Host "Running LabVIEWCLI MassCompile with the following parameters:" -ForegroundColor Cyan
Write-Host "DirectoryToCompile: $MassCompileDir"

& LabVIEWCLI `
    -LogToConsole TRUE `
    -OperationName MassCompile `
    -DirectoryToCompile "$MassCompileDir" `
    -LabVIEWPath "$LabVIEWPath" `
    -Headless

if ($LASTEXITCODE -ne 0) {
    Write-Host "MassCompile failed with exit code $LASTEXITCODE." -ForegroundColor Red
    exit $LASTEXITCODE
}

Write-Host "MassCompile completed successfully." -ForegroundColor Green
