from functools import lru_cache
from typing import Optional
import os
import subprocess


def run(*args: str, colorize: bool = True, capture_output: bool = True) -> Optional[str]:
    """
    :param colorize: set to False if attempting to mutate original git output.
    :param capture_output: set to False if just relying on `git` to format output
        (e.g. git clone progress bar)

    :raises: subprocess.CalledProcessError
    """
    params = [_get_path_to_original_git()]
    if colorize:
        # Source: https://stackoverflow.com/a/22074539
        params.extend(['-c', 'color.ui=always'])
    
    options = {
        'check': True,                # If non-zero returncode, raise error.
    }
    if capture_output:
        options['stderr'] = subprocess.PIPE
        options['stdout'] = subprocess.PIPE

    try:    
        response = subprocess.run([*params, *args], **options)
        if capture_output:
            return response.stdout.decode().rstrip()
    except subprocess.CalledProcessError as e:
        if e.stderr:
            e.stderr = e.stderr.decode().rstrip()
        if e.stdout:
            e.stdout = e.stdout.decode().rstrip()

        raise e


@lru_cache(maxsize=1)
def _get_path_to_original_git() -> str:
    return subprocess.check_output('which git'.split()).decode().strip()