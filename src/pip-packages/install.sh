#!/bin/bash

set -e

PACKAGES="${PACKAGES:-}"

# The Python feature's interpreter first, then whatever python3 is on PATH: on
# the Python image (mcr.microsoft.com/devcontainers/python) PYTHON_PATH is set
# but points nowhere, and Python lives in /usr/local/bin instead. 'python3'
# rather than 'python' because a distro Python ships only the former.
PYTHON="${PYTHON_PATH:-/usr/local/python/current}/bin/python3"
if [ ! -x "$PYTHON" ]; then
    PYTHON=$(command -v python3 || true)
fi
if [ -z "$PYTHON" ]; then
    echo "No python3 found -- install the Python feature before this one, or use an image that has Python." >&2
    exit 1
fi
echo "Using $PYTHON ($("$PYTHON" --version))"

# Programs embedding Python (e.g. a simulator loading cocotb) dlopen()
# libpython by name, so the linker must find it on its own. Register
# Python's lib directory only when it cannot.
LDLIBRARY=$("$PYTHON" -c 'import sysconfig; print(sysconfig.get_config_var("LDLIBRARY"))')
LIBDIR=$("$PYTHON" -c 'import sysconfig; print(sysconfig.get_config_var("LIBDIR"))')
if [ "${LDLIBRARY##*.}" != "so" ]; then
    # Not a failure: most packages never need it, and nothing here can build
    # one after the fact.
    echo "Warning: this Python has no shared libpython (${LDLIBRARY})." >&2
    echo "  Programs that embed Python, such as simulators running cocotb, will not be able to load it." >&2
    echo "  Set \"enableShared\": true on the Python feature if you need that." >&2
elif ! ldconfig -p | grep -qF "${LDLIBRARY} "; then
    echo "$LIBDIR" > /etc/ld.so.conf.d/python.conf
    ldconfig
fi

if [ -z "$PACKAGES" ]; then
    echo "No pip packages requested."
    exit 0
fi

# Where pip puts what it installs, deduplicated: purelib and platlib are
# usually the same directory.
mapfile -t TARGETS < <("$PYTHON" -c '
import sysconfig
for d in dict.fromkeys(sysconfig.get_path(k) for k in ("purelib", "platlib", "scripts")):
    print(d)')

# Anything pip creates from here on has a newer ctime than this.
STAMP=$(mktemp)

# 'set -f' so that a specifier with extras, such as 'requests[socks]', is passed
# as-is rather than taken as a glob against the current directory.
set -f
# shellcheck disable=SC2046
"$PYTHON" -m pip install --no-cache-dir $(echo "$PACKAGES" | tr ',' ' ')
set +f

# pip ran as root, so what it created is root's. Hand it to whoever owns the
# directory it landed in, the way the interpreter's own install is set up: on
# the Python feature that is the user and the python group, group-writable with
# setgid directories; on the Python image, root alone, which leaves it as is.
# Only files created above are touched, and symlinks are not followed.
for dir in "${TARGETS[@]}"; do
    [ -d "$dir" ] || continue
    owner=$(stat -c %u:%g "$dir")
    find "$dir" -cnewer "$STAMP" -exec chown -h "$owner" {} +
    if [ -n "$(find "$dir" -maxdepth 0 -perm -g+w)" ]; then
        find "$dir" -cnewer "$STAMP" ! -type l -exec chmod g+w {} +
    fi
    if [ -n "$(find "$dir" -maxdepth 0 -perm -g+s)" ]; then
        find "$dir" -cnewer "$STAMP" -type d -exec chmod g+s {} +
    fi
done
rm -f "$STAMP"
