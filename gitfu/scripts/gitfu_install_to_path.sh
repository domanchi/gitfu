#!/bin/bash

# Source this file to install gitfu to your PATH. This will allow for
# more flexible usage of gitfu in your command line.

source $GITFU_BASE/.config

echo $PATH | grep "^$GITFU_BASE" > /dev/null
if [[ $? == 1 ]]; then
    export PATH=$GITFU_BASE/gitfu:$PATH
fi

