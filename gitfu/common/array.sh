#!/bin/bash
# This file contains array-helper logic.

source $GITFU_BASE/gitfu/common/main.sh

function containsElement() {
    # Usage: containsElement "<search_string>" "${array[@]}"
    # Returns 0 if array contains <search_string>
    local e
    for e in "${@:2}"; do 
        if [[ "$e" == "$1" ]]; then
            return 0
        fi
    done
    return 1
}

function special_main() {
    # Usage: special_main "$@"
    # Since `main` needs containsElement, this makes sure that no
    # infinite recursive calls are made.
    if [[ "$1" == "containsElement" ]]; then
        shift
        runCommonFunction "containsElement" "$@"
        return $?
    else
        main ${0} "$@"
    fi
}

special_main "$@"
