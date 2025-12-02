# Texas Instruments Sitara Board Support

Complete support for Texas Instruments Sitara embedded processors using the official meta-ti BSP layer.

## 🖥️ Supported Machines

### AM335x Series (Sitara AM335x)

| Machine | Architecture | CPU | GPU | RAM | Notes |
|---------|--------------|-----|-----|-----|-------|
| **beaglebone** | arm | Cortex-A8 (1-core, 1GHz) | SGX530 | 512MB | Original BeagleBone |
| **beaglebone-yocto** | arm | Cortex-A8 (1-core, 1GHz) | SGX530 | 512MB | Yocto optimized |
| **am335x-evm** | arm | Cortex-A8 (1-core, 1GHz) | SGX530 | 512MB | AM335x Evaluation Module |

### AM437x Series (Sitara AM437x)

| Machine | Architecture | CPU | GPU | RAM | Notes |
|---------|--------------|-----|-----|-----|-------|
| **am437x-evm** | arm | Cortex-A9 (1-core, 1GHz) | SGX530 | 1GB | AM437x Evaluation Module |
| **am437x-hsevm** | arm | Cortex-A9 (1-core, 1GHz) | SGX530 | 1GB | High Security EVM |

### AM57xx Series (Sitara AM57xx)

| Machine | Architecture | CPU | GPU | RAM | Notes |
|---------|--------------|-----|-----|-----|-------|
| **am57xx-evm** | arm | Cortex-A15 (2-core) + DSP | SGX544 | 2GB | AM57xx Evaluation Module |
| **am57xx-hsevm** | arm | Cortex-A15 (2-core) + DSP | SGX544 | 2GB | High Security EVM |

## 🎯 Supported Image Targets

### Standard Yocto Images

- **core-image-minimal** - Minimal bootable system (~50MB)
- **core-image-base** - Base console image with package manager (~200MB)
- **core-image-full-cmdline** - Full console image with tools (~400MB)
- **core-image-sato** - SATO desktop environment (X11-based)
- **core-image-weston** - Weston Wayland compositor

### TI SDK Images

- **tisdk-default-image** - Full-featured TI SDK image with graphics and multimedia
- **tisdk-base-image** - Base TI SDK without graphics
- **tisdk-thinlinux-image** - Minimal TI Linux distribution
- **tisdk-tiny-image** - Ultra-minimal TI image

### Custom SOC Images

From `meta-soc-ti` layer:

- **ti-image-base** - Custom base with optimizations
- **ti-image-ros2** - ROS 2 Humble development stack
- **ti-image-iot** - IoT connectivity (MQTT, CoAP, etc.)
- **ti-image-grpc** - gRPC communication framework
- **ti-image-vision** - Computer vision (OpenCV, GStreamer)
- **ti-image-dds** - DDS middleware for robotics
- **ti-image-rust** - Rust development environment

## 🚀 Quick Start

### Basic Build

```bash
# BeagleBone with base image (recommended for first build)
make build texas-instruments beaglebone core-image-base

# AM335x EVM
make build texas-instruments am335x-evm core-image-base

# AM437x EVM
make build texas-instruments am437x-evm core-image-minimal
```

### Development Builds

```bash
# Debug build with symbols and tools
make build texas-instruments beaglebone core-image-base BUILD_VARIANT=debug

# TI SDK full image
make build texas-instruments am335x-evm tisdk-default-image

# Computer vision development
make build texas-instruments am335x-evm ti-image-vision
```

## 📦 Build Outputs

After a successful build, find your artifacts at:

```
build/texas-instruments-beaglebone/tmp/deploy/images/beaglebone/
├── am335x-bone.dtb                     # Device tree
├── zImage                              # Linux kernel
├── core-image-base-beaglebone.rootfs.ext4  # Root filesystem
├── core-image-base-beaglebone.rootfs.wic.bz2  # Flashable image
├── modules-*.tgz                       # Kernel modules
└── MLO/u-boot.img                      # Bootloader
```

### Flashing to Sitara

Sitara boards can be flashed via SD card or eMMC:

```bash
# Find your SD card device
lsblk

# Flash WIC image to SD card
sudo bmaptool copy core-image-base-beaglebone.rootfs.wic.bz2 /dev/sdX

# Alternative: Direct dd (slower)
# sudo dd if=core-image-base-beaglebone.rootfs.wic of=/dev/sdX bs=4M status=progress

# Sync to ensure data is written
sync
```

## ⚙️ Hardware Setup

### BeagleBone

