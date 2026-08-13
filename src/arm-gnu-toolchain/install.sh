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

# Ask the installed toolchain for its own version and do nothing if it is
# already the requested one, the way the official Features do it (see
# devcontainers/features src/go/install.sh). Without this, a base image that
# already bakes this Feature in re-downloads several hundred MB on rebuild.
GCC="/opt/gcc-arm/bin/${TARGET}-gcc"
if [ -x "$GCC" ] && "$GCC" --version | grep -qi "${VERSION}"; then
    echo "ARM GNU Toolchain ${VERSION} for ${TARGET} is already installed. Skipping."
else
    # 'curl' and 'xz' (needed by 'tar -xJf') are missing from the bare distro
    # images. 'ca-certificates' has to be named explicitly: it is only a
    # Recommends of curl, so with --no-install-recommends the CA bundle never
    # gets built and the download fails with "error setting certificate file".
    if ! command -v curl >/dev/null || ! command -v xz >/dev/null; then
        echo "Installing curl and xz-utils..."
        export DEBIAN_FRONTEND=noninteractive
        apt-get update
        apt-get install -y --no-install-recommends curl ca-certificates xz-utils
        rm -rf /var/lib/apt/lists/*
    fi

    # '-f' matters: without it curl writes the server's error page into the
    # tarball and still exits 0, which would take out the existing install
    # below before tar discovers the file is not an archive.
    echo "Downloading ARM GNU Toolchain ${VERSION}..."
    curl -fL -o gcc-arm.tar.xz "${URL}"

    # Replace rather than extract on top of what is already there. A different
    # version brings its own set of files, and the two would otherwise end up
    # merged in one directory. Done after the download so that a failed fetch
    # cannot leave the existing install destroyed.
    rm -rf /opt/gcc-arm
    mkdir -p /opt/gcc-arm
    tar -xJf gcc-arm.tar.xz --strip-components=1 -C /opt/gcc-arm
    rm gcc-arm.tar.xz
fi

# Written on every run, with '>' rather than '>>', so that repeated installs
# leave exactly one line.
echo 'export PATH="/opt/gcc-arm/bin:$PATH"' > /etc/profile.d/arm-gnu-toolchain.sh
chmod +x /etc/profile.d/arm-gnu-toolchain.sh
