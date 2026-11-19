#!/bin/bash

# pip-packages with nothing to install still registers libpython: that step
# comes before the early exit for an empty package list.

# Not 'set -e': a failing 'check' returns non-zero, which would abort the script
# and skip every remaining check. 'check' collects failures and 'reportResults'
# exits non-zero at the end, so the run is still reported as failed.
set +e

source dev-container-features-test-lib
source ./_common.sh

check "libpython loads by name" libpython_loads_by_name

reportResults
