#!/bin/bash
# This file contains string-helper logic.

source $GITFU_BASE/gitfu/common/main.sh

function getStringLength() {
    # Usage: getStringLength "<string>"
    local string=$1
    echo "${#string}"
}

function startsWith() {
    # Usage: startsWith "<string>" "<prefix>"
    echo "$1" | head -1 | grep "^$2" > /dev/null
    return $?
}

main ${0} "$@"
