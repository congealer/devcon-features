#!/bin/bash

# Neither Feature owns this. 'prezto' makes zsh the login shell and rewrites the
# runcoms behind ~/.zshrc; 'arm-gnu-toolchain' puts its bin directory on PATH.
# Whether the toolchain survives into the shell prezto set up is a question each
# Feature's own tests cannot ask - arm's run under bash, and prezto's know
# nothing about a toolchain.
#
# It passes on its own today, because PATH comes from containerEnv and is
# inherited rather than sourced. It is here for the day that stops being true:
# arm going back to a profile.d or rc file, or prezto touching PATH from the
# runcom it already writes to.
#
# This test can be run with the following command (from the root of this repo)
#    make test-global

# Not 'set -e': a failing 'check' returns non-zero, which would abort the script
# and skip every remaining check. 'check' collects failures and 'reportResults'
# exits non-zero at the end, so the run is still reported as failed.
set +e

source dev-container-features-test-lib

# The directory rather than a binary: which one is installed depends on the
# 'target' option, but the PATH entry is the same either way.
BIN=/opt/gcc-arm/bin

echo "login shell: $(getent passwd "$(id -un)" | cut -d: -f7)"
echo "PATH:        $PATH"

check "prezto made zsh the login shell" bash -c '
    test "$(getent passwd "$(id -un)" | cut -d: -f7)" = "$(command -v zsh)"'

# What the user gets when the terminal opens.
check "the toolchain is on PATH in a login zsh" bash -c "
    zsh -l -c 'echo \$PATH' | grep -q '$BIN' || {
        echo \"$BIN missing from a login zsh\"
        echo \"got: \$(zsh -l -c 'echo \$PATH')\"
        exit 1
    }
"

check "the toolchain is on PATH in an interactive zsh" bash -c "
    zsh -i -c 'echo \$PATH' | grep -q '$BIN'"

# And the toolchain is not merely on PATH but runs from that shell.
check "the toolchain runs from a login zsh" bash -c '
    zsh -l -c "ls /opt/gcc-arm/bin/*-gcc" > /dev/null'

# The other half: prezto is still itself with another Feature alongside it.
check "prezto loads in an interactive zsh" bash -c '
    zsh -i -c "whence -w pmodload" | grep -q "pmodload: function"'

reportResults
