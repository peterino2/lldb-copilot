# LLDB Windows Installation & Python Configuration Script
# Run this in PowerShell as Administrator

Write-Host "=== LLDB Windows Installation & Configuration ===" -ForegroundColor Cyan

# Step 1: Check if Scoop is installed
Write-Host "`n[1/6] Checking for Scoop..." -ForegroundColor Yellow
if (!(Get-Command scoop -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Scoop..." -ForegroundColor Green
    Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
    Invoke-RestMethod get.scoop.sh | Invoke-Expression
} else {
    Write-Host "Scoop already installed" -ForegroundColor Green
}

# Step 2: Update Scoop
Write-Host "`n[2/6] Updating Scoop..." -ForegroundColor Yellow
scoop update

# Step 3: Install Python 3.10 (required by LLDB)
Write-Host "`n[3/6] Installing Python 3.10..." -ForegroundColor Yellow
scoop bucket add versions
scoop install versions/python310

# Get Python 3.10 installation path
$python310Path = scoop prefix python310
Write-Host "Python 3.10 installed at: $python310Path" -ForegroundColor Green

# Step 4: Install LLVM (includes LLDB)
Write-Host "`n[4/6] Installing LLVM/LLDB..." -ForegroundColor Yellow
scoop install llvm

# Get LLVM installation path
$llvmPath = scoop prefix llvm

# Step 5: Configure environment variables
Write-Host "`n[5/6] Configuring Python environment variables..." -ForegroundColor Yellow

# Set user environment variables permanently
[System.Environment]::SetEnvironmentVariable('PYTHONHOME', $python310Path, 'User')
[System.Environment]::SetEnvironmentVariable('PYTHONPATH', "$python310Path\Lib;$python310Path\DLLs", 'User')

# Set for current session
$env:PYTHONHOME = $python310Path
$env:PYTHONPATH = "$python310Path\Lib;$python310Path\DLLs"

Write-Host "PYTHONHOME set to: $python310Path" -ForegroundColor Green
Write-Host "PYTHONPATH set to: $python310Path\Lib;$python310Path\DLLs" -ForegroundColor Green

# Step 6: Copy Python DLL to LLDB directory (if missing)
Write-Host "`n[6/6] Ensuring Python DLL is accessible..." -ForegroundColor Yellow
$pythonDll = "$python310Path\python310.dll"
$lldbBinPath = "$llvmPath\bin"

if (Test-Path $pythonDll) {
    if (!(Test-Path "$lldbBinPath\python310.dll")) {
        Copy-Item $pythonDll $lldbBinPath -Force
        Write-Host "Copied python310.dll to LLDB directory" -ForegroundColor Green
    } else {
        Write-Host "python310.dll already exists in LLDB directory" -ForegroundColor Green
    }
} else {
    Write-Host "Warning: python310.dll not found at $pythonDll" -ForegroundColor Red
}

# Verification
Write-Host "`n=== Verification ===" -ForegroundColor Cyan
Write-Host "Testing LLDB..." -ForegroundColor Yellow

# Test LLDB version
& "$lldbBinPath\lldb.exe" --version

if ($LASTEXITCODE -eq 0) {
    Write-Host "`nSuccess! LLDB is configured correctly." -ForegroundColor Green
    Write-Host "`nTo use LLDB in new terminals, restart them or run:" -ForegroundColor Yellow
    Write-Host "  `$env:PYTHONHOME = '$python310Path'" -ForegroundColor White
    Write-Host "  `$env:PYTHONPATH = '$python310Path\Lib;$python310Path\DLLs'" -ForegroundColor White
} else {
    Write-Host "`nWarning: LLDB may still have issues. Check the output above." -ForegroundColor Red
}

Write-Host "`n=== Installation Complete ===" -ForegroundColor Cyan
