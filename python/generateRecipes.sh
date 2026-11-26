#!/bin/bash
set -euo pipefail

scriptPath="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

versions=$(curl -fsSL "https://www.python.org/ftp/python/" \
    | grep -oP 'href="\K3\.[0-9]+\.[0-9]+(?=/")' \
    | sort -Vr)

version=""
for candidate in ${versions}; do
    url="https://www.python.org/ftp/python/${candidate}/python-${candidate}-embed-amd64.zip"
    if curl -fsI --max-time 15 "${url}" >/dev/null 2>&1; then
        version="${candidate}"
        break
    fi
done

if [ -z "${version}" ]; then
    echo "ERROR: could not resolve latest downloadable Python 3 embeddable Windows x64 release" >&2
    exit 1
fi

echo "=== Python ${version} at ${scriptPath}/python-3.levain.yaml"
cat <<EOF > "${scriptPath}/python-3.levain.yaml"
version: ${version}

dependencies:

downloadUrl: https://www.python.org/ftp/python/\${version}

cmd.install:
    - extract \${downloadUrl}/python-\${version}-embed-amd64.zip \${baseDir}
    - addPath --permanent \${baseDir}

cmd.env:
    - addPath \${baseDir}
EOF
