"""Allows for quick movement between git branches, for long branch names."""
import argparse
import subprocess
import sys
from contextlib import contextmanager
from enum import Enum
from typing import List
from typing import Optional
from typing import Tuple

from ..core import color
from ..core import git
from ..exceptions import GitfuException


class BranchNotFoundError(GitfuException):
    pass


class ExcessivelyBroadQueryError(GitfuException):
    pass


class BranchChangeStrategy(Enum):
    DISCARD = 1
    OVERWRITE_DEST = 2
    SAVE = 3


def main(*argv: str) -> int:
    args = parse_args(*argv)
    if not args.name:
        print(show_git_branches())
        return 0

    try:
        dest_branch = get_branch(args.name)
    except BranchNotFoundError:
        print(
            (
                f'{color.colorize("ERROR", color.AnsiColor.RED)}: '
                'No branch found with that query.'
            ),
            file=sys.stderr,
        )
        return 1
    except ExcessivelyBroadQueryError as e:
        error = f'{color.colorize("ERROR", color.AnsiColor.RED)}: '
        error += 'Multiple git branches found:\n - '
        error += '\n - '.join(e.args[0])
        error += '\n\nTry a different query.'
        print(error, file=sys.stderr)
        return 1

    options = {}
    if args.force:
        options['should_force'] = True

    branch_change_strategy = None
    if args.force:
        branch_change_strategy = BranchChangeStrategy.DISCARD
    elif args.stash:
        branch_change_strategy = BranchChangeStrategy.OVERWRITE_DEST
    elif args.commit:
        branch_change_strategy = BranchChangeStrategy.SAVE

    try:
        switch_branch(dest_branch, strategy=branch_change_strategy)
    except subprocess.CalledProcessError as e:
        print(e.stderr, file=sys.stderr)
        return 1

    return 0


def parse_args(*argv: str) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        'name',
        nargs='?',
        help='Branch identifier to switch to.',
    )

    group = parser.add_mutually_exclusive_group()
    group.add_argument(
        '-f',
        '--force',
        action='store_true',
        help=(
            'Forcefully changes branches, by **discarding** any local changes and '
            'removing any untracked files.'
        ),
    )
    group.add_argument(
        '-s',
        '--stash',
        action='store_true',
        help=(
            'Forcefully changes branches, but **preserves** changes by stashing them '
            'and overwriting the files after the branch change.'
        ),
    )
    group.add_argument(
        '-c',
        '--commit',
        action='store_true',
        help=(
            'Forcefully changes branches, by **committing** them to the current branch '
            'as a WIP commit, so it can be restored when you come back to this branch.'
        ),
    )

    # NOTE: `None` is needed to print the help string.
    return parser.parse_args(argv or None)


def show_git_branches() -> str:
    output = 'These are the branches you can switch to:\n'
    output += git.run('branch')

    return output


def get_branch(name: str) -> str:
    branches = [
        candidate.strip('* ')
        for candidate in git.run('branch', colorize=False).splitlines()
        if name in candidate
    ]

    if not branches:
        raise BranchNotFoundError

    if len(branches) > 1:
        raise ExcessivelyBroadQueryError(branches)

    return branches[0]


def switch_branch(name: str, *, strategy: Optional[BranchChangeStrategy] = None) -> None:
    try:
        git.run('checkout', name)
    except subprocess.CalledProcessError as e:
        if not strategy:
            raise

        error = e.stderr
        handler = {
            BranchChangeStrategy.DISCARD: resolve_errors_through_discard,
            BranchChangeStrategy.OVERWRITE_DEST: resolve_errors_through_preservation,
            BranchChangeStrategy.SAVE: resolve_errors_through_commit,
        }.get(strategy)

        with handler(error):
            git.run('checkout', name)

    last_commit_message = git.run(
        'log', '--pretty=format:"%s"', '-1', colorize=False,
    )
    if last_commit_message == 'WIP: switch-branch-cache':
        git.run('reset', 'HEAD~1')


@contextmanager
def resolve_errors_through_discard(error: str):
    tracked_files, untracked_files = _get_blocking_files(error)

    # TODO: git reset all tracked files (unstage them, if staged)
    # TODO: git checkout all tracked files (discard changes)
    # TODO: remove all untracked files (discard changes)
    yield


@contextmanager
def resolve_errors_through_preservation(error: str):
    tracked_files, untracked_files = _get_blocking_files(error)

    # TODO: git stash (and see what that resolves)
    # TODO: rename untracked files to `.bak`
    yield

    # TODO: rename untracked files back to original


@contextmanager
def resolve_errors_through_commit(error: str):
    tracked_files, untracked_files = _get_blocking_files(error)

    git.run('add', *tracked_files, *untracked_files)
    git.run('commit', '-m', 'WIP: switch-branch-cache')
    yield


def _get_blocking_files(error: str) -> Tuple[List[str], List[str]]:
    # NOTE: From trial and error, there are several error messages that may appear at once.
    # These are the scenarios I've encountered:
    #   1. staged file that would be overwritten by checkout
    #   2. modified files (but not staged) that would be overwritten by checkout
    #   3. untracked files that would be overwritten by checkout
    tracked_files = []
    untracked_files = []

    collection = None
    for line in error.splitlines():
        if line == (
            'error: Your local changes to the following files would be overwritten by checkout:'
        ):
            collection = tracked_files
        elif line == (
            'error: The following untracked working tree files would be overwritten by checkout:'
        ):
            collection = untracked_files
        elif line not in {
            'Please commit your changes or stash them before you switch branches.',
            'Please move or remove them before you switch branches.',
            'Aborting',
        }:
            collection.append(line.strip())

    return tracked_files, untracked_files


if __name__ == '__main__':
    sys.exit(main())
