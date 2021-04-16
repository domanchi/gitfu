from ..core import color
from ..core import git
from ..exceptions import GitfuException


def run(*argv: str) -> None:
    prevent_wip_commits()

    return git.run('commit', *argv)


def prevent_wip_commits():
    """
    Prevent committing if the last commit has a `wip` comment in it.
    """
    last_commit_message = git.run('log', '--pretty=format:"%s"', '-1', colorize=False)
    if 'wip' in last_commit_message.split():
        raise LastCommitWIPException(
            f'{color.colorize("ERROR:", color.AnsiColor.RED)} '
            'Last commit was a WIP.'
        )


class LastCommitWIPException(GitfuException):
    pass
