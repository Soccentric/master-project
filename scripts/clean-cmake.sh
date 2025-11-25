#!/bin/bash
# Script to clean cmake-native build artifacts

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GIT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_NAME="${1:-nvidia-jetson-jetson-agx-orin-devkit}"
BUILD_DIR="$GIT_ROOT/build/$BUILD_NAME"
DOCKER_IMAGE="master-builder:latest"
WORKSPACE_MOUNT="/workspace"

echo "Cleaning cmake-native for build: $BUILD_NAME"

if [ ! -d "$BUILD_DIR" ]; then
    echo "Error: Build directory not found: $BUILD_DIR"
    exit 1
fi

# Extract family from build name (e.g., nvidia-jetson-jetson-agx-orin-devkit -> nvidia-jetson)
# The pattern is: family-machine, where machine can contain hyphens
# We need to find where the family ends by checking against existing source dirs
BUILD_NAME_NO_EXT="${BUILD_NAME}"
for src_dir in "$GIT_ROOT/sources"/*; do
    family_name=$(basename "$src_dir")
    if [[ "$BUILD_NAME" == "$family_name-"* ]]; then
        FAMILY="$family_name"
        break
    fi
done

if [ -z "$FAMILY" ]; then
    echo "Error: Could not determine family from build name: $BUILD_NAME"
    exit 1
fi

echo "Detected family: $FAMILY"

# Run bitbake cleansstate through Docker
docker run --rm --network host \
    -v "$GIT_ROOT:$WORKSPACE_MOUNT" \
    -w "$WORKSPACE_MOUNT/build/$BUILD_NAME" \
    --user "$(id -u):$(id -g)" \
    "$DOCKER_IMAGE" \
    bash -c "source ../../sources/$FAMILY/poky/oe-init-build-env . && bitbake -c cleansstate cmake-native"

echo "✓ cmake-native cleaned successfully"
echo "Now retry your build with: make build nvidia-jetson jetson-agx-orin-devkit core-image-full-cmdline"
