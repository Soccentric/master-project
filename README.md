# Embedded Linux Builder

A unified build system for creating custom embedded Linux distributions across multiple hardware platforms using Yocto/OpenEmbedded.

## Supported Platforms

This builder supports the following hardware platforms and boards:

### NVIDIA Jetson
- **jetson-agx-orin-devkit** - NVIDIA Jetson AGX Orin Developer Kit
- **Distro**: poky
- **Branch**: soc-rel-v2025.4
- **Layers**: meta-tegra, meta-tegra-community, meta-virtualization

### NXP i.MX
- **imx93frdm** - NXP i.MX 93 Freedom Development Board
- **Distro**: fslc-wayland
- **Branch**: soc-rel-v2025.4
- **Layers**: meta-freescale, meta-freescale-3rdparty, meta-imx-frdm

### Raspberry Pi
- **raspberrypi5** - Raspberry Pi 5
- **Distro**: poky
- **Branch**: soc-rel-v2025.4
- **Layers**: meta-raspberrypi

### Texas Instruments
- **am62xx-evm** - TI AM62x Evaluation Module
- **am64xx-evm** - TI AM64x Evaluation Module
- **Distro**: poky
- **Branch**: scarthgap
- **Layers**: meta-ti-bsp, meta-ti-extras, meta-arm

### Xilinx Zynq
- **k26-sm** - Kria K26 SOM (System-on-Module)
- **k26-smk-kr** - Kria K26 SOM Starter Kit with KR260
- **zynqmp-ev-generic** - Zynq UltraScale+ MPSoC Generic Evaluation Board
- **Distro**: petalinux
- **Branch**: soc-rel-v2025.4
- **Layers**: meta-xilinx-bsp, meta-xilinx-core, meta-kria, meta-ros

## Build Directory Structure

Each platform has its own build directory under `build/`:

```
build/
├── nvidia-jetson-jetson-agx-orin-devkit/
├── nxp-imx-imx93frdm/
├── raspberry-pi-raspberrypi5/
├── texas-instruments-am62xx-evm/
├── texas-instruments-am64xx-evm/
├── xilinx-zynq-k26-sm/
├── xilinx-zynq-k26-smk-kr/
└── xilinx-zynq-zynqmp-ev-generic/
```

Each build directory contains:
- `conf/` - Configuration files (local.conf, bblayers.conf)
- `tmp/` - Build artifacts and temporary files
- `downloads/` - Downloaded source packages
- `sstate-cache/` - Shared state cache for faster rebuilds
- `cache/` - BitBake cache files

## Quick Start

### Build an Image

Use the Makefile to build for a specific platform and machine:

```bash
# Raspberry Pi 5
make PLATFORM=raspberry-pi MACHINE=raspberrypi5 TARGET=core-image-minimal

# NVIDIA Jetson AGX Orin
make PLATFORM=nvidia-jetson MACHINE=jetson-agx-orin-devkit TARGET=core-image-minimal

# NXP i.MX 93
make PLATFORM=nxp-imx MACHINE=imx93frdm TARGET=core-image-minimal

# Texas Instruments AM62x
make PLATFORM=texas-instruments MACHINE=am62xx-evm TARGET=core-image-minimal

# Xilinx Kria K26
make PLATFORM=xilinx-zynq MACHINE=k26-sm TARGET=core-image-minimal
```

### Common Build Targets

- `core-image-minimal` - Minimal console-based image
- `core-image-base` - Console image with additional utilities
- `core-image-full-cmdline` - Full-featured console image
- `core-image-weston` - Wayland/Weston graphical image (where supported)

## Configuration Files

Board configurations are stored in `boards/`:

```
boards/
├── common.yml                    # Shared configuration
├── nvidia-jetson/
│   └── nvidia-jetson.yml
├── nxp-imx/
│   └── nxp-imx.yml
├── raspberry-pi/
│   └── raspberry-pi.yml
├── texas-instruments/
│   └── texas-instruments.yml
└── xilinx-zynq/
    └── xilinx-zynq.yml
```

Each YAML file defines:
- Repository URLs and branches
- Layer configurations
- Machine-specific settings
- Local configuration headers
- Distribution features

## Shared Resources

The builder uses shared directories to optimize disk usage and build times:

- `shared/downloads/` - Shared download cache across all builds
- `shared/sstate-cache/` - Shared state cache for build artifacts

## Docker Support

Docker containers are available for building in a consistent environment:

```bash
cd docker
make build    # Build the Docker image
make run      # Run the Docker container
```

## Scripts

Utility scripts are provided in `scripts/`:

- `preflight-check.sh` - Verify system requirements before building
- `update-repos.sh` - Update all repository sources
- `clean-cmake.sh` - Clean CMake build artifacts
- `build-history.sh` - Track build history
- `validate-target.sh` - Validate build targets
- `analyze-errors.sh` - Analyze build errors

## Features

### Platform-Specific Features

**NVIDIA Jetson:**
- Docker/container support via meta-virtualization
- CUDA acceleration
- Multimedia support

**NXP i.MX:**
- Wayland/Weston graphics
- Hardware acceleration
- FSL EULA acceptance

**Raspberry Pi:**
- Hardware-accelerated graphics
- Synaptics killswitch license

**Texas Instruments:**
- Systemd init system
- ARM toolchain support
- Extended rootfs (2GB)
- SDK tools included

**Xilinx Zynq:**
- RAUC update system
- Virtualization support
- ROS/ROS2 support (Noetic, Humble, Iron, Jazzy, Rolling)
- Vitis acceleration
- OpenAMP support
- Qt5 support

## Requirements

- Ubuntu 20.04 LTS or later (or equivalent)
- At least 100GB free disk space per platform
- 8GB RAM minimum (16GB+ recommended)
- Internet connection for downloading sources

## Default Users

Each platform creates a default user with sudo privileges:

- **NVIDIA Jetson**: `jetson` (no password)
- **NXP i.MX**: `imx` (no password)
- **Raspberry Pi**: `pi` (no password)
- **Texas Instruments**: `ti` (no password)
- **Xilinx Zynq**: `xilinx` (no password)

## License

See individual layer repositories for specific license information. The builder framework itself follows the licenses of the Yocto Project and OpenEmbedded.
