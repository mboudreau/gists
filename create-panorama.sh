#!/usr/bin/env bash
set -e

BOLD=$(tput bold)
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
RESET=$(tput sgr0)
RELEASE=$(lsb_release -cs)

# Check if hugin is available
if ! [ -x "$(command -v hugin)" ]; then
  echo "${RED}hugin is not installed, please install it first.${RESET}"
  exit 1
fi

if [[ $# -lt 2 ]]; then
    echo "${RED}Need a minimum of 2 images to create a panorama.${RESET}"
    exit 2
fi

PROJECT="/tmp/project-$(date +'%s').pto"
PREFIX="$1-${@: -1}-panorama"

pto_gen -o "$PROJECT" "$@"
cpfind -o "$PROJECT" --multirow --celeste "$PROJECT"
cpclean -o "$PROJECT" "$PROJECT"
linefind -o "$PROJECT" "$PROJECT"
autooptimiser -a -m -l -s -o "$PROJECT" "$PROJECT"
pano_modify --ldr-file=JPG --ldr-compression=100 --canvas=AUTO --crop=AUTO -o "$PROJECT" "$PROJECT"
hugin_executor --stitching --prefix="$PREFIX" "$PROJECT"
