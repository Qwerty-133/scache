# Contributing Guidelines

Feel free to open an issue if you have any questions or suggestions.\
Directly creating a pull request is fine for small changes, but please open an issue before making any major changes.

## Setting up the Development Environment

### Pre-requisites

| Tool | Installation Guide |
| --- | --- |
| Python 3.8+ | <https://docs.python-guide.org/starting/installation/> |
| Poetry | <https://python-poetry.org/docs/#installation> |
| Git | <https://github.com/git-guides/install-git> |

### Steps

1. Fork the repository, and clone your forked repository.
1. Make sure you are in the root project directory.
1. Install the dependencies using `poetry install`.
1. Run `poetry run task precommit` to install pre-commit hooks.
1. Run `pre-commit install` to install the pre-commit hooks.

You can now make your changes!\
Run `poetry run spcache` to use the CLI, for example `poetry run spcache detect`.

## pre-commit

Whenever you make a commit, pre-commit hooks will be run against your changed files. If any of them fail, update your
code and try to commit again.

## Open a Pull Request

Once you are done making your changes, open a pull request.
