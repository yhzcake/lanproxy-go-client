# 专门为 Redmi AX5 (ipq60xx) 构建 lanproxy-client
# Redmi AX5: ARMv7 Processor rev 4 (v7l), ipq60xx 架构

param(
    [string]$Version = ""
)

$ErrorActionPreference = "Stop"

if (-not $Version) {
    $Version = Get-Date -Format "yyyyMMdd"
}

$LDFLAGS = "-X main.VERSION=$Version -s -w"
$PKG_NAME = "lanproxy-client"

Write-Host "Building lanproxy-client for Redmi AX5 (ipq60xx)..." -ForegroundColor Green
Write-Host "Version: $Version" -ForegroundColor Yellow

# 构建二进制文件
Write-Host "Building binary..." -ForegroundColor Cyan
$env:CGO_ENABLED = "0"
$env:GOOS = "linux"
$env:GOARCH = "arm"
$env:GOARM = "7"

try {
    & go build -ldflags $LDFLAGS -o "lanproxy-client-ipq60xx" ./src/main
    if ($LASTEXITCODE -ne 0) {
        throw "Build failed"
    }
    Write-Host "✓ Binary built successfully" -ForegroundColor Green
}
catch {
    Write-Host "✗ Build failed: $_" -ForegroundColor Red
    exit 1
}
finally {
    # 清理环境变量
    Remove-Item Env:CGO_ENABLED -ErrorAction SilentlyContinue
    Remove-Item Env:GOOS -ErrorAction SilentlyContinue
    Remove-Item Env:GOARCH -ErrorAction SilentlyContinue
    Remove-Item Env:GOARM -ErrorAction SilentlyContinue
}

# 压缩二进制文件（如果有 upx）
if (Get-Command upx -ErrorAction SilentlyContinue) {
    Write-Host "Compressing binary..." -ForegroundColor Yellow
    & upx -9 "lanproxy-client-ipq60xx" 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Binary compressed" -ForegroundColor Green
    }
}

# 创建 IPK 包结构
Write-Host "Creating IPK package structure..." -ForegroundColor Cyan
$PKG_DIR = "${PKG_NAME}_${Version}_ipq60xx"

# 清理旧的构建
if (Test-Path $PKG_DIR) {
    Remove-Item -Recurse -Force $PKG_DIR
}

# 创建目录结构
New-Item -ItemType Directory -Path "$PKG_DIR/usr/bin" -Force | Out-Null
New-Item -ItemType Directory -Path "$PKG_DIR/etc/init.d" -Force | Out-Null
New-Item -ItemType Directory -Path "$PKG_DIR/etc/config" -Force | Out-Null
New-Item -ItemType Directory -Path "$PKG_DIR/CONTROL" -Force | Out-Null

# 复制二进制文件
Copy-Item "lanproxy-client-ipq60xx" "$PKG_DIR/usr/bin/lanproxy-client"

# 创建控制文件
@"
Package: $PKG_NAME
Version: $Version
Description: LanProxy Go client for OpenWrt (Redmi AX5 optimized)
Section: net
Priority: optional
Maintainer: LanProxy Team <support@lanproxy.com>
Architecture: ipq60xx
Depends: 
Source: https://github.com/ffay/lanproxy-go-client
"@ | Out-File -FilePath "$PKG_DIR/CONTROL/control" -Encoding ASCII

# 创建启动脚本
@'
#!/bin/sh /etc/rc.common

START=99
STOP=10

USE_PROCD=1
PROG=/usr/bin/lanproxy-client

start_service() {
    config_load lanproxy
    
    local enabled server_host server_port client_key enable_ssl ssl_cert
    config_get enabled main enabled 0
    config_get server_host main server_host
    config_get server_port main server_port 4900
    config_get client_key main client_key
    config_get enable_ssl main enable_ssl false
    config_get ssl_cert main ssl_cert
    
    [ "$enabled" = "1" ] || return 1
    [ -n "$server_host" ] || return 1
    [ -n "$client_key" ] || return 1
    
    procd_open_instance
    procd_set_param command $PROG
    procd_append_param command -s "$server_host"
    procd_append_param command -p "$server_port"
    procd_append_param command -k "$client_key"
    
    if [ "$enable_ssl" = "true" ]; then
        procd_append_param command -ssl true
        [ -n "$ssl_cert" ] && procd_append_param command -cer "$ssl_cert"
    fi
    
    procd_set_param respawn
    procd_set_param stdout 1
    procd_set_param stderr 1
    procd_close_instance
}

reload_service() {
    stop
    start
}
'@ | Out-File -FilePath "$PKG_DIR/etc/init.d/lanproxy" -Encoding ASCII

# 创建配置文件
@'
config lanproxy 'main'
    option enabled '0'
    option server_host ''
    option server_port '4900'
    option client_key ''
    option enable_ssl 'false'
    option ssl_cert ''
'@ | Out-File -FilePath "$PKG_DIR/etc/config/lanproxy" -Encoding ASCII

# 创建安装后脚本
@'
#!/bin/sh

# 启用服务但不自动启动
/etc/init.d/lanproxy enable

echo "LanProxy client installed successfully on Redmi AX5!"
echo "Please configure /etc/config/lanproxy and then start the service:"
echo "  uci set lanproxy.main.enabled='1'"
echo "  uci set lanproxy.main.server_host='your.server.com'"
echo "  uci set lanproxy.main.client_key='your_client_key'"
echo "  uci commit lanproxy"
echo "  /etc/init.d/lanproxy start"
'@ | Out-File -FilePath "$PKG_DIR/CONTROL/postinst" -Encoding ASCII

# 创建卸载前脚本
@'
#!/bin/sh

/etc/init.d/lanproxy stop
/etc/init.d/lanproxy disable
'@ | Out-File -FilePath "$PKG_DIR/CONTROL/prerm" -Encoding ASCII

Write-Host "✓ Package structure created" -ForegroundColor Green

Write-Host ""
Write-Host "🎉 Build completed for Windows!" -ForegroundColor Green
Write-Host "Note: IPK packaging requires Linux tools (WSL or Linux VM)" -ForegroundColor Yellow
Write-Host ""
Write-Host "Binary created: lanproxy-client-ipq60xx" -ForegroundColor Cyan
Write-Host "Package structure created in: $PKG_DIR" -ForegroundColor Cyan
Write-Host ""
Write-Host "To complete IPK packaging, use WSL or Linux:" -ForegroundColor Yellow
Write-Host "  1. Copy files to Linux environment" -ForegroundColor Gray
Write-Host "  2. Run: ./build-redmi-ax5.sh" -ForegroundColor Gray
Write-Host ""
Write-Host "Or upload the binary directly to your router:" -ForegroundColor Cyan
Write-Host "  scp lanproxy-client-ipq60xx root@192.168.1.1:/usr/bin/lanproxy-client" -ForegroundColor Gray

# 清理
Remove-Item -Force "lanproxy-client-ipq60xx" -ErrorAction SilentlyContinue