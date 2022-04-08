from setuptools import setup


def readfile(filename):
    with open(filename, 'r+') as f:
        return f.read()


setup(
    name="realms-cli",
    version="",
    description="",
    long_description=readfile('README.md'),
    author="",
    author_email="",
    url="",
    py_modules=['realms-cli'],
    license="",
    entry_points={
        'console_scripts': [
            'realms = cli:main'
        ]
    },
)