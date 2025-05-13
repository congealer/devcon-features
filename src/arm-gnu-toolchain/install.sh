#!/bin/bash

set -e

# Default values
VERSION=${VERSION:-"14.2.rel1"}
TARGET=${TARGET:-"aarch64-none-elf"}

# Extract major version number
MAJOR_VERSION=$(echo $VERSION | cut -d'.' -f1)

ARCH=$(uname -m)
if [ "$ARCH" = "arm64" ]; then
    ARCH="aarch64"
fi

# Determine URL based on version
if [ "$MAJOR_VERSION" -le 10 ]; then
    # For versions <= 10.x
    URL="https://developer.arm.com/-/media/Files/downloads/gnu-a/${VERSION}/binrel/gcc-arm-${VERSION}-${ARCH}-${TARGET}.tar.xz"
else
    # For versions > 10.x
    URL="https://developer.arm.com/-/media/Files/downloads/gnu/${VERSION}/binrel/arm-gnu-toolchain-${VERSION}-${ARCH}-${TARGET}.tar.xz"
fi

# Download and extract
echo "Downloading ARM GNU Toolchain ${VERSION}..."
curl -L -o gcc-arm.tar.xz "${URL}" \
    && mkdir -p /opt/gcc-arm \
    && tar -xJf gcc-arm.tar.xz --strip-components=1 -C /opt/gcc-arm \
    && rm gcc-arm.tar.xz

# Add to PATH
echo 'export PATH="/opt/gcc-arm/bin:$PATH"' >> /etc/profile.d/arm-gnu-toolchain.sh
chmod +x /etc/profile.d/arm-gnu-toolchain.sh
