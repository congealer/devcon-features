#!/bin/bash

# This test file will be executed against the 'keep_default_shell' scenario,
# which sets 'setZshAsDefault' to false.
#
# The option defaults to true and every other test runs with that default, so
# this is the only place the false branch is exercised. Without it an install.sh
# that ignored the option entirely would still pass everything.
#
# For more information, see: https://github.com/devcontainers/cli/blob/main/docs/features/test.md

# Not 'set -e': a failing 'check' returns non-zero, which would abort the script
# and skip every remaining check. 'check' collects failures and 'reportResults'
# exits non-zero at the end, so the run is still reported as failed.
set +e

source dev-container-features-test-lib

# The Feature is still installed; only the login shell is left alone.
check "Prezto installed" bash -c '[ -d "$HOME/.zprezto" ]'
check "prezto loads in an interactive zsh" bash -c 'zsh -i -c "whence -w pmodload" | grep -q "pmodload: function"'

check "login shell was left alone" bash -c '
    shell=$(getent passwd "$(id -un)" | cut -d: -f7)
    [ "$shell" != "$(command -v zsh)" ] || { echo "login shell was changed to $shell"; exit 1; }
'

reportResults
