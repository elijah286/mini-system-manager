param(
    [string]$WorkspaceRoot = "C:\workspace",
    [string]$WorkspaceBaseRoot = "C:\workspace-base",
    [Parameter(Mandatory = $true)]
    [string]$VIFilesCsv
)

$VIFiles = $VIFilesCsv -split ',' | Where-Object { $_ -ne '' }

$LabVIEWPath = "C:\Program Files\National Instruments\LabVIEW 2026\LabVIEW.exe"
$AdditionalOpDir = $PSScriptRoot
$ReportDir = Join-Path $WorkspaceRoot "vidiff-reports"

if (-not (Test-Path -Path $ReportDir)) {
    New-Item -ItemType Directory -Path $ReportDir -Force | Out-Null
}

function Test-LabVIEWFile {
    param([string]$Path)

    if (-not (Test-Path -Path $Path)) {
        return $false
    }

    $bytes = [System.IO.File]::ReadAllBytes($Path)
    if ($bytes.Length -lt 12) {
        return $false
    }

    $magic = [System.Text.Encoding]::ASCII.GetString($bytes, 8, 4)
    return ($magic -eq 'LVIN' -or $magic -eq 'LVCC')
}

$failed = 0
$skipped = 0

foreach ($relativePath in $VIFiles) {
    $name = [System.IO.Path]::GetFileNameWithoutExtension($relativePath)
    $prPath = Join-Path $WorkspaceRoot $relativePath
    $basePath = Join-Path $WorkspaceBaseRoot $relativePath
    $prExists = Test-Path -Path $prPath
    $baseExists = Test-Path -Path $basePath
    $reportPath = $null

    if ($prExists -and $baseExists) {
        if (-not (Test-LabVIEWFile -Path $prPath) -or -not (Test-LabVIEWFile -Path $basePath)) {
            Write-Host "Skipping $relativePath because one side is not a LabVIEW file." -ForegroundColor Yellow
            $skipped++
            continue
        }

        $reportPath = Join-Path $ReportDir "$name (Modified).html"
        & LabVIEWCLI `
            -LogToConsole TRUE `
            -OperationName CreateComparisonReport `
            -VI1 "$basePath" `
            -VI2 "$prPath" `
            -ReportType html `
            -ReportPath "$reportPath" `
            -LabVIEWPath "$LabVIEWPath" `
            -Headless
    } elseif ($prExists) {
        if (-not (Test-LabVIEWFile -Path $prPath)) {
            Write-Host "Skipping $relativePath because it is not a LabVIEW file." -ForegroundColor Yellow
            $skipped++
            continue
        }

        $reportPath = Join-Path $ReportDir "$name (Added).html"
        & LabVIEWCLI `
            -OperationName PrintToSingleFileHtml `
            -LabVIEWPath "$LabVIEWPath" `
            -AdditionalOperationDirectory "$AdditionalOpDir" `
            -LogToConsole TRUE `
            -VI "$prPath" `
            -OutputPath "$reportPath" `
            -o -c `
            -Headless
    } elseif ($baseExists) {
        if (-not (Test-LabVIEWFile -Path $basePath)) {
            Write-Host "Skipping $relativePath because the base file is not a LabVIEW file." -ForegroundColor Yellow
            $skipped++
            continue
        }

        $reportPath = Join-Path $ReportDir "$name (Deleted).html"
        & LabVIEWCLI `
            -OperationName PrintToSingleFileHtml `
            -LabVIEWPath "$LabVIEWPath" `
            -AdditionalOperationDirectory "$AdditionalOpDir" `
            -LogToConsole TRUE `
            -VI "$basePath" `
            -OutputPath "$reportPath" `
            -o -c `
            -Headless
    } else {
        Write-Host "Skipping $relativePath because neither side exists." -ForegroundColor Yellow
        $skipped++
        continue
    }

    if ($LASTEXITCODE -ne 0 -or -not (Test-Path -Path $reportPath)) {
        Write-Host "VIDiff failed for $relativePath." -ForegroundColor Red
        $failed++
    } else {
        Write-Host "Generated report: $reportPath" -ForegroundColor Green
    }
}

Write-Host "VIDiff summary: $($VIFiles.Count) processed, $skipped skipped, $failed failed."

if ($failed -gt 0) {
    exit 1
}

exit 0
