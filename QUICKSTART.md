# 快速入门指南

## 🚨 IPK 包问题解决

如果遇到 `Malformed package file` 错误，请使用以下解决方案：

## 🚀 立即开始使用

### 方法1: 一键安装脚本（推荐 - Redmi AX5）

```bash
# 1. 配置脚本（编辑 install-redmi-ax5.sh）
# 设置你的服务器信息：
#   SERVER_HOST="your.proxy.server.com"
#   CLIENT_KEY="your_client_key_here"

# 2. 运行一键安装
./install-redmi-ax5.sh
```

### 方法2: 使用原始构建脚本

```bash
# 运行增强版构建脚本（已添加 ipq60xx 支持）
./build-release.sh

# 找到适合的文件
# Redmi AX5 使用: client_linux_ipq60xx
# 或者: client_linux_arm7

# 上传到路由器
scp client_linux_ipq60xx root@192.168.1.1:/usr/bin/lanproxy-client

# 在路由器上运行
ssh root@192.168.1.1 "/usr/bin/lanproxy-client -s server -p 4900 -k key"
```

### 方法3: GitHub Actions 构建

访问 [Actions 页面](../../actions) 下载最新构建的文件：
- 标准包：`standard-packages` 
- OpenWrt 专用：`openwrt-ipq60xx`

## 🔧 常见架构识别

不确定你的路由器架构？运行以下命令：

```bash
# 在路由器上执行
uname -m
cat /proc/cpuinfo | grep "model name"
```

常见结果对应：
- `mips` → 使用 `mips_24kc` 包
- `mipsel` → 使用 `mipsel_24kc` 包  
- `armv7l` → 使用 `arm_cortex-a7` 包
- `aarch64` → 使用 `aarch64_cortex-a53` 包
- `x86_64` → 使用 `x86_64` 包

## 📞 获取帮助

遇到问题？请：
1. 查看 [完整文档](README-OpenWrt.md)
2. [提交 Issue](../../issues)
3. 查看 [故障排除指南](README-OpenWrt.md#troubleshooting)

---
💡 **提示**: 首次安装后记得在防火墙中开放相关端口，确保内网穿透正常工作！