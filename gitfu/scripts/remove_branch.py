#!/usr/bin/env python3
import argparse
import re
import subprocess
import sys
from functools import lru_cache


class SuccessfulExecution(Exception):
    pass


class ErrorDuringExecution(Exception):
    pass


def main():
    if len(sys.argv) == 1:
        sys.argv.append('-h')

    args = parse_args()

    try:
        branch_name = get_branch_name(
            query=args.branch_name,
            function=get_local_branches,
            descriptor='local',
        )
        found_local_branch = branch_name in get_local_branches()
        if found_local_branch:
            should_delete = get_user_input(
                'Do you want to delete branch: {}?'.format(branch_name)
            )
            if not should_delete:
                raise SuccessfulExecution

            delete_local_branch(branch_name, force=args.force)

    except SuccessfulExecution:
        return 0
    except ErrorDuringExecution:
        return 1 

    try:
        branch_name = get_branch_name(
            query=branch_name,
            function=lambda x=args.remote: get_remote_branches(x),
            descriptor='remote',
        )

        delete_remote_branch(branch_name, remote=args.remote)
    except ErrorDuringExecution:
        return not found_local_branch

    return 0


def parse_args():
    parser = argparse.ArgumentParser(
        description=(
            'This cleans up an inactive branch, both locally and on the '
            'remote repository.'
        ),
        prog='rmb',
    )
    parser.add_argument(
        '-f',
        '--force',
        action='store_true',
        help='Force removes the branch.',
    )
    parser.add_argument(
        '-r',
        '--remote',
        default='origin',
        type=str,
        help='Specifies the remote repository to query.',
    )
    parser.add_argument(
        'branch_name',
        help='Branch to remove.',
    )

    return parser.parse_args()


def get_branch_name(query, function, descriptor):
    """
    :type query: str

    :type function: callable
    :param function: generator for repositories to iterate through

    :type descriptor: str
    :param descriptor: "local"|"remote"

    :raises: SuccessfulExecution
    :raises: ErrorDuringExecution
    :rtype: str
    :returns: improved query, for fuzzy matching remote repositories
    """
    branches = get_branch_name_candidates(
        query,
        function,
    )
    if len(branches) > 1:
        print_error(
            'More than one branch found! Try using a more specific query.',
            '{} branches found:'.format(descriptor.title()),
            *[
                '* {}'.format(branch)
                for branch in branches
            ]
        )

        raise ErrorDuringExecution 

    if not branches:
        print_error(
            'Unable to find "{}" in {} branches!'.format(
                query,
                descriptor.lower()
            ),
        )
        if descriptor == 'remote':
            raise ErrorDuringExecution

        # We only prompt for local branches, so that you
        # can try the remote branch.
        should_continue_process = get_user_input(
            'Do you want to continue?'
        )
        if not should_continue_process:
            raise SuccessfulExecution

        return query

    return branches[0]


def get_branch_name_candidates(query, function):
    """
    :type query: str

    :type function: callable
    :param function: generates branch names to iterate through
    """
    return [
        branch
        for branch in function()
        if query in branch
    ]
    

@lru_cache(maxsize=1)
def get_local_branches():
    branches = subprocess.check_output(
        'git branch'.split()
    ).decode('utf-8').splitlines()

    return [
        # The format for this is either:
        #   "  branch" or
        #   "* branch"
        branch[2:]
        for branch in branches
    ]


@lru_cache(maxsize=1)
def get_remote_branches(remote):
    branches = subprocess.check_output(
        'git branch -a'.split()
    ).decode('utf-8').splitlines()

    regex = re.compile('^[* ] remotes/{}/'.format(remote))
    return [
        branch[len('* remotes/{}/'.format(remote)):]
        for branch in branches
        if regex.match(branch)
    ]


def delete_local_branch(branch, force=False):
    """
    :type branch: str
    :type force: bool
    """
    try:
        subprocess.check_output([
            'git', 'branch',
            '-d' if not force else '-D',
            branch,
        ])
    except subprocess.CalledProcessError as e:
        raise ErrorDuringExecution 

    print_message('Removed local branch "{}".'.format(branch))


def delete_remote_branch(branch, remote):
    """
    :type branch: str
    :type remote: str
    """
    # TODO: Handle `remote ref does not exist`
    subprocess.check_output([
        'git', 'push',
        remote,
        '--delete',
        branch,
    ])
    print_message('Removed remote branch "{}".'.format(branch))


def get_user_input(question):
    """
    :type question: str
    """
    if not question.endswith(' '):
        question += ' '

    acceptable_input = ['y', 'Y', 'n', 'N']
    input_value = None
    while not input_value:
        input_value = input(question)
        if input_value not in acceptable_input:
            print_error(
                'Invalid input. Must be one of {}'.format(
                    acceptable_input,
                )
            )
            input_value = None

    return input_value.lower() == 'y'


def print_error(message, *lines):
    print_message('error: {}'.format(message))
    for line in lines:
        print_message(line)


def print_message(message):
    print(message, file=sys.stderr)


if __name__ == '__main__':
    main()
