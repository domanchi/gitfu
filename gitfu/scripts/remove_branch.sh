#!/bin/bash

GITFU="$GITFU_BASE/gitfu"

source $GITFU_BASE/.config
source $GITFU/common/git.sh
source $GITFU/common/input.sh

function usage() {
    echo "remove_branch (rmb) cleans up an inactive branch, both locally and on the remote repo."
    echo "Usage: rmb [-fr] <branch-name>"
    echo
    echo "Flags:"
    echo "  -h : shows this message"
    echo "  -r : specifies the remote repo. Default: origin"
}

function deleteLocalBranch() {
    # Usage: deleteLocalBranch <branch-name> <force>
    # Params:
    #   - branch-name: string; branch to delete.
    #   - force: integer (0 for false). Will denote whether to force delete.

    local branchName=$1
    local forceFlag=$2

    # First, make sure that the branch actually exists.
    # Faster to do this, than catching the error after attempting.
    git branch | grep "^[* ] $branchName$"
    if [[ $? == 1 ]]; then
        echo "error: Branch '$branchName' not found in local repo!"
        return 2
    fi

    local errorMsg
    if [[ $forceFlag == 0 ]]; then
        errorMsg=$(git branch -d "$branchName" 2>&1)
    else
        errorMsg=$(git branch -D "$branchName" 2>&1)
    fi

    if [[ $? != 0 ]]; then
        echo "TODO"
        echo "$errorMsg"
        return 1
    fi

    echo "Removed local branch '$branchName'."
    return 0
}

function deleteRemoteBranch() {
    # Usage: deleteRemoteBranch <branch-name> <remote-repo>
    # Params:
    #   - branch-name: string; branch to delete.
    #   - remote-repo: string; name of remote repo.
    
    local branchName=$1
    local remoteRepo=$2

    # First, make sure that the branch actually exists.
    # Faster to do this, than catching the error after attempting.
    git branch -a | grep "^[* ] remotes/$remoteRepo/$branchName$"
    if [[ $? == 1 ]]; then
        echo "error: Branch '$branchName' not found in remote repo!"
        return 2
    fi

    local errorMsg
    errorMsg=$(git push $remoteRepo --delete "$branchName" 2>&1)
    if [[ $? != 0 ]]; then
        echo "TODO"
        echo "$errorMsg"
        return 1
    fi

    echo "Removed remote branch '$branchName'."
    return 0
}

function main() {

    local forceFlag=0
    local remoteRepo='origin'
   
    # getopt process
    while getopts "hf" opt; do
        case $opt in
            h)
                usage
                return 0
                ;;

            f)
                forceFlag=1
                ;;

            r)
                remoteRepo=${ARGS[$OPTIND-2]}
                ;;
        esac
    done
    shift $((OPTIND-1))

    if [[ $# == 0 ]]; then
        usage
        return 0
    fi

    local errorCode

    deleteLocalBranch "$1" forceFlag
    errorCode=$?
    if [[ $errorCode == 1 ]]; then
        return 1

    elif [[ $errorCode == 2 ]]; then
        promptUserContinue "Do you want to continue?"
        if [[ $? == 1 ]]; then
            return 0
        fi
    fi

    deleteRemoteBranch "$1" "$remoteRepo"
    return $?
}

main "$@"
