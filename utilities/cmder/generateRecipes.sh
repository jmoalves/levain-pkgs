#!/bin/bash
set -euo pipefail

scriptPath="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

authArgs=()
if [ -n "${GITHUB_TOKEN:-}" ]; then
    authArgs=(-H "Authorization: Bearer ${GITHUB_TOKEN}")
fi

releaseJson=$(curl -fsSL "${authArgs[@]}" \
    -H "Accept: application/vnd.github+json" \
    "https://api.github.com/repos/cmderdev/cmder/releases/latest")

version=$(printf '%s' "${releaseJson}" | jq -r '.tag_name // empty' | sed 's/^v//')
assetName=$(printf '%s' "${releaseJson}" | jq -r '.assets[]?.name | select(. == "cmder_mini.zip")' | head -n 1)

if [ -z "${version}" ] || [ -z "${assetName}" ]; then
    echo "ERROR: could not resolve latest Cmder release" >&2
    exit 1
fi

echo "=== Cmder ${version} at ${scriptPath}/cmder.levain.yaml"
cat <<EOF > "${scriptPath}/cmder.levain.yaml"
version: ${version}

dependencies:

downloadUrl: https://github.com/cmderdev/cmder/releases/download

cmd.install:
    - extract \${downloadUrl}/v\${version}/${assetName} \${baseDir}
    - addToStartMenu \${baseDir}/Cmder.exe
    - addPath --permanent \${baseDir}

cmd.env:
    - addPath \${baseDir}
EOF
