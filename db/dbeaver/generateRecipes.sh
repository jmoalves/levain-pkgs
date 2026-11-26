#!/bin/bash
set -euo pipefail

scriptPath="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

authArgs=()
if [ -n "${GITHUB_TOKEN:-}" ]; then
    authArgs=(-H "Authorization: Bearer ${GITHUB_TOKEN}")
fi

releaseJson=$(curl -fsSL "${authArgs[@]}" \
    -H "Accept: application/vnd.github+json" \
    "https://api.github.com/repos/dbeaver/dbeaver/releases/latest")

version=$(printf '%s' "${releaseJson}" | jq -r '.tag_name // empty' | sed 's/^v//')
assetName=$(printf '%s' "${releaseJson}" | jq -r '.assets[]?.name | select(test("^dbeaver-ce-.*-(windows-x86_64|win32\\.win32\\.x86_64)\\.zip$"))' | head -n 1)

if [ -z "${version}" ] || [ -z "${assetName}" ]; then
    echo "ERROR: could not resolve latest DBeaver CE Windows x64 zip release" >&2
    exit 1
fi

echo "=== DBeaver ${version} at ${scriptPath}/dbeaver.levain.yaml"
cat <<EOF > "${scriptPath}/dbeaver.levain.yaml"
version: ${version}

dependencies:

downloadUrl: https://github.com/dbeaver/dbeaver/releases/download/\${version}

cmd.install:
    - extract --strip \${downloadUrl}/${assetName} \${baseDir}
    - addToStartMenu \${baseDir}/dbeaver.exe
    - addPath --permanent \${baseDir}

cmd.env:
    - addPath \${baseDir}
EOF
