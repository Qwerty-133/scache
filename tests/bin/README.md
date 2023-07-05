# Script Tests

The tests in this directory are ran in GitHub workflows for testing PowerShell and Bash scripts.\
They can be used for local testing, but no efforts at clean-ups are made.

The tests also test some basic spcache functionality.

During PowerShell tests, some output and error messages may still be displayed, but can be ignored as long as the final
pass message is printed.

## Pre-requisities for bash tests

The following shells should be installed and added to PATH:

- fish
- bash
- zsh
