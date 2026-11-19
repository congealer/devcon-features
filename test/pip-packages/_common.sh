#!/bin/bash

# Checks shared by the pip-packages tests. Everything under test/pip-packages/
# is copied into the test container, so the scripts source this with
# 'source ./_common.sh'.
#
# 'python3' is the interpreter under test throughout: on the Python image it is
# the image's own, and on top of the Python feature that feature's containerEnv
# puts its interpreter first on PATH.

# Prints the files a distribution installed, as absolute paths. These come from
# its RECORD, so console scripts under bin/ are included.
dist_files() {
    python3 - "$1" <<'EOF'
import sys
from importlib import metadata
dist = metadata.distribution(sys.argv[1])
for f in dist.files or []:
    print(dist.locate_file(f).resolve())
EOF
}

# Where pip put a distribution: the directory its metadata lives in.
dist_location() {
    python3 -c "from importlib import metadata; print(metadata.distribution('$1').locate_file(''))"
}

# The directories pip installs into for this interpreter.
purelib() { python3 -c 'import sysconfig; print(sysconfig.get_path("purelib"))'; }
scripts() { python3 -c 'import sysconfig; print(sysconfig.get_path("scripts"))'; }

# Asserts that every file distribution $1 installed matches the directory it
# landed in: the same owner and group, and group-writable when that directory
# is. That is the rule the interpreter's own install follows, whichever way it
# was installed.
files_match_their_directory() {
    local dist="$1"
    local site bin f dir bad=()
    site=$(readlink -f "$(purelib)")
    bin=$(readlink -f "$(scripts)")
    while read -r f; do
        [ -e "$f" ] || continue
        case "$f" in
            "$site"/*) dir="$site" ;;
            "$bin"/*)  dir="$bin" ;;
            *) continue ;;
        esac
        if [ "$(stat -c %U:%G "$f")" != "$(stat -c %U:%G "$dir")" ]; then
            bad+=("$f is $(stat -c %U:%G "$f"), $dir is $(stat -c %U:%G "$dir")")
        elif [ -n "$(find "$dir" -maxdepth 0 -perm -g+w)" ] && [ -z "$(find "$f" -maxdepth 0 -perm -g+w)" ]; then
            bad+=("$f is not group-writable, $dir is")
        fi
    done < <(dist_files "$dist")
    # A whole package usually goes wrong the same way, so a few lines and the
    # count say as much as the full list.
    [ ${#bad[@]} -eq 0 ] && return 0
    printf '%s\n' "${bad[@]:0:3}"
    [ ${#bad[@]} -gt 3 ] && echo "... ${#bad[@]} files in all"
    return 1
}

# Asserts that a program which is not Python can load this interpreter's
# libpython by name alone, the way a simulator loading cocotb does. ctypes goes
# through the same dlopen() search; the ldconfig cache is what that search
# reads when nothing else points at the library. /sbin is spelled out because a
# non-root PATH on Debian does not carry it.
libpython_loads_by_name() {
    local lib
    lib=$(python3 -c 'import sysconfig; print(sysconfig.get_config_var("LDLIBRARY"))')
    echo "LDLIBRARY: $lib"
    /sbin/ldconfig -p | grep -qF "$lib " || { echo "$lib is not in the ldconfig cache"; return 1; }
    python3 -c "import ctypes; ctypes.CDLL('$lib')"
}

# The checks run most of these inside 'bash -c', which only sees functions that
# are exported.
export -f dist_files dist_location purelib scripts files_match_their_directory libpython_loads_by_name
