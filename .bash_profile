# Add these to your current .bash_profile, to install this wrapper.

# Change this value to suit your environment.
export GITFU_BASE='/fully/qualified/path/to/git-wrapper'

# This will override your default git alias.
alias git="$GITFU_BASE/gitfu/main.sh "$@""

# This is to make sure that you can still manually access git
# if/when needed. (optional)
alias GIT='/usr/local/bin/git'
