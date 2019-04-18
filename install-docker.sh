#!/usr/bin/env bash

BOLD=`tput bold`
RED=`tput setaf 1`
GREEN=`tput setaf 2`
YELLOW=`tput setaf 3`
RESET=`tput sgr0`

function show_help {
    echo "${BOLD}Docker Install Script${RESET}"
    echo ""
    echo "Basic usage: ./$(basename $0) [options]"
    echo "Example: ./$(basename $0) -v 5:18.09.5~3-0~ubuntu-bionic"
    echo ""
    echo "${BOLD}Options${RESET}:"
    echo " ${BOLD}-v${RESET}: Version (Optional) - Docker version to install. Defaults to 'latest'. Versions can be found by running 'apt-cache madison docker-ce'"
    echo " ${BOLD}-h${RESET}: Help - Show me this helpful message."
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
    esac
done
shift $((OPTIND-1))

if [ -z "${VERSION}" ] || [ "${VERSION}" == "latest" ]; then
  VERSION=`apt-cache --quiet=0 policy docker-ce 2>&1 | sed -E -n "s/\s*Candidate: (.*)/\1/p"`
fi

echo "${YELLOW}Trying to install docker version ${VERSION}${RESET}"

sudo apt-get install apt-transport-https ca-certificates curl gnupg-agent software-properties-common -y > /dev/null
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - > /dev/null
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" -y > /dev/null
sudo apt-get update > /dev/null
sudo apt-get install docker-ce=${VERSION} docker-ce-cli=${VERSION} containerd.io -y > /dev/null


if ! [ -x "$(command -v docker)" ]; then
  echo "${RED}Docker did not install correctly.${RESET}"
  exit 1
fi

echo "${BOLD}${GREEN}Docker version ${VERSION} installed successfully.${RESET}"
echo "Making docker accessible to user '${USER}'."
sudo groupadd docker
sudo usermod -aG docker $USER

echo "${BOLD}Docker added to user '${USER}', but you must log out and log back in to be able to use docker without sudo.${RESET}"