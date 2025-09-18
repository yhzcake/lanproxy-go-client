# OpenWrt build script for lanproxy-go-client (Windows PowerShell)
# This script builds the client for common OpenWrt architectures

param(
    [string]$Version = ""
)

$ErrorActionPreference = "Stop"

if (-not $Version) {
    $Version = Get-Date -Format "yyyyMMdd"
}

$LDFLAGS = "-X main.VERSION=$Version -s -w"

Write-Host "Building lanproxy-go-client for OpenWrt architectures..." -ForegroundColor Green
Write-Host "Version: $Version" -ForegroundColor Yellow

# Create build directory
if (-not (Test-Path "build")) {
    New-Item -ItemType Directory -Name "build" | Out-Null
}

# Common OpenWrt architectures
$targets = @{
    "mips" = @{
        "GOOS" = "linux"
        "GOARCH" = "mips" 
        "GOMIPS" = "softfloat"
    }
    "mipsel" = @{
        "GOOS" = "linux"
        "GOARCH" = "mipsle"
        "GOMIPS" = "softfloat"
    }
    "arm_cortex-a7" = @{
        "GOOS" = "linux"
        "GOARCH" = "arm"
        "GOARM" = "7"
    }
    "aarch64" = @{
        "GOOS" = "linux"
        "GOARCH" = "arm64"
    }
    "x86_64" = @{
        "GOOS" = "linux"
        "GOARCH" = "amd64"
    }
    "i386" = @{
        "GOOS" = "linux"
        "GOARCH" = "386"
    }
}

foreach ($target in $targets.Keys) {
    Write-Host "Building for $target..." -ForegroundColor Cyan
    
    $env:CGO_ENABLED = "0"
    $env:GOOS = $targets[$target]["GOOS"]
    $env:GOARCH = $targets[$target]["GOARCH"]
    
    if ($targets[$target].ContainsKey("GOMIPS")) {
        $env:GOMIPS = $targets[$target]["GOMIPS"]
    } else {
        Remove-Item Env:GOMIPS -ErrorAction SilentlyContinue
    }
    
    if ($targets[$target].ContainsKey("GOARM")) {
        $env:GOARM = $targets[$target]["GOARM"]
    } else {
        Remove-Item Env:GOARM -ErrorAction SilentlyContinue
    }
    
    $outputFile = "build/lanproxy-client-$target"
    
    try {
        & go build -ldflags $LDFLAGS -o $outputFile ./src/main
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✓ Built lanproxy-client-$target" -ForegroundColor Green
            
            # Try to compress if upx is available
            if (Get-Command upx -ErrorAction SilentlyContinue) {
                Write-Host "Compressing $target binary..." -ForegroundColor Yellow
                & upx -9 $outputFile 2>$null
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "✓ Compressed $target binary" -ForegroundColor Green
                }
            }
        } else {
            Write-Host "✗ Failed to build lanproxy-client-$target" -ForegroundColor Red
        }
    }
    catch {
        Write-Host "✗ Error building $target`: $_" -ForegroundColor Red
    }
}

# Clean up environment variables
Remove-Item Env:CGO_ENABLED -ErrorAction SilentlyContinue
Remove-Item Env:GOOS -ErrorAction SilentlyContinue  
Remove-Item Env:GOARCH -ErrorAction SilentlyContinue
Remove-Item Env:GOMIPS -ErrorAction SilentlyContinue
Remove-Item Env:GOARM -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "Build completed! Binaries are in ./build/ directory:" -ForegroundColor Green
Get-ChildItem build/ | Format-Table Name, Length, LastWriteTime

Write-Host ""
Write-Host "To test a binary, upload it to your OpenWrt router and run:" -ForegroundColor Yellow
Write-Host "  ./lanproxy-client-<target> -s your.server.com -p 4900 -k your_client_key" -ForegroundColor Cyan