**Minimum Requirements**:
- BeagleBone or BeagleBone Black board
- 5V power supply (USB or barrel jack)
- MicroSD card (4GB minimum, Class 10)
- USB cable for power/programming
- Ethernet cable (optional)

**Interfaces**:
- USB 2.0 host port
- 10/100 Ethernet
- HDMI output
- 2x 46-pin expansion headers
- JTAG connector

### AM335x EVM

**Minimum Requirements**:
- AM335x Evaluation Module
- 5V power supply
- MicroSD card (8GB minimum)
- Serial cable for console

**Boot Sources**: SD card → NAND → USB → UART

### Serial Console

Sitara boards use **115200 8N1** serial settings:
```bash
sudo minicom -D /dev/ttyUSB0 -b 115200
```

## 🔧 Customization

### Adding DSP Support

```bash
make shell texas-instruments am57xx-evm tisdk-default-image

# Edit local.conf
vi build/texas-instruments-am57xx-evm/conf/local.conf

# Add DSP packages
IMAGE_INSTALL:append = " ti-cgt-arm ti-cgt-c6000"

# Rebuild
bitbake tisdk-default-image
```

### Graphics Acceleration

```bash
# Enable SGX GPU
DISTRO_FEATURES:append = " opengl"

# Add graphics libraries
IMAGE_INSTALL:append = " ti-sgx-ddk-km ti-sgx-ddk-um"
```

### PRU Programming

```bash
# Add PRU support
IMAGE_INSTALL:append = " ti-pru-sw-examples"

# Enable remoteproc
KERNEL_MODULE_AUTOLOAD:append = " remoteproc"
```

## 🐛 Troubleshooting

### Build Issues

**Error**: "No space left on device"
```bash
# Check space usage
make info

# Clean old builds
make clean-all

# Clean caches
make clean-sstate-family texas-instruments
```

**Error**: "SGX kernel module failed"
```bash
# Check kernel config
# Ensure CONFIG_DRM_OMAP is enabled
bitbake -c menuconfig virtual/kernel
```

### Boot Issues

**Board not booting from SD**:
1. Check boot switches (if available)
2. Verify SD card is properly formatted
3. Check power supply voltage
4. Try different SD card

**No HDMI output**:
1. Ensure HDMI cable is connected before power-on
2. Check monitor compatibility
3. Add to bootargs: `video=HDMI-A-1:1024x768@60`

**Network not working**:
1. Check Ethernet cable connection
2. Verify network configuration
3. Add packages: `IMAGE_INSTALL:append = " dhcp-client"`

### Performance Issues

**Slow graphics performance**:
```bash
# Enable GPU acceleration
DISTRO_FEATURES:append = " opengl"

# Check SGX status
lsmod | grep pvrsrvkm
```

**Thermal throttling**:
1. Ensure proper cooling (heatsink)
2. Check thermal zones: `cat /sys/class/thermal/thermal_zone*/temp`

## 📚 Additional Resources

### Official Documentation
- [TI Sitara Documentation](https://www.ti.com/processors/sitara-arm-cortex-a-processors/overview.html)
- [meta-ti Layer](https://git.yoctoproject.org/meta-ti/)
- [BeagleBoard Community](https://beagleboard.org/)

### Useful Links
- [TI E2E Forums](https://e2e.ti.com/)
- [BeagleBoard Forums](https://forum.beagleboard.org/)

### Example Projects
- GPIO control and expansion
- PRU real-time programming
- DSP acceleration examples

## 🔄 Layer Information

This configuration uses the following layers:

- **poky** - Yocto core reference system
- **meta-ti** - Official TI BSP
- **meta-arm** - ARM toolchain support
- **meta-openembedded** - Community layers
- **meta-soc-ti** - Custom SOC additions

See `boards/texas-instruments/texas-instruments.yml` for complete layer configuration.

## 📊 Performance Expectations

| Machine | Image | Build Time | Image Size |
|---------|-------|------------|------------|
| beaglebone | core-image-minimal | 1-2 hours | ~40MB |
| beaglebone | core-image-base | 2-3 hours | ~150MB |
| am335x-evm | tisdk-default-image | 3-4 hours | ~600MB |
| beaglebone | ti-image-ros2 | 4-5 hours | ~1GB |

*First build times on modern system (8+ cores, 16GB RAM, SSD). Subsequent builds much faster with cache.*

## 🤝 Contributing

To add support for new Sitara boards:

1. Test on actual hardware
2. Update machine configurations
3. Document expansion capabilities
4. Submit PR with boot verification

See [CONTRIBUTING.md](../../CONTRIBUTING.md) for details.

---

**Need Help?** Open an issue or check the main [README.md](../../README.md) for general troubleshooting.