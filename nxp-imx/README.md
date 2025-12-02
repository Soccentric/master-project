# NXP i.MX Board Support

Complete support for NXP i.MX embedded processors using the official meta-freescale BSP layer.

## 🖥️ Supported Machines

### i.MX 9 Series (Latest Generation)

| Machine | Architecture | CPU | GPU | RAM | Notes |
|---------|--------------|-----|-----|-----|-------|
| **imx93frdm** | aarch64 | Cortex-A55 (2-core, 1.7GHz) | 2D GPU | 2GB | Freedom Development Board |
| **imx93evk** | aarch64 | Cortex-A55 (2-core, 1.7GHz) | 2D GPU | 2GB | Evaluation Kit |

### i.MX 8 Series (High Performance)

| Machine | Architecture | CPU | GPU | RAM | Notes |
|---------|--------------|-----|-----|-----|-------|
| **imx8mp-lpddr4-evk** | aarch64 | Cortex-A53 (4-core) + M7 | GC7000XSVX | 4GB | Mainline EVK |
| **imx8mm-lpddr4-evk** | aarch64 | Cortex-A53 (4-core) + M4 | GC7000Lite | 2GB | Mini EVK |
| **imx8mq-evk** | aarch64 | Cortex-A53 (4-core) + M4 | GC7000XSVX | 4GB | Quad EVK |
| **imx8qm-mek** | aarch64 | Cortex-A72 (2-core) + A53 (4-core) + M4 | GC7000XSVX | 4GB | QuadMax MEK |
| **imx8qxp-mek** | aarch64 | Cortex-A35 (4-core) + M4 | GC320 | 2GB | QuadXPlus MEK |

### i.MX 7 Series

| Machine | Architecture | CPU | GPU | RAM | Notes |
|---------|--------------|-----|-----|-------|
| **imx7dsabresd** | arm | Cortex-A7 (2-core) + M4 | GC320 | 1GB | Sabre SD |
| **imx7ulpevk** | arm | Cortex-A7 (1-core) + M4 | - | 512MB | Ultra Low Power EVK |

### i.MX 6 Series

| Machine | Architecture | CPU | GPU | RAM | Notes |
|---------|--------------|-----|-----|-----|-------|
| **imx6qpsabreauto** | arm | Cortex-A9 (1-core) + M4 | GC2000 | 1GB | Automotive |
| **imx6qpsabresd** | arm | Cortex-A9 (4-core) + M4 | GC2000 | 1GB | Sabre SD |
| **imx6slevk** | arm | Cortex-A9 (1-core) | GC2000 | 512MB | Solo Lite EVK |
| **imx6ulevk** | arm | Cortex-A9 (1-core) | GC2000 | 512MB | ULL EVK |

## 🎯 Supported Image Targets

### Standard Yocto Images

- **core-image-minimal** - Minimal bootable system (~50MB)
- **core-image-base** - Base console image with package manager (~200MB)
- **core-image-full-cmdline** - Full console image with tools (~400MB)
- **core-image-sato** - SATO desktop environment (X11-based)
- **core-image-weston** - Weston Wayland compositor

### NXP BSP Images

- **fsl-image-gui** - GUI image with X11/Weston
- **fsl-image-qt5** - Qt5 framework image
- **fsl-image-multimedia** - Multimedia codecs included
- **fsl-image-machine-test** - Hardware testing image
- **fsl-image-validation-imx** - Validation and testing

### Custom SOC Images

From `meta-soc-imx` layer:

- **imx-image-base** - Custom base with optimizations
- **imx-image-ros2** - ROS 2 Humble development stack
- **imx-image-iot** - IoT connectivity (MQTT, CoAP, etc.)
- **imx-image-grpc** - gRPC communication framework
- **imx-image-vision** - Computer vision (OpenCV, GStreamer)
- **imx-image-dds** - DDS middleware for robotics
- **imx-image-rust** - Rust development environment

## 🚀 Quick Start

### Basic Build

```bash
# i.MX 93 Freedom Development Board with base image (recommended for first build)
make build nxp-imx imx93frdm core-image-base

# i.MX 8M Plus EVK
make build nxp-imx imx8mp-lpddr4-evk core-image-base

# i.MX 8M Mini EVK
make build nxp-imx imx8mm-lpddr4-evk core-image-minimal
```

### Development Builds

```bash
# Debug build with symbols and tools
make build nxp-imx imx93frdm core-image-base BUILD_VARIANT=debug

# Qt5 GUI development image
make build nxp-imx imx8mp-lpddr4-evk fsl-image-qt5

# Computer vision development
make build nxp-imx imx8mp-lpddr4-evk imx-image-vision
```

## 📦 Build Outputs

After a successful build, find your artifacts at:

```
build/nxp-imx-imx93frdm/tmp/deploy/images/imx93frdm/
├── imx93-frdm.dtb                      # Device tree
├── Image                               # Linux kernel
├── core-image-base-imx93frdm.rootfs.ext4  # Root filesystem
├── core-image-base-imx93frdm.rootfs.wic.bz2  # Flashable image
├── modules-*.tgz                       # Kernel modules
└── u-boot-imx93frdm.bin                # U-Boot bootloader
```

### Flashing to i.MX

i.MX boards use U-Boot bootloader and can be flashed via SD card or eMMC:

