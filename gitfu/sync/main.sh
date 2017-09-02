#!/bin/bash
# This file contains logic for keeping your local repository synced with
# your designated remote repository.
#
# In general, I use these return codes:
#   - 0 if successful.
#   - 1 if soft error (keep trying the git command locally only)
#   - 2 if hard error (immediately quit)

GITFU="$GITFU_BASE/gitfu"

source $GITFU_BASE/.config  
source $GITFU/sync/execute.sh

function getCurrentRepo() {
    # Usage: getCurrentRepo
    # Returns the repo folder you are currently in.
    # MUST be within $LOCAL_SYNC_DIR, otherwise, unexpected results.

    local syncDirLength=$($GITFU/common/string.sh \
        'getStringLength' "$LOCAL_SYNC_DIR")
    local python_cmd=$(echo "path='`pwd`'; print reduce(lambda x,y : x + '/' + y," \
        "path[$syncDirLength:].split('/')[:2])")
    local repo=$(python2.7 -c "$python_cmd")

    echo "$repo"
}

function serverSync() {
    # Usage: serverSync "$@"
    # Attempts to sync git commands with the server.
    # MUST be within $LOCAL_SYNC_DIR, otherwise, unexpected results.

    local repo=$(getCurrentRepo)
    if [[ -f "$LOCAL_SYNC_DIR$repo/.sync_ignore" ]]; then
        # This functionality allows us to ignore repos of our choosing.
        return 1
    fi

    local cmds=("commit" "add" "push" "reset" "checkout" "pull")
    $GITFU_BASE/common/array.sh "containsElement" "$1" "${cmds[@]}"
    if [[ $? == 1 ]]; then
        # We only need to sync a subset of git commands
        return 1
    fi

    # Perform sync checks
    $GITFU/sync/checks.sh $repo "$@"
    local errorCode=$?
    if [[ $errorCode != 0 ]]; then
        return $errorCode
    fi

    # This will bundle multi-word arguments together, as expected.
    if [[ "$1" != "push" ]]; then
        # For all commands except push, FIRST try local copy.
        # Only if succeeds, then attempt on server.
        $GIT "$@"
        if [[ $? != 0 ]]; then
            return 2
        fi

        $((executeRemoteGitCommand $repo "$@") > /dev/null)
        return 0

    else
        echo "TODO"
        return 2
        # Committing in dev only updates your local history, but doesn't
        # do anything else. However, when we push, we need to update our
        # local history with the **real** history.
        executeRemoteGitCommand $repo "$@"
        if [[ $? != 0 ]]; then
            return 2
        fi

        # NOTE: Stashing changes and popping them later shouldn't do
        #       anything, because there's not going to be any merge conflicts
        #       with our own changes.
        # TODO
        $GIT stash
        $GIT "pull" "$args"
        $GIT "stash" "pop"
    
        return 0
    fi    

    return 0
}

function main() {
    local syncDirLength=$($GITFU/common/string.sh \
        'getStringLength' "$LOCAL_SYNC_DIR")
    local workdir=${PWD:0:$syncDirLength}

    if [[ "$1" == "sync" ]]; then
        # Manually check sync (without running git commands)
        if [[ "$workdir" != "$LOCAL_SYNC_DIR" ]]; then
            echo "Not in synced repo!"
        fi

        local repo=$(getCurrentRepo)
        $GITFU/sync/checks.sh $repo "all"
        if [[ $? == 0 ]]; then
            echo "Everything in sync!"
        else
            echo "Checks completed."
        fi

        return 0

    else
        serverSync "$@"
        local errorCode=$?
        case $errorCode in
            0)
                return 0
                ;;
            1)
                #echo "Something went wrong when communicating with server. Continue?"
                ;;
            2)
                return 1
                ;;
        esac
    fi
}

main "$@"
