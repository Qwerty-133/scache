#!/bin/bash
# Test script for install_spcache.sh

. ./tests/bin/helpers/utils.sh

readonly LINK="https://qwertie.pages.dev/install_spcache.sh"
bash_command="curl -sSL '${LINK}' --header '${HEADER}' | bash -s - -y -s bash"
fish_command="curl -sSL '${LINK}' --header '${HEADER}' | bash -s - -y -s fish"
zsh_command="curl -sSL '${LINK}' --header '${HEADER}' | bash -s - -y -s zsh"

print "${GREEN}" "Test bash online installation\n"
bash --login -c "${bash_command}"
test_spcache_in_path bash

print "${GREEN}" "Test fish online installation\n"
fish --login -c "${fish_command}"
test_spcache_in_path fish

print "${GREEN}" "Test zsh online installation\n"
zsh --login -c "${zsh_command}"
test_spcache_in_path zsh
