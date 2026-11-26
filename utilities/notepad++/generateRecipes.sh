#!/bin/bash
set -euo pipefail

scriptPath="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

authArgs=()
if [ -n "${GITHUB_TOKEN:-}" ]; then
    authArgs=(-H "Authorization: Bearer ${GITHUB_TOKEN}")
fi

releaseJson=$(curl -fsSL "${authArgs[@]}" \
    -H "Accept: application/vnd.github+json" \
    "https://api.github.com/repos/notepad-plus-plus/notepad-plus-plus/releases/latest")

version=$(printf '%s' "${releaseJson}" | jq -r '.tag_name // empty' | sed 's/^v//')
assetName=$(printf '%s' "${releaseJson}" | jq -r '.assets[]?.name | select(test("^npp\\..*\\.portable\\.x64\\.zip$"))' | head -n 1)

if [ -z "${version}" ] || [ -z "${assetName}" ]; then
    echo "ERROR: could not resolve latest Notepad++ portable x64 release" >&2
    exit 1
fi

echo "=== Notepad++ ${version} at ${scriptPath}/notepad++.levain.yaml"
cat <<EOF > "${scriptPath}/notepad++.levain.yaml"
version: ${version}

dependencies:

downloadUrl: https://github.com/notepad-plus-plus/notepad-plus-plus/releases/download

cmd.install:
    - extract \${downloadUrl}/v\${version}/${assetName} \${baseDir}
    # Store user configuration in %APPDATA% instead of the installation folder
    - levainShell if exist "\${baseDir}\\doLocalConf.xml" del /q "\${baseDir}\\doLocalConf.xml"

    # Windows context menu (HKCU)
    - template --replace=/@@baseDir@@/g --with=\${baseDir} --doubleBackslash \${pkgDir}/notepad++.reg \${baseDir}/notepad++.reg
    - levainShell reg import "\${baseDir}\\notepad++.reg"

    # Start Menu & PATH
    - addToStartMenu \${baseDir}/notepad++.exe
    - addPath --permanent \${baseDir}

cmd.env:
    - addPath \${baseDir}
EOF
