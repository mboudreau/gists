#!/usr/bin/env bash
set -e

BOLD=$(tput bold)
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
RESET=$(tput sgr0)
RELEASE=$(lsb_release -cs)

declare -a AVAILABLE_STEPS=("dist-upgrade" "install-prerequisite" "add-ppa" "apt-install" "snap-install" "flatpak-install" "volta-install" "docker-compose" "p4merge" "install-autocpufreq" "configure" "install-gnome-modules")
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
    cifs-utils \
    ca-certificates \
    curl \
    wget \
    gnupg-agent \
    software-properties-common \
    gcc \
    g++ \
    make \
    jq \
    snapd \
    flatpak
  
  # Install Volta
  curl https://get.volta.sh | bash
  source ~/.profile

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

  # VIRTUALBOX
  add-apt-keyfile https://www.virtualbox.org/download/oracle_vbox_2016.asc
  add-apt-keyfile https://www.virtualbox.org/download/oracle_vbox.asc
  add-apt-string virtualbox "deb [arch=amd64] http://download.virtualbox.org/virtualbox/debian $RELEASE contrib"

  # BALENA ETCHER
  # add-apt-string etcher "deb https://deb.etcher.io stable etcher"
  # add-apt-key 379CE192D401AB61
  
  # GTHUMB
  add-apt ppa:dhor/myway

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
    freerdp2-x11 \
    ghostwriter \
    git \
    dconf-editor \
    gnome-system-monitor \
    gnome-disk-utility \
    gimp \
    libreoffice \
    vlc \
    openssh-server \
    gnome-tweaks \
    virtualbox-6.1 \
    ffmpeg \
    docker-ce docker-ce-cli containerd.io \
    awscli \
    gthumb
#    balena-etcher-electron

  add_message "${GREEN}APT packages installed.${RESET}"
}

function snap-install() {
  declare -a SNAPS=("postman" "ngrok" "--classic dotnet-sdk" "--classic webstorm" "--classic intellij-idea-ultimate" "--classic rider" "--classic sublime-text" "--beta authy")

  for pkg in "${SNAPS[@]}"
  do
    sudo snap install $pkg
  done

  echo -e "# set PATH to include /snap/bin\nPATH=\"/snap/bin:\$PATH\"" >> ~/.profile
  source ~/.profile

  add_message "${GREEN}All Snap packages installed.${RESET}${YELLOW}${BOLD} You might need to logout/login to see the changes.${RESET}"
}

function flatpak-install() {
  declare -a FLATS=("us.zoom.Zoom" "org.inkscape.Inkscape" "com.slack.Slack")
  
  # Add flathub remote if missing
  sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

  for pkg in "${FLATS[@]}"
  do
    sudo flatpak install -y flathub $pkg
  done

  # Small fix for zoom on wayland
  sudo flatpak override --env=GDK_BACKEND=wayland us.zoom.Zoom
  sudo flatpak override --env=XDG_CURRENT_DESKTOP=GNOME us.zoom.Zoom
  sudo flatpak override --socket=wayland us.zoom.Zoom

  add_message "${GREEN}All Flatpak packages installed.${RESET}${YELLOW}${BOLD} You might need to logout/login to see the changes.${RESET}"
}

function volta-install() {
  declare -a PACKAGES=("node" "yarn")
  
  for pkg in "${PACKAGES[@]}"
  do
    volta install $pkg
  done

  add_message "${GREEN}All Volta packages installed.${RESET}${YELLOW}${BOLD}"
}

function docker-compose() {
  COMPOSE_RELEASE=$(curl --silent "https://api.github.com/repos/docker/compose/releases/latest" | grep -Po '"tag_name": "\K.*?(?=")')

  sudo curl -L https://github.com/docker/compose/releases/download/$COMPOSE_RELEASE/docker-compose-$(uname -s)-$(uname -m) -o /usr/bin/docker-compose
  sudo chmod +x /usr/bin/docker-compose

  add_message "${GREEN}docker-compose installed.${RESET}"
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

function displaylink() {
  DOWNLOAD_DIR=/tmp/displaylink
  [[ -f $DOWNLOAD_DIR ]] && sudo rm -R $DOWNLOAD_DIR
  git clone https://github.com/AdnanHodzic/displaylink-debian.git $DOWNLOAD_DIR
  pushd $DOWNLOAD_DIR
  sudo ./displaylink-debian.sh
  popd

  add_message "${GREEN}DisplayLink driver installed.${RESET}"
}

function configure() {
  # Increasing file watchers & restarting system controller
  echo "${YELLOW}Increasing file watcher maximum...${RESET}"
  echo "fs.inotify.max_user_watches = 524288" | sudo tee /etc/sysctl.d/90-file-watchers.conf
  sudo sysctl -p --system

  # Adding user to docker group
  echo "${YELLOW}Adding user to docker group...${RESET}"
  sudo usermod -aG docker $USER

  # Adding git config
  echo "${YELLOW}Setting up Git global config...${RESET}"
  read -rp 'Your Name: ' gitname
  git config --global user.name "${gitname}"
  read -rp 'Your Email: ' gitemail
  git config --global user.email "${gitemail}"
  git config --global push.default current

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
  echo ".idea/" >> ~/.gitignore

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

function install-autocpufreq() {
  sudo git clone https://github.com/AdnanHodzic/auto-cpufreq.git /usr/src/auto-cpufreq
  sudo /usr/src/auto-cpufreq/auto-cpufreq-installer --install
  sudo auto-cpufreq --install
  
  add_message "${GREEN}Auto-cpufreq daemon has been installed.${RESET}"
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
