# AMD Xilinx Zynq Board Support

Complete support for AMD Xilinx Zynq UltraScale+ MPSoC and Versal platforms using PetaLinux distribution.

## 🖥️ Supported Machines

### Zynq UltraScale+ MPSoC (ZU+)

| Machine | Architecture | CPU | FPGA | RAM | Notes |
|---------|--------------|-----|------|-----|-------|
| **zynqmp-ev-generic** | aarch64 | Cortex-A53 (4-core) + R5 | Programmable | 4GB+ | Generic evaluation |
| **zynqmp-zcu102-rev1.0** | aarch64 | Cortex-A53 (4-core) + R5 | XCZU9EG | 4GB | ZCU102 rev 1.0 |
| **zynqmp-zcu102-rev1.1** | aarch64 | Cortex-A53 (4-core) + R5 | XCZU9EG | 4GB | ZCU102 rev 1.1 |
| **zynqmp-zcu104-revA** | aarch64 | Cortex-A53 (4-core) + R5 | XCZU7EV | 2GB | ZCU104 rev A |
| **zynqmp-zcu104-revB** | aarch64 | Cortex-A53 (4-core) + R5 | XCZU7EV | 2GB | ZCU104 rev B |
| **zynqmp-zcu106-revA** | aarch64 | Cortex-A53 (4-core) + R5 | XCZU7EV | 4GB | ZCU106 rev A |

### Zynq-7000 (Z-7000)

| Machine | Architecture | CPU | FPGA | RAM | Notes |
|---------|--------------|-----|------|-----|-------|
| **zynq-zc702** | arm | Cortex-A9 (2-core) | XC7Z020 | 1GB | ZC702 evaluation |
| **zynq-zc706** | arm | Cortex-A9 (2-core) | XC7Z045 | 1GB | ZC706 evaluation |
| **zynq-zed** | arm | Cortex-A9 (2-core) | XC7Z020 | 512MB | ZedBoard |

### Versal (VCK190)

| Machine | Architecture | CPU | FPGA | RAM | Notes |
|---------|--------------|-----|------|-----|-------|
| **versal-vck190-reva-x-ebm-01-reva** | aarch64 | Cortex-A72 (2-core) + R5 | XCVC1902 | 16GB | VCK190 evaluation |

### Kria SOMs (Adaptive Computing)

| Machine | Architecture | CPU | FPGA | RAM | Notes |
|---------|--------------|-----|------|-----|-------|
| **k26-sm** | aarch64 | Cortex-A53 (4-core) + R5 | XCK26 | 2GB | Kria K26 SOM |
| **k26-smk-kr** | aarch64 | Cortex-A53 (4-core) + R5 | XCK26 | 2GB | K26 with KR260 carrier |

## 🎯 Supported Image Targets

### PetaLinux Images

- **petalinux-image-minimal** - Minimal bootable system (~50MB)
- **petalinux-image-full** - Full-featured image with tools (~400MB)
- **petalinux-image-weston** - Weston Wayland compositor

### Custom SOC Images

From `meta-soc-xilinx` layer:

- **zynq-image-base** - Custom base with optimizations
- **zynq-image-ros2** - ROS 2 Humble/Iron/Jazzy development stack
- **zynq-image-iot** - IoT connectivity (MQTT, CoAP, etc.)
- **zynq-image-grpc** - gRPC communication framework
- **zynq-image-vision** - Computer vision (OpenCV, Vitis AI)
- **zynq-image-dds** - DDS middleware for robotics
- **zynq-image-rust** - Rust development environment

### Specialized Images

- **zynq-image-rauc** - RAUC update system enabled
- **zynq-image-virtualization** - Container support
- **zynq-image-ros** - ROS/ROS2 with acceleration
- **zynq-image-vitis** - Vitis acceleration stack

## 🚀 Quick Start

### Basic Build

```bash
# ZynqMP Generic with base image (recommended for first build)
make build xilinx-zynq zynqmp-ev-generic petalinux-image-full

# Kria K26 SOM
make build xilinx-zynq k26-sm petalinux-image-full

# ZedBoard (legacy)
make build xilinx-zynq zynq-zed petalinux-image-minimal
```

### Development Builds

```bash
# Debug build with symbols and tools
make build xilinx-zynq zynqmp-ev-generic petalinux-image-full BUILD_VARIANT=debug

# ROS 2 development image
make build xilinx-zynq k26-sm zynq-image-ros2

# Computer vision with Vitis AI
make build xilinx-zynq k26-sm zynq-image-vision
```

## 📦 Build Outputs

After a successful build, find your artifacts at:

```
build/xilinx-zynq-zynqmp-ev-generic/tmp/deploy/images/zynqmp-ev-generic/
├── system.dtb                           # Device tree
├── Image                                # Linux kernel
├── petalinux-image-full-zynqmp-ev-generic.rootfs.ext4  # Root filesystem
├── petalinux-image-full-zynqmp-ev-generic.rootfs.wic.bz2  # Flashable image
├── modules-*.tgz                        # Kernel modules
├── boot.bin                             # Boot image (FSBL + U-Boot + ATF)
└── u-boot.elf                           # U-Boot bootloader
```

### Flashing to Zynq

Zynq boards require special flashing procedures using AMD tools:

