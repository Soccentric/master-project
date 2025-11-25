# Texas Instruments Board Support

This directory contains board support configuration for Texas Instruments embedded processors.

## Supported Processor Families

### AM62x Series (Low Power)
- **am62xx-evm**: AM62x Evaluation Module (general purpose)
- **am62xx-lp-evm**: AM62x Low Power Evaluation Module
- **am62pxx-evm**: AM62P with GPU acceleration (SK-AM62P-LP)
- **am62axx-evm**: AM62A with vision processing

### AM64x Series (Industrial)
- **am64xx-evm**: AM64x Evaluation Module
- **am64xx-hsevm**: AM64x High Security Evaluation Module

### AM65x Series (High Performance Industrial)
- **am65xx-evm**: AM65x Evaluation Module
- **am65xx-hsevm**: AM65x High Security Evaluation Module

### Legacy Series
- **beaglebone**: BeagleBone / BeagleBone Black (AM335x)
- **beaglebone-yocto**: BeagleBone with Yocto optimizations
- **am437x-evm**: AM437x Evaluation Module
- **am57xx-evm**: AM57xx Evaluation Module

### Jacinto Series (Automotive/ADAS)
- **j721e-evm**: TDA4VM (J721E) for ADAS
- **j7200-evm**: J7200 for gateway applications
- **j721s2-evm**: J721S2 automotive processor
- **j784s4-evm**: J784S4 high-performance ADAS

## Building Images

### Basic Build Command
```bash
make build texas-instruments am62pxx-evm tisdk-default-image
```

### Available Images

#### Standard Yocto Images
- `core-image-minimal`: Minimal console-only system
- `core-image-base`: Basic image with package management
- `core-image-full-cmdline`: Full command-line tools
- `core-image-sato`: SATO desktop environment
- `core-image-weston`: Wayland/Weston compositor

#### TI SDK Images (Recommended)
- `tisdk-default-image`: Full-featured TI SDK image with graphics and multimedia
- `tisdk-base-image`: Base TI SDK without graphics
- `tisdk-thinlinux-image`: Minimal TI Linux distribution
- `tisdk-tiny-image`: Ultra-minimal TI image

#### Specialized Images
- `tisdk-docker-rootfs-image`: Container support enabled
- `tisdk-machine-learning-image`: ML/AI frameworks included
- `tisdk-automotive-image`: Automotive-specific features

## Examples

### AM62P Starter Kit (SK-AM62P-LP)
```bash
# Standard build
make build texas-instruments am62pxx-evm tisdk-default-image

# Debug variant
make build texas-instruments am62pxx-evm tisdk-default-image BUILD_VARIANT=debug

# Minimal image
make build texas-instruments am62pxx-evm core-image-minimal
```

### BeagleBone Black
```bash
make build texas-instruments beaglebone tisdk-default-image
```

### Jacinto J721E (ADAS)
```bash
make build texas-instruments j721e-evm tisdk-automotive-image
```

## Configuration

The Texas Instruments configuration includes:

- **Init System**: systemd (recommended by TI)
- **Extra Root Filesystem Space**: 2GB
- **Default User**: `ti` (password-less login)
- **Meta Layers**: meta-ti-bsp, meta-ti-extras, meta-arm

## Hardware Requirements

- **Minimum Disk Space**: 100GB free
- **Recommended RAM**: 16GB+
- **Build Time**: 1-3 hours (first build)

## Serial Console

Most TI boards use **115200 8N1** serial settings:
```bash
sudo minicom -D /dev/ttyUSB0 -b 115200
```

## Flashing to SD Card

After build completes, images are located in:
```
build/texas-instruments-<machine>/tmp/deploy/images/<machine>/
```

Flash to SD card:
```bash
cd build/texas-instruments-<machine>/tmp/deploy/images/<machine>/
sudo bmaptool copy tisdk-default-image-<machine>.wic.xz /dev/sdX
```

## Resources

- [TI Processor SDK Documentation](https://software-dl.ti.com/processor-sdk-linux/esd/docs/)
- [meta-ti Layer](https://git.yoctoproject.org/meta-ti/)
- [Yocto Project](https://www.yoctoproject.org/)
- [BeagleBoard Community](https://beagleboard.org/)

## Support

For TI-specific questions:
- [TI E2E Forums](https://e2e.ti.com/)
- [meta-ti Mailing List](https://lists.yoctoproject.org/g/meta-ti)
