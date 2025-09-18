# 快速入门指南

## 🚀 立即开始使用

### 1. 获取适用于你路由器的软件包

访问 [Releases 页面](../../releases) 下载对应架构的 IPK 包：

- **大多数路由器**: `lanproxy-client_*_mips_24kc.ipk` 或 `lanproxy-client_*_mipsel_24kc.ipk`
- **ARM 路由器**: `lanproxy-client_*_arm_cortex-a7.ipk`
- **软路由/x86**: `lanproxy-client_*_x86_64.ipk`

### 2. 安装到 OpenWrt 路由器

```bash
# 上传文件到路由器
scp lanproxy-client_*.ipk root@192.168.1.1:/tmp/

# SSH 连接路由器并安装
ssh root@192.168.1.1
opkg install /tmp/lanproxy-client_*.ipk
```

### 3. 配置服务

```bash
# 启用服务
uci set lanproxy.main.enabled='1'

# 设置服务器信息（请替换为你的实际信息）
uci set lanproxy.main.server_host='你的代理服务器地址'
uci set lanproxy.main.client_key='你的客户端密钥'

# 提交配置
uci commit lanproxy

# 启动服务
/etc/init.d/lanproxy start
/etc/init.d/lanproxy enable
```

### 4. 验证运行状态

```bash
# 检查服务状态
/etc/init.d/lanproxy status

# 查看日志
logread | grep lanproxy

# 检查进程
ps | grep lanproxy-client
```

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