```bash
# For SD card boot (most common)
sudo bmaptool copy petalinux-image-full-zynqmp-ev-generic.rootfs.wic.bz2 /dev/sdX

# For QSPI flash (advanced)
# Use AMD Flash Programmer or U-Boot commands

# For JTAG programming (development)
# Use AMD Vitis or xsct tools
```

## ⚙️ Hardware Setup

### ZynqMP Generic Evaluation

**Minimum Requirements**:
- Zynq UltraScale+ MPSoC evaluation board
- 12V power supply
- MicroSD card (32GB minimum, Class 10)
- USB-UART cable for console
- Ethernet cable

**Boot Modes**:
- SD card (most common)
- QSPI flash
- JTAG (development)

### Kria K26 SOM

**Minimum Requirements**:
- Kria K26 SOM + carrier board (KR260 recommended)
- 12V power supply
- MicroSD card (32GB minimum)
- Cooling solution (fan/heatsink)

**Interfaces**:
- 4x USB 3.0 ports
- Gigabit Ethernet
- PCIe Gen 3
- DisplayPort
- CSI camera interfaces

### Serial Console

Zynq boards typically use **115200 8N1** serial settings:
```bash
sudo minicom -D /dev/ttyUSB0 -b 115200
```

## 🔧 Customization

### FPGA Programming

```bash
make shell xilinx-zynq zynqmp-ev-generic petalinux-image-full

# Program FPGA bitstream
vi build/xilinx-zynq-zynqmp-ev-generic/conf/local.conf

# Add bitstream to boot files
IMAGE_BOOT_FILES:append = " design_1_wrapper.bit.bin"

# Rebuild
bitbake petalinux-image-full
```

### Vitis AI Acceleration

```bash
# Enable Vitis AI
IMAGE_INSTALL:append = " packagegroup-petalinux-vitisai"

# Add DPU packages
IMAGE_INSTALL:append = " dpu-trd"
```

### ROS 2 with Acceleration

```bash
# Build ROS 2 image
make build xilinx-zynq k26-sm zynq-image-ros2

# Enable acceleration packages
IMAGE_INSTALL:append = " ros2-vitis-acceleration-examples"
```

## 🐛 Troubleshooting

### Build Issues

**Error**: "Xilinx license not accepted"
```bash
# Accept licenses in local.conf
LICENSE_FLAGS_ACCEPTED:append = " xilinx"
```

**Error**: "No space left on device"
```bash
# Check space usage
make info

# Clean old builds
make clean-all

# Clean caches
make clean-sstate-family xilinx-zynq
```

### Boot Issues

**Board not booting**:
1. Check boot mode switches (SD boot position)
2. Verify SD card formatting
3. Check power supply (adequate voltage/current)
4. Verify boot.bin integrity

**FPGA not programmed**:
1. Ensure bitstream is in correct location
2. Check device tree overlay configuration
3. Verify FPGA manager is enabled

**Network not working**:
1. Check Ethernet cable connection
2. Verify network configuration in image
3. Add packages: `IMAGE_INSTALL:append = " dhcp-client"`

### Performance Issues

**Slow boot times**:
```bash
# Optimize kernel config
# Remove unnecessary drivers
KERNEL_MODULE_AUTOLOAD:remove = "unneeded_module"
```

**Thermal throttling**:
1. Ensure proper cooling solution
2. Check thermal zones: `cat /sys/class/thermal/thermal_zone*/temp`
3. Adjust fan control if available

## 📚 Additional Resources

### Official Documentation
- [AMD Xilinx Documentation](https://docs.xilinx.com/)
- [PetaLinux Tools](https://www.xilinx.com/products/design-tools/petalinux-sdk.html)
- [meta-xilinx Layer](https://github.com/Xilinx/meta-xilinx)

### Useful Links
- [AMD Community Forums](https://support.xilinx.com/)
- [Kria Documentation](https://www.xilinx.com/products/som/kria.html)

### Example Projects
- FPGA acceleration examples
- ROS 2 robotics applications
- Computer vision with Vitis AI

## 🔄 Layer Information

This configuration uses the following layers:

- **poky** - Yocto core reference system
- **meta-openembedded** - Community layers
- **meta-xilinx** - Official AMD Xilinx BSP
- **meta-xilinx-tools** - Development tools
- **meta-petalinux** - PetaLinux distribution
- **meta-kria** - Kria SOM support
- **meta-ros** - ROS/ROS2 support
- **meta-soc-xilinx** - Custom SOC additions

See `boards/xilinx-zynq/xilinx-zynq.yml` for complete layer configuration.

## 📊 Performance Expectations

| Machine | Image | Build Time | Image Size |
|---------|-------|------------|------------|
| zynqmp-ev-generic | petalinux-image-minimal | 3-4 hours | ~60MB |
| zynqmp-ev-generic | petalinux-image-full | 4-5 hours | ~400MB |
| k26-sm | zynq-image-ros2 | 6-8 hours | ~2GB |
| zynqmp-ev-generic | zynq-image-vision | 5-7 hours | ~1.2GB |

*First build times on modern system (8+ cores, 32GB RAM, SSD). Subsequent builds much faster with cache.*

## 🤝 Contributing

To add support for new Zynq/Versal boards:

1. Test on actual hardware
2. Update machine configurations
3. Document FPGA requirements
4. Submit PR with boot verification

See [CONTRIBUTING.md](../../CONTRIBUTING.md) for details.

---

**Need Help?** Open an issue or check the main [README.md](../../README.md) for general troubleshooting.