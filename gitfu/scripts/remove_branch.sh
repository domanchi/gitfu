#!/bin/bash

GITFU="$GITFU_BASE/gitfu"

source $GITFU_BASE/.config
source $GITFU/common/git.sh

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

    local errorMsg
    if [[ $forceFlag == 0 ]]; then
        errorMsg=$(git branch -d "$branchName")
    else
        errorMsg=$(git branch -D "$branchName")
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

    local errorMsg
    errorMsg=$(git push $remoteRepo --delete $branchName)
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

    deleteLocalBranch "$1" forceFlag
    if [[ $? == 1 ]]; then
        return 1
    fi

    deleteRemoteBranch "$1" "$remoteRepo"
    return $?
}

main "$@"
