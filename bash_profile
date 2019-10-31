#!/bin/bash
# This will only work with `source <this file>`.
# This will populate $BASH_SOURCE, readlink will get the absolute
# path to the location, and dirname will get the directory.
if readlink -f "${BASH_SOURCE[0]}" 1>/dev/null 2>&1; then
    export GITFU_BASE="$(dirname $(readlink -f ${BASH_SOURCE[0]}))"
else
    # I'm not sure why a shell opened in vscode doesn't like `readlink`,
    # but this is patches the issue.
    export GITFU_BASE="$(dirname "${BASH_SOURCE[0]}")"
fi

alias sb="$GITFU_BASE/gitfu/scripts/switch_branch.sh"
alias rmb="$GITFU_BASE/gitfu/scripts/remove_branch.py"
