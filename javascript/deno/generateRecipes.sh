#!/bin/bash
# Define the script path and the template file
scriptPath="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd && cd - >/dev/null 2>&1 )"

# Function to generate Deno recipes
generateDenoRecipes() {
    local version=$1
    local filename=${scriptPath}/deno-${version}.levain.yaml
    echo "=== Deno ${version} at ${filename}"
    cat <<EOF > ${scriptPath}/deno.levain.yaml
version: $version

dependencies:

downloadUrl: https://github.com/denoland/deno/releases/download

cmd.install:
    - extract \${downloadUrl}/v\${version}/deno-x86_64-pc-windows-msvc.zip \${baseDir}
    - addPath --permanent \${baseDir}

cmd.env:
    - setEnv DENO_DIR \${baseDir}
    - addPath \${baseDir}
EOF
}

# Fetch Deno versions from GitHub releases
authArgs=()
if [ -n "${GITHUB_TOKEN:-}" ]; then
    authArgs=(-H "Authorization: Bearer ${GITHUB_TOKEN}")
fi
version=$(curl -fsSL "${authArgs[@]}" https://api.github.com/repos/denoland/deno/releases \
    | grep -oP '"tag_name": "\Kv[\d.]+(?=")' \
    | sed 's/v//g' \
    | sort -Vr \
    | head -n 1
)
if [ -z "${version}" ]; then
    echo "ERROR: could not determine latest Deno version" >&2
    exit 1
fi
generateDenoRecipes "$version"
