#!/bin/bash
# This file contains array-helper logic.

source $GITFU_BASE/gitfu/common/main.sh

function getStringLength() {
    # Usage: getStringLength "<string>"
    local string=$1
    echo "${#string}"
}

main ${0} "$@"
