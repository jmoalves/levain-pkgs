#!/bin/bash
set -euo pipefail

scriptPath="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

authArgs=()
if [ -n "${GITHUB_TOKEN:-}" ]; then
    authArgs=(-H "Authorization: Bearer ${GITHUB_TOKEN}")
fi

releaseJson=$(curl -fsSL "${authArgs[@]}" \
    -H "Accept: application/vnd.github+json" \
    "https://api.github.com/repos/mikefarah/yq/releases/latest")

version=$(printf '%s' "${releaseJson}" | jq -r '.tag_name // empty' | sed 's/^v//')
assetName=$(printf '%s' "${releaseJson}" | jq -r '.assets[]?.name | select(. == "yq_windows_amd64.exe")' | head -n 1)

if [ -z "${version}" ] || [ -z "${assetName}" ]; then
    echo "ERROR: could not resolve latest yq release" >&2
    exit 1
fi

echo "=== yq ${version} at ${scriptPath}/yq.levain.yaml"
cat <<EOF > "${scriptPath}/yq.levain.yaml"
version: ${version}

dependencies:

downloadUrl: https://github.com/mikefarah/yq/releases/download/v\${version}

cmd.install:
    - copy \${downloadUrl}/${assetName} \${baseDir}/yq.exe
    - addPath --permanent \${baseDir}

cmd.env:
    - addPath \${baseDir}
EOF
