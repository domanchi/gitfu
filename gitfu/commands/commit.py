import subprocess

from ..core import color
from ..core import git
from ..exceptions import GitfuException


def run(*argv: str) -> None:
    prevent_wip_commits()

    git.run('commit', *argv, capture_output=False)


def prevent_wip_commits():
    """
    Prevent committing if the last commit has a `wip` comment in it.
    """
    try:
        last_commit_message = git.run(
            'log', '--pretty=format:"%s"', '-1', colorize=False,
        )
    except subprocess.CalledProcessError as e:
        if not e.stderr.endswith('does not have any commits yet'):
            raise

        last_commit_message = ''

    if last_commit_message and 'wip' in last_commit_message.split()[0].lower():
        raise LastCommitWIPException(
            f'{color.colorize("ERROR:", color.AnsiColor.RED)} '
            'Last commit was a WIP.',
        )


class LastCommitWIPException(GitfuException):
    pass
