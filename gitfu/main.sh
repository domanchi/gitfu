#!/bin/bash
# This file lives separate from the eco-system, because it's written in
# the new paradigm. It should only be called directly, and not sourced.
#
# In general, I use these return codes:
#   - 0 if successful.
#   - 1 if soft error (keep trying the git command locally only)
#   - 2 if hard error (immediately quit)

source $GITFU_BASE/.config  

GITFU="$GITFU_BASE/gitfu"

function isLastCommitWIP() {
    # Usage: isLastCommitWIP
    # Returns 0 if true.

    # NOTE: We use `sed` to remove whitespace.
    if [[ `$GIT log -n 1 --pretty=%B | sed /^$/d` == "wip" ]]; then
        return 1
    fi
    return 0
}

function main() {

    # I use a diff alias, so I need to manually resolve this back to `diff`
    # when using this git interceptor.
    if [[ "$1" == "colordiff" ]]; then
        set -- "diff" "${@:2}"
    fi

    # Check to see if the last commit was "wip".
    # This allows for per-branch stashing.
    if [[ "$1" == "commit" ]]; then
        isLastCommitWIP
        if [[ $? == 1 ]]; then
            echo 'You have a WIP commit'
            return 1
        fi
    fi

    # Add your custom git commands here.
    case $1 in
        edit)
            cd $GITFU_BASE
            vim git_wrapper/main.sh
            return 0
            ;;
           
        sync)
            $GITFU/sync/main.sh "$@"
            return $?
            ;;
    esac

    # Special server synchronization.
    $GITFU/sync/main.sh "$@"
    local errorCode=$?
    case $errorCode in
        0)
            return 0
            ;;
        1)
            # Fall through to normal git operations
            #echo "Something went wrong when communicating with server. Continue?"
            ;;
        2)
            return 1
            ;;
    esac

    # Default git management
    $GIT "$@"
}

main "$@"
