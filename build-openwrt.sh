#!/bin/bash

# OpenWrt build script for lanproxy-go-client
# This script builds the client for common OpenWrt architectures

set -e

VERSION=$(date -u +%Y%m%d)
LDFLAGS="-X main.VERSION=$VERSION -s -w"

echo "Building lanproxy-go-client for OpenWrt architectures..."
echo "Version: $VERSION"

# Create build directory
mkdir -p build

# Common OpenWrt architectures
declare -A TARGETS=(
    ["mips"]="GOOS=linux GOARCH=mips GOMIPS=softfloat"
    ["mipsel"]="GOOS=linux GOARCH=mipsle GOMIPS=softfloat"
    ["arm_cortex-a7"]="GOOS=linux GOARCH=arm GOARM=7"
    ["aarch64"]="GOOS=linux GOARCH=arm64"
    ["x86_64"]="GOOS=linux GOARCH=amd64"
    ["i386"]="GOOS=linux GOARCH=386"
)

for target in "${!TARGETS[@]}"; do
    echo "Building for $target..."
    env CGO_ENABLED=0 ${TARGETS[$target]} go build \
        -ldflags "$LDFLAGS" \
        -o "build/lanproxy-client-$target" \
        ./src/main
    
    # Compress if upx is available
    if command -v upx >/dev/null 2>&1; then
        echo "Compressing $target binary..."
        upx -9 "build/lanproxy-client-$target" 2>/dev/null || true
    fi
    
    echo "✓ Built lanproxy-client-$target"
done

echo ""
echo "Build completed! Binaries are in ./build/ directory:"
ls -la build/

echo ""
echo "To test a binary, upload it to your OpenWrt router and run:"
echo "  ./lanproxy-client-<target> -s your.server.com -p 4900 -k your_client_key"