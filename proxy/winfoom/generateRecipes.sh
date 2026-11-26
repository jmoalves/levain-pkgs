#!/bin/bash
set -euo pipefail

scriptPath="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

authArgs=()
if [ -n "${GITHUB_TOKEN:-}" ]; then
    authArgs=(-H "Authorization: Bearer ${GITHUB_TOKEN}")
fi

releaseJson=$(curl -fsSL "${authArgs[@]}" \
    -H "Accept: application/vnd.github+json" \
    "https://api.github.com/repos/ecovaci/winfoom/releases/latest")

version=$(printf '%s' "${releaseJson}" | jq -r '.tag_name // empty' | sed 's/^v//')
assetName=$(printf '%s' "${releaseJson}" | jq -r '.assets[]?.name | select(. == "winfoom-windows.zip")' | head -n 1)

if [ -z "${version}" ] || [ -z "${assetName}" ]; then
    echo "ERROR: could not resolve latest winfoom release" >&2
    exit 1
fi

echo "=== winfoom ${version} at ${scriptPath}/winfoom.levain.yaml"
cat <<EOF > "${scriptPath}/winfoom.levain.yaml"
version: ${version}

dependencies:
    - jdk-21-ibm-latest

downloadUrl: https://github.com/ecovaci/winfoom/releases/download

cmd.install:
    - extract \${downloadUrl}/v\${version}/${assetName} \${baseDir}
    - addToDesktop \${baseDir}/launchGui.bat
    - addToStartMenu \${baseDir}/launchGui.bat
    - addPath --permanent \${baseDir}

cmd.env:
    - addPath \${baseDir}
EOF
