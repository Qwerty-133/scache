#!/bin/bash
# Test script for install_spcache.sh

. ./tests/bin/helpers/utils.sh

link="https://raw.githubusercontent.com/Qwerty-133/spcache/main/bin/install_spcache.sh"

print "${GREEN}" "Test bash online installation\n"
curl -sSL "${link}" --header "${HEADER}"

curl -sSL "${link}" --header "${HEADER}" | bash -s - -y 1>/dev/null 2>&1
test_spcache_in_path bash
