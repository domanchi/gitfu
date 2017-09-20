# Add these to your current .bash_profile, to install this wrapper.

# Change this value to suit your environment.
export GITFU_BASE='/fully/qualified/path/to/git-wrapper'

# Use ONE of the following:
#       1) override your default git alias
#       2) install git wrapper to your path
alias git="$GITFU_BASE/gitfu/git "$@""   # option #1
source $GITFU_BASE/gitfu/scripts/gitfu_install_to_path.sh

# This is to make sure that you can still manually access git
# if/when needed. (optional)
alias GIT='/usr/local/bin/git'
