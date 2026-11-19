#!/bin/bash

# pip-packages on top of the Python feature left at enableShared=false: there
# is no shared libpython to register, which is a warning, not a failure. Also
# takes the packages space-separated, and a Python version other than 'shared'.

# Not 'set -e': a failing 'check' returns non-zero, which would abort the script
# and skip every remaining check. 'check' collects failures and 'reportResults'
# exits non-zero at the end, so the run is still reported as failed.
set +e

source dev-container-features-test-lib
source ./_common.sh

echo "python3: $(command -v python3) ($(python3 --version))"
echo "LDLIBRARY: $(python3 -c 'import sysconfig; print(sysconfig.get_config_var("LDLIBRARY"))')"

# Getting here at all means the build went through despite the missing .so.

check "python3 is the requested version" bash -c 'python3 --version | grep -q "^Python 3\.11\."'

check "space-separated packages are installed" python3 -c 'import packaging, six'

check "packages are in the 3.11 site-packages" bash -c '
    loc=$(dist_location six)
    [ "$loc" = "$(purelib)" ] || { echo "six is in $loc, not $(purelib)"; exit 1; }
    case "$loc" in */python3.11/*) ;; *) echo "$loc is not a 3.11 path"; exit 1 ;; esac'

check "installed files match their directory" files_match_their_directory six

check "no linker config is written for a static libpython" bash -c '[ ! -e /etc/ld.so.conf.d/python.conf ]'

reportResults
