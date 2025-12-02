# NVIDIA Jetson Board Support

Complete support for NVIDIA Jetson embedded platforms using the official meta-tegra BSP layer.

## 🖥️ Supported Machines

### Jetson Orin Series (Latest Generation)

| Machine | Architecture | GPU | RAM | Notes |
|---------|--------------|-----|-----|-------|
| **jetson-agx-orin-devkit** | aarch64 | Ampere (2048 CUDA cores) | 32GB | Flagship developer kit |
| **jetson-orin-nano-devkit** | aarch64 | Ampere (1024 CUDA cores) | 8GB | Nano form factor |
| **jetson-orin-nx-devkit** | aarch64 | Ampere (1024 CUDA cores) | 8GB | NX module |

### Jetson Xavier Series

| Machine | Architecture | GPU | RAM | Notes |
|---------|--------------|-----|-----|-------|
| **jetson-xavier-nx-devkit** | aarch64 | Volta (384 CUDA cores) | 8GB | NX developer kit |
| **jetson-xavier-nx-devkit-emmc** | aarch64 | Volta (384 CUDA cores) | 8GB | eMMC variant |
| **jetson-agx-xavier-devkit** | aarch64 | Volta (512 CUDA cores) | 32GB | AGX Xavier |

### Jetson Nano Series

| Machine | Architecture | GPU | RAM | Notes |
|---------|--------------|-----|-----|-------|
| **jetson-nano-devkit** | aarch64 | Maxwell (128 CUDA cores) | 4GB | Original Nano |
| **jetson-nano-devkit-nvidia** | aarch64 | Maxwell (128 CUDA cores) | 4GB | Official variant |
| **jetson-nano-2gb-devkit** | aarch64 | Maxwell (128 CUDA cores) | 2GB | Low-cost variant |

## 🎯 Supported Image Targets

### Standard Yocto Images

- **core-image-minimal** - Minimal bootable system (~50MB)
- **core-image-base** - Base console image with package manager (~200MB)
- **core-image-full-cmdline** - Full console image with tools (~400MB)
- **core-image-sato** - SATO desktop environment (X11-based)
- **core-image-weston** - Weston Wayland compositor

### NVIDIA BSP Images

- **tegra-minimal-initramfs** - Minimal initramfs for Jetson
- **tegra-recovery-image** - Recovery image for flashing
- **tegra-demo-distro** - NVIDIA demo distribution

### Custom SOC Images

From `meta-soc-jetson` layer:

- **jetson-image-base** - Custom base with optimizations
- **jetson-image-ros2** - ROS 2 Humble development stack
- **jetson-image-iot** - IoT connectivity (MQTT, CoAP, etc.)
- **jetson-image-grpc** - gRPC communication framework
- **jetson-image-vision** - Computer vision (OpenCV, TensorFlow, CUDA)
- **jetson-image-dds** - DDS middleware for robotics
- **jetson-image-rust** - Rust development environment

## 🚀 Quick Start

### Basic Build

```bash
# Jetson AGX Orin with base image (recommended for first build)
make build nvidia-jetson jetson-agx-orin-devkit core-image-base

# Jetson Orin Nano
make build nvidia-jetson jetson-orin-nano-devkit core-image-base

# Jetson Xavier NX
make build nvidia-jetson jetson-xavier-nx-devkit core-image-minimal
```

### Development Builds

```bash
# Debug build with symbols and tools
make build nvidia-jetson jetson-agx-orin-devkit core-image-base BUILD_VARIANT=debug

# ROS 2 development image
make build nvidia-jetson jetson-agx-orin-devkit jetson-image-ros2

# Computer vision development with CUDA
make build nvidia-jetson jetson-agx-orin-devkit jetson-image-vision
```

## 📦 Build Outputs

After a successful build, find your artifacts at:

```
build/nvidia-jetson-jetson-agx-orin-devkit/tmp/deploy/images/jetson-agx-orin-devkit/
├── tegra234-p3701-0000-p3737-0000.dtb    # Device tree
├── Image                                 # Linux kernel
├── core-image-base-jetson-agx-orin-devkit.rootfs.ext4  # Root filesystem
├── core-image-base-jetson-agx-orin-devkit.rootfs.wic.bz2  # Flashable image
├── modules-*.tgz                        # Kernel modules
└── tegraflash/                          # NVIDIA flashing tools
```

### Flashing to Jetson

NVIDIA Jetson devices require special flashing tools. Use the NVIDIA SDK Manager or flash manually:

```bash
# Enter build environment
make shell nvidia-jetson jetson-agx-orin-devkit core-image-base

# Flash using NVIDIA tools (from within container)
cd tmp/deploy/images/jetson-agx-orin-devkit/
sudo ./tegraflash.py --chip 0x23 --applet nvtboot_recovery.bin \
  --cmd "flash; reboot" --cfg flash.xml --skipuid

# Alternative: Use SDK Manager for GUI flashing
```

