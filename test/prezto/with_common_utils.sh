#!/bin/bash

# This test file will be executed against the 'with_common_utils' scenario:
# common-utils creating a brand new 'octocat' user, plus this Feature.
#
# The point is install order. common-utils is what creates the user, so if
# prezto were installed first the CLI would not be able to resolve the user's
# home yet and the build would fail before this script ever runs:
#
#     The effective dev container remoteUser's home directory is ''
#     Git cloning Prezto into /.zprezto
#     sudo: unknown user octocat
#
# 'installsAfter' in devcontainer-feature.json is what keeps that from
# happening. The checks below confirm the install landed in the new user's home
# and belongs to them, rather than to root or to the image's default user.
#
# For more information, see: https://github.com/devcontainers/cli/blob/main/docs/features/test.md

# Not 'set -e': a failing 'check' returns non-zero, which would abort the script
# and skip every remaining check. 'check' collects failures and 'reportResults'
# exits non-zero at the end, so the run is still reported as failed.
set +e

source dev-container-features-test-lib

check "running as the user common-utils created" bash -c '[ "$(id -un)" = "octocat" ]'

check "prezto installed into that user's home" bash -c '
    [ -d "$HOME/.zprezto" ] || { echo "not found: $HOME/.zprezto"; exit 1; }
    case "$HOME" in /home/octocat) ;; *) echo "unexpected home: $HOME"; exit 1 ;; esac
'

check "no files owned by another user under ~/.zprezto" bash -c '
    owner=$(id -un)
    stray=$(find "$HOME/.zprezto" ! -user "$owner" -print -quit)
    [ -z "$stray" ] || { echo "not owned by $owner: $stray"; exit 1; }
'

check "~/.zshrc links into .zprezto" bash -c '
    [ -L "$HOME/.zshrc" ] || { echo "~/.zshrc is not a symlink"; exit 1; }
    [ "$(readlink "$HOME/.zshrc")" = "$HOME/.zprezto/runcoms/zshrc" ]
'

check "prezto loads in an interactive zsh" bash -c 'zsh -i -c "whence -w pmodload" | grep -q "pmodload: function"'

reportResults
