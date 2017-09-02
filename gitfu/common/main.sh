#!/bin/bash
# This file is to provide a standardized DRY manner to call common functions.
# This should be `source`d in all common files.

function runCommonFunction() {
    # Usage: runCommonFunction "<function_name>" "$@"
    local fn=$1
    shift

    local output
    local returnCode

    output=$($fn "$@")
    returnCode=$?

    echo "$output"
    return $returnCode
}

function main() {
    # Usage: main ${0} "<function_to_execute>" "$@"
    local filepath=$1
    local fn=$2
    shift
    shift

    # Get all functions available from filepath.
    local fns=()
    while read -r line; do                                                      
        local functionName=$(echo $line | cut -d ' ' -f 2 | cut -d '(' -f 1)

        # Append to array
        fns+=("$functionName")

    done <<< "$(grep '^function [a-zA-Z_]\(\)' $filepath)"

    $GITFU_BASE/gitfu/common/array.sh "containsElement" "$fn" "${fns[@]}"
    if [[ $? == 0 ]]; then
        runCommonFunction "$fn" "$@"
        return $?
    fi
}
