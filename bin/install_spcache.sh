#!/bin/bash
# Usage: install_spcache [-v <version>] [-d]
# Description: Installs spcache pre-built binaries from GitHub.
# Author: Qwerty-133
# License: MIT

set -euo pipefail

RED=$(tput setaf 9 || printf "")
GREEN=$(tput setaf 10 || printf "")
CYAN=$(tput setaf 12 || printf "")
YELLOW=$(tput setaf 11 || printf "")
RESET=$(tput sgr0 || printf "")

readonly NOCOLOUR=""
readonly RED
readonly GREEN
readonly CYAN
readonly YELLOW
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

readonly prog_name="${0}"

read -r -d '' HELP << EOM || true
Usage: ${prog_name} [-v <version>] [-d]

  Installs spcache.

  If the GITHUB_TOKEN environment variable is set, it will be used to
  authenticate with GitHub. This is useful if you are hitting the rate limit
  for unauthenticated requests.

Options:
  -v  Specify a version to install. [Default: latest]
  -d  Enable verbose output.
  -y  Execute commands required to add spcache to PATH without confirming.
  -s  The shell to add spcache to PATH for. One of: bash, zsh, fish.
  -h  Show this help message and exit.
EOM

VERBOSE="0"
VERSION="latest"
YES="0"
SHELL_ARG=$SHELL

# Print a message in yellow if verbose mode is enabled.
print_verbose() {
    local -r message="${1}"
    if [ "${VERBOSE}" = "1" ]; then
        print "${YELLOW}" "${message}"
    fi
}

while getopts ":v:dys:h" opt; do
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
        print "${NOCOLOUR}" "${HELP}\n"
        exit 0
        ;;
    d)
        VERBOSE="1"
        ;;
    y)
        YES="1"
        ;;
    s)
        if [[ "${OPTARG}" =~ ^(.*/)?(bash|fish|zsh)$ ]]; then
            SHELL_ARG="${OPTARG}"
        else
            print "${RED}" "Unsupported shell: ${OPTARG}\n"
            exit 1
        fi
        ;;
    \?)
        print "${RED}" "Invalid option: -${OPTARG}\n"
        print "${NOCOLOUR}" "${HELP}\n"
        exit 1
        ;;
    esac
done

readonly VERBOSE
readonly VERSION
readonly YES
readonly SHELL_ARG

print_verbose "Using version: ${VERSION}, verbose: ${VERBOSE}\n"

if [ -z "${XDG_DATA_HOME:-}" ]; then
    # shellcheck disable=SC2016
    RAW_APP_DIR='$HOME/.local/share/spcache'
    APP_DIR="${HOME}/.local/share/spcache"
else
    # shellcheck disable=SC2016
    RAW_APP_DIR='$XDG_DATA_HOME/spcache'
    APP_DIR="${XDG_DATA_HOME}/spcache"
fi

readonly RAW_APP_DIR
readonly APP_DIR
print_verbose "App Dir: ${APP_DIR}\n"

if [ ! -d "${APP_DIR}" ]; then
    mkdir -p "${APP_DIR}" # --parents
    print_verbose "Created directory ${APP_DIR}\n"
fi

if [ "${VERSION}" = "latest" ]; then
    release_url="https://api.github.com/repos/Qwerty-133/spcache/releases/latest"
else
    release_url="https://api.github.com/repos/Qwerty-133/spcache/releases/tags/v${VERSION}"
fi
print_verbose "Fetching release data from ${release_url}\n"

if [ -n "${GITHUB_TOKEN:-}" ]; then
    print_verbose "Using GitHub token for authentication\n"
    HEADER="Authorization: Bearer ${GITHUB_TOKEN:-}"
else
    HEADER=""
fi
readonly HEADER

release_data=$(curl --fail --silent --location "${release_url}" --header "${HEADER}")

