import os
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
    # NOTE: We use a function here, so that it's easy to uninstall (i.e. `unset git`),
    # yet it doesn't interfere with our PATH. As such, it is only a user-based shim,
    # and (hopefully) won't affect any other scripts that depend on `git`.
    return textwrap.dedent("""
        function git {
            gitfu run "$@"
        }
    """)[1:-1]


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