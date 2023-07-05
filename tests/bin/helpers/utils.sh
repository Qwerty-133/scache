#!/bin/bash
# Taken from bin/install_spcache.sh

set -euo pipefail

if command -v tput >/dev/null 2>&1; then
    RED=$(tput setaf 9)
    GREEN=$(tput setaf 10)
    RESET=$(tput sgr0)
else
    RED=""
    GREEN=""
    RESET=""
fi

# shellcheck disable=SC2034
readonly GREEN
readonly RESET

# Print a message in the specified colour.
print() {
    local -r colour="${1}"
    local -r message="${2}"
    printf "%b" "${colour}${message}${RESET}"
}

# Log the command and line number causing an error.
# shellcheck disable=SC2317
traphandler() {
    status=$?
    command="${BASH_COMMAND}"
    ln="${BASH_LINENO[0]}"
    print "${RED}" "An unexpected error occurred:\n"
    msg="Command: ${command}\nLine: ${ln}\nExit code: ${status}"
    print "${RED}" "${msg}\n"
    exit "${status}"
}
trap traphandler ERR

if [ -n "${GITHUB_TOKEN:-}" ]; then
    print "${GREEN}" "Using GitHub token for authentication\n"
    readonly HEADER="Authorization: Bearer ${GITHUB_TOKEN:-}"
else
    # shellcheck disable=SC2034
    readonly HEADER=""
fi

# Print a message in red and exit with status 1.
throw() {
    local -r message="${1}"
    print "${RED}" "${message}"
    print "${RED}" "Test failed! Aborting...\n"
    exit 1
}

# shellcheck disable=SC2034
bash_files=("${HOME}/.bashrc" "${HOME}/.profile" "${HOME}/.bash_profile" "${HOME}/.bash_login")
zsh_files=("${HOME}/.zshrc" "${HOME}/.zprofile")

# Get the number of times spcache occurs in the PATH for non-login and login shells.
get_path_counts() {
    local -r shell="${1}"
    # shellcheck disable=SC2016
    local -r count=$("${shell}" -c 'echo $PATH' | tr ':' '\n' | grep --count "spcache")
    # shellcheck disable=SC2016
    local -r login_count=$(
        "${shell}" --login -c 'echo $PATH' | tr ':' '\n' | grep --count "spcache"
    )
    echo "${count} ${login_count}"
}


# Check that the number of times spcache occurs in the PATH for non-login and login shells
check_same_path_counts() {
    local -r shell="${1}"
    local -r previous_counts="${2}"
    local -r current_counts=$(get_path_counts "${shell}")
    if [ "${previous_counts}" != "${current_counts}" ]; then
        throw "Cur: ${current_counts} Prev: ${previous_counts}\n"
    fi
}

contents=()

# Get the contents of the files that spcache is added to.
# Stores the contents in the contents global array.
get_file_contents() {
    local -r shell="${1}"
    local files=()
    contents=()

    case "${shell}" in
        bash)
            files+=("${bash_files[@]}")
            ;;
        zsh)
            files+=("${zsh_files[@]}")
            ;;
        *)
            throw "Invalid shell: ${shell}\n"
            ;;
    esac

    for file in "${files[@]}"; do
        if [ -f "${file}" ]; then
            contents+=("$(cat "${file}")")
        else
            contents+=("")
        fi
    done
}

# Check that the contents of the files that spcache is added to have not changed.
# Uses the contents global array.
check_same_file_contents() {
    local -r shell="${1}"
    local -r previous_contents=( "${contents[@]}" )
    get_file_contents "${shell}"

    local -r count="${#contents[@]}"
    for ((i=0; i < count; i++)); do
        if [ "${previous_contents[i]}" != "${contents[i]}" ]; then
            throw "Cur: ${contents[i]} Prev: ${previous_contents[i]}\n"
        fi
    done
}

# Check that spcache is present in the PATH for login shells.
test_spcache_in_path() {
    local -r shell="${1}"
    "${shell}" --login -c "spcache --version" 1>/dev/null
}
