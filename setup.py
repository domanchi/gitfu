import os
from pathlib import Path

from setuptools import find_packages
from setuptools import setup


VERSION = '0.0.1'


setup(
    name='gitfu',
    packages=find_packages(exclude=['test*', 'tmp*']),
    version=VERSION,
    description='Custom git commands for faster development.',
    author='Aaron Loo',
    author_email='admin@aaronloo.com',
    url='https://github.com/domanchi/gitfu',
    entry_points={
        'console_scripts': [
            'gitfu = gitfu.__main__:run',
            *[
                (
                    f'{os.path.splitext(item)[0].replace("_", "-")} '
                    f'= gitfu.standalone.{os.path.splitext(item)[0]}:main'
                )
                for item in os.listdir(Path('gitfu') / 'standalone')
                if not item.startswith('_')
            ],
        ],
    },
)
