#!/bin/bash

# pip-packages on the Python image, where Python did not come from the Python
# feature: the interpreter is /usr/local/bin/python3 and its site-packages
# belongs to root alone.

# Not 'set -e': a failing 'check' returns non-zero, which would abort the script
# and skip every remaining check. 'check' collects failures and 'reportResults'
# exits non-zero at the end, so the run is still reported as failed.
set +e

source dev-container-features-test-lib
source ./_common.sh

echo "python3: $(command -v python3) ($(python3 --version))"
echo "site-packages: $(purelib) ($(stat -c '%U:%G %A' "$(purelib)"))"

check "packages import in the image's python3" python3 -c 'import packaging, requests, socks, cowsay'

check "packages are in the interpreter's site-packages" bash -c '
    loc=$(dist_location packaging)
    [ "$loc" = "$(purelib)" ] || { echo "packaging is in $loc, not $(purelib)"; exit 1; }'

check "a pinned version is honoured" python3 -c '
from importlib import metadata
v = metadata.version("packaging")
assert v == "24.1", v'

# Extras ride along with the specifier rather than being taken as a glob.
check "extras are installed" python3 -c 'import socks'

check "console scripts land in the interpreter's bin" bash -c '
    [ "$(command -v cowsay)" = "$(scripts)/cowsay" ] || { echo "cowsay is $(command -v cowsay)"; exit 1; }'

# The image's site-packages is root:root and not group-writable, so the
# installed files stay that way too.
check "installed files match their directory" files_match_their_directory packaging
check "console scripts match their directory" files_match_their_directory cowsay

check "installed files are not writable by the user" bash -c '
    f=$(dist_files packaging | head -1)
    [ ! -w "$f" ] || { echo "$f is writable by $(id -un)"; exit 1; }'

# Installing later is not the recommended route (change devcontainer.json
# instead), but when it happens it has to go to ~/.local, not fail.
check "a later pip install goes to ~/.local" bash -c '
    python3 -m pip install --no-cache-dir --quiet six || exit 1
    loc=$(dist_location six)
    case "$loc" in "$HOME"/.local/*) ;; *) echo "six went to $loc"; exit 1 ;; esac'

check "libpython loads by name" libpython_loads_by_name

reportResults
