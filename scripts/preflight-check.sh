#!/bin/bash
# ==============================================================================
# Pre-flight validation script
# Comprehensive checks before starting a build
# ==============================================================================

set -e

# Color codes
COLOR_RESET="\033[0m"
COLOR_GREEN="\033[32m"
COLOR_YELLOW="\033[33m"
COLOR_RED="\033[31m"
COLOR_BLUE="\033[34m"
COLOR_CYAN="\033[36m"

# Validation results
ERRORS=0
WARNINGS=0

# Required minimum versions
MIN_DOCKER_VERSION="20.10"
MIN_DISK_SPACE_GB=100
MIN_RAM_GB=6
RECOMMENDED_RAM_GB=12

# Helper functions
print_header() {
    echo -e "${COLOR_BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_RESET}"
    echo -e "${COLOR_BLUE}  $1${COLOR_RESET}"
    echo -e "${COLOR_BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_RESET}"
}

print_check() {
    echo -e "${COLOR_CYAN}Checking:${COLOR_RESET} $1"
}

print_pass() {
    echo -e "  ${COLOR_GREEN}✓${COLOR_RESET} $1"
}

print_warn() {
    echo -e "  ${COLOR_YELLOW}⚠${COLOR_RESET} $1"
    ((WARNINGS++))
}

print_error() {
    echo -e "  ${COLOR_RED}✗${COLOR_RESET} $1"
    ((ERRORS++))
}

# Version comparison helper
version_ge() {
    printf '%s\n%s\n' "$2" "$1" | sort -V -C
}

# ==============================================================================
# System Requirements
# ==============================================================================
check_system() {
    print_header "System Requirements"
    
    # Check OS
    print_check "Operating System"
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        print_pass "OS: $PRETTY_NAME"
    else
        print_warn "Could not determine OS version"
    fi
    
    # Check CPU cores
    print_check "CPU Cores"
    cpu_cores=$(nproc)
    if [ "$cpu_cores" -ge 4 ]; then
        print_pass "$cpu_cores cores available"
    elif [ "$cpu_cores" -ge 2 ]; then
        print_warn "$cpu_cores cores (4+ recommended for faster builds)"
    else
        print_error "$cpu_cores cores (minimum 2 required)"
    fi
    
    # Check RAM
    print_check "Memory (RAM)"
    total_ram_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    total_ram_gb=$((total_ram_kb / 1024 / 1024))
    
    if [ "$total_ram_gb" -ge "$RECOMMENDED_RAM_GB" ]; then
        print_pass "${total_ram_gb}GB RAM (excellent)"
    elif [ "$total_ram_gb" -ge "$MIN_RAM_GB" ]; then
        print_warn "${total_ram_gb}GB RAM (${RECOMMENDED_RAM_GB}GB+ recommended)"
    else
        print_error "${total_ram_gb}GB RAM (minimum ${MIN_RAM_GB}GB required)"
    fi
    
    # Check available RAM
    available_ram_kb=$(grep MemAvailable /proc/meminfo | awk '{print $2}')
    available_ram_gb=$((available_ram_kb / 1024 / 1024))
    
    if [ "$available_ram_gb" -lt 4 ]; then
        print_warn "Only ${available_ram_gb}GB RAM available (close other applications)"
    fi
}

# ==============================================================================
# Disk Space
# ==============================================================================
check_disk_space() {
    print_header "Disk Space"
    
    workspace_path=$(pwd)
    
    print_check "Available disk space at $workspace_path"
    
    # Get available space in GB
    available_kb=$(df -k "$workspace_path" | tail -1 | awk '{print $4}')
    available_gb=$((available_kb / 1024 / 1024))
    
    if [ "$available_gb" -ge 150 ]; then
        print_pass "${available_gb}GB available (excellent)"
    elif [ "$available_gb" -ge "$MIN_DISK_SPACE_GB" ]; then
        print_warn "${available_gb}GB available (150GB+ recommended)"
    else
        print_error "${available_gb}GB available (minimum ${MIN_DISK_SPACE_GB}GB required)"
    fi
    
    # Check individual directories
    for dir in "shared/downloads" "shared/sstate-cache" "build" "sources"; do
        if [ -d "$dir" ]; then
            size=$(du -sh "$dir" 2>/dev/null | cut -f1)
            echo -e "  ${COLOR_CYAN}$dir:${COLOR_RESET} $size"
        fi
    done
}

# ==============================================================================
# Required Tools
# ==============================================================================
check_tools() {
    print_header "Required Tools"
    
    # Docker
    print_check "Docker"
    if command -v docker >/dev/null 2>&1; then
        docker_version=$(docker --version | grep -oP '\d+\.\d+' | head -1)
        if version_ge "$docker_version" "$MIN_DOCKER_VERSION"; then
            print_pass "Docker $docker_version installed"
        else
            print_error "Docker $docker_version (minimum $MIN_DOCKER_VERSION required)"
        fi
        
        # Check Docker daemon
        if docker info >/dev/null 2>&1; then
            print_pass "Docker daemon running"
        else
            print_error "Docker daemon not running (try: sudo systemctl start docker)"
        fi
        
        # Check Docker permissions
        if docker ps >/dev/null 2>&1; then
            print_pass "Docker permissions OK"
        else
            print_error "Docker permission denied (try: sudo usermod -aG docker $USER)"
        fi
    else
        print_error "Docker not installed"
    fi
    
    # Git
    print_check "Git"
    if command -v git >/dev/null 2>&1; then
        git_version=$(git --version | grep -oP '\d+\.\d+\.\d+')
        print_pass "Git $git_version installed"
    else
        print_error "Git not installed"
    fi
    
    # Python3
    print_check "Python3"
    if command -v python3 >/dev/null 2>&1; then
        python_version=$(python3 --version | grep -oP '\d+\.\d+\.\d+')
        print_pass "Python $python_version installed"
    else
        print_warn "Python3 not found (optional, but recommended)"
    fi
}

