Write-Host "=== VI Analyzer Test Installation (v5) ==="

$viaTestDir = "C:\Program Files\National Instruments\LabVIEW 2026\project\_VI Analyzer\_tests"

# Step 1: Check if tests already exist
if (Test-Path $viaTestDir) {
    $testCount = (Get-ChildItem $viaTestDir -Recurse -Filter "*.llb" -ErrorAction SilentlyContinue).Count
    Write-Host "VI Analyzer tests already installed: $testCount LLBs found"
    exit 0
}

Write-Host "VI Analyzer _tests directory not found. Attempting to install..."

# Step 2: Find nipkg
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

# Step 3: Get nipkg help for feed-add syntax
Write-Host "`n=== nipkg help feed-add ==="
try {
    $helpOutput = & $nipkgPath help feed-add 2>&1
    $helpOutput | ForEach-Object { Write-Host "  $_" }
} catch {
    Write-Host "  help failed: $_"
}

# Step 4: Show current feeds
Write-Host "`n=== Current feeds ==="
$feedOutput = & $nipkgPath feed-list 2>&1
$feedOutput | ForEach-Object { Write-Host "  $_" }

# Step 5: Try multiple feed-add syntax variations
Write-Host "`n=== Adding NI product feeds (trying multiple syntaxes) ==="
$feedUrls = @(
    "https://download.ni.com/support/nipkg/products/ni-l/ni-labview-2026-community/26.1/released",
    "https://download.ni.com/support/nipkg/products/ni-v/ni-viawin-labview-support/26.1/released",
    "https://download.ni.com/support/nipkg/products/ni-l/ni-labview-2026/26.1/released"
)

foreach ($url in $feedUrls) {
    # Syntax 1: just URL
    Write-Host "`n  Trying: nipkg feed-add $url"
    $out = & $nipkgPath feed-add $url 2>&1
    $out | ForEach-Object { Write-Host "    $_" }
}

# Also try --name= syntax
Write-Host "`n  Trying: nipkg feed-add --name=ni-lv2026 <url>"
$out = & $nipkgPath feed-add "--name=ni-lv2026" "https://download.ni.com/support/nipkg/products/ni-l/ni-labview-2026-community/26.1/released" 2>&1
$out | ForEach-Object { Write-Host "    $_" }

# Also try with quotes and different arg order
Write-Host "`n  Trying: nipkg feed-add <url> --name ni-via"
$out = & $nipkgPath feed-add "https://download.ni.com/support/nipkg/products/ni-v/ni-viawin-labview-support/26.1/released" "--name" "ni-via" 2>&1
$out | ForEach-Object { Write-Host "    $_" }

# Step 6: Update feeds
Write-Host "`n=== nipkg update ==="
$updateOutput = & $nipkgPath update 2>&1
$updateOutput | ForEach-Object { Write-Host "  $_" }

# Step 7: Show updated feeds
Write-Host "`n=== Updated feeds ==="
$feedOutput = & $nipkgPath feed-list 2>&1
$feedOutput | ForEach-Object { Write-Host "  $_" }

# Step 8: Search for VIA packages
Write-Host "`n=== Available VIA/analyzer packages ==="
$allPkgs = & $nipkgPath list 2>&1
$matchCount = 0
$allPkgs | Where-Object { $_ -match "via|analyzer" } | ForEach-Object {
    Write-Host "  $_"
    $matchCount++
}
Write-Host "  Found $matchCount matching packages (total: $($allPkgs.Count))"

# Step 9: Try installing
$packageNames = @(
    "ni-viawin-labview-support",
    "ni-vi-analyzer",
    "ni-labview-2026-vi-analyzer"
)
foreach ($pkg in $packageNames) {
    Write-Host "`n=== nipkg install $pkg ==="
    $installOutput = & $nipkgPath install $pkg --accept-eulas -y 2>&1
    $installOutput | ForEach-Object { Write-Host "  $_" }
    if ($LASTEXITCODE -eq 0 -and (Test-Path $viaTestDir)) {
        Write-Host "  SUCCESS: _tests now exists!" -ForegroundColor Green
        break
    }
}

# Step 9: Post-install check
Write-Host "`n=== Post-install check ==="
if (Test-Path $viaTestDir) {
    $testCount = (Get-ChildItem $viaTestDir -Recurse -Filter "*.llb" -ErrorAction SilentlyContinue).Count
    Write-Host "SUCCESS: VI Analyzer tests now installed: $testCount LLBs" -ForegroundColor Green
} else {
    Write-Host "Tests still not found at $viaTestDir" -ForegroundColor Yellow
    
    # Show _VI Analyzer dir structure
    $viaDir = "C:\Program Files\National Instruments\LabVIEW 2026\project\_VI Analyzer"
    if (Test-Path $viaDir) {
        Write-Host "`nContents of _VI Analyzer:"
        Get-ChildItem $viaDir -ErrorAction SilentlyContinue | ForEach-Object {
            $type = if ($_.PSIsContainer) { "DIR" } else { "FILE ($($_.Length) bytes)" }
            Write-Host "  $type  $($_.Name)"
        }
    }
}
