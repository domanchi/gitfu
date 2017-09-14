#!/bin/bash
# This file is to provide a standardized DRY manner to run commands on the
# remote server.
# This should be `source`d in all sync files.

source $GITFU_BASE/.config

function executeRemoteGitCommand() {
    # Usage: executeRemoteGitCommand <repo> *args 
    # Returns the output of executed command if successful;
    # otherwise, returns the error code from the git command that failed.

    local repo=$1
    shift

    # NOTE: Looks like this is only needed when sent to the server,
    #       and fails when attempted to do the same thing locally.
    local args=$(printf "'%s' " "$@")

    # NOTE: We need to define the local variable first, so that the
    #       error code is properly caught.
    #       https://unix.stackexchange.com/a/66583
    #
    # NOTE: We don't want server error messages to appear to the user,
    #       so we pipe it to stdout and manage it there.
    local output
    output=$(ssh $DEVBOX "cd $REMOTE_SYNC_DIR$repo; git $args 2>&1")

    # Save the error code, otherwise, the next execution will change it.
    local errorCode=$?

    if [[ $errorCode != 0 ]]; then
        echo "$output"
        return $errorCode
    fi

    echo "$output"
}


