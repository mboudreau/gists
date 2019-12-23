# Check if ffmpeg is available
if ! [ -x "$(command -v ffmpeg)" ]; then
  echo "${RED}ffmpeg is not installed, please install it first.${RESET}"
  exit 1
fi

ffmpeg -r 15 -pattern_type glob -i '*.jpg' -s hd720 -vcodec libx264 animation.mp4
