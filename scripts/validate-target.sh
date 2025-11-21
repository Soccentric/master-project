#!/bin/bash
# Script to validate build arguments (family, machine, target)

COLOR_RESET="\033[0m"
COLOR_YELLOW="\033[33m"
COLOR_RED="\033[31m"

BOARDS_DIR="boards"

if [ "$#" -ne 3 ]; then
    echo -e "${COLOR_RED}Error: Invalid arguments${COLOR_RESET}"
    echo "Usage: $0 <family> <machine> <target>"
    exit 1
fi

family="$1"
machine="$2"
target="$3"

yml_file="${BOARDS_DIR}/${family}/${family}.yml"

if [ ! -f "$yml_file" ]; then
    echo -e "${COLOR_YELLOW}Error: Family configuration '${family}' not found${COLOR_RESET}"
    echo "Available families: raspberry-pi, xilinx-zynq, nvidia-jetson, nxp-imx"
    exit 1
fi

machines_file="${BOARDS_DIR}/${family}/.machines"
targets_file="${BOARDS_DIR}/${family}/.targets"

if ! grep -qx "${machine}" "${machines_file}" 2>/dev/null; then
    echo -e "${COLOR_YELLOW}Error: Machine '${machine}' not supported for ${family}${COLOR_RESET}"
    echo "Supported machines:"
    grep -v "^#" "${machines_file}" | grep -v "^$" | sed 's/^/  • /'
    exit 1
fi

if ! grep -qx "${target}" "${targets_file}" 2>/dev/null; then
    echo -e "${COLOR_YELLOW}Error: Target '${target}' not supported for ${family}${COLOR_RESET}"
    echo "Supported targets:"
    grep -v "^#" "${targets_file}" | grep -v "^$" | sed 's/^/  • /'
    exit 1
fi

exit 0
