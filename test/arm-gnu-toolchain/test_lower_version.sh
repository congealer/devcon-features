#!/bin/bash

set -e

# Import test library
source dev-container-features-test-lib

# Expected configuration
TARGET="aarch64-none-elf"
VERSION="10.3-2021.07"

# Feature-specific tests
ls -alh /opt/gcc-arm/bin
check "arm-gnu-toolchain installed" bash -c "[ -x /opt/gcc-arm/bin/${TARGET}-gcc ]"

# Check if the version is installed correctly
${TARGET}-gcc --version
check "arm-gnu-toolchain version" bash -c "${TARGET}-gcc --version | grep -i -q ${VERSION}"

# Report results
# If any of the checks above exited with a non-zero exit code, the test will fail.
reportResults