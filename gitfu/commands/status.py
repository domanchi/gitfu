from ..core import git


def run(*argv: str) -> None:
    output = git.run('status', *argv)
    output += '\n'
    
    return output