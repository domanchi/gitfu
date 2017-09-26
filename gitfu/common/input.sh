#!/bin/bash
# This file provides the ability to request user input for certain actions.
#
# `source` this file when needed.

source $GITFU_BASE/gitfu/common/main.sh


function promptUserContinue() {
    # Usage: promptUserContinue "$messageToDisplay"
    # Prompts user input to see whether to continue operations.
    # Returns 0 if should continue.

    local message=$1
    local response

    read -r -p "$message [y/N] " response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
        return 0
    fi

    return 1
}
