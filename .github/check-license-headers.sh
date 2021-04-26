#!/usr/bin/env bash

# Check that source code files in this repo have the appropriate license
# header.

if [ "$TRACE" != "" ]; then
    export PS4='${BASH_SOURCE}:${LINENO}: ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'
    set -o xtrace
fi
set -o errexit
set -o pipefail

TOP=$(cd "$(dirname "$0")/.." >/dev/null && pwd)
LICENSE=$(cat .github/license-header.txt)

function check_license_header {
    local f
    f=$1
    if ! grep -Fxq "$LICENSE" "$f"; then
        echo "check-license-headers: error: '$f' does not have required license header"
        return 1
    else
        return 0
    fi
}


cd "$TOP"
nErrors=0
for f in $(git ls-files | grep -E '\.rb|Rakefile|\.rake|\.erb|Gemfile'); do
    if ! check_license_header $f; then
        nErrors=$((nErrors+1))
    fi
done

if [[ $nErrors -eq 0 ]]; then
    exit 0
else
    exit 1
fi
