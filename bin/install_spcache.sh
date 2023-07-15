#!/bin/bash
# Usage: install_spcache [-v <version>] [-d] [-y] [-s <shell>] [-h]
# Description: Install spcache pre-built binaries from GitHub releases.
# Author: Qwerty-133
# License: MIT

set -euo pipefail

RED="$(tput setaf 9 || printf '')"
GREEN="$(tput setaf 10 || printf '')"
CYAN="$(tput setaf 12 || printf '')"
YELLOW="$(tput setaf 11 || printf '')"
RESET="$(tput sgr0 || printf '')"
readonly NOCOLOUR=''
readonly RED
readonly GREEN
readonly CYAN
readonly YELLOW
readonly RESET
# Print a message to STDOUT in the specified colour.
print() {
  local -r colour="$1"
  local -r message="$2"
  printf '%b' "${colour}${message}${RESET}"
}
# Log the command and line number causing an error to STDERR.
# Returns: The exit code of the command that failed.
# shellcheck disable=SC2317
traphandler() {
  status=$?
  command="${BASH_COMMAND}"
  ln="${BASH_LINENO[0]}"
  print "${RED}" 'An unexpected error occurred:\n' 1>&2
  msg="Command: ${command}\nLine: ${ln}\nExit code: ${status}"
  print "${RED}" "${msg}\n" 1>&2
  exit "${status}"
}
trap traphandler ERR

os_name="$(uname)"
if [[ "${os_name}" == 'Darwin' ]]; then
  readonly PLATFORM='macos'
elif [[ "${os_name}" == 'Linux' ]]; then
  readonly PLATFORM='linux'
else
  print "${YELLOW}"\
    "Unrecognised platform: ${os_name}, the installed executable may not work\n" 1>&2
  readonly PLATFORM='linux'
fi
readonly PROG_NAME="$0"

if [[ -n "${XDG_DATA_HOME:-}" ]]; then
  # shellcheck disable=SC2016
  readonly RAW_APP_DIR='${XDG_DATA_HOME}/spcache'
  readonly APP_DIR="${XDG_DATA_HOME}/spcache"
else
  # shellcheck disable=SC2016
  readonly RAW_APP_DIR='${HOME}/.local/share/spcache'
  readonly APP_DIR="${HOME}/.local/share/spcache"
fi
readonly ZIP="${APP_DIR}/spcache_dist.zip"
readonly EXPORT_LINE="export PATH=\"${RAW_APP_DIR}:\${PATH}\""
readonly ECHO_CMD="echo '${EXPORT_LINE}'" # Normalized: echo 'export PATH="${HOME}/path:${PATH}"'

verbose=0
version='latest'
yes=0
shell="${SHELL}"

read -r -d '' HELP_MSG <<EOM || true
Usage: ${PROG_NAME} [-v <version>] [-d] [-y] [-s <shell>]

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

read -r -d '' RESTART_MSG <<EOM || true
${YELLOW}Please restart your shell${RESET} before using spcache, or run ${YELLOW}exec \$SHELL${RESET}
EOM

read -r -d '' UNRECOGNISED_SHELL_MSG <<EOM || true
${YELLOW}spcache can't be added to PATH automatically.${RESET}
Please add the following line to your shell's config file:

${EXPORT_LINE}
(or equivalent)
EOM

# Print a message in yellow to STDOUT if verbose mode is enabled.
print_verbose() {
  local -r message="$1"
  if (( verbose == 1 )); then
    print "${YELLOW}" "${message}"
  fi
}

# Add the export line to the commands array if not present in the file.
# Globals: adds to the global commands array.
add_if_not_present() {
  local -r file="$1"
  # Redirect stderr to null incase the file doesn't exist.
  # --fixed-strings --line-regexp --quiet
  if ! grep -Fxq "${EXPORT_LINE}" "${file}" 2>/dev/null; then
    # check whether the file ends on a new-line, if it exists
    if (( $( (tail -c 1 "${file}" 2>/dev/null || echo) | wc -l) != 1 )); then
      commands+=("echo >> ${file}")
    fi
    commands+=("${ECHO_CMD} >> ${file}")
  fi
}

# If spcache isn't present in the session PATH, ask users to restart their shell.
handle_restart() {
  if [[ ":$PATH:" != *":${APP_DIR}:"* ]]; then
    print "${NOCOLOUR}" "${RESTART_MSG}\n"
  else
    print "${NOCOLOUR}" "Run 'spcache set' to set the cache limit.\n"
  fi
}

while getopts ':v:dys:h' opt; do
  case "${opt}" in
    v)
      if [[ "${OPTARG}" =~ ^([0-9]+\.[0-9]+\.[0-9]+|latest)$ ]]; then
        version="${OPTARG}"
      else
        print "${RED}" "Invalid version: ${OPTARG}\n" 1>&2
        print "${NOCOLOUR}" "Supply a version in the form of X.Y.Z\n" 1>&2
        exit 2
      fi
      ;;
    h)
      print "${NOCOLOUR}" "${HELP_MSG}\n"
      exit 0
      ;;
    d) verbose=1 ;;
    y) yes=1 ;;
    s)
      if [[ "${OPTARG}" =~ ^(.*/)?(bash|fish|zsh)$ ]]; then
        shell="${OPTARG}"
      else
        print "${RED}" "Unsupported shell: ${OPTARG}\n" 1>&2
        exit 3
      fi
      ;;
    \?)
      print "${RED}" "Invalid option: -${OPTARG}\n" 1>&2
      print "${NOCOLOUR}" "${HELP_MSG}\n" 1>&2
      exit 1
      ;;
  esac
