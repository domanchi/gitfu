#!/bin/bash
# This file provides the ability to call the aliased `git` wrapper in
# functions, when needed. This is because subshells don't inherit
# aliases.
#
# `source` this file when needed.

function git() {
    $GITFU_BASE/gitfu/main.sh "$@"
}