version_tag="${release_data#*\"tag_name\": \"}"
version_tag="${version_tag%%\"*}"
print_verbose "Version tag: ${version_tag}\n"

if [ "$(uname)" = "Darwin" ]; then
    platform="macos"
elif [ "$(uname)" = "Linux" ]; then
    platform="linux"
else
    print "${RED}" "Unsupported platform: $(uname)\n"
    exit 2
fi

asset_url="https://github.com/Qwerty-133/spcache/releases/download/${version_tag}/spcache_${platform}"
print_verbose "Asset url: ${asset_url}\n"

print "${CYAN}" "Downloading spcache ${version_tag} for ${platform}...\n"
curl --fail --silent --location "${asset_url}" --output "${APP_DIR}/spcache" --header "${HEADER}"

chmod +x "${APP_DIR}/spcache"

print "${GREEN}" "Successfully installed spcache ${version_tag} to ${APP_DIR}\n\n"

commands=()

readonly EXPORT_LINE="export PATH=\"${RAW_APP_DIR}:\$PATH\""
# Normalized: echo 'export PATH="$HOME/path:$PATH"'
readonly ECHO_CMD="echo '${EXPORT_LINE}'"


# Add the export line to the commands array if not present in the file.
add_if_not_present() {
    local -r file="${1}"
    # Redirect stderr to null incase the file doesn't exist.
    # --fixed-strings --line-regexp --quiet
    if ! grep -Fxq "${EXPORT_LINE}" "${file}" 2>/dev/null; then
        if [[ $(tail -c 1 "${file}" 2>/dev/null) != $'\n' ]]; then
            commands+=("echo >> ${file}")
        fi
        commands+=("${ECHO_CMD} >> ${file}")
    fi
}

read -r -d '' UNRECOGNISED_SHELL << EOM || true
${YELLOW}spcache can't be added to PATH automatically.${RESET}
Please add the following line to your shell's config file:

${EXPORT_LINE}
(or equivalent)
EOM

case "${SHELL_ARG}" in
*bash)
    add_if_not_present "${HOME}/.bashrc"
    add_if_not_present "${HOME}/.profile"
    if [ -f "${HOME}/.bash_profile" ]; then
        add_if_not_present "${HOME}/.bash_profile"
    fi
    if [ -f "${HOME}/.bash_login" ]; then
        add_if_not_present "${HOME}/.bash_login"
    fi
    ;;
*zsh)
    add_if_not_present "${HOME}/.zshrc"
    add_if_not_present "${HOME}/.zprofile"
    ;;
*fish)
    if ! "${SHELL_ARG}" -c "contains \"${APP_DIR}\" \$fish_user_paths"; then
        if "${SHELL_ARG}" -c "type -q fish_add_path"; then
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

# If spcache isn't in the session PATH, tell them to restart their shell.
handle_restart() {
    if [[ ! ":$PATH:" == *":${APP_DIR}:"* ]]; then
        print "${YELLOW}" "${RESTART_MSG}\n"
    else
        print "${NOCOLOUR}" "Run 'spcache set' to set the cache limit.\n"
    fi
}

if [ ${#commands[@]} -eq 0 ]; then
    handle_restart
    exit 0
fi

print "${NOCOLOUR}" "The following commands need to be run to add spcache to your PATH:\n"
for cmd in "${commands[@]}"; do
    print "${NOCOLOUR}" "${cmd}\n"
done


if [ "${YES}" = "1" ]; then
    yn="y"
else
    print "${YELLOW}" "Proceed? [y/N] "
    read -r yn < /dev/tty
    yn=$(echo "${yn}" | tr '[:upper:]' '[:lower:]')
fi

case "${yn}" in
    "y" | "yes" | "true" | "t" | "on" | "1")
        for cmd in "${commands[@]}"; do
            if ! eval "${cmd}"; then
                print "${RED}" "Failed to run: ${cmd}\nspcache couldn't be added to PATH.\n"
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
