#!/bin/bash
# Define the script path
scriptPath="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd && cd - >/dev/null 2>&1 )"

# Function to generate jq recipes
generateJqRecipes() {
    local version=$1
    local filename=${scriptPath}/jq.levain.yaml
    echo "=== jq ${version} at ${filename}"
    mkdir -p $(dirname $filename)
    cat <<EOF > ${filename}
version: ${version}

dependencies:

downloadUrl: https://github.com/stedolan/jq/releases/download/jq-${version}

cmd.install:
    - extract \${downloadUrl}/jq-win64.exe \${baseDir}/jq.exe

cmd.env:
    - addPath \${baseDir}
EOF
}

# Fetch jq versions from GitHub releases
versions=$(curl -Ls https://api.github.com/repos/stedolan/jq/releases \
    | grep -oP '"tag_name": "\Kjq-[\d.]+(?=")' \
    | sed 's/jq-//g' \
    | sort -Vr)

# Generate recipes for the latest version
latest=$(echo "$versions" | head -n 1)
generateJqRecipes $latest
