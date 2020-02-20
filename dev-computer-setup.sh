#!/usr/bin/env bash
set -e

BOLD=`tput bold`
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
RESET=$(tput sgr0)
RELEASE=$(lsb_release -cs)

declare -a AVAILABLE_STEPS=("install-prerequisite" "add-ppa" "apt-install" "snap-install" "dist-upgrade", "configure")

function show_help {
    echo "${BOLD}Development Computer Setup Script${RESET} - Must be ran as sudo to work"
    echo ""
    echo "Basic usage: sudo ./$(basename $0) [options] [steps-to-run]"
    echo "Example: sudo ./$(basename $0) add-ppa apt-install"
    echo ""
    echo "By default, this scripts runs all the steps sequentially."
    echo "You can specify a list of space delimited steps like one of the following: ${AVAILABLE_STEPS[@]}"
    echo ""
    echo "${BOLD}Options${RESET}:"
    echo " ${BOLD}-h${RESET}: Help - Show me this helpful message."
}

# Check if in sudo
if [ "$EUID" -ne 0 ]
then
    echo "${YELLOW}You must run this script as sudo to be able to do everything. Exiting.${RESET}"
    exit 1
fi

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
    esac
done
shift $((OPTIND-1))

declare -a STEPS=( "$@" )

# Are steps specified?
if [[ -z "${STEPS}" ]]; then
    echo "${YELLOW}No steps specified, running through all of them: ${AVAILABLE_STEPS[@]} ${RESET}"
    STEPS=( "${AVAILABLE_STEPS[@]}" )
else
    echo "${YELLOW}Running through specified steps: ${STEPS[@]} ${RESET}"
    for step in "${STEPS[@]}"
    do
        if [[ ! $STEPS =~ (^| )$step($| ) ]]; then
            echo "${RED}Step '$step' is not available.  Please use one of the following: $AVAILABLE_STEPS[@]${RESET}"
            exit 1
        fi
    done
fi

function dist-upgrade {
    apt-get update
    apt-get dist-upgrade -y
}

function install-prerequisite {
    echo "${YELLOW}Installing prerequisite dependencies...${RESET}"

    apt-get update
    apt-get install -y \
        apt-transport-https \
        ca-certificates \
        curl \
        wget \
        gnupg-agent \
        software-properties-common \
        gcc \
        g++ \
        make

    echo "${GREEN}Prerequisite dependencies installed.${RESET}"
}

function add-ppa {
    echo "${YELLOW}Adding PPAs...${RESET}"

    # DOCKER
    add-apt-key https://download.docker.com/linux/ubuntu/gpg
    add-apt-string docker "deb [arch=amd64] https://download.docker.com/linux/ubuntu $RELEASE stable"

    # CHROME
    add-apt-key https://dl-ssl.google.com/linux/linux_signing_key.pub
    add-apt-string google-chrome "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main"

    # FIREFOX
    add-apt ppa:mozillateam/ppa

    # WEBUPD8
    add-apt ppa:nilarimogard/webupd8

    # REMMIMMA (FREERDP)
    add-apt ppa:remmina-ppa-team/remmina-next

    # GHOSTWRITER
    add-apt ppa:wereturtle/ppa

    # GIT
    add-apt ppa:git-core/ppa

    # LIBRE OFFICE
    add-apt ppa:libreoffice/ppa

    # OIBAF VIDEO DRIVERS
    add-apt ppa:oibaf/graphics-drivers

    # NODE & NPM & YARN
    add-apt-key https://deb.nodesource.com/gpgkey/nodesource.gpg.key
    echo "deb https://deb.nodesource.com/node_10.x $RELEASE main" > /etc/apt/sources.list.d/node.list
    add-apt-key https://dl.yarnpkg.com/debian/pubkey.gpg
    add-apt-string yarn "deb https://dl.yarnpkg.com/debian/ stable main"

    # VIRTUALBOX
    add-apt-key https://www.virtualbox.org/download/oracle_vbox_2016.asc
    add-apt-key https://www.virtualbox.org/download/oracle_vbox.asc
    add-apt-string virtualbox "deb http://download.virtualbox.org/virtualbox/debian $RELEASE contrib"
    
    # UPDATE CACHE
    apt-get update

    echo "${GREEN}PPAs added.${RESET}"
}

function apt-install {
    echo "${YELLOW}Installing APT packages...${RESET}"

    apt-get update
    apt-get install -y \
        google-chrome-stable \
        firefox \
        snapd \
        freerdp2-x11 \
        ghostwriter \
        git \
        dconf-editor \
        gnome-system-monitor \
        gnome-disk-utility \
        gimp \
        libreoffice \
        inkscape \
        vlc \
        nodejs \
        yarn \
        openssh-server \
        gnome-tweaks \
        virtualbox-6.1

    echo "${GREEN}APT packages installed.${RESET}"
}

function snap-install {
    snap install postman
    snap install ngrok
    snap install --classic dotnet-sdk
    snap install --classic slack
    snap install --classic webstorm
    snap install --classic intellij-idea-ultimate
    snap install --classic rider
    snap install --classic sublime-text

    echo "${GREEN}All Snap packages installed.${RESET}${YELLOW} You might need to logout/login to see the changes.${RESET}"
}

function add-apt {
    add-apt-repository -n -y "$@"
}

function add-apt-key {
    curl -sL "$@" | sudo apt-key add -
}

function add-apt-string {
    echo "$2" | sudo tee "/etc/apt/sources.list.d/$1.list"
}

function configure {
    # Increasing file watchers & restarting system controller
    echo "fs.inotify.max_user_watches = 524288" > /etc/sysctl.d/90-file-watchers.conf
    sysctl -p --system

    # Adding git config
    read -p 'Git User Name: ' gitname
    git config --global user.name "${gitname}"
    read -p 'Git Email: ' gitemail
    git config --global user.email "${gitemail}"

    # Adding git alias "all"
    git config --global alias.all '!f() { ls -R -d */.git | sed 's,\/.git,,' | xargs -P10 -I{} git -C {} $1; }; f'
}

for step in "${STEPS[@]}"
do
    # Call function of the step name
    $step
done

