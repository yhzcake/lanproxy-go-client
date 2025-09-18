#!/bin/bash

# 专门为 Redmi AX5 (ipq60xx) 构建 lanproxy-client
# Redmi AX5: ARMv7 Processor rev 4 (v7l), ipq60xx 架构

set -e

VERSION=$(date -u +%Y%m%d)
LDFLAGS="-X main.VERSION=$VERSION -s -w"
PKG_NAME="lanproxy-client"

echo "Building lanproxy-client for Redmi AX5 (ipq60xx)..."
echo "Version: $VERSION"

# 构建二进制文件
echo "Building binary..."
env CGO_ENABLED=0 GOOS=linux GOARCH=arm GOARM=7 go build \
    -ldflags "$LDFLAGS" \
    -o lanproxy-client-ipq60xx \
    ./src/main

echo "✓ Binary built successfully"

# 压缩二进制文件（如果有 upx）
if command -v upx >/dev/null 2>&1; then
    echo "Compressing binary..."
    upx -9 lanproxy-client-ipq60xx 2>/dev/null || true
    echo "✓ Binary compressed"
fi

# 创建 IPK 包结构
echo "Creating IPK package structure..."
PKG_DIR="${PKG_NAME}_${VERSION}_ipq60xx"

# 清理旧的构建
rm -rf $PKG_DIR

# 创建目录结构
mkdir -p $PKG_DIR/usr/bin
mkdir -p $PKG_DIR/etc/init.d
mkdir -p $PKG_DIR/etc/config
mkdir -p $PKG_DIR/CONTROL

# 复制二进制文件
cp lanproxy-client-ipq60xx $PKG_DIR/usr/bin/lanproxy-client
chmod +x $PKG_DIR/usr/bin/lanproxy-client

# 创建控制文件
cat > $PKG_DIR/CONTROL/control << EOF
Package: $PKG_NAME
Version: $VERSION
Description: LanProxy Go client for OpenWrt (Redmi AX5 optimized)
Section: net
Priority: optional
Maintainer: LanProxy Team <support@lanproxy.com>
Architecture: ipq60xx
Depends: 
Source: https://github.com/ffay/lanproxy-go-client
EOF

# 创建启动脚本
cat > $PKG_DIR/etc/init.d/lanproxy << 'EOF'
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
EOF
chmod +x $PKG_DIR/etc/init.d/lanproxy

# 创建配置文件
cat > $PKG_DIR/etc/config/lanproxy << 'EOF'
config lanproxy 'main'
    option enabled '0'
    option server_host ''
    option server_port '4900'
    option client_key ''
    option enable_ssl 'false'
    option ssl_cert ''
EOF

# 创建安装后脚本
cat > $PKG_DIR/CONTROL/postinst << 'EOF'
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
EOF
chmod +x $PKG_DIR/CONTROL/postinst

# 创建卸载前脚本
cat > $PKG_DIR/CONTROL/prerm << 'EOF'
#!/bin/sh

/etc/init.d/lanproxy stop
/etc/init.d/lanproxy disable
EOF
chmod +x $PKG_DIR/CONTROL/prerm

echo "✓ Package structure created"

# 构建 IPK 包
echo "Building IPK package..."

# 创建数据压缩包（排除 CONTROL 目录）
cd $PKG_DIR
find . -path ./CONTROL -prune -o -type f -print | tar --no-recursion -czf ../data.tar.gz -T -
cd ..

# 创建控制信息压缩包
cd $PKG_DIR/CONTROL
tar -czf ../../control.tar.gz .
cd ../..

# 创建 debian-binary 文件
echo "2.0" > debian-binary

# 验证文件存在
if [ ! -f debian-binary ] || [ ! -f control.tar.gz ] || [ ! -f data.tar.gz ]; then
    echo "✗ Error: Missing required files for IPK creation"
    exit 1
fi

# 创建 IPK 包
IPK_FILE="${PKG_NAME}_${VERSION}_ipq60xx.ipk"
ar r $IPK_FILE debian-binary control.tar.gz data.tar.gz

# 验证 IPK 包
echo "Verifying IPK package..."
if [ -f $IPK_FILE ]; then
    echo "✓ IPK package created: $IPK_FILE"
    echo "Package contents:"
    ar t $IPK_FILE
    echo "File size: $(ls -lh $IPK_FILE | awk '{print $5}')"
else
    echo "✗ Error: Failed to create IPK package"
    exit 1
fi

# 生成校验和
sha256sum $IPK_FILE > $IPK_FILE.sha256
md5sum $IPK_FILE > $IPK_FILE.md5

# 清理临时文件
rm -rf $PKG_DIR debian-binary control.tar.gz data.tar.gz lanproxy-client-ipq60xx

echo ""
echo "🎉 Build completed successfully!"
echo "Files created:"
echo "  - $IPK_FILE"
echo "  - $IPK_FILE.sha256"
echo "  - $IPK_FILE.md5"
echo ""
echo "To install on your Redmi AX5:"
echo "  1. scp $IPK_FILE root@192.168.1.1:/tmp/"
echo "  2. ssh root@192.168.1.1"
echo "  3. opkg install /tmp/$IPK_FILE"
echo ""
echo "To verify integrity:"
echo "  sha256sum -c $IPK_FILE.sha256"