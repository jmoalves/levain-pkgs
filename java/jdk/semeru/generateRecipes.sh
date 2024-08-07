#!/bin/bash

scriptPath="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd && cd - >/dev/null 2>&1 )"

####################################################
### Functions
####################################################

generateJdkRecipe() {
    local filename=$1
    local adjustedVersion=$2
    local zipPath=$3

    mkdir -p $( dirname ${filename})
    cat <<-EOF > ${filename}
version: ${adjustedVersion}

dependencies:

downloadUrl: https://github.com/ibmruntimes/semeru${jdkMajor}-binaries/releases/download
javaHome: \${baseDir}

cmd.install:
    - extract --strip \${downloadUrl}/${zipPath} \${baseDir}
    - setEnv --permanent JAVA${jdkMajor}_HOME \${javaHome}
    - addPath --permanent \${javaHome}/bin

cmd.env:
    - addPath \${javaHome}/bin
    - setEnv JAVA_HOME \${javaHome}
EOF
}

javaGithub() {
    # https://stackoverflow.com/questions/16654607/using-getopts-inside-a-bash-function
    local OPTIND OPTARG o

    while getopts "v:" o; do
        case "${o}" in
        v) jdkMajor="${OPTARG}";;
        *)
            echo Invalid options
            exit 1
            ;;
        esac
    done
    shift $((OPTIND - 1))

    # Java GITHUB
    echo
    echo = Java ${jdkMajor}

    local jdkType=jdk
    local binType=x64_windows
    local extension=zip
    local grepExpression=".*/download/jdk.*${jdkType}_${binType}.*[0-9]\.${extension}$"
    local certifiedJDK=
    for url in $( \
        curl -kLs \
            -H "Accept: application/vnd.github+json" \
            https://api.github.com/repos/ibmruntimes/semeru${jdkMajor}${certifiedJDK}-binaries/releases \
        | jq -r '.[]|select(.prerelease == false)| .assets[].browser_download_url ' \
        | grep "${grepExpression}"
    ); do
        # echo
        # echo URL: ${url}
        if [ $jdkMajor = 8 ]; then
            version='8.0.'$( echo ${url} | sed 's@^.*/download/jdk8u\([0-9]\+\).*.\.\([0-9]\+\)/.*$@\1.\2@g' )
        else
            version=($( echo ${url} | sed 's@^.*/download/jdk-\([^%]\+\).*$@\1@g' ))
        fi

        my_arr=($( echo ${version} | tr "." "\n" ))
        if [ "${my_arr[3]}" == "" ]; then
            adjustedVersion=${my_arr[0]}.${my_arr[1]}.${my_arr[2]}.0
        else
            adjustedVersion=$version
        fi

        filename=${scriptPath}/jdk-${jdkMajor}/jdk-${jdkMajor}-ibm-${adjustedVersion}.levain.yaml
        if [ ! -e $filename ]; then
            echo === MISSING - JDK version - ${adjustedVersion} at ${filename}
            zipPath=($(echo ${url} | sed 's@^.*/download/@@g'))
            # echo ZIP: ${zipPath}
            generateJdkRecipe ${filename} ${adjustedVersion} ${zipPath}
        fi
    done

    ### Update latest
    latest=$( \
        find ${scriptPath}/jdk-${jdkMajor} -name 'jdk-*.levain.yaml' \
            | grep -v latest \
            | sed 's/\.\([0-9]\)\./.0\1\./g' \
            | sed 's/\.\([0-9]\)\./.0\1\./g' \
            | sed 's/\.\([0-9]\{2\}\)\./.0\1\./g' \
            | sed 's/\.\([0-9]\{2\}\)\./.0\1\./g' \
            | sed 's/.*jdk-.*-\([0-9.]\+\).levain.yaml.*/\1/g' \
            | sort -r \
            | sed 's/\.0\+\([1-9]\+\)/.\1/g' \
            | sed 's/\.0\+0/.0/g' \
            | head -n 1
    )

    cp ${scriptPath}/jdk-${jdkMajor}/jdk-${jdkMajor}-ibm-${latest}.levain.yaml ${scriptPath}/jdk-${jdkMajor}/jdk-${jdkMajor}-ibm-latest.levain.yaml
    cp ${scriptPath}/jdk-${jdkMajor}/jdk-${jdkMajor}-ibm-${latest}.levain.yaml ${scriptPath}/jdk-${jdkMajor}-ibm.levain.yaml
}

####################################################
### MAIN
###

javaGithub -v 21 # LTS
javaGithub -v 17 # LTS
javaGithub -v 11 # LTS
javaGithub -v 8  # LTS