## ⚙️ Hardware Setup

### Jetson AGX Orin Developer Kit

**Minimum Requirements**:
- Jetson AGX Orin Developer Kit
- 19V power supply (120W recommended for full performance)
- NVMe SSD (optional, for extended storage)
- USB keyboard and mouse
- HDMI cable and monitor

**Interfaces**:
- 4x USB 3.2 Gen 2 ports
- Gigabit Ethernet
- HDMI 2.1 output
- CSI camera connectors
- PCIe Gen 4 slots

### Jetson Orin Nano

**Minimum Requirements**:
- Jetson Orin Nano Developer Kit
- 19V power supply (65W recommended)
- MicroSD card (32GB minimum, Class 10)
- USB-C to USB-A cable for flashing

### Jetson Xavier NX

**Minimum Requirements**:
- Jetson Xavier NX Developer Kit
- 19V power supply (65W recommended)
- MicroSD card (32GB minimum)

## 🔧 Customization

### Adding CUDA Packages

```bash
make shell nvidia-jetson jetson-agx-orin-devkit core-image-base

# Edit local.conf
vi build/nvidia-jetson-jetson-agx-orin-devkit/conf/local.conf

# Add CUDA support
IMAGE_INSTALL:append = " cuda-toolkit cuda-samples"

# Rebuild
bitbake core-image-base
```

### GPU Acceleration

```bash
# Enable GPU features
DISTRO_FEATURES:append = " opengl vulkan"

# Add GPU libraries
IMAGE_INSTALL:append = " mesa-dev libglu-dev"
```

### Container Support

Jetson supports Docker containers with GPU acceleration:

```bash
# Enable virtualization
DISTRO_FEATURES:append = " virtualization"

# Add Docker
IMAGE_INSTALL:append = " docker docker-compose"
```

## 🐛 Troubleshooting

### Build Issues

**Error**: "CUDA not found"
```bash
# Ensure CUDA toolkit is installed on host
# Add to local.conf:
CUDA_TOOLKIT_PATH = "/usr/local/cuda"
```

**Error**: "Out of memory during build"
```bash
# Reduce parallelism
BB_NUMBER_THREADS = "4"
PARALLEL_MAKE = "-j 4"
```

### Flash Issues

**Device not detected**:
1. Ensure device is in recovery mode (hold RECOVERY button while powering on)
2. Check USB connection
3. Try different USB port/cable

**Flash fails**:
1. Verify power supply meets requirements
2. Check for sufficient host disk space
3. Ensure no other processes are using the device

### Performance Issues

**Slow GPU performance**:
```bash
# Check power mode
sudo nvpmodel -m 0  # Max performance mode

# Check jetson_clocks
sudo jetson_clocks
```

**Thermal throttling**:
1. Ensure proper cooling (fan/heatsink)
2. Check thermal zones: `cat /sys/devices/virtual/thermal/thermal_zone*/temp`

## 📚 Additional Resources

### Official Documentation
- [NVIDIA Jetson Documentation](https://docs.nvidia.com/jetson/)
- [meta-tegra Layer](https://github.com/OE4T/meta-tegra)
- [CUDA Toolkit](https://developer.nvidia.com/cuda-toolkit)

### Useful Links
- [NVIDIA Developer Forums](https://forums.developer.nvidia.com/c/agx-autonomous-machines/jetson-embedded-systems/)
- [Jetson Community Projects](https://github.com/dusty-nv/jetson-containers)

### Example Projects
- AI/ML inference examples in `meta-soc-jetson`
- Camera streaming with GStreamer
- ROS 2 navigation stack

## 🔄 Layer Information

This configuration uses the following layers:

- **poky** - Yocto core reference system
- **meta-tegra** - Official NVIDIA Jetson BSP
- **meta-tegra-community** - Community additions
- **meta-virtualization** - Container support
- **meta-openembedded** - Community layers
- **meta-soc-jetson** - Custom SOC additions

See `boards/nvidia-jetson/nvidia-jetson.yml` for complete layer configuration.

## 📊 Performance Expectations

| Machine | Image | Build Time | Image Size |
|---------|-------|------------|------------|
| jetson-agx-orin-devkit | core-image-minimal | 3-4 hours | ~60MB |
| jetson-agx-orin-devkit | core-image-base | 4-5 hours | ~250MB |
| jetson-orin-nano-devkit | core-image-base | 3-4 hours | ~200MB |
| jetson-agx-orin-devkit | jetson-image-ros2 | 6-8 hours | ~2GB |

*First build times on modern system (8+ cores, 32GB RAM, SSD). Subsequent builds much faster with cache.*

## 🤝 Contributing

To add support for new Jetson modules:

1. Test on actual hardware
2. Update machine configurations
3. Document power requirements
4. Submit PR with flash verification

See [CONTRIBUTING.md](../../CONTRIBUTING.md) for details.

---

**Need Help?** Open an issue or check the main [README.md](../../README.md) for general troubleshooting.