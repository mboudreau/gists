#!/usr/bin/env bash

BOLD=`tput bold`
RED=`tput setaf 1`
GREEN=`tput setaf 2`
YELLOW=`tput setaf 3`
RESET=`tput sgr0`

DOWNLOAD_URL="https://cdist2.perforce.com/perforce"
APPLICATION="p4merge"

function show_help {
    echo "${BOLD}P4Merge Merge/Diff Tool Install Script${RESET} - run as sudo to install globally, or else it'll install only for the current user"
    echo ""
    echo "Basic usage: sudo ./$(basename $0) [options]"
    echo "Example: sudo ./$(basename $0) -v r18.5"
    echo ""
    echo "${BOLD}Options${RESET}:"
    echo " ${BOLD}-v${RESET}: Version (Optional) - App version to install. Defaults to 'latest'. List can be found here: https://cdist2.perforce.com/perforce/"
    echo " ${BOLD}-d${RESET}: Directory (Optional) - App installation directory. Defaults to '/usr/share/perforce' in sudo, '~/.local/share/perforce' otherwise"
    echo " ${BOLD}-h${RESET}: Help - Show me this helpful message."
}

function check_version {
  http_status=`curl -# -s -o $1 -w "%{http_code}" $2`
  if [ $http_status != 200 ]; then
    return 1
  fi
  return 0
}

function download_version {
  http_status=`curl -# -o $1 -w "%{http_code}" $2`
  if [ $http_status != 200 ]; then
    echo $3
    exit 1
  fi
}

function check_version_error {
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

# Check if in sudo
if [ "$EUID" -ne 0 ]
then
	echo ""
  echo "${YELLOW}Installing for current user only. If you want to install globally, run with sudo.${RESET}"
	echo ""
fi

# Check if tar is available
if ! [ -x "$(command -v tar)" ]; then
  echo "${RED}Tar is not installed, please install it.${RESET}"
  exit 1
fi

case "$OSTYPE" in
  linux*)   OS="linux26x86_64" ;;
  bsd*)     OS="linux26x86_64" ;;
  *)        echo "${BOLD}ERROR${RESET}: OS not supported"; exit 1 ;;
esac

if [ -z "${VERSION}" ] || [ "${VERSION}" == "latest" ]; then
  IFS=$'\n'
  VERSIONS=`curl -s ${DOWNLOAD_URL}/ | sed "s/<\/*[^>]*>//g" | grep -o "r[0-9]\+.[0-9]\+" | sort --version-sort --reverse`
  for VERSION in $VERSIONS
  do
    # Check to see if it exists, then break away when found a correct version
    check_version '/dev/null' "${DOWNLOAD_URL}/${VERSION}/bin.${OS}/" && break
  done
  echo "Latest version is $VERSION"
else
  check_version_error '/dev/null' "${DOWNLOAD_URL}/${VERSION}/bin.${OS}/" "${BOLD}ERROR${RESET}: ${VERSION} does not appear to exist. Please enter a valid version."
fi

BINARY_URL="${DOWNLOAD_URL}/${VERSION}/bin.${OS}/p4v.tgz"

if [ -z "${INSTALL_DIRECTORY}" ]; then
	if [ "$EUID" -ne 0 ]
	then
		INSTALL_DIRECTORY=$HOME/.local/share/perforce
		BIN_DIRECTORY=$HOME/.local/bin
	else
        INSTALL_DIRECTORY=/usr/share/perforce
		BIN_DIRECTORY=/usr/bin
  fi
fi

# Try to create the application directory.
mkdir -p ${INSTALL_DIRECTORY} &>/dev/null
mkdir -p ${BIN_DIRECTORY} &>/dev/null
check_dir=`echo $?`
if [ "${check_dir}" -ne 0 ]; then
  echo -e "${BOLD}ERROR${RESET}: It appears ${INSTALL_DIRECTORY} does not exist and/or failed to create."
  exit 1
fi

TMP="/tmp/${APPLICATION}.tgz"

# Download and extract the application.
echo "${BOLD}NOTICE${RESET}: Downloading and Installing ${APPLICATION} ${VERSION} to ${INSTALL_DIRECTORY}"
download_version "${TMP}" "${BINARY_URL}" "${BOLD}ERROR${RESET}: ${VERSION} does not appear to exist. Please enter a valid version."
tar -xf "${TMP}" --strip 1 -C "${INSTALL_DIRECTORY}" &>/dev/null

rm "${TMP}"

# Create link to bin directory
ln -fs "${INSTALL_DIRECTORY}/bin/${APPLICATION}" "${BIN_DIRECTORY}/${APPLICATION}"

# If the user has elected to update their bash_profile, verify the app runs by outputting the version.
verify=`${APPLICATION} -V | tail -1`
if [ -z "$verify" ]; then
  echo "${BOLD}ERROR${RESET}: It appears ${BOLD}${APPLICATION}${RESET} did not install correctly. Try re-executing this script."
  exit 1
fi

echo "${BOLD}${APPLICATION} ${VERSION}${RESET} has been successfully installed."

# Check if git is available
if ! [ -x "$(command -v git)" ]; then
  echo "${YELLOW}Git is not installed, skipping setting ${APPLICATION} as diff/merge tool.${RESET}"
  exit 1
else
  echo "Setting up ${APPLICATION} as merge and diff tool in git..."
  git config --global merge.tool p4merge
  git config --global diff.tool p4merge
fi

exit 0
