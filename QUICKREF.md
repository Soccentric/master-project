# Quick Reference Card

## 🚀 Most Common Commands

```bash
# First-time setup
make setup-completion          # Enable tab completion
make doctor                    # Check system readiness

# Building
make build raspberry-pi raspberrypi5 core-image-base
make build <family> <machine> <target> BUILD_VARIANT=debug
make sdk <family> <machine> <target>

# Information
make list                      # Show all boards
make info                      # System status
make config                    # Show configuration
make history                   # Build history
make stats                     # Build statistics

# Troubleshooting
make doctor                    # Full diagnostics
make why-failed <family-machine>  # Analyze last error
make shell <family> <machine> <target>  # Interactive debug

# Cleanup
make clean <family-machine>    # Clean one build
make clean-all                 # Clean all builds
make clean-sstate-family <family>  # Clean family cache
```

## 📋 Board Families

| Family | Example Machine | Popular Target |
|--------|----------------|----------------|
| raspberry-pi | raspberrypi5 | core-image-base |
| xilinx-zynq | zynqmp-zcu102 | petalinux-image-minimal |
| nvidia-jetson | jetson-agx-orin-devkit | core-image-base |
| nxp-imx | imx8mpevk | core-image-minimal |

## ⚙️ Configuration (.builderrc)

```bash
# Copy template
cp .builderrc.example .builderrc

# Edit
nano .builderrc

# Common settings
BUILD_VARIANT=debug            # debug|release|production
BB_NUMBER_THREADS=8            # Parallel BitBake tasks
PARALLEL_MAKE=-j 8             # Parallel make jobs
RM_WORK=1                      # Remove work files (saves space)
```

## 🏥 Health Checks

```bash
make doctor                    # Run before building
make preflight                 # Quick validation
df -h                          # Check disk space
docker ps                      # Check Docker
```

## 🐛 When Builds Fail

```bash
# 1. Analyze the error
make why-failed raspberry-pi-raspberrypi5

# 2. Check logs
ls build/raspberry-pi-raspberrypi5/tmp/log/

# 3. Check disk space
make info

# 4. Try again (uses cached work)
make build raspberry-pi raspberrypi5 core-image-base
```

## 📊 Performance Tuning

```bash
# Reduce parallelism (if system struggles)
make build ... BB_NUMBER_THREADS=4 PARALLEL_MAKE="-j 4"

# Keep work files (faster rebuilds, uses more disk)
make build ... RM_WORK=0

# Debug variant (includes dev tools)
make build ... BUILD_VARIANT=debug
```

## 🔍 Finding Things

```bash
# List all options
make list

# Find build outputs
ls build/<family-machine>/tmp/deploy/images/

# Find artifacts after collection
ls artifacts/

# View history
make history
make stats
```

## 💾 Disk Space Management

```bash
# Check usage
make info
df -h

# Clean strategies (in order of impact)
make clean <specific-build>              # ~20-50GB freed
make clean-all                           # ~100GB+ freed
make clean-sstate-family <family>        # ~50-100GB freed
make clean-downloads                     # ~50GB freed (slows next build)
make clean-shared                        # Everything (very slow next build)
```

## 🎯 Quick Troubleshooting

| Problem | Solution |
|---------|----------|
| "No space left on device" | `df -h`, `make clean-all` |
| "Docker permission denied" | `sudo usermod -aG docker $USER`, logout/login |
| "Fetch failure" | `ping github.com`, check proxy |
| "Machine not supported" | `make list`, check spelling |
| Build very slow | Reduce BB_NUMBER_THREADS, check RAM |
| Build hangs | Check with `htop`, reduce parallelism |

## 📖 Documentation Locations

- **Main docs**: `README.md`
- **Board-specific**: `boards/<family>/README.md`
- **Contributing**: `CONTRIBUTING.md`
- **This card**: `QUICKREF.md`
- **Implementation**: `IMPLEMENTATION_SUMMARY.md`

## 🆘 Getting Help

1. Check documentation: `README.md`
2. Run diagnostics: `make doctor`
3. Analyze errors: `make why-failed <build>`
4. Search build logs: `build/*/tmp/log/`
5. File an issue with system info from `make info`

---

**Keep this card handy for quick reference!**
