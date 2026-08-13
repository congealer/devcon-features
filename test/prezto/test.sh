#!/bin/bash

# This test file will be executed against an auto-generated devcontainer.json that
# includes the 'prezto' Feature with no options.
#
# For more information, see: https://github.com/devcontainers/cli/blob/main/docs/features/test.md
#
# Two different users are involved, which is what most of the checks below are
# about:
#
#   - install.sh runs as root, at image build time. The CLI injects _REMOTE_USER
#     and _REMOTE_USER_HOME so that it can install into somebody else's home and
#     hand the result over with 'sudo -u'.
#   - this script runs later, inside the started container, as that remoteUser
#     (e.g. 'vscode' for mcr.microsoft.com/devcontainers/base:ubuntu; it can be
#     overridden with the '--remote-user' flag).
#
# The _REMOTE_USER* variables are build-time only and are not exported into this
# environment, but they do not need to be: because the script already runs as the
# remote user, 'id -un' is _REMOTE_USER and $HOME is _REMOTE_USER_HOME.
#
# This test can be run with the following command:
#
#    devcontainer features test \
#                   --features prezto   \
#                   --skip-scenarios   \
#                   --base-image mcr.microsoft.com/devcontainers/base:ubuntu \
#                   /path/to/this/repo

# Not 'set -e': a failing 'check' returns non-zero, which would abort the script
# and skip every remaining check. 'check' collects failures and 'reportResults'
# exits non-zero at the end, so the run is still reported as failed.
set +e

# Optional: Import test library bundled with the devcontainer CLI
# See https://github.com/devcontainers/cli/blob/HEAD/docs/features/test.md#dev-container-features-test-lib
# Provides the 'check' and 'reportResults' commands.
source dev-container-features-test-lib

# The runcoms that install.sh links into the home directory. install.sh links
# every file under runcoms/ except README.md, so this list mirrors the upstream
# prezto repository.
RUNCOMS="zshrc zshenv zprofile zlogin zlogout zpreztorc"

# ---------------------------------------------------------------------------
# 1. Installation: prezto was cloned and the bundled zpreztorc replaced the
#    upstream one (which install.sh keeps as zpreztorc_org).
# ---------------------------------------------------------------------------
# The 'check' command comes from the dev-container-features-test-lib. Syntax is...
# check <LABEL> <cmd> [args...]
check "Prezto installed" bash -c "[ -d \$HOME/.zprezto ]"

# install.sh renames the upstream zpreztorc to zpreztorc_org and puts the copy
# bundled with this Feature in its place, so a correct install leaves two files
# that differ. The backup is checked for existence first: 'diff' also exits
# non-zero when a file is missing, so comparing alone would pass even if
# zpreztorc_org had never been created.
check "zpreztorc modified" bash -c '
    org="$HOME/.zprezto/runcoms/zpreztorc_org"
    new="$HOME/.zprezto/runcoms/zpreztorc"
    [ -f "$org" ] || { echo "upstream backup missing: $org"; exit 1; }
    [ -f "$new" ] || { echo "missing: $new"; exit 1; }
    if diff -q "$org" "$new" >/dev/null; then
        echo "zpreztorc is identical to the upstream backup - it was not replaced"
        exit 1
    fi
'

# ---------------------------------------------------------------------------
# 2. Runcoms are symlinked into ~/.zprezto rather than copied, so that pulling
#    the prezto repository updates them in place.
# ---------------------------------------------------------------------------
for rc in $RUNCOMS; do
    check "~/.$rc links to .zprezto/runcoms/$rc" bash -c "
        [ -L \"\$HOME/.$rc\" ] || { echo \"not a symlink: \$HOME/.$rc\"; exit 1; }
        [ -e \"\$HOME/.$rc\" ] || { echo \"dangling symlink: \$HOME/.$rc\"; exit 1; }
        target=\$(readlink \"\$HOME/.$rc\")
        [ \"\$target\" = \"\$HOME/.zprezto/runcoms/$rc\" ] || { echo \"unexpected target: \$target\"; exit 1; }
    "
done

# ---------------------------------------------------------------------------
# 3. Ownership: install.sh is executed as root, so every file it creates would
#    end up root-owned unless it hands it over with 'sudo -u $_REMOTE_USER'.
#    Since this script runs as that same remote user, comparing against
#    'id -un' is comparing against _REMOTE_USER. A single root-owned file would
#    leave the shell unable to rewrite its own history or completion dumps.
# ---------------------------------------------------------------------------
check "no files owned by another user under ~/.zprezto" bash -c '
    owner=$(id -un)
    stray=$(find "$HOME/.zprezto" ! -user "$owner" -print -quit)
    [ -z "$stray" ] || { echo "not owned by $owner: $stray"; exit 1; }
'

check "home symlinks owned by the remote user" bash -c "
    owner=\$(id -un)
    for rc in $RUNCOMS; do
        # stat does not dereference symlinks, so this is the link's own owner.
        actual=\$(stat -c %U \"\$HOME/.\$rc\")
        [ \"\$actual\" = \"\$owner\" ] || { echo \"\$HOME/.\$rc owned by \$actual, expected \$owner\"; exit 1; }
    done
"

# ---------------------------------------------------------------------------
# 4. Prezto actually loads. ~/.zshrc is only sourced by interactive shells,
#    hence 'zsh -i'; a plain 'zsh -c' would report 'pmodload: none' even on a
#    correct install.
# ---------------------------------------------------------------------------
check "prezto loads in an interactive zsh" bash -c 'zsh -i -c "whence -w pmodload" | grep -q "pmodload: function"'
check "ZPREZTODIR points at ~/.zprezto" bash -c 'test "$(zsh -i -c "printf %s \$ZPREZTODIR")" = "$HOME/.zprezto"'
# The bundled zpreztorc loads the 'git' pmodule, which defines the 'git-info' function.
check "pmodules from the bundled zpreztorc are loaded" bash -c 'zsh -i -c "whence -w git-info" | grep -q "git-info: function"'

# ---------------------------------------------------------------------------
# 5. setZshAsDefault defaults to true, so the login shell is zsh. The opposite
#    is covered by the 'keep_default_shell' scenario.
# ---------------------------------------------------------------------------
check "login shell is zsh" bash -c '
    shell=$(getent passwd "$(id -un)" | cut -d: -f7)
    [ "$shell" = "$(command -v zsh)" ] || { echo "login shell is $shell"; exit 1; }
'

# Installing the Feature twice is covered separately, by duplicate.sh.

# Report results
# If any of the checks above exited with a non-zero exit code, the test will fail.
reportResults
