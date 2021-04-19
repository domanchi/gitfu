"""Re-adds all staged files."""
import subprocess
import sys

from ..core import git


def main(*argv: str) -> None:
    staged_files = git.run(
        'diff', '--staged', '--name-only',
        '--diff-filter=ARM',
    ).splitlines()
    if not staged_files:
        # If no staged files, add all tracked files.
        git.run('add', '-u')
    else:
        # NOTE: If you run this script in a non-root directory, `staged_files` will show
        # paths relative to the git root, but we won't be able to add it directly. As such,
        # compute the prefix to the current directory, and we can remove this prefix accordingly.
        root = git.run('rev-parse', '--show-toplevel')
        prefix = subprocess.check_output(
            ['realpath', '--relative-to', root, '.'],
        ).decode().rstrip()
        if prefix == '.':
            prefix = ''

        files_to_add = [filename[len(prefix):] for filename in staged_files]
        git.run('add', *files_to_add)


if __name__ == '__main__':
    try:
        main()
        sys.exit(0)
    except subprocess.CalledProcessError as e:
        print(e.stderr, file=sys.stderr)
        sys.exit(1)
