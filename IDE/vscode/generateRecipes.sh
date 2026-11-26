#!/bin/bash
set -euo pipefail

scriptPath="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

releaseJson=$(curl -fsSL "https://update.code.visualstudio.com/api/update/win32-x64-archive/stable/latest")
version=$(printf '%s' "${releaseJson}" | jq -r '.name // .productVersion // empty')

if [ -z "${version}" ]; then
    echo "ERROR: could not resolve latest stable VS Code version" >&2
    exit 1
fi

echo "=== VS Code ${version} at ${scriptPath}/vscode.levain.yaml"
cat <<EOF > "${scriptPath}/vscode.levain.yaml"
version: ${version}

dependencies:

downloadUrl: https://update.code.visualstudio.com/\${version}/win32-x64-archive/stable

cmd.install:
    - extract --type zip \${downloadUrl} \${baseDir}
    - addToStartMenu \${baseDir}/Code.exe
    - addPath --permanent \${baseDir}/bin

cmd.env:
    - addPath \${baseDir}/bin
EOF
