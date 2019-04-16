#!/usr/bin/env bash

BOLD=`tput bold`
RED=`tput setaf 1`
GREEN=`tput setaf 2`
YELLOW=`tput setaf 3`
RESET=`tput sgr0`

function show_help {
    echo "${BOLD}Hashicorp Application Install Script${RESET} - run as sudo to install globally, or else it'll install only for the current user"
    echo ""
    echo "Basic usage: sudo ./$(basename $0) [options] <app-name>"
    echo "Example: sudo ./$(basename $0) -v 0.10.0 terraform"
    echo ""
    echo "${BOLD}Application Name${RESET}:"
    echo "Can be one of the following: consul, nomad, otto, packer, serf, terraform, vagrant, vault"
    echo "For a full list, visit https://releases.hashicorp.com/"
    echo ""
    echo "${BOLD}Options${RESET}:"
    echo " ${BOLD}-v${RESET}: Version (Optional) - App version to install. Defaults to 'latest'."
    echo " ${BOLD}-d${RESET}: Directory (Optional) - App installation directory. Defaults to '/usr/share/hashicorp' in sudo, '~/.local/share' otherwise"
    echo " ${BOLD}-h${RESET}: Help - Show me this helpful message."
}

function check_http_status {
  http_status=`curl -# -o $1 -w "%{http_code}" $2`
  if [ $http_status != 200 ]; then
    echo $3
    exit 1
  fi
}

function check_http_status_silent {
  http_status=`curl -# -s -o $1 -w "%{http_code}" $2`
  if [ $http_status != 200 ]; then
    echo $3
    exit 1
  fi
}

# Gather options from flags.
while getopts "h:v:d:a:b:" opt; do
    case "$opt" in
    h)
        show_help
        exit 0
        ;;
    \?)
        show_help
        exit 0
        ;;
    v)
        VERSION=$OPTARG
        ;;
    d)
        INSTALL_DIRECTORY=$OPTARG
        ;;
    esac
done
shift $((OPTIND-1))

APPLICATION=$1

# Validate options and set defaults.
if [ -z "${APPLICATION}" ]; then
  show_help
  echo ""
  echo "${BOLD}ERROR:${YELLOW} You must specify an application to install.${RESET}"
  exit 1
fi

# Check if in sudo
if [ "$EUID" -ne 0 ]
then
	echo ""
  echo "${YELLOW}Installing for current user only. If you want to install globally, run with sudo.${RESET}"
	echo ""
fi

# Check if unzip is available
if ! [ -x "$(command -v unzip)" ]; then
  echo "${RED}Unzip is not installed, please install it.${RESET}"
  exit 1
fi

check_http_status_silent '/dev/null' "https://releases.hashicorp.com/${APPLICATION}/" "${BOLD}ERROR${RESET}: ${APPLICATION} does not appear to exist. Please enter a valid application name."

if [ -z "${VERSION}" ] || [ "${VERSION}" == "latest" ]; then
  VERSION=`curl -s https://releases.hashicorp.com/${APPLICATION}/ | sed "s/<\/*[^>]*>//g" | grep -o "${APPLICATION}_[0-9]\+.[0-9]\+.[0-9]\+$" | sort --version-sort | tail -1 | sed s/${APPLICATION}_//`
else
  check_http_status_silent '/dev/null' "https://releases.hashicorp.com/${APPLICATION}/${VERSION}/" "${BOLD}ERROR${RESET}: ${APPLICATION} ${VERSION} does not appear to exist. Please enter a valid application version."
fi

case "$OSTYPE" in
  darwin*)  OS="darwin" ;; 
  linux*)   OS="linux" ;;
  bsd*)     OS="openbsd" ;;
  msys*)    OS="windows" ;;
  *)        echo "${BOLD}ERROR${RESET}: unknown OS"; exit 1 ;;
esac

if [ `uname -m` == "x86_64" ]; then
  ARCHITECTURE="${OS}_amd64"
else
  ARCHITECTURE="${OS}_386"
fi

if [ -z "${INSTALL_DIRECTORY}" ]; then
	if [ "$EUID" -ne 0 ]
	then
		INSTALL_DIRECTORY=$HOME/.local/share/hashicorp
		BIN_DIRECTORY=$HOME/.local/bin
	else
    INSTALL_DIRECTORY=/usr/share/hashicorp
		BIN_DIRECTORY=/usr/bin
  fi
fi

# Try to create the application directory.
mkdir -p ${INSTALL_DIRECTORY} &>/dev/null
check_dir=`echo $?`
if [ "${check_dir}" -ne 0 ]; then
  echo -e "${BOLD}ERROR${RESET}: It appears ${INSTALL_DIRECTORY} does not exist and/or failed to create."
  exit 1
fi

TMP="/tmp/${APPLICATION}.zip"

# Download and extract the application.
echo "${BOLD}NOTICE${RESET}: Downloading and Installing ${APPLICATION}_${VERSION}_${ARCHITECTURE} to ${INSTALL_DIRECTORY}"
check_http_status "${TMP}" "https://releases.hashicorp.com/${APPLICATION}/${VERSION}/${APPLICATION}_${VERSION}_${ARCHITECTURE}.zip" "${BOLD}ERROR${RESET}: ${APPLICATION} ${VERSION} does not appear to exist. Please enter a valid application version."
unzip -o "${TMP}" -d "${INSTALL_DIRECTORY}" &>/dev/null
rm "${TMP}"

# Create link to bin directory
ln -fs  "${INSTALL_DIRECTORY}/${APPLICATION}" "${BIN_DIRECTORY}/${APPLICATION}"

# If the user has elected to update their bash_profile, verify the app runs by outputting the version.
verify=`${APPLICATION} version | head -1`
if [ -z "$verify" ]; then
  echo "${BOLD}ERROR${RESET}: It appears ${BOLD}${APPLICATION}${RESET} did not install correctly. Try re-executing this script."
  exit 1
else
  echo "${BOLD}${APPLICATION}${RESET} ${VERSION} has been successfully installed."
  exit 0
fi