# ==============================================================================
# Network Connectivity
# ==============================================================================
check_network() {
    print_header "Network Connectivity"
    
    print_check "Internet connectivity"
    
    # Check DNS
    if ping -c 1 -W 2 8.8.8.8 >/dev/null 2>&1; then
        print_pass "Internet connection available"
    else
        print_error "No internet connection (required for downloading sources)"
    fi
    
    # Check GitHub connectivity
    print_check "GitHub access"
    if ping -c 1 -W 2 github.com >/dev/null 2>&1; then
        print_pass "GitHub reachable"
    else
        print_error "Cannot reach GitHub (required for source repositories)"
    fi
    
    # Check if behind proxy
    if [ -n "$HTTP_PROXY" ] || [ -n "$http_proxy" ]; then
        print_pass "Proxy configured: ${HTTP_PROXY:-$http_proxy}"
    fi
}

# ==============================================================================
# Project Structure
# ==============================================================================
check_project() {
    print_header "Project Structure"
    
    print_check "Required directories"
    
    if [ -f "Makefile" ]; then
        print_pass "Makefile found"
    else
        print_error "Makefile not found (are you in the project root?)"
    fi
    
    if [ -d "boards" ]; then
        print_pass "boards/ directory found"
        
        # Count board families
        family_count=$(find boards -maxdepth 1 -type d ! -name boards | wc -l)
        print_pass "$family_count board families configured"
    else
        print_error "boards/ directory not found"
    fi
    
    if [ -d "docker" ]; then
        print_pass "docker/ directory found"
    else
        print_error "docker/ directory not found"
    fi
    
    if [ -d "scripts" ]; then
        print_pass "scripts/ directory found"
    else
        print_error "scripts/ directory not found"
    fi
    
    # Check for config file
    print_check "Configuration"
    if [ -f ".builderrc" ]; then
        print_pass ".builderrc found (using custom configuration)"
    else
        print_pass "Using default configuration (create .builderrc to customize)"
    fi
}

# ==============================================================================
# Docker Image Status
# ==============================================================================
check_docker_image() {
    print_header "Docker Images"
    
    print_check "Build environment image"
    
    if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
        if docker images -q master-builder:latest | grep -q .; then
            image_size=$(docker images master-builder:latest --format "{{.Size}}")
            print_pass "master-builder:latest exists ($image_size)"
        else
            print_warn "master-builder:latest not built yet (will be built automatically)"
        fi
    fi
}

# ==============================================================================
# Build-specific Validation
# ==============================================================================
check_build_args() {
    if [ $# -eq 3 ]; then
        print_header "Build Configuration"
        
        family="$1"
        machine="$2"
        target="$3"
        
        print_check "Family: $family"
        if [ -f "boards/$family/$family.yml" ]; then
            print_pass "Configuration file exists"
        else
            print_error "Configuration not found: boards/$family/$family.yml"
        fi
        
        print_check "Machine: $machine"
        if [ -f "boards/$family/.machines" ]; then
            if grep -qx "$machine" "boards/$family/.machines"; then
                print_pass "Machine supported"
            else
                print_error "Machine not in supported list"
            fi
        fi
        
        print_check "Target: $target"
        if [ -f "boards/$family/.targets" ]; then
            if grep -qx "$target" "boards/$family/.targets"; then
                print_pass "Target supported"
            else
                print_error "Target not in supported list"
            fi
        fi
        
        # Architecture info
        if [ -f "boards/$family/.arch-map" ]; then
            arch=$(grep "^$machine:" "boards/$family/.arch-map" | cut -d: -f2)
            if [ -n "$arch" ]; then
                print_pass "Architecture: $arch"
            fi
        fi
    fi
}

# ==============================================================================
# Main Execution
# ==============================================================================
main() {
    clear
    echo -e "${COLOR_BLUE}╔════════════════════════════════════════════════════════════════════╗${COLOR_RESET}"
    echo -e "${COLOR_BLUE}║  Pre-flight Validation - KAS Board Building System                ║${COLOR_RESET}"
    echo -e "${COLOR_BLUE}╚════════════════════════════════════════════════════════════════════╝${COLOR_RESET}"
    echo ""
    
    check_system
    echo ""
    
    check_disk_space
    echo ""
    
    check_tools
    echo ""
    
    check_network
    echo ""
    
    check_project
    echo ""
    
    check_docker_image
    echo ""
    
    # Check build-specific args if provided
    if [ $# -eq 3 ]; then
        check_build_args "$@"
        echo ""
    fi
    
    # Summary
    print_header "Validation Summary"
    
    if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
        echo -e "${COLOR_GREEN}✓ All checks passed! System ready for building.${COLOR_RESET}"
        exit 0
    elif [ $ERRORS -eq 0 ]; then
        echo -e "${COLOR_YELLOW}⚠ $WARNINGS warning(s) found. Build should work but may be slower.${COLOR_RESET}"
        exit 0
    else
        echo -e "${COLOR_RED}✗ $ERRORS error(s) and $WARNINGS warning(s) found.${COLOR_RESET}"
        echo -e "${COLOR_RED}Please fix the errors before building.${COLOR_RESET}"
        exit 1
    fi
}

# Run main
main "$@"
