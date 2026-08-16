#!/bin/bash

# This test file will be executed against a container in which the
# 'arm-gnu-toolchain' Feature has been installed twice, to assert that a second
# install does not conflict with the first.
#
# For more information, see: https://github.com/devcontainers/cli/blob/main/docs/features/test.md

# Not 'set -e': a failing 'check' returns non-zero, which would abort the script
# and skip every remaining check. 'check' collects failures and 'reportResults'
# exits non-zero at the end, so the run is still reported as failed.
set +e

source dev-container-features-test-lib

ls -alh /opt/gcc-arm/bin
echo "PATH: $PATH"

check "toolchain is installed" bash -c "ls /opt/gcc-arm/bin/*-gcc >/dev/null 2>&1"

# Not how many times: PATH is declared as containerEnv, so applying the Feature
# twice leaves the entry twice, which costs nothing but cannot be avoided.
check "PATH carries the toolchain" bash -c '
    echo "$PATH" | tr : "\n" | grep -qx "/opt/gcc-arm/bin"
'

# Both installs extract into the same /opt/gcc-arm, so two different versions
# cannot coexist: the second one lands on top of the first.
check "only one toolchain version is present" bash -c '
    versions=$(ls /opt/gcc-arm/bin/*-gcc-*.*.* 2>/dev/null | sed "s/.*-gcc-//" | sort -u | wc -l)
    [ "$versions" -le 1 ] || { echo "$versions toolchain versions mixed under /opt/gcc-arm"; exit 1; }
'

reportResults
