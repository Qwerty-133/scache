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

print_error() {
    printf "${RED}$1${RESET}" >&2
}

traphandler() {
    status=$?
    command="$BASH_COMMAND"
    ln="$BASH_LINENO"
    print_error "An unexpected error occurred:\n"
    msg="Command: ${command}Line: ${ln}\nExit code: ${status}"
    print_error "${msg}\n"
    exit $status
}

trap traphandler ERR

read -r -d '' HELP << EOM || true
Usage: install_spcache [-v <version>] [-d]

  Installs spcache.

Options:
  -h  Show this help message and exit.
  -v  Specify a version to install. [Default: latest]
  -d  Show verbose output.
EOM

print_verbose() {
    if [ "$VERBOSE" = "1" ]; then
        printf "${YELLOW}$1${RESET}"
    fi
}

print_info() {
    printf "${CYAN}$1${RESET}"
}

print_success() {
    printf "${GREEN}$1${RESET}"
}

VERBOSE="0"
VERSION="latest"

while getopts ":v:dh" opt; do
    case $opt in
    v)
        if [[ "$OPTARG" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            VERSION="$OPTARG"
        elif [ "$OPTARG" != "latest" ]; then
            print_error "Invalid version: ${OPTARG}\nSupply a version in the form of X.Y.Z\n"
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
        print_error "Invalid option: -$OPTARG\n"
        printf "${HELP}\n"
        exit 1
        ;;
    esac
done

if [ -z "${XDG_DATA_HOME:-}" ]; then
    APP_DIR="$HOME/.local/share/spcache"
else
    APP_DIR="$XDG_DATA_HOME/spcache"
fi

if [ ! -d "$APP_DIR" ]; then
    mkdir -p "$APP_DIR"
    print_verbose "Created directory $APP_DIR\n"
fi

if [ "$VERSION" = "latest" ]; then
    release_url="https://api.github.com/repos/Qwerty-133/spcache/releases/latest"
else
    release_url="https://api.github.com/repos/Qwerty-133/spcache/releases/tags/v${VERSION}"
fi

print_verbose "Fetching release data from $release_url\n"

release_data=$(curl -sL "$release_url")
actual_version=$(echo "$release_data" | grep -oP '(?<="tag_name": ")[^"]*')

# find if this is linux or macos

if [ "$(uname)" = "Darwin" ]; then
    platform="macos"
elif [ "$(uname)" = "Linux" ]; then
    platform="linux"
else
    print_error "Unsupported platform: $(uname)\n"
    exit 2
fi

asset_url=$(echo "$release_data" | grep -oP "(?<=\"browser_download_url\": \")[^\"]*${platform}")

if [ -z "$asset_url" ]; then
    print_error "Could not find a ${platform} release asset for version ${actual_version}\n"
    exit 3
fi

print_info "Downloading spcache ${actual_version}...\n"
curl -sL "$asset_url" -o "$APP_DIR/spcache"

chmod +x "$APP_DIR/spcache"

print_success "Successfully installed spcache ${actual_version} to $APP_DIR\n"

printf "\n"
printf "To add spcache to your PATH, add the following line to your shell's configuration file:\n"
print_info "export PATH=\"\$PATH:$APP_DIR\"\n"
printf "Then, restart your shell or run ${CYAN}source ~/.bashrc${RESET} (or equivalent) to apply the changes.\n"
printf "See
