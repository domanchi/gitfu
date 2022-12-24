"""Re-adds all staged files."""
import subprocess
import sys

from ..core import git


def main(*argv: str) -> None:
    staged_files = git.run(
        'diff', '--staged', '--name-only', '--relative',
        '--diff-filter=ARM',
    ).splitlines()
    if not staged_files:
        # If no staged files, add all tracked files.
        git.run('add', '-u')
    else:
        git.run('add', *staged_files)


if __name__ == '__main__':
    try:
        main()
        sys.exit(0)
    except subprocess.CalledProcessError as e:
        print(e.stderr, file=sys.stderr)
        sys.exit(1)
