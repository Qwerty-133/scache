#!/bin/bash
# Test script for install_spcache.sh

. ./tests/bin/helpers/utils.sh

readonly INSTALL="./bin/install_spcache.sh"

print "${GREEN}" 'Test bash installation\n'
"${INSTALL}" -s bash -y 1>/dev/null
test_spcache_in_path bash

path_counts="$(get_path_counts bash)"
get_file_contents bash

print "${GREEN}" "Test that bash re-installation doesn't change paths (nor prompt)\n"
"${INSTALL}" -s "$(which bash)" 1>/dev/null
test_spcache_in_path bash
check_same_path_counts bash "${path_counts}"
check_same_file_contents bash

print "${GREEN}" 'Test that invalid files return the correct exit code\n'
ret=0
bash --login -c 'spcache set --file .gitattributes' 1>/dev/null 2>&1 || ret=$?
(( ret == 3 ))

print "${GREEN}" 'Test that spcache detects prefs file in arbitrary locations\n'
prefs="${HOME}/a/b/spotify/prefs"
mkdir -p "$(dirname "${prefs}")"
touch "${prefs}"
bash --login -c 'spcache set --size 200 --yes' 1>/dev/null

print "${GREEN}" 'Test that spcache reads from same prefs file\n'
bash --login -c 'spcache get --yes' | grep --silent 200

print "${GREEN}" 'Test that installation fails on invalid versions\n'
! "${INSTALL}" -s bash -v foobar 1>/dev/null 2>&1

print "${GREEN}" 'Test installation of a specific version\n'
"${INSTALL}" -s bash -v "1.0.0" 1>/dev/null
bash --login -c 'spcache --version' | grep --silent "1.0.0"

print "${GREEN}" 'Test that the help flag works\n'
"${INSTALL}" -h 1>/dev/null

print "${GREEN}" 'Test that the debug flag works\n'
"${INSTALL}" -d 1>/dev/null

print "${GREEN}" 'Test fish installation\n'
"${INSTALL}" -y -s fish 1>/dev/null
test_spcache_in_path fish

# shellcheck disable=SC2016
fish_user_paths="$(fish -c 'echo $fish_user_paths')"
print "${GREEN}" "Test fish re-installation doesn't change paths.\n"
"${INSTALL}" -s "$(which fish)" 1>/dev/null
test_spcache_in_path fish

# shellcheck disable=SC2016
[[ "${fish_user_paths}" == "$(fish -c 'echo $fish_user_paths')" ]]

print "${GREEN}" 'Test zsh installation\n'
"${INSTALL}" -y -s zsh 1>/dev/null
test_spcache_in_path zsh
path_counts="$(get_path_counts zsh)"
get_file_contents zsh

print "${GREEN}" "Test that zsh re-installation doesn't change paths (nor prompt)\n"
"${INSTALL}" -s "$(which zsh)" 1>/dev/null
test_spcache_in_path zsh
check_same_path_counts zsh "${path_counts}"
check_same_file_contents zsh

print "${GREEN}" 'Test installation without specifying shell\n'
"${INSTALL}" -y 1>/dev/null

print "${GREEN}" 'Test that the script fails on invalid shells\n'
! "${INSTALL}" -s invalid_shell 1>/dev/null 2>&1

print "${GREEN}" 'Test that the script fails on invalid options\n'
! "${INSTALL}" -x 1>/dev/null 2>&1

print "${GREEN}" 'All tests passed!\n'
