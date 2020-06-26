#!/usr/bin/env bash
set -e

BOLD=$(tput bold)
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
RESET=$(tput sgr0)
RELEASE=$(lsb_release -cs)

# Check if ffmpeg is available
if ! [ -x "$(command -v ffmpeg)" ]; then
  echo "${RED}ffmpeg is not installed, please install it first.${RESET}"
  exit 1
fi

# Default output name is the name of the containing folder
OUTPUT="${PWD##*/}"

# Check to see if a name was specified for the output file
if [[ -n "$1" ]]; then
  OUTPUT="$1"
fi

# Gather options from flags.
while getopts "o:" opt; do
    case "$opt" in
    o)
        OUTPUT=$OPTARG
        ;;
   *)
      ;;
    esac
done
shift $((OPTIND-1))

ffmpeg -r 15 -pattern_type glob -i '*.jpg' -s hd1080 -vcodec libx264 "${OUTPUT}.mp4"
