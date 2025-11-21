# Contributing to KAS Board Building System

Thank you for considering contributing to this project! This document provides guidelines and instructions for contributing.

## 🎯 Ways to Contribute

- Report bugs and issues
- Suggest new features or enhancements
- Improve documentation
- Add support for new board families
- Submit bug fixes
- Optimize build performance

## 🐛 Reporting Issues

When reporting issues, please include:

1. **System Information**:
   - OS and version (from `make info`)
   - Docker version
   - Available disk space and RAM

2. **Build Configuration**:
   - Family, machine, and target you're building
   - Build variant used
   - Contents of `.builderrc` (if used)

3. **Error Details**:
   - Complete error message
   - Relevant log excerpts
   - Output of `make doctor`

4. **Steps to Reproduce**:
   - Exact commands you ran
   - Any modifications you made

## 🔧 Development Setup

```bash
# Fork and clone the repository
git clone https://github.com/YOUR_USERNAME/builder.git
cd builder

# Run system checks
make doctor

# Make your changes...

# Test your changes
make build raspberry-pi raspberrypi5 core-image-base
```

## 📝 Code Style

### Shell Scripts

- Use `shellcheck` for linting
- Follow bash best practices
- Add comments for complex logic
- Use meaningful variable names

```bash
# Install shellcheck
sudo apt-get install shellcheck

# Check scripts
shellcheck scripts/*.sh
```

### Makefiles

- Use tabs for indentation (required by Make)
- Add comments for complex targets
- Group related targets together
- Use `.PHONY` for non-file targets

### YAML Configuration

- Use 2-space indentation
- Validate with `yamllint`
- Follow KAS schema requirements
- Document non-obvious settings

## 🧪 Testing

Before submitting a PR:

1. **Run pre-flight checks**:
   ```bash
   make doctor
   ```

2. **Test your changes**:
   ```bash
   # Test at least one successful build
   make build raspberry-pi raspberrypi5 core-image-base
   ```

3. **Check for regressions**:
   ```bash
   # Ensure existing functionality still works
   make list
   make info
   make config
   ```

4. **Validate new board families** (if applicable):
   ```bash
   ./scripts/validate-target.sh <family> <machine> <target>
   ```

## 📦 Adding a New Board Family

To add support for a new board family:

### 1. Create Board Configuration

```bash
# Create family directory
mkdir -p boards/my-family

# Create main configuration file
# boards/my-family/my-family.yml
```

Example configuration:

```yaml
header:
  version: 8
  includes:
    - boards/common.yml

machine: __MACHINE__
distro: poky
target:
  - __TARGET__

repos:
  poky:
    url: https://github.com/organization/poky
    branch: main
    path: sources/my-family/poky
    layers:
      meta:
      meta-poky:
  
  meta-my-bsp:
    url: https://github.com/organization/meta-my-bsp
    branch: main
    path: sources/my-family/meta-my-bsp
```

### 2. Create Support Files

**Machines List** (`boards/my-family/.machines`):
```
# Supported machines (one per line)
machine1
machine2
machine3
```

**Targets List** (`boards/my-family/.targets`):
```
# Supported image targets (one per line)
core-image-minimal
core-image-base
```

**Architecture Map** (`boards/my-family/.arch-map`):
```
# Machine to architecture mapping
# Format: machine:architecture
machine1:arm
machine2:aarch64
machine3:aarch64
```

### 3. Create Family Documentation

Create `boards/my-family/README.md` with:
- Hardware overview
- Supported machines
- Build instructions
- Known issues
- Hardware setup requirements

### 4. Update Main Files

Update `Makefile` help text:
```makefile
@printf "$(COLOR_MAGENTA)%-35s$(COLOR_RESET) $(COLOR_WHITE)%s$(COLOR_RESET)\n" "• my-family" "My Family boards"
```

Update bash completion in `make-completion.bash`:
```bash
_get_families() {
    echo "raspberry-pi xilinx-zynq nvidia-jetson nxp-imx my-family"
}
```

### 5. Test Thoroughly

```bash
# Validate configuration
./scripts/validate-target.sh my-family machine1 core-image-minimal

# Test build
make build my-family machine1 core-image-minimal

# Test SDK
make sdk my-family machine1 core-image-minimal

# Test shell
make shell my-family machine1 core-image-minimal
```

## 🔀 Pull Request Process

1. **Create a feature branch**:
   ```bash
   git checkout -b feature/add-my-family
   ```

2. **Make your changes**:
   - Follow code style guidelines
   - Add tests if applicable
   - Update documentation

3. **Commit with clear messages**:
   ```bash
   git add .
   git commit -m "feat: Add support for My Family boards"
   ```

   Commit message format:
   - `feat:` New feature
   - `fix:` Bug fix
   - `docs:` Documentation changes
   - `refactor:` Code refactoring
   - `test:` Add or update tests
   - `chore:` Maintenance tasks

4. **Push and create PR**:
   ```bash
   git push origin feature/add-my-family
   ```

5. **PR Description should include**:
   - What changes were made
   - Why the changes were needed
   - How to test the changes
   - Screenshots (if UI-related)
   - Related issue numbers

## 📋 PR Checklist

Before submitting, ensure:

- [ ] Code follows project style guidelines
- [ ] Documentation is updated
- [ ] Commit messages are clear and descriptive
- [ ] Changes have been tested
- [ ] No merge conflicts with main branch
- [ ] `make doctor` passes
- [ ] At least one successful build completes
- [ ] New board families include all required files
- [ ] README.md updated if adding features

## 🎨 Documentation Guidelines

- Use clear, concise language
- Include code examples
- Add troubleshooting tips
- Keep formatting consistent
- Update README.md for user-facing changes
- Update board-specific docs for family changes

## 🐞 Bug Fix Guidelines

1. **Verify the bug**:
   - Reproduce the issue
   - Identify root cause
   - Check if already reported

2. **Create fix**:
   - Minimal changes to fix the issue
   - Don't introduce new features
   - Add comments if logic is complex

3. **Test fix**:
   - Verify fix resolves the issue
   - Test edge cases
   - Ensure no regressions

## ✨ Feature Guidelines

1. **Propose first**:
   - Open an issue to discuss
   - Get feedback before implementing
   - Ensure it fits project goals

2. **Implement incrementally**:
   - Break into smaller PRs if large
   - Keep PRs focused
   - Add tests

3. **Document thoroughly**:
   - Update README.md
   - Add inline comments
   - Provide usage examples

## 🏆 Recognition

Contributors will be:
- Listed in project contributors
- Credited in release notes
- Acknowledged in documentation

## 📧 Contact

- Issues: [GitHub Issues](https://github.com/yourorg/builder/issues)
- Discussions: [GitHub Discussions](https://github.com/yourorg/builder/discussions)
- Email: [your-email@example.com]

## 📜 License

By contributing, you agree that your contributions will be licensed under the same license as the project.

---

Thank you for contributing! 🎉
