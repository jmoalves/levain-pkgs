#!/bin/bash

scriptPath="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd && cd - >/dev/null 2>&1 )"

template=${scriptPath}/openliberty-runtime-template.yaml
for version in $( \
    curl -kLs https://public.dhe.ibm.com/ibmdl/export/pub/software/openliberty/runtime/release/ | grep -o 'href=".*/">' | sed 's/.*href="\(.*\)\/".*/\1/g' | grep '^[0-9]\{2\}\.' \
); do
    my_arr=($( echo ${version} | tr "." "\n" ))
    year=${my_arr[0]}
    unset my_arr

    filename=${scriptPath}/${year}/openliberty-runtime-${version}.levain.yaml
    if [ ! -e ${filename} ]; then
        echo === MISSING ${version} at ${filename}
		mkdir -p $( dirname $filename )
        cat ${template} | sed "s/x.x.x.x/${version}/g" > ${filename}
    fi
done

### Update latest
latest=$( \
    find -name 'openliberty-*.levain.yaml' \
        | grep -v latest \
        | sort -r \
        | head -n 1 \
        | sed 's/.*openliberty-runtime-\([0-9.]\+\).levain.yaml.*/\1/g'
)

cat <<EOF > ${scriptPath}/openliberty-runtime-latest.levain.yaml
version: $latest

levain.pkg.skipInstallDir: true

dependencies:
    - openliberty-runtime-$latest
EOF
