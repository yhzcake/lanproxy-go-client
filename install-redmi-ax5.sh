#!/bin/bash

# Redmi AX5 快速安装脚本
# 这个脚本会构建并安装适用于 Redmi AX5 的 lanproxy-client

set -e

# 配置参数（请修改这些值）
ROUTER_IP="192.168.1.1"
SERVER_HOST=""
SERVER_PORT="4900"
CLIENT_KEY=""

# 检查必需参数
if [ -z "$SERVER_HOST" ] || [ -z "$CLIENT_KEY" ]; then
    echo "❌ 请先在脚本中配置 SERVER_HOST 和 CLIENT_KEY"
    echo "编辑此脚本，设置以下变量："
    echo "  SERVER_HOST=\"your.proxy.server.com\""
    echo "  CLIENT_KEY=\"your_client_key_here\""
    exit 1
fi

echo "🚀 开始为 Redmi AX5 构建和安装 lanproxy-client"
echo "目标路由器: $ROUTER_IP"
echo "代理服务器: $SERVER_HOST:$SERVER_PORT"

# 构建二进制文件
echo "📦 构建二进制文件..."
VERSION=$(date -u +%Y%m%d)
LDFLAGS="-X main.VERSION=$VERSION -s -w"

env CGO_ENABLED=0 GOOS=linux GOARCH=arm GOARM=7 go build \
    -ldflags "$LDFLAGS" \
    -o client_linux_ipq60xx \
    ./src/main

echo "✅ 构建完成: client_linux_ipq60xx"

# 压缩文件（如果有 upx）
if command -v upx >/dev/null 2>&1; then
    echo "🗜️ 压缩二进制文件..."
    upx -9 client_linux_ipq60xx 2>/dev/null || true
fi

# 上传到路由器
echo "📤 上传到路由器 $ROUTER_IP..."
scp client_linux_ipq60xx root@$ROUTER_IP:/usr/bin/lanproxy-client

# 在路由器上安装
echo "⚙️ 在路由器上配置服务..."
ssh root@$ROUTER_IP << EOF
# 设置权限
chmod +x /usr/bin/lanproxy-client

# 测试二进制文件
echo "🧪 测试二进制文件..."
/usr/bin/lanproxy-client --help

# 创建配置目录
mkdir -p /etc/config

# 创建配置文件
cat > /etc/config/lanproxy << 'EOL'
config lanproxy 'main'
    option enabled '1'
    option server_host '$SERVER_HOST'
    option server_port '$SERVER_PORT'
    option client_key '$CLIENT_KEY'
    option enable_ssl 'false'
    option ssl_cert ''
EOL

# 创建启动脚本
cat > /etc/init.d/lanproxy << 'EOL'
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
    
    [ "\$enabled" = "1" ] || return 1
    [ -n "\$server_host" ] || return 1
    [ -n "\$client_key" ] || return 1
    
    procd_open_instance
    procd_set_param command \$PROG
    procd_append_param command -s "\$server_host"
    procd_append_param command -p "\$server_port"
    procd_append_param command -k "\$client_key"
    
    if [ "\$enable_ssl" = "true" ]; then
        procd_append_param command -ssl true
        [ -n "\$ssl_cert" ] && procd_append_param command -cer "\$ssl_cert"
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
EOL

# 设置权限
chmod +x /etc/init.d/lanproxy

# 启用并启动服务
/etc/init.d/lanproxy enable
/etc/init.d/lanproxy start

echo "✅ 服务已启动"
echo "📋 配置信息:"
echo "  服务器: $SERVER_HOST:$SERVER_PORT"
echo "  状态: \$((/etc/init.d/lanproxy status && echo "运行中") || echo "未运行")"

echo ""
echo "🔧 管理命令:"
echo "  查看状态: /etc/init.d/lanproxy status"
echo "  启动服务: /etc/init.d/lanproxy start"
echo "  停止服务: /etc/init.d/lanproxy stop"
echo "  重启服务: /etc/init.d/lanproxy restart"
echo "  查看日志: logread | grep lanproxy"
echo "  查看进程: ps | grep lanproxy"
EOF

# 清理本地文件
rm -f client_linux_ipq60xx

echo ""
echo "🎉 安装完成！"
echo "✅ lanproxy-client 已安装并启动在 Redmi AX5 上"
echo ""
echo "📱 在路由器上检查状态："
echo "  ssh root@$ROUTER_IP \"/etc/init.d/lanproxy status\""
echo ""
echo "📝 查看日志："
echo "  ssh root@$ROUTER_IP \"logread | grep lanproxy\""