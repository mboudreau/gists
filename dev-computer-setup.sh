#!/usr/bin/env bash
set -e

BOLD=$(tput bold)
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
RESET=$(tput sgr0)
RELEASE=$(lsb_release -cs)

declare -a AVAILABLE_STEPS=("install-prerequisite" "add-ppa" "apt-install" "snap-install" "dist-upgrade" "p4merge" "zoom" "configure" "install-gnome-modules")
declare -a MESSAGES=()

function add_message() {
  echo "$1"
  MESSAGES+=("$1")
}

function show_help() {
  echo "${BOLD}Development Computer Setup Script${RESET}"
  echo ""
  echo "Basic usage: ./$(basename "$0") [options] [steps-to-run]"
  echo "Example: ./$(basename "$0") add-ppa apt-install"
  echo ""
  echo "By default, this scripts runs all the steps sequentially."
  echo "You can specify a list of space delimited steps like one of the following: ${AVAILABLE_STEPS[*]}"
  echo ""
  echo "${BOLD}Options${RESET}:"
  echo " ${BOLD}-h${RESET}: Help - Show me this helpful message."
}

# Gather options from flags.
while getopts "h:?:" opt; do
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
shift $((OPTIND - 1))

declare -a STEPS=("$@")

# Are steps specified?
if [[ -z "${STEPS[*]}" ]]; then
  echo "${YELLOW}No steps specified, running through all of them: ${AVAILABLE_STEPS[*]} ${RESET}"
  STEPS=("${AVAILABLE_STEPS[@]}")
else
  echo "${YELLOW}Running through specified steps: ${STEPS[*]} ${RESET}"
  for step in "${STEPS[@]}"; do
    # shellcheck disable=SC2076
    if [[ ! " ${AVAILABLE_STEPS[*]} " =~ " $step " ]]; then
      echo "${RED}Step '$step' is not available.  Please use one of the following: ${AVAILABLE_STEPS[*]} ${RESET}"
      exit 1
    fi
  done
fi

function dist-upgrade() {
  sudo apt-get update
  sudo apt-get dist-upgrade -y
}

function install-prerequisite() {
  echo "${YELLOW}Installing prerequisite dependencies...${RESET}"

  sudo apt-get update
  sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    wget \
    gnupg-agent \
    software-properties-common \
    gcc \
    g++ \
    make

  add_message "${GREEN}Prerequisite dependencies installed.${RESET}"
}

function add-apt() {
  sudo add-apt-repository -n -y "$@"
}

function add-apt-key() {
  # Default keyserver to ubuntu.com unless specified
  if [[ -z "$2" ]]; then
    2=hkps://keyserver.ubuntu.com:443
  fi
  sudo apt-key adv --keyserver "$2" --recv-keys "$1"
}

function add-apt-keyfile() {
  curl -sL "$@" | sudo apt-key add -
}

function add-apt-string() {
  echo "$2" | sudo tee "/etc/apt/sources.list.d/$1.list"
}

function add-ppa() {
  echo "${YELLOW}Adding PPAs...${RESET}"

  # DOCKER
  add-apt-keyfile https://download.docker.com/linux/ubuntu/gpg
  add-apt-string docker "deb [arch=amd64] https://download.docker.com/linux/ubuntu $RELEASE stable"

  # CHROME
  add-apt-keyfile https://dl-ssl.google.com/linux/linux_signing_key.pub
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
  add-apt-keyfile https://deb.nodesource.com/gpgkey/nodesource.gpg.key
  add-apt-string node "deb https://deb.nodesource.com/node_12.x $RELEASE main"
  add-apt-keyfile https://dl.yarnpkg.com/debian/pubkey.gpg
  add-apt-string yarn "deb https://dl.yarnpkg.com/debian/ stable main"

  # VIRTUALBOX
  add-apt-keyfile https://www.virtualbox.org/download/oracle_vbox_2016.asc
  add-apt-keyfile https://www.virtualbox.org/download/oracle_vbox.asc
  add-apt-string virtualbox "deb http://download.virtualbox.org/virtualbox/debian $RELEASE contrib"

  # BALENA ETCHER
  add-apt-string etcher "deb https://deb.etcher.io stable etcher"
  add-apt-key 379CE192D401AB61

  # UPDATE CACHE
  sudo apt-get update

  add_message "${GREEN}PPAs added.${RESET}"
}

