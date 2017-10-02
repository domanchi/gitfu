#!/bin/bash
# Source this file, for common sync functions.


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

