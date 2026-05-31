param(
    [string]$WorkspaceRoot = "C:\workspace"
)

$LabVIEWPath = "C:\Program Files\National Instruments\LabVIEW 2026\LabVIEW.exe"
$AdditionalOpDir = $PSScriptRoot
$OutputDir = Join-Path $WorkspaceRoot "vi-snapshots"

if (-not (Test-Path -Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

# ── Diagnostic: find available CLI operations ──
Write-Host "=== CLI Operations Diagnostic ===" -ForegroundColor Cyan
$searchDirs = @(
    "C:\Program Files\National Instruments\Shared\LabVIEWCLI",
    "C:\Program Files\National Instruments\LabVIEW 2026\resource\cli",
    "C:\Program Files\National Instruments\LabVIEW 2026\vi.lib\LabVIEWCLI",
    $PSScriptRoot
)
foreach ($sd in $searchDirs) {
    Write-Host "`nDirectory: $sd"
    if (Test-Path $sd) {
        Get-ChildItem -Path $sd -Directory -ErrorAction SilentlyContinue | ForEach-Object { Write-Host "  OP: $($_.Name)" }
    } else {
        Write-Host "  (not found)"
    }
}

# Search for PrintToSingleFileHtml anywhere under Program Files\National Instruments
Write-Host "`n=== Searching for PrintToSingleFileHtml ===" -ForegroundColor Cyan
$ptsfDirs = Get-ChildItem -Path "C:\Program Files\National Instruments" -Recurse -Directory -Filter "PrintToSingleFileHtml" -ErrorAction SilentlyContinue
if ($ptsfDirs) {
    foreach ($d in $ptsfDirs) { Write-Host "  FOUND: $($d.FullName)" }
    # Use the first found directory's parent as AdditionalOperationDirectory
    $AdditionalOpDir = $ptsfDirs[0].Parent.FullName
    Write-Host "  Using AdditionalOperationDirectory: $AdditionalOpDir" -ForegroundColor Green
} else {
    Write-Host "  Not found in NI directories."
    # Also try nipkg list to see what's installed
    Write-Host "`n=== Installed NI Packages ===" -ForegroundColor Cyan
    $nipkg = "C:\Program Files\National Instruments\NI Package Manager\nipkg.exe"
    if (Test-Path $nipkg) {
        & $nipkg list 2>&1 | Select-String -Pattern "diff|vidiff|cli" -CaseSensitive:$false | ForEach-Object { Write-Host "  $_" }
        Write-Host "`n=== Searching for VIDiff package ===" -ForegroundColor Cyan
        # Add NI feed and update
        & $nipkg feed-add NI "https://download.ni.com/support/nipkg/products/ni-package-manager/26.0/released" 2>&1 | ForEach-Object { Write-Host "  feed-add: $_" }
        & $nipkg update 2>&1 | Out-Null
        # Search for available VIDiff packages
        & $nipkg list --available 2>&1 | Select-String -Pattern "vidiff|vi-diff|VIDiff" -CaseSensitive:$false | ForEach-Object { Write-Host "  available: $_" }
        # Also search for labviewcli operations packages
        & $nipkg list --available 2>&1 | Select-String -Pattern "labviewcli|cli-operation|PrintToSingle" -CaseSensitive:$false | ForEach-Object { Write-Host "  available: $_" }
        # Try various possible package names
        $packageNames = @(
            "ni-vidiff",
            "ni-labview-vidiff-toolkit",
            "ni-labview-2026-vidiff-toolkit",
            "ni-labview-2026-vidiff",
            "ni-labview-vi-diff"
        )
        foreach ($pkg in $packageNames) {
            Write-Host "  Trying: $pkg" -ForegroundColor Yellow
            $result = & $nipkg install $pkg -y 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Host "  Installed $pkg successfully!" -ForegroundColor Green
                break
            }
        }
        # Re-check after install attempt
        $ptsfDirs = Get-ChildItem -Path "C:\Program Files\National Instruments" -Recurse -Directory -Filter "PrintToSingleFileHtml" -ErrorAction SilentlyContinue
        if ($ptsfDirs) {
            $AdditionalOpDir = $ptsfDirs[0].Parent.FullName
            Write-Host "  Post-install found: $($ptsfDirs[0].FullName)" -ForegroundColor Green
        }
    } else {
        Write-Host "  nipkg not found at expected path."
        # Try to find nipkg elsewhere
        $nipkgAlt = Get-Command nipkg -ErrorAction SilentlyContinue
        if ($nipkgAlt) {
            Write-Host "  Found nipkg at: $($nipkgAlt.Source)"
        }
    }
}

Write-Host "`nUsing AdditionalOperationDirectory: $AdditionalOpDir" -ForegroundColor Cyan
Write-Host ""

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

# Write manifest JSON for the gallery page generator (UTF-8 without BOM)
if ($manifest.Count -eq 0) {
    $jsonText = "[]"
} else {
    $jsonText = $manifest | ConvertTo-Json -Depth 3
}
[System.IO.File]::WriteAllText((Join-Path $OutputDir "manifest.json"), $jsonText, [System.Text.UTF8Encoding]::new($false))

Write-Host ""
Write-Host "Snapshot summary: $($viFiles.Count) total, $succeeded succeeded, $failed failed." -ForegroundColor Cyan

if ($failed -gt 0) {
    Write-Host "Some snapshots failed. See above for details." -ForegroundColor Yellow
}
