# git sync

This module serves to keep your local git repo in sync with a remote git repo. See
[Detailed Explanation](https://github.com/domanchi/gitfu/new/master/docs#detailed-explanation) for more details.

## Installation

In `gitfu/main.sh`, the following additions are responsible for this module:

### 1. Custom git command

This allows you to run `git sync` for manual access to a subset of synchronization commands.

### 2. Automated Synchronization

```
if [[ "$workdir" == "$LOCAL_SYNC_DIR" ]] && \
   [[ "$workdir" != `pwd` ]]; then
    $GITFU/sync/main.sh "$@"
fi
```

This makes sure that your repos (within your local sync directory) are automatically in sync, without any additional commands
on your part.

## Usage

### Explicit Usage (`git sync`)

* Runs a list of synchronization checks to check that you are in sync with the server.

### Automated Synchronization

* As long as you are within your configured `$LOCAL_SYNC_DIR`, any state changing git commands (commit, add, push, reset,
checkout and pull) will be also executed on the server. Other commands don't need to be synced, and therefore do not need
the additional server call (eg. `git diff`).

* The git repo will check whether it's currently in sync with its remote counterpart, before attempting the sync. In addition,
the git command will be attempted locally, before attempting the sync. It's assumed that since the repos are already in sync,
any failing git commands locally will also fail on the server.

* If you don't want a repo in `$LOCAL_SYNC_DIR` to be synced, just add a `.sync_ignore` file to the repo's root.
Eg. `touch do-not-sync-repo/.sync_ignore`.

* For this to work successfully, you should use some sort of
[Automated Deployment](https://confluence.jetbrains.com/display/PYH/Deployment+in+PyCharm#DeploymentinPyCharm-Automaticuploadtothedefaultserver)
feature (like in PyCharm) to keep your files in sync as well.


## Detailed Explanation

TODO