```bash
# Find your SD card device
lsblk

# Flash WIC image to SD card
sudo bmaptool copy core-image-base-imx93frdm.rootfs.wic.bz2 /dev/sdX

# Alternative: Direct dd (slower)
# sudo dd if=core-image-base-imx93frdm.rootfs.wic of=/dev/sdX bs=4M status=progress

# Sync to ensure data is written
sync
```

## ⚙️ Hardware Setup

### i.MX 93 Freedom Development Board

**Minimum Requirements**:
- i.MX 93 FRDM board
- 5V power supply (USB-C)
- MicroSD card (16GB minimum, Class 10)
- USB-C cable for flashing/programming
- Serial cable (optional, for console)

**Interfaces**:
- USB 2.0 OTG port
- Gigabit Ethernet
- Wi-Fi 6 + Bluetooth 5.2
- CSI camera connector
- PCIe Gen 3 slot

### i.MX 8M Plus EVK

**Minimum Requirements**:
- i.MX 8M Plus EVK board
- 12V power supply
- MicroSD card (32GB minimum)
- HDMI cable and monitor (for GUI)

**Boot Sources**: SD card → eMMC → USB → Network

### Serial Console

Most i.MX boards use **115200 8N1** serial settings:
```bash
sudo minicom -D /dev/ttyUSB0 -b 115200
```

## 🔧 Customization

### Adding Multimedia Support

```bash
make shell nxp-imx imx8mp-lpddr4-evk fsl-image-multimedia

# Edit local.conf
vi build/nxp-imx-imx8mp-lpddr4-evk/conf/local.conf

# Add additional codecs
IMAGE_INSTALL:append = " gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly"

# Rebuild
bitbake fsl-image-multimedia
```

### GPU Acceleration

```bash
# Enable GPU features
DISTRO_FEATURES:append = " opengl"

# Add GPU libraries
IMAGE_INSTALL:append = " libgl-mesa-dev libgles2-mesa-dev"
```

### Qt5 Development

```bash
# Build Qt5 image
make build nxp-imx imx8mp-lpddr4-evk fsl-image-qt5

# Add Qt Creator
IMAGE_INSTALL:append = " qtcreator"
```

## 🐛 Troubleshooting

### Build Issues

**Error**: "EULA not accepted"
```bash
# Accept FSL EULA in local.conf
ACCEPT_FSL_EULA = "1"
```

**Error**: "No space left on device"
```bash
# Check space usage
make info

# Clean old builds
make clean-all

# Clean caches
make clean-sstate-family nxp-imx
```

### Boot Issues

**Board not booting from SD**:
1. Check boot switches (SD boot position)
2. Verify SD card is properly formatted
3. Check power supply voltage
4. Try different SD card

**No HDMI output**:
1. Ensure HDMI cable is connected before power-on
2. Check monitor compatibility
3. Add to bootargs: `video=HDMI-A-1:1920x1080@60`

**Network not working**:
1. Check Ethernet cable connection
2. Verify network configuration
3. Add packages: `IMAGE_INSTALL:append = " dhcp-client"`

### Performance Issues

**Slow graphics performance**:
```bash
# Enable GPU acceleration
DISTRO_FEATURES:append = " opengl vulkan"

# Check GPU usage
glxinfo | grep renderer
```

**Thermal throttling**:
1. Ensure proper cooling (heatsink/fan)
2. Check thermal zones: `cat /sys/class/thermal/thermal_zone*/temp`

## 📚 Additional Resources

### Official Documentation
- [NXP i.MX Documentation](https://www.nxp.com/products/processors-and-microcontrollers/arm-processors/i-mx-applications-processors:iMX_HOME)
- [meta-freescale Layer](https://github.com/Freescale/meta-freescale)
- [Yocto Project](https://www.yoctoproject.org/)

### Useful Links
- [NXP Community Forums](https://community.nxp.com/)
- [OpenEmbedded Wiki](http://www.openembedded.org/wiki/)

### Example Projects
- Camera processing with GStreamer
- Qt5 GUI applications
- Real-time audio/video streaming

## 🔄 Layer Information

This configuration uses the following layers:

- **openembedded-core** - OpenEmbedded core
- **bitbake** - Build tool
- **meta-openembedded** - Community layers
- **meta-freescale** - Official NXP BSP
- **meta-freescale-3rdparty** - Third-party boards
- **meta-freescale-distro** - NXP distribution
- **meta-soc-imx** - Custom SOC additions

See `boards/nxp-imx/nxp-imx.yml` for complete layer configuration.

## 📊 Performance Expectations

| Machine | Image | Build Time | Image Size |
|---------|-------|------------|------------|
| imx93frdm | core-image-minimal | 2-3 hours | ~50MB |
| imx93frdm | core-image-base | 3-4 hours | ~200MB |
| imx8mp-lpddr4-evk | fsl-image-qt5 | 5-6 hours | ~800MB |
| imx93frdm | imx-image-ros2 | 5-7 hours | ~1.5GB |

*First build times on modern system (8+ cores, 16GB RAM, SSD). Subsequent builds much faster with cache.*

## 🤝 Contributing

To add support for new i.MX boards:

1. Test on actual hardware
2. Update machine configurations
3. Document power requirements and interfaces
4. Submit PR with boot verification

See [CONTRIBUTING.md](../../CONTRIBUTING.md) for details.

---

**Need Help?** Open an issue or check the main [README.md](../../README.md) for general troubleshooting.