Write-Host "=== VI Analyzer Test Installation (v3) ==="

$viaTestDir = "C:\Program Files\National Instruments\LabVIEW 2026\project\_VI Analyzer\_tests"

# Step 1: Check if tests already exist
if (Test-Path $viaTestDir) {
    $testCount = (Get-ChildItem $viaTestDir -Recurse -Filter "*.llb" -ErrorAction SilentlyContinue).Count
    Write-Host "VI Analyzer tests already installed: $testCount LLBs found"
    exit 0
}

Write-Host "VI Analyzer _tests directory not found. Attempting to install..."

# Step 2: Find nipkg (confirmed available from prior run)
$nipkgPath = "C:\Program Files\National Instruments\NI Package Manager\nipkg.exe"
if (-not (Test-Path $nipkgPath)) {
    $nipkgCmd = Get-Command nipkg -ErrorAction SilentlyContinue
    if ($nipkgCmd) { $nipkgPath = $nipkgCmd.Source }
    else {
        Write-Host "ERROR: nipkg not found"
        exit 1
    }
}
Write-Host "Using nipkg: $nipkgPath"

# Step 3: Update feeds first
Write-Host "`n=== nipkg update (refresh feeds) ==="
try {
    $updateOutput = & $nipkgPath update 2>&1
    $updateOutput | ForEach-Object { Write-Host "  $_" }
} catch {
    Write-Host "  nipkg update failed: $_"
}

# Step 4: Show what's installed for VIA
Write-Host "`n=== Installed VIA packages ==="
try {
    $installed = & $nipkgPath list-installed 2>&1
    $installed | Where-Object { $_ -match "via|analyzer" } | ForEach-Object { Write-Host "  $_" }
} catch {
    Write-Host "  list-installed failed: $_"
}

# Step 5: Show files from installed VIA packages
Write-Host "`n=== Files in ni-viawin-labview-support ==="
try {
    $files = & $nipkgPath content ni-viawin-labview-support 2>&1
    $files | ForEach-Object { Write-Host "  $_" }
} catch {
    Write-Host "  content query failed: $_"
}

Write-Host "`n=== Files in ni-labview-vi-analyzer-toolkit-lic ==="
try {
    $files = & $nipkgPath content ni-labview-vi-analyzer-toolkit-lic 2>&1
    $files | ForEach-Object { Write-Host "  $_" }
} catch {
    Write-Host "  content query failed: $_"
}

# Step 6: Search ALL available packages for anything VIA/analyzer/test related
Write-Host "`n=== ALL available packages matching via|analyzer|test ==="
try {
    $allPkgs = & $nipkgPath list 2>&1
    $matchCount = 0
    $allPkgs | Where-Object { $_ -match "via|analyzer" } | ForEach-Object {
        Write-Host "  $_"
        $matchCount++
    }
    if ($matchCount -eq 0) {
        Write-Host "  (no matches found)"
        Write-Host "`n=== Total available packages count ==="
        Write-Host "  $($allPkgs.Count) packages in feeds"
        # Show first 10 to verify feeds are working
        Write-Host "`n=== First 10 available packages (feed health check) ==="
        $allPkgs | Select-Object -First 10 | ForEach-Object { Write-Host "  $_" }
    }
} catch {
    Write-Host "  list failed: $_"
}

# Step 7: Try installing with various package name patterns
$packageNames = @(
    "ni-viawin-tests",
    "ni-viawin-labview-tests",
    "ni-vi-analyzer-tests",
    "ni-vi-analyzer",
    "ni-labview-2026-vi-analyzer",
    "ni-labview-vi-analyzer-toolkit",
    "ni-viawin"
)
foreach ($pkg in $packageNames) {
    Write-Host "`n=== nipkg: Trying to install $pkg ==="
    try {
        $installOutput = & $nipkgPath install $pkg --accept-eulas -y 2>&1
        $installOutput | ForEach-Object { Write-Host "  $_" }
        if ($LASTEXITCODE -eq 0 -and (Test-Path $viaTestDir)) {
            Write-Host "  SUCCESS: $pkg installed and _tests now exists!" -ForegroundColor Green
            break
        }
    } catch {
        Write-Host "  Failed: $_"
    }
}

# Step 8: Search for test LLBs anywhere in the LabVIEW directory
Write-Host "`n=== Searching for test LLBs in LabVIEW installation ==="
$lvDir = "C:\Program Files\National Instruments\LabVIEW 2026"
try {
    $testLlbs = Get-ChildItem $lvDir -Recurse -Filter "*.llb" -ErrorAction SilentlyContinue | 
        Where-Object { $_.FullName -match "test|_tests|analyzer" }
    if ($testLlbs) {
        $testLlbs | ForEach-Object { Write-Host "  $($_.FullName) ($($_.Length) bytes)" }
    } else {
        Write-Host "  No test LLBs found"
    }
} catch {
    Write-Host "  Search failed: $_"
}

# Step 9: Check for feed configuration
Write-Host "`n=== nipkg feed configuration ==="
try {
    $feedOutput = & $nipkgPath feed-list 2>&1
    $feedOutput | ForEach-Object { Write-Host "  $_" }
} catch {
    Write-Host "  feed-list failed: $_"
}

# Also try alternate command
try {
    $feedDirs = Get-ChildItem "C:\ProgramData\National Instruments\NI Package Manager\Feeds" -ErrorAction SilentlyContinue
    if ($feedDirs) {
        Write-Host "`n=== Feed directories ==="
        $feedDirs | ForEach-Object { Write-Host "  $($_.FullName)" }
    }
} catch {}

# Step 10: Post-install check
Write-Host "`n=== Post-install check ==="
if (Test-Path $viaTestDir) {
    $testCount = (Get-ChildItem $viaTestDir -Recurse -Filter "*.llb" -ErrorAction SilentlyContinue).Count
    Write-Host "SUCCESS: VI Analyzer tests now installed: $testCount LLBs" -ForegroundColor Green
} else {
    Write-Host "Tests still not found at $viaTestDir" -ForegroundColor Yellow
    
    # Show _VI Analyzer dir structure
    $viaDir = "C:\Program Files\National Instruments\LabVIEW 2026\project\_VI Analyzer"
    if (Test-Path $viaDir) {
        Write-Host "`nContents of _VI Analyzer (dirs only):"
        Get-ChildItem $viaDir -Directory -ErrorAction SilentlyContinue | ForEach-Object {
            Write-Host "  DIR  $($_.FullName)"
        }
        Write-Host "LLB files:"
        Get-ChildItem $viaDir -Filter "*.llb" -ErrorAction SilentlyContinue | ForEach-Object {
            Write-Host "  $($_.Name) ($($_.Length) bytes)"
        }
    }
}
