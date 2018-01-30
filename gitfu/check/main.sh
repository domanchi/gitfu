#!/bin/bash
source $GITFU_BASE/gitfu/common/input.sh

function usage() {
cat << EOF
Usage: git check [<file>]
Performs git diff (to make sure you're checking in the right thing), then
prompts to add to staged files.
EOF
}

function checkAndPrompt() {
    # Usage: checkAndPrompt "<file>"
    local file=$1

    git diff "$file"
    if [[ $? != 0 ]]; then
        return 1
    fi

    echo ""
    promptUserContinue "Do you want to add this file?"
    if [[ $? == 0 ]]; then
        git add "$file"
    fi
    return 0
}

function main() {
    while getopts "h" opt; do
        case $opt in
            h)
                usage
                return 0
                ;;
        esac
    done
    shift $((OPTIND-1))

    if [[ $# == 0 ]]; then
        local file
        for file in `git diff --name-only`; do
            checkAndPrompt "$file"
            if [[ $? == 1 ]]; then
                echo "skipping "$file"..."
            fi
        done
    else
        checkAndPrompt "$1"
    fi
}

main "$@"
