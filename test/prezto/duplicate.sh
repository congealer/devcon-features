#!/bin/bash

# This test file will be executed against a container in which the 'prezto'
# Feature has been installed twice, to assert that a second install is a no-op.
#
# install.sh guards against this by returning early when ~/.zprezto already
# exists. Without that guard the second 'git clone' fails into the '|| exit 1'
# branch and the image build itself breaks, so this test failing usually means
# the build never got that far.
#
# For more information, see: https://github.com/devcontainers/cli/blob/main/docs/features/test.md

# Not 'set -e': a failing 'check' returns non-zero, which would abort the script
# and skip every remaining check. 'check' collects failures and 'reportResults'
# exits non-zero at the end, so the run is still reported as failed.
set +e

source dev-container-features-test-lib

check "Prezto installed" bash -c "[ -d \$HOME/.zprezto ]"

# A second pass over the swap would move the bundled copy onto the backup,
# leaving the two identical. Existence is checked first because 'diff' also
# exits non-zero when a file is missing.
check "zpreztorc swap did not run twice" bash -c '
    org="$HOME/.zprezto/runcoms/zpreztorc_org"
    new="$HOME/.zprezto/runcoms/zpreztorc"
    [ -f "$org" ] || { echo "upstream backup missing: $org"; exit 1; }
    [ -f "$new" ] || { echo "missing: $new"; exit 1; }
    if diff -q "$org" "$new" >/dev/null; then
        echo "zpreztorc is identical to the upstream backup - the swap ran twice"
        exit 1
    fi
'

# A second pass over the backup loop would back up the backups.
check "backups were not backed up again" bash -c '
    stray=$(find "$HOME" -maxdepth 1 -name "*.prezto_backup.prezto_backup" -print -quit)
    [ -z "$stray" ] || { echo "backup was backed up again: $stray"; exit 1; }
'

check "~/.zshrc still links into .zprezto" bash -c "
    [ -L \"\$HOME/.zshrc\" ] || { echo '~/.zshrc is no longer a symlink'; exit 1; }
    [ \"\$(readlink \"\$HOME/.zshrc\")\" = \"\$HOME/.zprezto/runcoms/zshrc\" ]
"

check "prezto still loads in an interactive zsh" bash -c 'zsh -i -c "whence -w pmodload" | grep -q "pmodload: function"'

# The duplicate test feeds a string option from its 'proposals' rather than its
# default, so extraZshrc arrives carrying the fzf line. install.sh appends it to
# the runcom ~/.zshrc points at, wrapped in markers, dropping any block an
# earlier pass left behind - which is the point: a second install must replace
# the block rather than stack another one up.
check "the extraZshrc block was replaced, not stacked" bash -c '
    runcom="$HOME/.zprezto/runcoms/zshrc"
    count=$(grep -c "^# >>> devcontainer extraZshrc >>>$" "$runcom")
    [ "$count" = "1" ] || { echo "expected one marker block, found $count"; exit 1; }
'

# fzf is not on the image, but that only decides whether the line does anything
# at shell start - it is written at install time either way.
check "the runcom carries the proposed extraZshrc line" bash -c '
    grep -qF "fzf --zsh" "$HOME/.zprezto/runcoms/zshrc"
'

reportResults
