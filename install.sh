#!/usr/bin/env bash

BOLD=$(tput bold)
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
RESET=$(tput sgr0)

DIRECTORY=~/.local/bin
declare -a SCRIPTS=("create-timelapse.sh" "dev-computer-setup.sh" "get-temporary-token.sh" "install-docker.sh" "install-hashicorp.sh" "install-p4merge-git.sh" "docker-delete-all-the-things.sh")

function show_help {
    echo "${GREEN}${BOLD}Install Gist Scripts Locally${RESET}"
    echo ""
    echo "Basic usage: ./$(basename $0) <options>"
    echo "Examples: "
    echo "./$(basename $0) -d /share/scripts"
    echo ""
    echo "Options:"
    echo " ${YELLOW}-d${RESET}: directory to install scripts, defaults to ${DIRECTORY}"
    echo ""
}

# Gather options from flags.
while getopts "d:h:?:" opt; do
    case "$opt" in
	    d)
	        DIRECTORY=$OPTARG
	        ;;
	    h|\?)
	        show_help
	        exit 0
	        ;;
    esac
done
shift $((OPTIND-1))

echo "${YELLOW}Installing scripts to '${DIRECTORY}'${RESET}"

# Creates directory if not available
mkdir -p $DIRECTORY

# Add scripts to directory
for scriptName in "${SCRIPTS[@]}"
do
  script="$DIRECTORY/$scriptName"
  echo -e "#!/usr/bin/env bash\nsource <(curl -s https://raw.githubusercontent.com/mboudreau/gists/master/${scriptName})" > "$script"
  chmod +x "$script"
done

echo "${GREEN}Successfully installed scripts to '${DIRECTORY}': ${SCRIPTS[*]}${RESET}"

# add directory to bash profile & reload in current terminal
echo "${YELLOW}Adding scripts to ${HOME}/.profile${RESET}"
echo -e "# set PATH so it includes user's private bin if it exists\nif [ -d \"${DIRECTORY}\" ] ; then\n    PATH=\"${DIRECTORY}:$PATH\"\nfi" >> ~/.profile
source ~/.profile
echo "${GREEN}Done. You can now reference the scripts directly.${RESET}"
