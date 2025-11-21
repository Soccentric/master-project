# Raspberry Pi Board Family

Complete support for Raspberry Pi boards using the official meta-raspberrypi BSP layer.

## 🖥️ Supported Machines

### Latest Generation (Recommended)

| Machine | Architecture | CPU | RAM | Notes |
|---------|--------------|-----|-----|-------|
| **raspberrypi5** | aarch64 | Cortex-A76 (4-core, 2.4GHz) | 4/8GB | Latest, best performance |
| **raspberrypi4-64** | aarch64 | Cortex-A72 (4-core, 1.5GHz) | 2/4/8GB | Popular choice |
| **raspberrypi3-64** | aarch64 | Cortex-A53 (4-core, 1.2GHz) | 1GB | Good for development |

### Legacy / 32-bit

| Machine | Architecture | CPU | RAM | Notes |
|---------|--------------|-----|-----|-------|
| raspberrypi4 | arm | Cortex-A72 | 2/4/8GB | 32-bit variant |
| raspberrypi3 | arm | Cortex-A53 | 1GB | 32-bit variant |
| raspberrypi2 | arm | Cortex-A7 | 1GB | Older generation |
| raspberrypi0-2w-64 | aarch64 | Cortex-A53 | 512MB | Compact, 64-bit |

### Compute Modules

| Machine | Architecture | Notes |
|---------|--------------|-------|
| raspberrypi-cm3 | arm | Industrial compute module |
| raspberrypi-cm | arm | Original compute module |

See `boards/raspberry-pi/.machines` for complete list.

## 🎯 Supported Image Targets

### Standard Yocto Images

- **core-image-minimal** - Minimal bootable system (~50MB)
- **core-image-base** - Base console image with package manager (~200MB)
- **core-image-full-cmdline** - Full console image with tools (~400MB)
- **core-image-sato** - SATO desktop environment (X11-based)
- **core-image-weston** - Weston Wayland compositor

### Raspberry Pi BSP Images

- **rpi-test-image** - Hardware testing image
- **rpi-hwup-image** - Hardware bringup image

### Custom SOC Images

From `meta-soc-rpi` layer:

- **rpi-image-base** - Custom base with optimizations
- **rpi-image-ros2** - ROS 2 Humble development stack
- **rpi-image-iot** - IoT connectivity (MQTT, CoAP, etc.)
- **rpi-image-grpc** - gRPC communication framework
- **rpi-image-vision** - Computer vision (OpenCV, TensorFlow)
- **rpi-image-dds** - DDS middleware for robotics
- **rpi-image-rust** - Rust development environment

## 🚀 Quick Start

### Basic Build

```bash
# Raspberry Pi 5 with base image (recommended for first build)
make build raspberry-pi raspberrypi5 core-image-base

# Raspberry Pi 4 64-bit
make build raspberry-pi raspberrypi4-64 core-image-base

# Raspberry Pi 3 64-bit
make build raspberry-pi raspberrypi3-64 core-image-minimal
```

### Development Builds

```bash
# Debug build with symbols and tools
make build raspberry-pi raspberrypi5 core-image-base BUILD_VARIANT=debug

# ROS 2 development image
make build raspberry-pi raspberrypi5 rpi-image-ros2

# Computer vision development
make build raspberry-pi raspberrypi5 rpi-image-vision
```

## 📦 Build Outputs

After a successful build, find your artifacts at:

```
build/raspberry-pi-raspberrypi5/tmp/deploy/images/raspberrypi5/
├── bcm2712-rpi-5-b.dtb                    # Device tree
├── Image                                   # Linux kernel
├── core-image-base-raspberrypi5.rootfs.ext4  # Root filesystem
├── core-image-base-raspberrypi5.rootfs.wic.bz2  # Flashable image
└── modules-*.tgz                          # Kernel modules
```

### Flashing to SD Card

```bash
# Find your SD card device (e.g., /dev/sdb)
lsblk

# Decompress and flash (CAUTION: DOUBLE-CHECK DEVICE!)
bzcat build/raspberry-pi-raspberrypi5/tmp/deploy/images/raspberrypi5/core-image-base-raspberrypi5.rootfs.wic.bz2 | sudo dd of=/dev/sdX bs=4M status=progress

# Sync to ensure data is written
sync
```

## ⚙️ Hardware Setup

### Raspberry Pi 5

**Minimum Requirements**:
- Raspberry Pi 5 board (4GB or 8GB recommended)
- USB-C power supply (27W / 5V 5A official adapter recommended)
- MicroSD card (16GB minimum, Class 10 or better)
- USB keyboard (for console)
- HDMI cable and monitor (optional, for display)

**Boot Order**: SD card → USB → Network

**GPIO**: 40-pin header compatible with previous models

### Raspberry Pi 4

