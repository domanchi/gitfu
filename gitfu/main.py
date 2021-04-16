import subprocess
import sys

from . import commands
from .core import git
from .exceptions import GitfuException


def main(*argv: str) -> int:
    if not argv:
        argv = sys.argv[1:]

    try:
        _process_inputs(*argv)
    except subprocess.CalledProcessError as e:
        # NOTE: stderr is already printed to console.
        return e.returncode
    except GitfuException as e:
        print(str(e), file=sys.stderr)
        return 1

    return 0


def _process_inputs(*argv: str) -> None:
    """
    :raises: subprocess.CalledProcessError
    """
    if not argv:
        return git.run('-h')
    
    command = argv[0]
    valid_commands = [
        key
        for key in dir(commands)
        if not key.startswith('_')
    ]

    # If not shimmed, fallback to default behavior.
    if command not in valid_commands:
        print(git.run(*argv))
        return
    
    sys.argv.pop()
    output = getattr(commands, command)(*argv[1:])
    if output:
        print(output)