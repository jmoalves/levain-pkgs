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

cmd.env:
    - setEnv DENO_DIR \${baseDir}
    - addPath --permanent \${baseDir}
EOF
}

# Fetch Deno versions from GitHub releases
version=$(curl -s https://api.github.com/repos/denoland/deno/releases \
    | grep -oP '"tag_name": "\Kv[\d.]+(?=")' \
    | sed 's/v//g' \
    | sort -r \
    | head -n 1
)
generateDenoRecipes $version
