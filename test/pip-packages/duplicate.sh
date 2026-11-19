#!/bin/bash

# This test file will be executed against a container in which the
# 'pip-packages' Feature has been installed twice, to assert that a second
# install does not conflict with the first.
#
# For more information, see: https://github.com/devcontainers/cli/blob/main/docs/features/test.md

# Not 'set -e': a failing 'check' returns non-zero, which would abort the script
# and skip every remaining check. 'check' collects failures and 'reportResults'
# exits non-zero at the end, so the run is still reported as failed.
set +e

source dev-container-features-test-lib
source ./_common.sh

ls -l /etc/ld.so.conf.d/

check "python3 still runs" python3 -c 'import sys'

check "libpython still loads by name" libpython_loads_by_name

# Written with '>', so a second install replaces the line rather than adding
# another. Absent is fine too: it is only written when libpython was not found.
check "python.conf holds at most one line" bash -c '
    [ ! -e /etc/ld.so.conf.d/python.conf ] || [ "$(wc -l < /etc/ld.so.conf.d/python.conf)" -le 1 ]'

reportResults
