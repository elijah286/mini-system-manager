param(
    [string]$WorkspaceRoot = "C:\workspace"
)

$LabVIEWPath = "C:\Program Files\National Instruments\LabVIEW 2026\LabVIEW.exe"
$MassCompileDir = $WorkspaceRoot
$ResultsDir = Join-Path $WorkspaceRoot "masscompile-results"
$LogPath = Join-Path $ResultsDir "masscompile-log.txt"
$ReportPath = Join-Path $ResultsDir "masscompile-report.html"

if (-not (Test-Path -Path $ResultsDir)) {
    New-Item -ItemType Directory -Path $ResultsDir -Force | Out-Null
}

# Count VIs in workspace (excluding .github)
$viFiles = Get-ChildItem -Path $WorkspaceRoot -Recurse -Include "*.vi","*.ctl" |
    Where-Object { $_.FullName -notlike "*\.github\*" -and $_.FullName -notlike "*masscompile-results*" }
$totalVIs = $viFiles.Count

Write-Host "Running LabVIEWCLI MassCompile:" -ForegroundColor Cyan
Write-Host "  DirectoryToCompile: $MassCompileDir"
Write-Host "  Total VIs/CTLs found: $totalVIs"
Write-Host ""

$output = & LabVIEWCLI `
    -LogToConsole TRUE `
    -OperationName MassCompile `
    -DirectoryToCompile "$MassCompileDir" `
    -LabVIEWPath "$LabVIEWPath" `
    -Headless *>&1

$exitCode = $LASTEXITCODE

# Save raw log
$output | Out-File -FilePath $LogPath -Encoding UTF8
$output | ForEach-Object { Write-Host $_ }

# Parse output for bad VIs
$outputText = $output -join "`n"
$badVILines = $output | Where-Object { $_ -match "### Bad VI:" }
$searchFailLines = $output | Where-Object { $_ -match "Search failed to find" }
$badCount = ($badVILines | Measure-Object).Count
$searchFailCount = ($searchFailLines | Measure-Object).Count
$goodCount = $totalVIs - $badCount

# Generate HTML report
$badVIRows = ""
foreach ($line in $badVILines) {
    $viName = ""
    $viPath = ""
    if ($line -match '### Bad VI:\s+"([^"]+)"') { $viName = $matches[1] }
    if ($line -match 'Path="([^"]+)"') { $viPath = $matches[1] }
    $badVIRows += "<tr><td>$viName</td><td>$viPath</td></tr>`n"
}

$searchFailRows = ""
foreach ($line in $searchFailLines) {
    $missing = ""
    $caller = ""
    if ($line -match 'Search failed to find "([^"]+)"') { $missing = $matches[1] }
    if ($line -match 'Caller:\s+"([^"]+)"') { $caller = $matches[1] }
    $searchFailRows += "<tr><td>$missing</td><td>$caller</td></tr>`n"
}

$timestamp = Get-Date -Format "dddd, MMMM dd, yyyy h:mm:ss tt"
$statusColor = if ($badCount -eq 0) { "green" } else { "red" }
$statusText = if ($badCount -eq 0) { "PASSED" } else { "FAILED" }

$html = @"
<html>
<head><title>Mass Compile Results</title></head>
<body>
<h1>Mass Compile Results</h1>
$timestamp
<br><br>
<h2>Results</h2>
<table border=1>
<tr><td>Total VIs</td><td>$totalVIs</td></tr>
<tr><td>Compiled Successfully</td><td>$goodCount</td></tr>
<tr><td>Failed to Compile</td><td>$badCount</td></tr>
<tr><td>Missing Dependencies</td><td>$searchFailCount</td></tr>
</table>
<br>
<h2 style="color: $statusColor">Status: $statusText</h2>
"@

if ($badCount -gt 0) {
    $html += @"
<h2>Failed VIs</h2>
<table border=1>
<tr><th>VI Name</th><th>Path</th></tr>
$badVIRows</table>
<br>
"@
}

if ($searchFailCount -gt 0) {
    $html += @"
<h2>Missing Dependencies</h2>
<table border=1>
<tr><th>Missing File</th><th>Caller</th></tr>
$searchFailRows</table>
<br>
"@
}

$html += @"
<h2>Full Log</h2>
<pre>$($outputText -replace '<','&lt;' -replace '>','&gt;')</pre>
</body>
</html>
"@

$html | Out-File -FilePath $ReportPath -Encoding UTF8

Write-Host ""
Write-Host "HTML report generated at: $ReportPath" -ForegroundColor Green
Write-Host "Results: $goodCount compiled, $badCount failed, $searchFailCount missing deps" -ForegroundColor Cyan

# Exit code 3 = some VIs failed (informational, report was generated)
if ($exitCode -eq 3) {
    Write-Host "MassCompile completed with failures (exit code 3). See report." -ForegroundColor Yellow
    exit 0
} elseif ($exitCode -ne 0) {
    Write-Host "MassCompile returned unexpected exit code $exitCode." -ForegroundColor Red
    exit $exitCode
}

Write-Host "MassCompile completed successfully." -ForegroundColor Green