function apt-install() {
  echo "${YELLOW}Installing APT packages...${RESET}"

  sudo apt-get update
  sudo apt-get install -y \
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
    virtualbox-6.1 \
    docker-ce docker-ce-cli containerd.io
#    balena-etcher-electron

  add_message "${GREEN}APT packages installed.${RESET}"
}

function snap-install() {
  declare -a SNAPS=("postman" "ngrok" "--classic dotnet-sdk" "--classic slack" "--classic webstorm" "--classic intellij-idea-ultimate" "--classic rider" "--classic sublime-text" "--beta authy")

  for pkg in "${SNAPS[@]}"
  do
    sudo snap install "$pkg"
  done

  echo -e "# set PATH to include /snap/bin\nPATH=\"/snap/bin:\$PATH\"" >>~/.profile
  source ~/.profile

  add_message "${GREEN}All Snap packages installed.${RESET}${YELLOW}${BOLD} You might need to logout/login to see the changes.${RESET}"
}

function p4merge() {
  DOWNLOAD_DIR=/tmp
  P4FILE=$DOWNLOAD_DIR/p4v.tgz
  P4_INSTALL_DIR=/usr/share/p4v
  wget -O $P4FILE https://cdist2.perforce.com/perforce/r19.2/bin.linux26x86_64/p4v.tgz
  tar zxvf $P4FILE -C $DOWNLOAD_DIR
  sudo cp -r $DOWNLOAD_DIR/p4v-* $P4_INSTALL_DIR/
  sudo ln -f -s $P4_INSTALL_DIR/bin/p4merge /usr/bin/p4merge

  add_message "${GREEN}P4Merge installed.${RESET}"
}

function zoom() {
  DOWNLOAD_DIR=/tmp
  ZOOM_FILE=zoom_amd64.deb
  ZOOM_FILEPATH=$DOWNLOAD_DIR/$ZOOM_FILE
  wget -O $ZOOM_FILEPATH "https://zoom.us/client/latest/${ZOOM_FILE}"
  sudo apt install -y $ZOOM_FILEPATH

  add_message "${GREEN}Zoom installed.${RESET}"
}

function configure() {
  # Increasing file watchers & restarting system controller
  echo "fs.inotify.max_user_watches = 524288" >/etc/sysctl.d/90-file-watchers.conf
  sudo sysctl -p --system

  # Adding user to docker group
  sudo usermod -aG docker $USER

  # Adding git config
  read -rp 'Your Name: ' gitname
  git config --global user.name "${gitname}"
  read -rp 'Your Email: ' gitemail
  git config --global user.email "${gitemail}"

  # Set git merge config
  git config --global merge.tool p4merge
  git config --global diff.tool p4merge
  git config --global mergetool.keepBackup false
  git config --global mergetool.keepTemporaries false
  git config --global mergetool.prompt false
  git config --global difftool.prompt false
  git config --global core.excludesfile '~/.gitignore'

  # Adding git alias "all"
  git config --global alias.all '!f() { ls -R -d */.git | sed 's,\/.git,,' | xargs -P10 -I{} git -C {} $@; }; f'

  # Adding git global ignore file
  echo ".idea/" >>~/.gitignore

  add_message "${GREEN}System has been configured.${RESET}"
}

function install-gnome-modules() {
  LINKS=("https://extensions.gnome.org/extension/708/panel-osd/" "https://extensions.gnome.org/extension/1160/dash-to-panel/" "https://extensions.gnome.org/extension/615/appindicator-support/")
  echo ""
  echo "${YELLOW}Installing gnome modules through firefox, trying to open following links through command line:${RESET}"
  for link in "${LINKS[@]}"; do
    echo "$link"
    firefox "$link" &
  done
}

for step in "${STEPS[@]}"; do
  # Call function of the step name
  $step
done

echo ""
echo "Setup complete:"
# Display all end messages
for msg in "${MESSAGES[@]}"; do
  echo " - $msg"
done
echo ""
