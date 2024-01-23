#!/usr/bin/env bash

BOLD=`tput bold`
RED=`tput setaf 1`
GREEN=`tput setaf 2`
YELLOW=`tput setaf 3`
RESET=`tput sgr0`

echo "${YELLOW}${BOLD}You are about to stop all containers and DELETE ALL THE DOCKER THINGS.${RESET}"
echo ""
read -p "Do you want to continue? [y/N] " CONTINUE

if [ "${CONTINUE,,}" != "y" ]
then
  echo "Exiting."
  exit 0
fi

CONTAINERS=$(docker ps -qa)
if ! [ -z "$CONTAINERS" ]
then
  echo "Stopping running docker containers..."
  docker stop `docker ps -qa`
  echo "${GREEN}All docker containers stopped.${RESET}"
fi

echo "Deleting all docker resources..."
docker system prune -f --volumes --all
echo "${GREEN}All docker resources deleted forever.  You have now a clean slate.${RESET}"