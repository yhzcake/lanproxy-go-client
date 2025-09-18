# LanProxy Go Client for OpenWrt

This repository provides pre-built OpenWrt packages for the LanProxy Go client, enabling easy installation and configuration on OpenWrt routers.

## Features

- 🚀 Automatic building for multiple OpenWrt architectures
- 📦 Ready-to-install IPK packages  
- ⚙️ UCI configuration integration
- 🔄 OpenWrt init script with procd support
- 🔒 SSL/TLS support
- 📱 Compatible with most OpenWrt routers

## Supported Architectures

| Architecture | Description | Common Devices |
|--------------|-------------|----------------|
| `mips_24kc` | MIPS big-endian | Atheros AR71xx, AR724x, AR934x |
| `mipsel_24kc` | MIPS little-endian | MediaTek MT76xx, Broadcom BCM47xx |
| `arm_cortex-a7` | ARM v7 | Raspberry Pi 2, many modern routers |
| `arm_cortex-a9` | ARM v7 (Cortex-A9) | High-end ARM routers |
| `aarch64_cortex-a53` | ARM 64-bit | Raspberry Pi 3/4, modern ARM64 routers |
| `x86_64` | Intel/AMD 64-bit | Soft routers, PC-based OpenWrt |
| `i386` | Intel/AMD 32-bit | Older x86 devices |

## Quick Installation

### Method 1: Download Pre-built Packages (Recommended)

1. Go to the [Releases](../../releases) page
2. Download the appropriate `.ipk` file for your router architecture
3. Upload to your router:
   ```bash
   scp lanproxy-client_*.ipk root@192.168.1.1:/tmp/
   ```
4. Install via SSH:
   ```bash
   opkg install /tmp/lanproxy-client_*.ipk
   ```

### Method 2: Build from Source

```bash
# Clone the repository
git clone https://github.com/ffay/lanproxy-go-client.git
cd lanproxy-go-client

# Build for OpenWrt (Linux/macOS)
./build-openwrt.sh

# Build for OpenWrt (Windows)
powershell -ExecutionPolicy Bypass -File build-openwrt.ps1
```

## Configuration

After installation, configure the client using UCI:

```bash
# Enable the service
uci set lanproxy.main.enabled='1'

# Set server connection details
uci set lanproxy.main.server_host='your.proxy.server.com'
uci set lanproxy.main.server_port='4900'
uci set lanproxy.main.client_key='your_client_key_here'

# Optional: Enable SSL (if your server supports it)
uci set lanproxy.main.enable_ssl='true'
uci set lanproxy.main.ssl_cert='/etc/ssl/certs/lanproxy.pem'

# Apply configuration
uci commit lanproxy

# Start the service
/etc/init.d/lanproxy start

# Enable auto-start on boot
/etc/init.d/lanproxy enable
```

## Service Management

```bash
# Start the service
/etc/init.d/lanproxy start

# Stop the service  
/etc/init.d/lanproxy stop

# Restart the service
/etc/init.d/lanproxy restart

# Check service status
/etc/init.d/lanproxy status

# View logs
logread | grep lanproxy
```

## Configuration File

The configuration is stored in `/etc/config/lanproxy`:

```bash
config lanproxy 'main'
    option enabled '1'
    option server_host 'your.proxy.server.com'
    option server_port '4900' 
    option client_key 'your_client_key_here'
    option enable_ssl 'false'
    option ssl_cert ''
```

## Manual Usage

You can also run the client manually:

```bash
# Basic usage
/usr/bin/lanproxy-client -s your.server.com -p 4900 -k your_client_key

# With SSL
/usr/bin/lanproxy-client -s your.server.com -p 4900 -k your_client_key -ssl true

# With SSL certificate verification
/usr/bin/lanproxy-client -s your.server.com -p 4900 -k your_client_key -ssl true -cer /path/to/cert.pem

# Background execution
nohup /usr/bin/lanproxy-client -s your.server.com -p 4900 -k your_client_key > /tmp/lanproxy.log 2>&1 &
```

## Troubleshooting

### Check if the service is running
```bash
ps | grep lanproxy-client
```

### View real-time logs
```bash
logread -f | grep lanproxy
```

### Test network connectivity
```bash
# Test connection to proxy server
nc -zv your.proxy.server.com 4900

# Check if client can resolve server hostname
nslookup your.proxy.server.com
```

### Common Issues

1. **Service won't start**: Check configuration with `uci show lanproxy`
2. **Connection refused**: Verify server address and port
3. **Authentication failed**: Double-check your client key
4. **SSL errors**: Ensure SSL certificate is valid and accessible

## Building Custom Packages

If you need to build for a specific architecture not covered by our releases:

1. Install Go 1.21+ and cross-compilation tools
2. Modify the GitHub Actions workflow or build scripts
3. Build locally or via GitHub Actions

## GitHub Actions Integration

This repository includes a comprehensive GitHub Actions workflow that:

- ✅ Builds for all major OpenWrt architectures
- ✅ Creates IPK packages with proper OpenWrt integration
- ✅ Generates checksums for verification
- ✅ Automatically creates releases on version tags
- ✅ Provides detailed installation documentation

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project follows the same license as the original [lanproxy](https://github.com/ffay/lanproxy) project.

## Related Projects

- [lanproxy](https://github.com/ffay/lanproxy) - The original Java implementation
- [lanproxy-go](https://github.com/ffay/lanproxy-go) - Go server implementation

## Support

- 🐛 [Report Issues](../../issues)
- 💬 [Discussions](../../discussions) 
- 📖 [Wiki](../../wiki)

---

**Note**: Make sure your router has sufficient storage space (at least 5MB free) before installing the package.