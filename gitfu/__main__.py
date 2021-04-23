import argparse
import os
import re
import sys
import textwrap
from typing import List
from typing import Optional
from typing import Tuple

from .main import main


def run() -> int:
    args, leftover = parse_args()
    if args.mode == 'init':
        print(get_bash_shim(args.directory))
        return 0
    else:
        sys.argv = [sys.argv[0]] + leftover
        return main()


def parse_args() -> Tuple[argparse.Namespace, List[str]]:
    parser = argparse.ArgumentParser()
    subparsers = parser.add_subparsers(dest='mode')

    init_parser = subparsers.add_parser(
        'init',
        help='Inject gitfu into shell.',
    )
    init_parser.add_argument(
        '-d',
        '--directory',
        help=(
            'Used for editable pip installations. Specifies the directory that holds the '
            'installed gitfu binaries.'
        ),
    )

    run_parser = subparsers.add_parser(
        'run',
        help='Runs shimmed git commands.',
    )

    # Index the arguments, so that we can process the leftover arguments in order.
    original_argv = sys.argv
    argv_indexes = {
        item: index
        for index, item in enumerate(sys.argv)
    }

    # Temporarily remove any help flags, so that they can be passed through
    # (rather than being handled by this parser).
    help_flags_index = []
    new_argv = []
    for index, item in enumerate(sys.argv):
        if item not in {'-h', '--help'} or index < 2:
            new_argv.append(item)
        else:
            help_flags_index.append(index)

    sys.argv = new_argv
    args, leftover = parser.parse_known_args()
    if not help_flags_index:
        return args, leftover

    index = 0
    new_leftover = []
    for item in leftover:
        while argv_indexes[item] > help_flags_index[index]:
            new_leftover.append(original_argv[help_flags_index[index]])
            index += 1

        new_leftover.append(item)

    while index < len(help_flags_index):
        new_leftover.append(original_argv[help_flags_index[index]])
        index += 1

    return args, new_leftover


def get_bash_shim(bin_directory: Optional[str] = None) -> str:
    if not bin_directory:
        bin_directory = _get_binary_directory()

    # NOTE: We use a function here, so that it's easy to uninstall (i.e. `unset git`),
    # yet it doesn't interfere with our PATH. As such, it is only a user-based shim,
    # and (hopefully) won't affect any other scripts that depend on `git`.
    output = []
    output.append(
        textwrap.dedent(f"""
            function git {{
                {bin_directory}/gitfu run "$@"
            }}
        """)[1:-1],
    )

    standalone_script_names = [
        os.path.splitext(item)[0].replace('_', '-')
        for item in os.listdir(
            os.path.join(
                os.path.dirname(__file__),
                'standalone',
            ),
        )
        if not item.startswith('_')
    ]
    output.extend([
        textwrap.dedent(f"""
            function {name} {{
                {bin_directory}/{name} "$@"
            }}
        """)[1:-1]
        for name in standalone_script_names
    ])

    return '\n\n'.join(output)


def _get_binary_directory() -> str:
    # NOTE: Especially with pyenv, gitfu will be installed to the respective python environment.
    # However, this may not be in the user's $PATH (since it would probably be in some directory
    # like ~/pyenv/versions/<version>/bin/gitfu). Furthermore, we don't want to necessarily add
    # this entire directory to the path (as it would override other python shims).
    #
    # As such, we find the location that `gitfu` is installed into, and figure out the binary
    # location ourselves. In this way, not only will we not need to do $PATH manipulations, but
    # it will also work when we change python versions with pyenv.
    #
    # NOTE: We assume that the binaries will be installed to <prefix>/bin/*, and the source files
    # will be installed to <prefix>/lib/python3.\d+/site-packages/gitfu/.
    python_regex = re.compile(r'(?P<prefix>.*?)\/python3\.\d+$')
    directory = os.path.dirname(__file__)
    while not python_regex.match(directory):
        new_directory, tail = os.path.split(directory)
        if new_directory == directory:
            break

        directory = new_directory

    if directory == '/':
        raise NotImplementedError(
            'This python install does not follow regular conventions. '
            'Are you using an editable installation? (e.g. `pip install -e`)',
        )

    return os.path.realpath(os.path.join(directory, '../../bin'))


if __name__ == '__main__':
    sys.exit(run())