done
readonly verbose
readonly version
readonly yes
readonly shell
print_verbose "Parsed version: ${version}, verbose: ${verbose}, shell: ${shell}, yes: ${yes}\n"
print_verbose "Using app dir: ${APP_DIR}\n"

if [[ -n "${GITHUB_TOKEN:-}" ]]; then
  print_verbose 'Using GitHub token for authentication\n'
  readonly header="Authorization: Bearer ${GITHUB_TOKEN:-}"
else
  readonly header=''
fi

if [[ -f "${APP_DIR}" ]] || [[ -L "${APP_DIR}" ]]; then
  print_verbose "Removing file present at path.\n"
  rm "${APP_DIR}"
fi
if [[ -d "${APP_DIR}" ]]; then
  print_verbose "Deleting existing directory.\n"
  rm -rf "${APP_DIR}"
fi
mkdir -p "${APP_DIR}"
if [[ "${version}" == 'latest' ]]; then
  readonly release_url='https://api.github.com/repos/Qwerty-133/spcache/releases/latest'
else
  readonly release_url="https://api.github.com/repos/Qwerty-133/spcache/releases/tags/v${version}"
fi

print_verbose "Fetching release data from ${release_url}\n"
release_data="$(curl --fail --silent --location "${release_url}" --header "${header}")"
version_tag="${release_data#*\"tag_name\": \"}"
version_tag="${version_tag%%\"*}"
print_verbose "Version tag: ${version_tag}\n"

asset_url="https://github.com/Qwerty-133/spcache/releases/download/${version_tag}/spcache_${PLATFORM}.tar.gz"
print_verbose "Asset url: ${asset_url}\n"
print "${CYAN}" "Downloading spcache ${version_tag} for ${PLATFORM}...\n"
curl --fail --silent --location "${asset_url}" --output "${ZIP}" --header "${header}"
print "${CYAN}" "Extracting spcache files...\n"
tar -xf "${ZIP}" -C "${APP_DIR}" # --extract, --file, --directory
rm "${ZIP}"
chmod +x "${APP_DIR}/spcache" # Shouldn't be necessary, but just in case.

if ! "${APP_DIR}/spcache" --version >/dev/null; then
  print "${RED}" "The installed spcache executable is corrupt, or unsupported on this system.\n" 1>&2
  print "${YELLOW}" "Please install spcache from PyPI instead, see " 1>&2
  print "${YELLOW}" "https://github.com/Qwerty-133/spcache#installing-from-pypi\n" 1>&2
  exit 4
fi

print "${GREEN}" "Successfully installed spcache ${version_tag} to ${APP_DIR}\n\n"

commands=()
case "${shell}" in
  *bash)
    add_if_not_present "${HOME}/.bashrc"
    add_if_not_present "${HOME}/.profile"
    if [[ -f "${HOME}/.bash_profile" ]]; then
      add_if_not_present "${HOME}/.bash_profile"
    fi
    if [[ -f "${HOME}/.bash_login" ]]; then
      add_if_not_present "${HOME}/.bash_login"
    fi
    ;;
  *zsh)
    add_if_not_present "${HOME}/.zshrc"
    add_if_not_present "${HOME}/.zprofile"
    ;;
  *fish)
    if ! "${shell}" -c "contains \"${APP_DIR}\" \$fish_user_paths"; then
      if "${shell}" -c 'type -q fish_add_path'; then
        commands+=("fish -c 'fish_add_path \"${APP_DIR}\"'")
      else
        commands+=("fish -c 'set -U fish_user_paths \"${APP_DIR}\" \$fish_user_paths'")
      fi
    fi
    ;;
  *)
    print "${NOCOLOUR}" "${UNRECOGNISED_SHELL_MSG}\n"
    exit 0
    ;;
esac

if (( ${#commands[@]} == 0 )); then
  handle_restart
  exit 0
fi

print "${NOCOLOUR}" 'The following commands need to be run to add spcache to your PATH:\n'
for cmd in "${commands[@]}"; do
  print "${NOCOLOUR}" "${cmd}\n"
done

if (( yes == 1 )); then
  yn='y'
else
  print "${YELLOW}" 'Proceed? [y/N] '
  read -r yn </dev/tty
  yn="$(echo "${yn}" | tr '[:upper:]' '[:lower:]')"
fi

case "${yn}" in
  'y' | 'yes' | 'true' | 't' | 'on' | 1)
    for cmd in "${commands[@]}"; do
      if ! eval "${cmd}"; then
        ret=$?
        print "${RED}" "Failed to run: ${cmd}\nspcache couldn't be added to PATH.\n" 1>&2
        exit "${ret}"
      fi
    done

    print "${GREEN}" "spcache has been added to PATH.\n"
    handle_restart
    exit 0
    ;;
  *)
    print "${YELLOW}" "spcache hasn't been added to PATH.\n"
    print "${YELLOW}" "Please run the above commands manually to add spcache to PATH.\n"
    exit 0
    ;;
esac
