import argparse
import subprocess
import sys

from ..core import color
from ..core import git


def main() -> int:
    args = parse_args()
    if args.prune:
        try:
            prune_branches(args.remote)
        except subprocess.CalledProcessError:
            return 1

    elif not args.branch:
        _print_error('Branch name required.')
        return 1

    else:
        try:
            delete_branch(
                name=args.branch, remote=args.remote,
                should_force=args.force,
            )
        except subprocess.CalledProcessError:
            return 1

    return 0


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        '-r',
        '--remote',
        default='origin',
        type=str,
        help='Specifies the remote repository to query.',
    )
    parser.add_argument(
        '--prune',
        action='store_true',
        help='Deletes all git branches which have already been merged.',
    )
    parser.add_argument(
        '-f',
        '--force',
        action='store_true',
        help='Force removes the branch, if the local branch has not been merged yet.',
    )
    parser.add_argument(
        'branch',
        type=str,
        nargs='?',
        help='Branch name to delete.',
    )

    return parser.parse_args()


def delete_local_branch(*names: str, force: bool = False) -> None:
    """
    :raises: subprocess.CalledProcessError
    """
    if not names:
        return

    try:
        git.run('branch', '-d' if not force else '-D', *names)
    except subprocess.CalledProcessError as e:
        print(e.stderr, file=sys.stderr)
        raise


def delete_remote_branch(*names: str, remote: str) -> None:
    """
    :raises: subprocess.CalledProcessError
    """
    for name in names:
        try:
            git.run('push', remote, '--delete', name)
        except subprocess.CalledProcessError as e:
            print(e.stderr, file=sys.stderr)
            raise


def delete_branch(name: str, remote: str, should_force: bool = False) -> None:
    """
    :raises: subprocess.CalledProcessError
    """
    should_delete = False

    # First, check local branches for this query.
    local_branches = {
        item.strip(
            '* ',
        ) for item in git.run('branch', colorize=False).splitlines()
    }
    candidates = [
        candidate
        for candidate in local_branches
        if name in candidate
    ]
    if len(candidates) > 1:
        _print_error(
            'More than one branch found! Try using a more specific query.\n - '
            + '\n - '.join(candidates),
        )
        return
    elif len(candidates) == 1:
        should_delete = _get_confirmation(*candidates)
        if not should_delete:
            print('Aborting')
            return

        delete_local_branch(*candidates, force=should_force)
    else:
        _print_warning(
            'Unable to find any local branches. Searching remote-only branches...',
        )

    # If no local branches, fall through to remote branches.
    # Alternatively, if successful with local branch, also try deleting remote.
    remote_branches = {
        item.split()[0][len(f'{remote}/'):]
        for item in git.run('branch', '-r', colorize=False).splitlines()
    } - {'HEAD'}
    if not candidates:
        candidates = [
            candidate
            for candidate in remote_branches
            if name in candidate
        ]

        if len(candidates) > 1:
            _print_error(
                'More than one branch found! Try using a more specific query.\n - '
                + '\n - '.join(candidates),
            )
            return
        elif not candidates:
            _print_error('No candidates found!')
            return
    elif candidates[0] not in remote_branches:
        # Only local branch exists.
        return

    # At this point, we will have a valid candidates array (with one item only),
    # that corresponds to the name of the remote branch. As such, we're prepared to
    # do the remote branch deletion.
    #
    # Only check for confirmation if you haven't already.
    if not should_delete:
        should_delete = _get_confirmation(candidates[0])

    if not should_delete:
        print('Aborting')
        return

    delete_remote_branch(candidates[0], remote=remote)


def prune_branches(remote: str) -> None:
    # First, determine if any local branches are already merged into the current one.
    current_branch = None
    already_merged_local_branches = []
    for name in git.run('branch', '--merged', colorize=False).splitlines():
        if name.startswith('*'):
            current_branch = name.strip('* ')
            continue

        name = name.strip('* ')
        if name == 'master':
            # Never delete master branch
            continue

        already_merged_local_branches.append(name)

    # Then, compile a list of remote branches that need cleaning up too.
    already_merged_remote_branches = [
        line.split()[0][len(f'{remote}/'):]
        for line in git.run('branch', '-r', '--merged', colorize=False).splitlines()
        if line.split()[0] not in {f'{remote}/{current_branch}', f'{remote}/HEAD'}
    ]

    if not already_merged_local_branches and not already_merged_remote_branches:
        print('No branches to delete!')
        return

    should_delete = _get_confirmation(
        *[*already_merged_local_branches, *already_merged_remote_branches]
    )
    if not should_delete:
        print('Aborting')
        return

    try:
        delete_local_branch(*already_merged_local_branches)
        delete_remote_branch(*already_merged_remote_branches, remote=remote)
    except subprocess.CalledProcessError as e:
        pass


def _get_confirmation(*names: str) -> bool:
    print(
        f'This will delete the following branch{"es" if len(names) > 1 else ""}:',
    )
    print(' - ' + '\n - '.join(sorted(names)))
    print()
    value = input('Are you sure you want to continue? (y/n) ').lower()
    while value not in 'yn':
        value = input('Are you sure you want to continue? (y/n) ').lower()

    return value == 'y'


def _print_error(message: str) -> None:
    print(
        (
            f'{color.colorize("ERROR", color.AnsiColor.RED)}: '
            f'{message}'
        ),
        file=sys.stderr,
    )


def _print_warning(message: str) -> None:
    print(
        (
            f'{color.colorize("WARNING", color.AnsiColor.YELLOW)}: '
            f'{message}'
        ),
        file=sys.stderr,
    )


if __name__ == '__main__':
    sys.exit(main())
