"""
Performs git diff (to make sure you're checking in the right thing), then
prompts to add to staged files.
"""
import argparse
import os
import platform
import textwrap
from functools import lru_cache
from typing import Iterator

from ..core import git
from ..core import color


def run(*argv: str) -> None:
    args = parse_args(*argv)
    filenames = args.filename

    deleted_files = set(
        git.run(
            'diff', '--name-only', '--diff-filter=D',
            colorize=False,
        ).splitlines()
    )

    try:
        is_first_file = True
        for filename in hydrate_filenames(*filenames):
            if not is_first_file:
                _clear_screen()

            if filename in deleted_files:
                verify_deletion(filename)
            else:
                check_and_prompt(filename)
            
            is_first_file = False
        
    except KeyboardInterrupt:
        return


def parse_args(*argv: str) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        prog='git check',
        description=__doc__,
    )
    parser.add_argument(
        'filename',
        nargs='*',
        help='Filename to examine.',
    )

    # NOTE: `None` is needed to print the help string.
    return parser.parse_args(argv or None)


def hydrate_filenames(*filenames: str) -> Iterator[str]:
    """
    Turns directories into actual paths.
    """
    known_files = git.run('diff', '--name-only', colorize=False).splitlines()

    if not filenames:
        yield from known_files
        return

    for filename in filenames:
        if os.path.isdir(filename):
            yield from [
                name
                for name in known_files
                if name.startswith(filename)
            ]
        else:
            yield filename


def check_and_prompt(filename: str) -> None:
    print(git.run('diff', filename))
    print()

    if should_add_file():
        git.run('add', filename)    


def verify_deletion(filename: str) -> None:
    # Custom output of deleted files.
    lines = [
        color.colorize(f'-{line}', color.AnsiColor.RED)
        for line in git.run('show', f'HEAD:{filename}', colorize=False).splitlines()
    ]
    
    header = textwrap.dedent(f"""
        diff --git a/{filename} b/{filename}
        index {_get_current_sha()[:7]}..0000000
        --- a/{filename}
        +++ /dev/null
        @@ -0,0 +1,{len(lines)} @@
    """)[1:-1]

    print(header)
    print('\n'.join(lines))
    print()

    if should_add_file():
        git.run('add', filename)


@lru_cache(maxsize=1)
def _get_current_sha() -> str:
    return git.run('rev-parse', 'HEAD', colorize=False)


def should_add_file() -> bool:
    value = input('Do you want to add this file? (y/n) ').lower()
    while value not in 'yn':
        value = input('Do you want to add this file? (y/n) ').lower()

    return value == 'y'


def _clear_screen() -> None:
    command = 'cls' if platform.system() == 'Windows' else 'clear'
    os.system(command)


if __name__ == '__main__':
    run()
