#!/bin/bash
# Define the script path
scriptPath="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd && cd - >/dev/null 2>&1 )"

# Function to generate Node.js recipes
generateNodeRecipes() {
    local version=$1
    local majorVersion=$(echo $version | cut -d. -f1)
    local filename=${scriptPath}/node-runtime-${majorVersion}.levain.yaml

    echo "=== Node.js ${version} (major version ${majorVersion}) at ${filename}"
    mkdir -p $(dirname $filename)

    cat <<EOF > ${filename}
version: ${version}

dependencies:

downloadUrl: https://nodejs.org/dist/v${version}/node-v${version}-win-x64.zip

cmd.install:
    - extract --strip \${downloadUrl} \${baseDir}
    - setEnv --permanent NODE_HOME \${baseDir}

cmd.env:
    - addPath --permanent \${baseDir}
    - setEnv NODE_VERSION ${version}
EOF
}

# Fetch Node.js versions from the official Node.js release API
# Update to 
versions=$(curl -s https://nodejs.org/dist/index.json \
    | sed 's/{"version/\n{"version/g' \
    | grep '"lts":"[^"]*"' \
    | sed 's/.*\"version\":\"v\([0-9.]\+\)".*/\1/g' \
    | grep '[0-9]' \
    | sort -Vr)

# Generate recipes for the latest version of each major release
for major in $(echo "$versions" | cut -d. -f1 | uniq); do
    latest=$(echo "$versions" | grep "^$major\." | head -n 1)
    generateNodeRecipes $latest
done

### Update latest
latest=$(echo "$versions" | cut -d. -f1 | uniq | head -n 1)
cat <<EOF > ${scriptPath}/node-runtime-latest.levain.yaml
version: $latest

levain.pkg.skipInstallDir: true

dependencies:
    - node-runtime-$latest
EOF