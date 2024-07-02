#!/bin/bash

scriptPath="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd && cd - >/dev/null 2>&1 )"

template=${scriptPath}/wlp-runtime-template.yaml
for version in $( \
    curl -kLs https://public.dhe.ibm.com/ibmdl/export/pub/software/websphere/wasdev/downloads/wlp/ | grep -o 'href=".*/">' | sed 's/.*href="\(.*\)\/".*/\1/g' | grep '^[0-9]' \
); do
    my_arr=($( echo ${version} | tr "." "\n" ))
    year=${my_arr[0]}
    unset my_arr

    if [ "${year}" == "8" ]; then
        # Ignore wlp 8.5.*
        continue
    fi

    filename=${scriptPath}/${year}/wlp-runtime-${version}.levain.yaml
    if [ ! -e ${filename} ]; then
        echo === MISSING ${version} at ${filename}
        cat ${template} | sed "s/x.x.x.x/${version}/g" > ${filename}
    fi
done

### Update latest
latest=$( \
    find -name 'wlp-runtime-*.levain.yaml' \
        | grep -v latest \
        | sort -r \
        | head -n 1 \
        | sed 's/.*wlp-runtime-\([0-9.]\+\).levain.yaml.*/\1/g'
)

cat <<EOF > ${scriptPath}/wlp-runtime-latest.levain.yaml
version: $latest

levain.pkg.skipInstallDir: true

dependencies:
    - wlp-runtime-$latest
EOF
