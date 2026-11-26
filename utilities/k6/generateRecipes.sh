#!/bin/bash
set -euo pipefail

scriptPath="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

authArgs=()
if [ -n "${GITHUB_TOKEN:-}" ]; then
    authArgs=(-H "Authorization: Bearer ${GITHUB_TOKEN}")
fi

releaseJson=$(curl -fsSL "${authArgs[@]}" \
    -H "Accept: application/vnd.github+json" \
    "https://api.github.com/repos/grafana/k6/releases/latest")

version=$(printf '%s' "${releaseJson}" | jq -r '.tag_name // empty' | sed 's/^v//')
assetName=$(printf '%s' "${releaseJson}" | jq -r '.assets[]?.name | select(test("^k6-.*-windows-amd64\\.zip$"))' | head -n 1)

if [ -z "${version}" ] || [ -z "${assetName}" ]; then
    echo "ERROR: could not resolve latest k6 release" >&2
    exit 1
fi

echo "=== k6 ${version} at ${scriptPath}/k6.levain.yaml"
cat <<EOF > "${scriptPath}/k6.levain.yaml"
version: ${version}

dependencies:

downloadUrl: https://github.com/grafana/k6/releases/download/v\${version}

cmd.install:
    - extract --strip \${downloadUrl}/${assetName} \${baseDir}
    - addPath --permanent \${baseDir}

cmd.env:
    - addPath \${baseDir}
EOF
