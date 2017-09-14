#!/bin/bash

GITFU="$GITFU_BASE/gitfu"

source $GITFU_BASE/.config
source $GITFU/common/git.sh

function usage() {
    echo "switch_branch (sb) allows quick movement between git branches, for overly long branch names.";
    echo "Usage: sb [-f] (<query>)";
    echo "  query is an optional parameter, that greps the branch name to switch to."
    echo "  When run without parameters, switch_branch will list the branches that can be switched to."
    echo ""
    echo "Flags:"
    echo "  -f : forces the switch (git checkout all conflicting files)"
    echo "  -h : shows this message"
    echo "  -s : git stash changes, then apply stash on branch switch."
}

function getBranch() {
    # Usage: getBranch <search_query>
    local branch=$($GIT branch | grep "$1")

    if [[ "$branch" = "" ]]; then
        echo "No git branch found with that query."
        return 1

    elif [[ $(echo "$branch" | wc -w) -gt 1 ]]; then
        echo "Multiple git branches found. Try a different query."
        return 1
    fi

    echo "$branch"
    return 0
}

function getAffectedFileList() {
    # Usage: getAffectedFileList "<error_message_from_git>"
    #
    # The error response is in format:
    #
    # ```
    # <expected error message>
    # <list of files>
    # Please commit your changes...
    # Aborting
    # ```
    #
    # There's probably a better sed way to do this, this will do.

    # First, we convert the list of files into space-delimited file list.
    local filelist=""
    while read -r line; do
        filelist="$filelist$line "
    done <<< "$(echo "$1" | sed '1d;$d;' | sed '$d')"

    # Then, we remove trailing whitespace (needed for git patch)
    filelist=$(echo -e "$filelist" | sed -e 's/[[:space:]]*$//')
    
    echo "$filelist"
}

function checkoutAffectedFiles() {
    # Usage: checkoutAffectedFiles "<error_message_from_git>"

    # Want to only checkout the files that will be overriden,
    # because if you checkout everything, you might lose files that
    # you wanted to keep.
    local filelist=$(getAffectedFileList "$1")

    git checkout -- $filelist
}

function switchBranch() {
    # Usage: switchBranch <branch_to_switch_to>
    # Return Codes:
    #   - 2 : local unsaved changes will be overriden

    local branch=$1

    # First, attempt changing branches.
    local errorMsg
    local errorCode
    errorMsg=$(git checkout $branch 2>&1)
    errorCode=$?
   
    echo "$errorMsg"
    if [[ $errorCode == 0 ]]; then
        return 0
    fi

    # Unfortunately, all failed git checkouts return 1 as an error code.
    # In order to distinguish their differences, we need to do string
    # comparisons for their expected error messages.
    local localUnsavedChangesError=`echo 'error: Your local changes to the' \
        'following files would be overwritten by checkout:'`
    $GITFU/common/string.sh "startsWith" "$errorMsg" "$localUnsavedChangesError"
    if [[ $? == 0 ]]; then
        return 2
    fi

    # TODO: Probably perform the following steps:
    #   - change to .bak
    #   - change back and override.
    local localUntrackedChangesError=`echo 'error: The following untracked' \
        ' working tree files would be overwritten by checkout:'`

    
    # If it's not one of the errors we can handle, just return the error
    # message that git gave us.
    return $errorCode
}

function main() {

    local forceFlag=false
    local stashFlag=false

    # getopt process.
    while getopts "hsf" opt; do
        case $opt in
            h)
                usage
                return 0
                ;;

            f)
                forceFlag=true
                ;;

            s)
                stashFlag=true
                ;;
        esac
    done
    shift $((OPTIND-1))

    if [[ $# == 0 ]]; then
        echo "These are the branches you can switch to:"
        git branch
        return 0
    fi

    local branchName
    branchName=$(getBranch "$1")
    if [[ $? != 0 ]]; then
        echo "$branchName"      # error stored in this
        return 1
    fi

    local errorMsg
    errorMsg=$(switchBranch $branchName)
    local errorCode=$?
    if [[ $errorCode == 0 ]]; then
        echo "$errorMsg"
        return 0

    elif [[ $errorCode == 2 ]]; then
        if [[ $forceFlag == 'true' ]]; then
            checkoutAffectedFiles "$errorMsg"

            # Attempt it one more time, and if it fails then just display
            # original failure message.
            switchBranch $branchName
            return $?

        elif [[ $stashFlag == 'true' ]]; then
            # Stash changes, change branch, then apply changes
            echo "TODO: Fix stash?"
            return 1

            git stash
            switchBranch $branchName
            git stash pop
        fi

        echo -e "$errorMsg\n"
        echo ">> Rerun switch_branch with either -s or -f flags to rectify."
        return 1

    else
        echo -e "TODO: switch_branch needs to be updated to handle this case\n"
        echo "$errorMsg"
        return 1
    fi
}

main "$@"
