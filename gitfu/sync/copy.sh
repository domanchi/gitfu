#!/bin/bash
# This file attempts to perform some sort of "Automated Deployment"
# by copying files between local and remote repo.

GITFU="$GITFU_BASE/gitfu"

source $GITFU_BASE/.config
source $GITFU/sync/common.sh


function main() {
    # TODO: Add subcommand support, if needed.

    # TODO: Need to get relative path from root of synced repo.
    # Assumes local files are **always** most updated.
    local repo=$(getCurrentRepo)

    local file
    for file in "$@"; do
        scp "$file" "$DEVBOX:$REMOTE_SYNC_DIR/$repo/$file"
    done
}

main "$@"
