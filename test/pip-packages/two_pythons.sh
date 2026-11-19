#!/bin/bash

# The Python image with the Python feature on top: two interpreters, the
# image's own in /usr/local/bin and the feature's under /usr/local/python.
# pip-packages has to pick the feature's, the one the user declared and the
# one first on PATH, and leave the image's alone.

# Not 'set -e': a failing 'check' returns non-zero, which would abort the script
# and skip every remaining check. 'check' collects failures and 'reportResults'
# exits non-zero at the end, so the run is still reported as failed.
set +e

source dev-container-features-test-lib
source ./_common.sh

echo "python3: $(command -v python3) -> $(readlink -f "$(command -v python3)") ($(python3 --version))"
echo "image's: /usr/local/bin/python3 ($(/usr/local/bin/python3 --version))"

check "space-separated packages are installed" python3 -c 'import packaging, cowsay'

check "python3 is the Python feature's" bash -c '
    case "$(readlink -f "$(command -v python3)")" in /usr/local/python/*) ;; *) exit 1 ;; esac'

check "packages are in the Python feature's site-packages" bash -c '
    loc=$(dist_location packaging)
    [ "$loc" = "$(purelib)" ] || { echo "packaging is in $loc, not $(purelib)"; exit 1; }
    case "$(readlink -f "$loc")" in /usr/local/python/*) ;; *) echo "$loc is not under /usr/local/python"; exit 1 ;; esac'

check "the image's own Python is left alone" bash -c '
    ! /usr/local/bin/python3 -c "import cowsay" 2>/dev/null'

check "console scripts land in the Python feature's bin" bash -c '
    [ "$(command -v cowsay)" = "$(scripts)/cowsay" ] || { echo "cowsay is $(command -v cowsay)"; exit 1; }'

check "installed files match their directory" files_match_their_directory packaging
check "console scripts match their directory" files_match_their_directory cowsay

reportResults