**Minimum Requirements**:
- Raspberry Pi 4 board (2GB+ recommended)
- USB-C power supply (15W / 5V 3A minimum)
- MicroSD card (16GB minimum)

**Boot Order**: Configurable via EEPROM

### Networking

All models support:
- Ethernet (Gigabit on Pi 4/5)
- Wi-Fi (802.11ac on Pi 4/5)
- Bluetooth 5.0 (Pi 4/5)

## 🔧 Customization

### Adding Packages

Create a custom layer or modify local.conf:

```bash
make shell raspberry-pi raspberrypi5 core-image-base

# Inside shell, edit build conf
vi build/raspberry-pi-raspberrypi5/conf/local.conf

# Add packages
IMAGE_INSTALL:append = " package1 package2"

# Rebuild
bitbake core-image-base
```

### Kernel Configuration

```bash
make shell raspberry-pi raspberrypi5 core-image-base

# Configure kernel
bitbake -c menuconfig virtual/kernel

# Rebuild kernel
bitbake -c compile -f virtual/kernel
bitbake virtual/kernel
```

### Device Tree Overlays

Edit `config.txt` on boot partition after flashing:

```
# Enable I2C
dtparam=i2c_arm=on

# Enable SPI
dtparam=spi=on

# Custom overlay
dtoverlay=my-overlay
```

## 🐛 Troubleshooting

### Build Issues

**Error**: "No space left on device"
```bash
# Check space
make info

# Clean old builds
make clean-all

# Clean caches (last resort)
make clean-sstate-family raspberry-pi
```

**Error**: "Fetch failure for git://github.com/..."
```bash
# Check connectivity
ping github.com

# Use HTTPS instead of git protocol (edit .yml)
# Change: git://github.com/... → https://github.com/...
```

### Boot Issues

**SD card not booting**:
1. Check power supply (use official adapter)
2. Try re-flashing the image
3. Verify SD card is not corrupted
4. Check boot partition has required files

**No HDMI output**:
1. Add to `config.txt`: `hdmi_safe=1`
2. Force HDMI hotplug: `hdmi_force_hotplug=1`
3. Try different HDMI port (Pi 4/5 have 2 ports)

**Network not working**:
1. Check cable connection
2. Verify network configuration in image
3. Add packages: `IMAGE_INSTALL:append = " dhcp-client"`

### Performance Issues

**Slow build times**:
```bash
# Reduce parallelism if running out of RAM
make build raspberry-pi raspberrypi5 core-image-base \
  BB_NUMBER_THREADS=4 \
  PARALLEL_MAKE="-j 4"
```

**Image too large**:
```bash
# Use minimal image
make build raspberry-pi raspberrypi5 core-image-minimal

# Remove unnecessary packages
IMAGE_INSTALL:remove = " package-to-remove"
```

## 📚 Additional Resources

### Official Documentation
- [Raspberry Pi Documentation](https://www.raspberrypi.com/documentation/)
- [meta-raspberrypi Layer](https://github.com/agherzan/meta-raspberrypi)
- [Yocto Project](https://www.yoctoproject.org/)

### Useful Links
- [Raspberry Pi Forums](https://forums.raspberrypi.com/)
- [Yocto Mailing Lists](https://www.yoctoproject.org/community/mailing-lists/)
- [OpenEmbedded Wiki](http://www.openembedded.org/wiki/)

### Example Projects
- GPIO control examples in `meta-soc-rpi`
- Camera integration examples
- Display configuration examples

## 🔄 Layer Information

This configuration uses the following layers:

- **poky** - Yocto core reference system
- **meta-raspberrypi** - Official Raspberry Pi BSP
- **meta-openembedded** - Community layers (networking, python, etc.)
- **meta-qt5** - Qt5 framework
- **meta-soc-rpi** - Custom SOC additions

See `boards/raspberry-pi/raspberry-pi.yml` for complete layer configuration.

## 📊 Performance Expectations

| Machine | Image | Build Time | Image Size |
|---------|-------|------------|------------|
| raspberrypi5 | core-image-minimal | 2-3 hours | ~50MB |
| raspberrypi5 | core-image-base | 3-4 hours | ~200MB |
| raspberrypi4-64 | core-image-base | 3-4 hours | ~200MB |
| raspberrypi5 | rpi-image-ros2 | 5-7 hours | ~1.5GB |

*First build times on modern system (8+ cores, 16GB RAM, SSD). Subsequent builds much faster with cache.*

## 🤝 Contributing

To add support for new machines or improve existing support:

1. Test your changes thoroughly
2. Update machine lists in `.machines`, `.targets`, `.arch-map`
3. Document hardware requirements
4. Submit PR with example build output

See [CONTRIBUTING.md](../../CONTRIBUTING.md) for details.

---

**Need Help?** Open an issue or check the main [README.md](../../README.md) for general troubleshooting.
