#!/bin/bash
# This file contains logic for keeping your local repository synced with
# your designated remote repository.

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
    `$GITFU/common/array.sh "containsElement" "$1" "${cmds[@]}"`
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
        # Committing in dev only updates your local history, but doesn't
        # do anything else. However, when we push, we need to update our
        # local history with the **real** history.
        executeRemoteGitCommand $repo $@
        if [[ $? != 0 ]]; then
            # Error message already displayed in executeRemoteGitCommand
            return 2
        fi

        # Parse remote name, and branch name (based on `git push` documentation).
        local remoteRepoName
        local branchName
        local param
        for param in "${@:2}"; do
            `$GITFU/common/string.sh startsWith "$param" "--"`
            if [[ $? != 0 ]] && [[ "$branchName" == "" ]]; then
                if [[ "$remoteRepoName" == "" ]]; then
                    remoteRepoName=$param
                else
                    branchName=$param
                fi
            fi
        done

        $GITFU/common/array.sh containsElement "--delete" "$@"
        if [[ $? != 0 ]]; then
            # NOTE: Can't be reset origin/HEAD, from git push origin HEAD
            if [[ "$branchName" == "HEAD" ]]; then
                branchName=`git rev-parse --abbrev-ref HEAD`
            fi
            
            # Align local with remote.
            $GIT fetch $remoteRepoName
            $GIT reset $remoteRepoName/$branchName 
        fi
 
        return 0
    fi    

    return 0
}

function main() {
    # Return values:
    #   - 0 if successful.
    #   - 1 if soft error (keep trying the git command locally only)
    #   - 2 if hard error (immediately quit)

    local syncDirLength=$($GITFU/common/string.sh \
        'getStringLength' "$LOCAL_SYNC_DIR")
    local workdir=${PWD:0:$syncDirLength}

    if [[ "$1" == "sync" ]]; then
        # Manually check sync (without running git commands)
        if [[ "$workdir" != "$LOCAL_SYNC_DIR" ]]; then
            echo "Not in synced repo!"
            return 1    # This goes straight to main's return value
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
        # We check to make sure that current directory is not `pwd`, because
        # we *only* want to sync repos under the $LOCAL_SYNC_DIR, not arbitrary files.
        if [[ "$workdir" != "$LOCAL_SYNC_DIR" ]] || \
           [[ "$workdir" == `pwd` ]]; then
            return 1
        fi

        serverSync "$@"
        return $?
    fi
}

main "$@"
