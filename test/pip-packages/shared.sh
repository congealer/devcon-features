#!/bin/bash

# pip-packages on top of the Python feature, with the options it recommends:
# Python built with a shared libpython, and no pipx tools.

# Not 'set -e': a failing 'check' returns non-zero, which would abort the script
# and skip every remaining check. 'check' collects failures and 'reportResults'
# exits non-zero at the end, so the run is still reported as failed.
set +e

source dev-container-features-test-lib
source ./_common.sh

echo "python3: $(command -v python3) ($(python3 --version))"
echo "site-packages: $(purelib) ($(stat -c '%U:%G %A' "$(purelib)"))"

check "python3 is the Python feature's" bash -c '
    case "$(readlink -f "$(command -v python3)")" in /usr/local/python/*) ;; *) exit 1 ;; esac'

check "python3 is the requested version" bash -c 'python3 --version | grep -q "^Python 3\.12\."'

check "packages import" python3 -c 'import packaging, requests, socks, cowsay'

check "packages are in the Python feature's site-packages" bash -c '
    loc=$(dist_location packaging)
    [ "$loc" = "$(purelib)" ] || { echo "packaging is in $loc, not $(purelib)"; exit 1; }
    case "$(readlink -f "$loc")" in /usr/local/python/*) ;; *) echo "$loc is not under /usr/local/python"; exit 1 ;; esac'

check "a pinned version is honoured" python3 -c '
from importlib import metadata
v = metadata.version("packaging")
assert v == "24.1", v'

check "extras are installed" python3 -c 'import socks'

check "console scripts land in the interpreter's bin" bash -c '
    [ "$(command -v cowsay)" = "$(scripts)/cowsay" ] || { echo "cowsay is $(command -v cowsay)"; exit 1; }'

# The Python feature hands its install to the user and the python group
# (group-writable, setgid directories). Files pip added as root must follow.
check "installed files match their directory" files_match_their_directory packaging
check "console scripts match their directory" files_match_their_directory cowsay

check "libpython loads by name" libpython_loads_by_name

reportResults
