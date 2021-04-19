# GitFu

This repository originally started off as my desire to add more custom functionality to
your normal git commands.

An alternative method is certainly to use `git alias`. This entire repository could have been
merely designed with standalone scripts, with some other form of automation connecting these
standalone scripts to the user's global config file. i.e.

```
$ git config -e --global
[alias]
   check = "!/path/to/gitfu/check.py"
```

The benefits with this approach is two-fold:

1. Easy installation (`pip install -u`, and everything is configured)
2. Adding customization on top of existing git commands

I admit, it's **very** specific to my workflow; however, if you're interested in using any
of the scripts piecemeal, all unique commands are written so that they can be imported in
your own `git alias` if you so desire.

## Quickstart

```bash
$ git clone https://github.com/domanchi/gitfu
$ cd gitfu && pip install -u -e .
```

Then, in your `.bash_profile`, add this line:

```bash
eval "$(gitfu init)"
```

## Features

### Custom Commands

- `git commit` prevents `WIP` commits from staying in git history.
- `git check` interactively displays changed file diffs, and prompts the user whether to
  stage this change.

### Standalone Scripts

- `add-git-staged-files` quickly adds all staged files again (useful for situations where
  linters modify the files on pre-commit)
- `remote-git-branch` helps you remove branches, and optionally purges all merged branches.
- `switch-git-branch` allows quick branch switching, with inexact branch name matching, and
  built in conflict resolution.
