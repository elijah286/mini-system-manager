Write-Host "=== VI Analyzer Test Installation ==="

$viaTestDir = "C:\Program Files\National Instruments\LabVIEW 2026\project\_VI Analyzer\_tests"

# Step 1: Check if tests already exist
if (Test-Path $viaTestDir) {
    $testCount = (Get-ChildItem $viaTestDir -Recurse -Filter "*.llb" -ErrorAction SilentlyContinue).Count
    Write-Host "VI Analyzer tests already installed: $testCount LLBs found"
    exit 0
}

Write-Host "VI Analyzer _tests directory not found. Attempting to install..."

# Step 2: Check if NIPM is available
Write-Host "`n=== Checking NIPM availability ==="
$nipmPath = $null
$nipmCandidates = @(
    "C:\Program Files\National Instruments\NI Package Manager\nipm.exe",
    "C:\Program Files (x86)\National Instruments\NI Package Manager\nipm.exe"
)
foreach ($p in $nipmCandidates) {
    if (Test-Path $p) {
        $nipmPath = $p
        Write-Host "Found NIPM at: $p"
        break
    }
}

# Also try PATH
if (-not $nipmPath) {
    $nipmCmd = Get-Command nipm -ErrorAction SilentlyContinue
    if ($nipmCmd) {
        $nipmPath = $nipmCmd.Source
        Write-Host "Found NIPM in PATH: $nipmPath"
    }
}

# Also try nipkg (older name)
$nipkgPath = $null
if (-not $nipmPath) {
    $nipkgCandidates = @(
        "C:\Program Files\National Instruments\NI Package Manager\nipkg.exe",
        "C:\Program Files (x86)\National Instruments\NI Package Manager\nipkg.exe"
    )
    foreach ($p in $nipkgCandidates) {
        if (Test-Path $p) {
            $nipkgPath = $p
            Write-Host "Found nipkg at: $p"
            break
        }
    }
    if (-not $nipkgPath) {
        $nipkgCmd = Get-Command nipkg -ErrorAction SilentlyContinue
        if ($nipkgCmd) {
            $nipkgPath = $nipkgCmd.Source
            Write-Host "Found nipkg in PATH: $nipkgPath"
        }
    }
}

# Step 3: List installed packages to find VI Analyzer
if ($nipmPath) {
    Write-Host "`n=== NIPM: Listing installed packages (filtered for analyzer/via) ==="
    try {
        $output = & $nipmPath list 2>&1
        $output | Where-Object { $_ -match "analyzer|via " } | ForEach-Object { Write-Host "  $_" }
        Write-Host "`n=== NIPM: All installed packages ==="
        $output | ForEach-Object { Write-Host "  $_" }
    } catch {
        Write-Host "NIPM list failed: $_"
    }

    # Try to find available VI Analyzer packages
    Write-Host "`n=== NIPM: Searching for available VI Analyzer packages ==="
    try {
        $searchOutput = & $nipmPath search "vi analyzer" 2>&1
        $searchOutput | ForEach-Object { Write-Host "  $_" }
    } catch {
        Write-Host "NIPM search failed: $_"
    }

    # Try installing common package names for VI Analyzer
    $packageNames = @(
        "ni-vi-analyzer",
        "ni-labview-2026-vi-analyzer",
        "ni-labview-vi-analyzer",
        "labview-vi-analyzer"
    )
    foreach ($pkg in $packageNames) {
        Write-Host "`n=== NIPM: Trying to install $pkg ==="
        try {
            $installOutput = & $nipmPath install $pkg --accept-eulas -y 2>&1
            $installOutput | ForEach-Object { Write-Host "  $_" }
            if ($LASTEXITCODE -eq 0) {
                Write-Host "  Package $pkg installed successfully!" -ForegroundColor Green
                break
            }
        } catch {
            Write-Host "  Failed: $_"
        }
    }
} elseif ($nipkgPath) {
    Write-Host "`n=== nipkg: Listing installed packages ==="
    try {
        $output = & $nipkgPath list-installed 2>&1
        $output | Where-Object { $_ -match "analyzer|via " } | ForEach-Object { Write-Host "  $_" }
        Write-Host "`nAll installed:"
        $output | ForEach-Object { Write-Host "  $_" }
    } catch {
        Write-Host "nipkg list failed: $_"
    }

    Write-Host "`n=== nipkg: Searching available packages ==="
    try {
        $output = & $nipkgPath list 2>&1
        $output | Where-Object { $_ -match "analyzer" } | ForEach-Object { Write-Host "  $_" }
    } catch {
        Write-Host "nipkg search failed: $_"
    }

    # Try installing
    $packageNames = @(
        "ni-vi-analyzer",
        "ni-labview-2026-vi-analyzer"
    )
    foreach ($pkg in $packageNames) {
        Write-Host "`n=== nipkg: Trying to install $pkg ==="
        try {
            $installOutput = & $nipkgPath install $pkg --accept-eulas -y 2>&1
            $installOutput | ForEach-Object { Write-Host "  $_" }
        } catch {
            Write-Host "  Failed: $_"
        }
    }
} else {
    Write-Host "Neither NIPM nor nipkg found in the container."

    # Search for any package manager executables
    Write-Host "`n=== Searching for package manager executables ==="
    $searchPaths = @(
        "C:\Program Files\National Instruments",
        "C:\Program Files (x86)\National Instruments"
    )
    foreach ($sp in $searchPaths) {
        if (Test-Path $sp) {
            Get-ChildItem $sp -Recurse -ErrorAction SilentlyContinue | Where-Object {
                $_.Name -match "nipm|nipkg|package.manager"
            } | ForEach-Object {
                Write-Host "  $($_.FullName)"
            }
        }
    }
}

# Step 4: Check if tests exist now (after install attempt)
Write-Host "`n=== Post-install check ==="
if (Test-Path $viaTestDir) {
    $testCount = (Get-ChildItem $viaTestDir -Recurse -Filter "*.llb" -ErrorAction SilentlyContinue).Count
    Write-Host "SUCCESS: VI Analyzer tests now installed: $testCount LLBs" -ForegroundColor Green
} else {
    Write-Host "Tests still not found at $viaTestDir" -ForegroundColor Yellow

    # List what IS in the _VI Analyzer directory
    $viaDir = "C:\Program Files\National Instruments\LabVIEW 2026\project\_VI Analyzer"
    if (Test-Path $viaDir) {
        Write-Host "Contents of _VI Analyzer:"
        Get-ChildItem $viaDir -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
            $type = if ($_.PSIsContainer) { "DIR" } else { "FILE ($($_.Length) bytes)" }
            Write-Host "  $type  $($_.FullName)"
        }
    }

    # List ALL NI directories for clues
    Write-Host "`nAll NI program directories:"
    $niDir = "C:\Program Files\National Instruments"
    if (Test-Path $niDir) {
        Get-ChildItem $niDir -Directory | ForEach-Object { Write-Host "  $($_.FullName)" }
    }
}
