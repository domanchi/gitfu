# GitFu

This repository originally started off as my desire to add more custom functionality to your normal git commands.

While `git alias` helps, it's functionality is limited as it only allows you to alias other git commands. You can't execute your own custom built scripts from a git alias.

But now you can.

## Highlights

### Server Synchronization

Keep your local git repo in sync with your remote git repo! See
[documentation](https://github.com/domanchi/gitfu/blob/master/docs/sync.md) for more details.

## Installation

1. ##### Set `$GITFU_BASE` to the location of your clone of this repo.
   
   See `.bash_profile` for an example of what to append to your
   `.bash_profile` to install this git wrapper.

2. ##### Configure your global variables

   Change the variables as appropriate in `.config`.
