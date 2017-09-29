#!/bin/bash
# This file contains the heuristic checks to determine whether the
# git repo is in sync with the server.

GITFU="$GITFU_BASE/gitfu"

source $GITFU_BASE/.config
source $GITFU/sync/execute.sh

function isGitRepo() {
    # Usage: isGitRepo <repo>
    # Returns 0 if both local path and synced server path is a git repo.
    
    # We use `git branch` because it's fast to execute, and quick to determine
    # whether you're currently in a git repo. Also, it doesn't have any
    # "persistent" effects.
    local localEnv
    localEnv=$($GIT branch 2>&1)
    if [[ $? != 0 ]]; then
        echo "Not currently in git repo."
        return 2
    fi

    local remoteEnv
    remoteEnv=$(executeRemoteGitCommand $1 "branch")
    if [[ $? != 0 ]]; then
        echo "Remote repo not set up."
        return 1
    fi

    return 0
}

function outputListOfFiles() {
    # Usage: outputListOfFiles <filelist> <default_value_if_no_files>
    # Outputs the list of files in a nice human readable format.
    # Mainly used for doStagedFilesMatch.
    if [[ $1 == "" ]]; then
        echo "$2"
    else
        local line
        echo "$1" | while read line
        do
            echo "   ${line}"
        done
    fi
}

function doStagedFilesMatch() {
    # Usage: doStagedFilesMatch <repo>
    # Checks to see if staged files are synced.
    local cmd=("diff" "--staged" "--full-index")

    local localEnv
    local remoteEnv

    localEnv=$(GIT ${cmd[@]})
    remoteEnv=$(executeRemoteGitCommand $1 ${cmd[@]})
    if [[ "$localEnv" != "$remoteEnv" ]]; then
        echo "Staged files do not match."

        # Write to temp file, then diff.
        if [[ ! -d $GITFU_BASE/tmp ]]; then
            mkdir $GITFU_BASE/tmp
        fi

        echo "$localEnv"  > $GITFU_BASE/tmp/local.files
        echo "$remoteEnv" > $GITFU_BASE/tmp/remote.files
        echo -e "\ndiff local_branch..remote_branch"
        colordiff $GITFU_BASE/tmp/local.files $GITFU_BASE/tmp/remote.files 
        rm $GITFU_BASE/tmp/local.files
        rm $GITFU_BASE/tmp/remote.files

        return 2
    fi

    return 0
}

function doBranchesMatch() {
    # Usage: doBranchesMatch <repo>
    # Check to see if you're on the same branch locally, as on the server.
    local cmd=("rev-parse" "--symbolic-full-name" "HEAD")

    local localEnv
    local remoteEnv

    localEnv=$(GIT ${cmd[@]})
    remoteEnv=$(executeRemoteGitCommand $1 ${cmd[@]})
    if [[ "$localEnv" != "$remoteEnv" ]]; then
        echo "Commit history does not match."
        echo "Local Branch:  ${localEnv}"
        echo "Remote Branch: ${remoteEnv}"

        return 2
    fi

    return 0
}

function doCommitsMatch() {
    # Usage: doCommitsMatch <repo>
    # Check to see if the last commit message is the same.
    # NOTE: We don't check the last commit hash, because that's expected
    #       to be different. After all, our local copy is just a mirror:
    #       we aren't saying they should be identical.

    local cmd=("log" "-1" "--pretty=%B")
    
    local localEnv
    local remoteEnv

    localEnv=$(GIT ${cmd[@]})
    remoteEnv=$(executeRemoteGitCommand $1 ${cmd[@]})
    if [[ "$localEnv" != "$remoteEnv" ]]; then
        echo "Commit history does not match."
        echo "Local Branch:  ${localEnv}"
        echo "Remote Branch: ${remoteEnv}"

        return 2
    fi

    return 0
}

function doesFileExistOnServer() {
    # Usage: doesFileExistOnServer <repo> <filename>

    # Filepath must be relative to the root of the repo.
    local filepath="`pwd`/$2"
    local prefix=`$GITFU/common/string.sh "getStringLength" $LOCAL_SYNC_DIR$repo`
    filepath=${filepath:$prefix + 1}    # excludes prefix-ed slash

    local cmd="if [[ -f '$filepath' ]]; then echo 0; else echo 1; fi"

    local localEnv
    local remoteEnv

    localEnv=$(bash -c "$cmd")
    remoteEnv=$(ssh $DEVBOX "cd $REMOTE_SYNC_DIR$repo; bash -c '$cmd' 2>&1")
    if [[ "$localEnv" != "$remoteEnv" ]]; then
        if [[ "$localEnv" == 1 ]]; then
            local location="locally"
        else
            local location="on server"
        fi

        echo "File '$2' does not exist ${location}."
        return 2
    fi

    return 0
}

function main() {
    # Usage: main <repo> <git_command_to_execute>
    # Performs a variety of heuristic checks to determine whether
    # local repo and server repo are in sync.
 
    local repo=$1 
    local cmd=$2

    # First determine whether it is in a git repo at all. 
    local errorMsg
    local errorCode 
    errorMsg=$(isGitRepo $repo)
    errorCode=$?
    if [[ $errorCode != 0 ]]; then
        echo "$errorMsg"
        return $errorCode
    fi

    # Determine which checks to run
    local checks
    case $cmd in
        add)
            doesFileExistOnServer $repo $3
            return $?
            ;;

        commit)
            checks=("doBranchesMatch" "doCommitsMatch" "doStagedFilesMatch")
            ;;

        all)
            checks=("doBranchesMatch" "doCommitsMatch" "doStagedFilesMatch")
            ;;
    esac 

    # Run the checks
    local finalErrorCode=0
    local errorCode
    for check in ${checks[@]}; do
        if [[ "$cmd" == "all" ]]; then
            echo "Running $check..."
        fi

        $check $repo
        errorCode=$?
        if [[ $errorCode != 0 ]]; then
            if [[ "$cmd" == "all" ]]; then
                # Better formatting.
                echo ''
                finalErrorCode=$errorCode
            else
                # Fail on first error
                return $errorCode
            fi
        fi
    done

    return $finalErrorCode
}

main "$@"
