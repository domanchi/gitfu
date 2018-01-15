#!/bin/bash
source $GITFU_BASE/gitfu/common/input.sh

function usage() {
cat << EOF
Usage: git check <file>
Performs git diff (to make sure you're checking in the right thing), then
prompts to add to staged files.
EOF
}

function main() {
    if [[ $# == 0 ]]; then
        usage
        return 1
    fi

    local file=$1
    
    git diff "$file"
    echo ""
    promptUserContinue ">>> Do you want to add this file?"
    if [[ $? == 0 ]]; then
        git add "$file"
    fi
}

main "$@"
