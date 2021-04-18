from functools import lru_cache
import os
import subprocess


def run(*args: str, colorize: bool = True) -> str:
    """
    :param colorize: set to False if attempting to mutate original git output.

    :raises: subprocess.CalledProcessError
    """
    params = [_get_path_to_original_git()]
    if colorize:
        # Source: https://stackoverflow.com/a/22074539
        params.extend(['-c', 'color.ui=always'])
    
    return subprocess.check_output(
        [*params, *args],
        stderr=subprocess.PIPE,
    ).decode().rstrip()


@lru_cache(maxsize=1)
def _get_path_to_original_git() -> str:
    return subprocess.check_output('which git'.split()).decode().strip()