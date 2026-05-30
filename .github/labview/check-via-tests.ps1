Write-Host "=== VI Analyzer Test Installation (v4) ==="

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

# Step 3: Show current feeds
Write-Host "`n=== Current feeds ==="
$feedOutput = & $nipkgPath feed-list 2>&1
$feedOutput | ForEach-Object { Write-Host "  $_" }

# Step 4: Add NI product feeds to get access to VI Analyzer packages
Write-Host "`n=== Adding NI product feeds ==="
$feedUrls = @(
    @{ Name = "ni-released"; Url = "https://download.ni.com/support/nipkg/products/ni-released" },
    @{ Name = "ni-labview-2026"; Url = "https://download.ni.com/support/nipkg/products/ni-l/ni-labview-2026/26.1/released" },
    @{ Name = "ni-labview-2026-community"; Url = "https://download.ni.com/support/nipkg/products/ni-l/ni-labview-2026-community/26.1/released" },
    @{ Name = "ni-via-toolkit"; Url = "https://download.ni.com/support/nipkg/products/ni-v/ni-viawin-labview-support/26.1/released" },
    @{ Name = "ni-all-products"; Url = "https://download.ni.com/support/nipkg/products" }
)

foreach ($feed in $feedUrls) {
    Write-Host "  Adding feed: $($feed.Name) -> $($feed.Url)"
    try {
        $addOutput = & $nipkgPath feed-add $feed.Name $feed.Url 2>&1
        $addOutput | ForEach-Object { Write-Host "    $_" }
    } catch {
        Write-Host "    Error: $_"
    }
}

# Step 5: Update feeds after adding new ones
Write-Host "`n=== nipkg update (refresh all feeds) ==="
try {
    $updateOutput = & $nipkgPath update 2>&1
    $updateOutput | ForEach-Object { Write-Host "  $_" }
} catch {
    Write-Host "  nipkg update failed: $_"
}

# Step 6: Show updated feed list
Write-Host "`n=== Updated feeds ==="
$feedOutput = & $nipkgPath feed-list 2>&1
$feedOutput | ForEach-Object { Write-Host "  $_" }

# Step 7: Search for VIA/analyzer packages in the new feeds
Write-Host "`n=== Available VIA/analyzer packages after feed update ==="
try {
    $allPkgs = & $nipkgPath list 2>&1
    $matchCount = 0
    $allPkgs | Where-Object { $_ -match "via|analyzer" } | ForEach-Object {
        Write-Host "  $_"
        $matchCount++
    }
    Write-Host "  Found $matchCount matching packages (total: $($allPkgs.Count))"
} catch {
    Write-Host "  list failed: $_"
}

# Step 8: Try installing VI Analyzer test packages
$packageNames = @(
    "ni-viawin-labview-support",
    "ni-viawin-tests",
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
