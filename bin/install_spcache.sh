#!/bin/bash
# Usage: install_spcache [-v <version>] [-d]
# Description: Installs spcache pre-built binaries from GitHub.
# Author: Qwerty-133
# License: MIT

set -euo pipefail

if command -v tput >/dev/null 2>&1; then
    RED=$(tput setaf 9)
    GREEN=$(tput setaf 10)
    CYAN=$(tput setaf 12)
    YELLOW=$(tput setaf 11)
    RESET=$(tput sgr0)
else
    RED=""
    GREEN=""
    CYAN=""
    YELLOW=""
    RESET=""
fi

readonly RED
readonly GREEN
readonly CYAN
readonly YELLOW
readonly RESET

print() {
    printf "${1}${2}${RESET}"
}

traphandler() {
    status=$?
    command="${BASH_COMMAND}"
    ln="${BASH_LINENO}"
    print "${RED}" "An unexpected error occurred:\n"
    msg="Command: ${command}\nLine: ${ln}\nExit code: ${status}"
    print "${RED}" "${msg}\n"
    exit "${status}"
}
trap traphandler ERR

read -r -d '' HELP << EOM || true
Usage: install_spcache [-v <version>] [-d]

  Installs spcache.

Options:
  -v  Specify a version to install. [Default: latest]
  -d  Show verbose output.
  -h  Show this help message and exit.
EOM

VERBOSE="0"
VERSION="latest"

print_verbose() {
    if [ "${VERBOSE}" = "1" ]; then
        print "${YELLOW}" "${1}"
    fi
}

while getopts ":v:dh" opt; do
    case $opt in
    v)
        if [[ "${OPTARG}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            VERSION="${OPTARG}"
        elif [ "${OPTARG}" != "latest" ]; then
            print "${RED}" "Invalid version: ${OPTARG}\nSupply a version in the form of X.Y.Z\n"
            exit 1
        fi
        ;;
    h)
        printf "${HELP}\n"
        exit 0
        ;;
    d)
        VERBOSE="1"
        ;;
    \?)
        print "${RED}" "Invalid option: -${OPTARG}\n"
        printf "${HELP}\n"
        exit 1
        ;;
    esac
done

readonly VERBOSE
readonly VERSION
print_verbose "Using version: ${VERSION}, verbose: ${VERBOSE}\n"

if [ -z "${XDG_DATA_HOME:-}" ]; then
    RAW_APP_DIR='${HOME}/.local/share/spcache'
    APP_DIR="${HOME}/.local/share/spcache"
else
    RAW_APP_DIR='${XDG_DATA_HOME}/spcache'
    APP_DIR="${XDG_DATA_HOME}/spcache"
fi

readonly RAW_APP_DIR
readonly APP_DIR
print_verbose "App Dir: ${APP_DIR}\n"

if [ ! -d "${APP_DIR}" ]; then
    mkdir -p "${APP_DIR}"
    print_verbose "Created directory ${APP_DIR}\n"
fi

if [ "${VERSION}" = "latest" ]; then
    release_url="https://api.github.com/repos/Qwerty-133/spcache/releases/latest"
else
    release_url="https://api.github.com/repos/Qwerty-133/spcache/releases/tags/v${VERSION}"
fi
print_verbose "Fetching release data from ${release_url}\n"
release_data=$(curl -sL "${release_url}")

version_tag=$(echo "${release_data}" | grep -oP '(?<="tag_name": ")[^"]*')
print_verbose "Version tag: ${version_tag}\n"

if [ "$(uname)" = "Darwin" ]; then
    platform="macos"
elif [ "$(uname)" = "Linux" ]; then
    platform="linux"
else
    print "${RED}" "Unsupported platform: $(uname)\n"
    exit 2
fi

asset_url=$(echo "${release_data}" | grep -oP "(?<=\"browser_download_url\": \")[^\"]*${platform}")
print_verbose "Asset url: ${asset_url}\n"

print "${CYAN}" "Downloading spcache ${version_tag} for ${platform}...\n"
curl -sL "${asset_url}" -o "${APP_DIR}/spcache"
chmod +x "${APP_DIR}/spcache"

print "${GREEN}" "Successfully installed spcache ${version_tag} to ${APP_DIR}\n\n"

commands=()

readonly EXPORT_LINE="export PATH=\"\$PATH:${RAW_APP_DIR}\""
# Normalized: echo 'export PATH="$PATH:$HOME/path"'
readonly ECHO_CMD="echo '${EXPORT_LINE}'"


add_if_not_present() {
    # Redirect stderr to null incase the file doesn't exist.
    if ! grep -Fxq "${EXPORT_LINE}" "${1}" 2>/dev/null; then
        commands+=("${ECHO_CMD} >> ${1}")
    fi
}

read -r -d '' UNRECOGNISED_SHELL << EOM || true
${YELLOW}spcache can't be added to PATH automatically.${RESET}
Please add the following line to your shell's config file:

${EXPORT_LINE}
(or equivalent)
EOM

case $SHELL in
*/bash)
    add_if_not_present "${HOME}/.bashrc"
    add_if_not_present "${HOME}/.profile"
    if [ -f "${HOME}/.bash_profile" ]; then
        add_if_not_present "${HOME}/.bash_profile"
    fi
    if [ -f "${HOME}/.bash_login" ]; then
        add_if_not_present "${HOME}/.bash_login"
    fi
    ;;
*/zsh)
    add_if_not_present "${HOME}/.zshrc"
    ;;
*/fish)
    if ! "${SHELL}" -c "contains \"${APP_DIR}\" \$fish_user_paths"; then
        if "${SHELL}" -c "type -q fish_add_path"; then
            commands+=("fish -c 'fish_add_path \"${APP_DIR}\"'")
        else
            commands+=("fish -c 'set -U fish_user_paths \"${APP_DIR}\" \$fish_user_paths'")
        fi
    fi
    ;;
*)
    print "${YELLOW}" "${UNRECOGNISED_SHELL}\n"
    exit 0
    ;;
esac

read -r -d '' RESTART_MSG << EOM || true
${YELLOW}Please restart your shell to start using spcache.${RESET}
Or run ${YELLOW}exec \$SHELL${RESET}.
EOM

handle_restart() {
    if [[ ! ":$PATH:" == *":${APP_DIR}:"* ]]; then
        print "${YELLOW}" "${RESTART_MSG}\n"
    else
        printf "Run 'spcache set' to set the cache limit.\n"
    fi
}

if [ ${#commands[@]} -eq 0 ]; then
    handle_restart
    exit 0
fi

printf "The following commands need to be run to add spcache to your PATH:\n"
for cmd in "${commands[@]}"; do
    printf "${cmd}\n"
done

print "${YELLOW}" "Proceed? [y/N] "

read yn
yn=$(echo "${yn}" | tr '[:upper:]' '[:lower:]')

case "${yn}" in
    "y" | "yes" | "true" | "t" | "on" | "1")
        for cmd in "${commands[@]}"; do
            if ! eval "${cmd}"; then
                print "${RED}" "Failed to run: ${cmd}\nspcache couldn't be added to path.\n"
                exit 1
            fi
        done

        print "${GREEN}" "spcache has been added to PATH.\n"
        handle_restart
        exit 0
        ;;
    *)
        print "${YELLOW}" "spcache hasn't been added to PATH.\n"
        exit 0
        ;;
esac
