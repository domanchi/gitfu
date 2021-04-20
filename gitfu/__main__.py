import os
import re
import sys
import textwrap

from .main import main


def run() -> int:
    if len(sys.argv) == 1:
        print(show_help(), file=sys.stderr)
        return 0

    mode = sys.argv[1]
    if mode == '-h':
        print(show_help(), file=sys.stderr)
        return 0
    elif mode == 'init':
        print(get_bash_shim())
        return 0
    elif mode != 'run':
        print(f'Unknown option: {mode}', file=sys.stderr)
        print(show_help(), file=sys.stderr)
        return 1

    sys.argv = [sys.argv[0]] + sys.argv[2:]
    return main()


def get_bash_shim() -> str:
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
        # TODO: This probably means it's invoked through other means.
        raise NotImplementedError(
            'This python install does not follow regular conventions. '
            'Are you using an editable installation? (e.g. `pip install -e`)',
        )

    bin_directory = os.path.realpath(os.path.join(directory, '../../bin'))

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


def show_help() -> str:
    """
    We can't use argparse, since we want to accept all arguments, and pass it along.
    """
    return textwrap.dedent("""
        usage: gitfu {init,run} ...

        positional arguments:
          init      Inject gitfu into shell.
          run       Runs shimmed git commands.

        optional arguments:
          -h        show this help message, and exit.
    """)[1:-1]


if __name__ == '__main__':
    sys.exit(run())
