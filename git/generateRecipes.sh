#!/bin/bash
set -euo pipefail

scriptPath="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

authArgs=()
if [ -n "${GITHUB_TOKEN:-}" ]; then
    authArgs=(-H "Authorization: Bearer ${GITHUB_TOKEN}")
fi

releaseJson=$(curl -fsSL "${authArgs[@]}" \
    -H "Accept: application/vnd.github+json" \
    "https://api.github.com/repos/git-for-windows/git/releases/latest")

versionTag=$(printf '%s' "${releaseJson}" | jq -r '.tag_name // empty' | sed 's/^v//')
assetName=$(printf '%s' "${releaseJson}" | jq -r '.assets[]?.name | select(test("^PortableGit-[0-9.]+-64-bit\\.7z\\.exe$"))' | head -n 1)

if [ -z "${versionTag}" ] || [ -z "${assetName}" ]; then
    echo "ERROR: could not resolve latest PortableGit release from git-for-windows/git" >&2
    exit 1
fi

version=$(printf '%s' "${assetName}" | sed -E 's/^PortableGit-([0-9.]+)-64-bit\.7z\.exe$/\1/')

echo "=== Git ${version} (${versionTag}) at ${scriptPath}/git.levain.yaml"
cat <<EOF > "${scriptPath}/git.levain.yaml"
version: ${version}
versionTag: ${versionTag}
expected.version: git version ${versionTag}

downloadUrl: https://github.com/git-for-windows/git/releases/download

gitHome: \${baseDir}

cmd.install:
    # download and extract
    - extract \${downloadUrl}/v\${versionTag}/${assetName} \${gitHome}

    # make visible
    - setEnv --permanent GIT_HOME \${gitHome}
    - addPath --permanent \${gitHome}/bin

    # verify extracted binary
    - levainShell --saveVar=installed.version --stripCRLF=true \${gitHome}/bin/git.exe --version
    - assertContains \${expected.version} \${installed.version}

cmd.env:
    # make visible
    - setEnv GIT_HOME \${gitHome}
    - addPath \${gitHome}/bin
EOF
