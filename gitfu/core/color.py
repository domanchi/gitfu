from enum import Enum


class AnsiColor(Enum):
    RESET = '[0m'
    RED = '[91m'
    YELLOW = '[33m'


def colorize(text: str, color: AnsiColor) -> str:
    return '\x1b{}{}\x1b{}'.format(
        color.value,
        text,
        AnsiColor.RESET.value,
    )
