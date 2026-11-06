#!/usr/bin/env bash
# Build validateAlreadyRealizedClass() from runtime/objc-runtime-new.mm on the
# host with a stub malloc_size() and check which sizes it rejects.
# Usage: bash tests/run-class-rw-malloc-size.sh   (CXX defaults to c++)
set -euo pipefail
here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
awk '/^static void validateAlreadyRealizedClass\(Class cls\) \{$/ {p = 1}
     p {print}
     p && /^}$/ {exit}' "$here/../runtime/objc-runtime-new.mm" > "$work/validate.inc"
if [[ ! -s "$work/validate.inc" ]]; then
    echo "FAIL: validateAlreadyRealizedClass not found in runtime/objc-runtime-new.mm" >&2
    exit 1
fi
${CXX:-c++} -std=c++17 -Wall -Wextra -O1 \
    -DVALIDATE_SOURCE="\"$work/validate.inc\"" \
    "$here/class-rw-malloc-size.cpp" -o "$work/test"
"$work/test"
