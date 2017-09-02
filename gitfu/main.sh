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
    # We check to make sure that current directory is not `pwd`, because
    # we *only* want to sync repos under the $LOCAL_SYNC_DIR, not arbitrary files.
    if [[ "$workdir" == "$LOCAL_SYNC_DIR" ]] && \
       [[ "$workdir" != `pwd` ]]; then
        $GITFU/sync/main.sh "$@"
    fi

    # Default git management
    $GIT "$@"
}

main "$@"
