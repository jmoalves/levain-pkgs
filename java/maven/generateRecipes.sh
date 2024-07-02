#!/bin/bash

# Define the script path and the template file
scriptPath="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd && cd - >/dev/null 2>&1 )"
template=${scriptPath}/maven-template.yaml

# Function to generate Maven recipes
generateMavenRecipes() {
    if [ "$1" == ".." ]; then
        return
    fi

    local version=$1
    local simpleVersion=$(echo $version | sed 's/\([0-9]\+\.[0-9]\+\)\..*/\1/g')
    local filename=${scriptPath}/maven-${simpleVersion}.levain.yaml

    # Check if the recipe file already exists
    # if [ ! -e ${filename} ]; then
        # echo "=== MISSING Maven ${simpleVersion} at ${filename}"
        mkdir -p $(dirname $filename)
        cat ${template} \
            | sed "s/x.x.x/${version}/g" \
            > ${filename}
    # fi
}

# Fetch Maven versions from the official Maven repository
for version in $(
        curl -s https://repo.maven.apache.org/maven2/org/apache/maven/apache-maven/ \
            | grep -oP 'href="\K[\d.]+(?=/")' \
            | grep '^3\.' \
            | sort -r \
            ) ; do
    generateMavenRecipes $version
done

### Update latest
latest=$(find -name 'maven-*.levain.yaml' \
        | grep -v latest \
        | sort -r \
        | head -n 1 \
        | sed 's/.*maven-\([0-9.]\+\).levain.yaml.*/\1/g'
)
cat <<EOF > ${scriptPath}/maven-latest.levain.yaml
version: $latest

dependencies:
    - maven-$latest
EOF