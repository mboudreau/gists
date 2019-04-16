#!/usr/bin/env bash

BOLD=`tput bold`
RED=`tput setaf 1`
GREEN=`tput setaf 2`
YELLOW=`tput setaf 3`
RESET=`tput sgr0`

function show_help {
    echo "${GREEN}${BOLD}XFree RDP Utility${RESET}"
    echo ""
    echo "Basic usage: ./$(basename $0) <options> <IP>[:PORT]"
    echo "Examples: "
    echo "./$(basename $0) connect -u username -p password 192.168.1.1"
    echo ""
    echo "Options:"
    echo " ${YELLOW}-u${RESET}: Username"
    echo " ${YELLOW}-p${RESET}: password"
    echo " ${YELLOW}-g${RESET}: gateway address"
    echo " ${YELLOW}-d${RESET}: domain"
    echo " ${YELLOW}-l${RESET}: set log level"
    echo ""
}

# Gather options from flags.
while getopts "u:p:g:d:l:h:help" opt; do
    case "$opt" in
	    u)
	        USERNAME=$OPTARG
	        ;;
	    p)
	        PASSWORD=$OPTARG
	        ;;
	    g)
	        GATEWAY=$OPTARG
	        ;;
	    d)
	        DOMAIN=$OPTARG
	        ;;
	    l)
            LOGLEVEL=$OPTARG
            ;;
	    h|help|\?)
	        show_help
	        exit 0
	        ;;
    esac
done
shift $((OPTIND-1))

ADDRESS=$1; shift

# Check if xfreerdp is available
INSTALL_COMMAND="sudo add-apt-repository ppa:remmina-ppa-team/remmina-next; sudo apt-get update; sudo apt-get install freerdp2-x11"
if ! [ -x "$(command -v xfreerdp)" ]; then
  echo "${RED}Please install xfreerdp2: ${INSTALL_COMMAND}.${RESET}"
  return 1
fi

# Make sure it's version 2
if ! [[ "$(xfreerdp --version)" = *"version 2."* ]]; then
  echo "${RED}You have freerdp version 1, Please install xfreerdp2: ${INSTALL_COMMAND}.${RESET}"
  return 1
fi

if [ -z "$ADDRESS" ]
then
	read -p "IP[:PORT]: " IP
	if [ -z "$ADDRESS" ]
	then
		echo "${RED}Address must be specified.${RESET}"
		return 1
	fi
fi

if [ -z "$USERNAME" ]
then
	read -p "Username: " USERNAME
	if [ -z "$USERNAME" ]
	then
		echo "${RED}Username must be specified.${RESET}"
		return 1
	fi
fi

if [ -z "$PASSWORD" ]
then
	echo -n "Password: "
	unset PASSWORD
	unset CHARCOUNT
	CHARCOUNT=0
	stty -echo
	while IFS= read -p "$PROMPT" -r -s -n 1 CHAR
	do
	    # Enter - accept password
	    if [[ $CHAR == $'\0' ]] ; then
	        break
	    fi
	    # Backspace
	    if [[ $CHAR == $'\177' ]] ; then
	        if [ $CHARCOUNT -gt 0 ] ; then
	            CHARCOUNT=$((CHARCOUNT-1))
	            PROMPT=$'\b \b'
	            PASSWORD="${PASSWORD%?}"
	        else
	            PROMPT=''
	        fi
	    else
	        CHARCOUNT=$((CHARCOUNT+1))
	        PROMPT='*'
	        PASSWORD+="$CHAR"
	    fi
	done
	stty echo
	echo ""
	if [ -z "$PASSWORD" ]
	then
		echo "${RED}Password must be specified.${RESET}"
		return 1
	fi
fi

# Set default arguments list
ARGS=("/v:${ADDRESS}" "/u:$USERNAME" "/p:$PASSWORD")

if ! [ -z "$GATEWAY" ]
then
	ARGS+=("/g:$GATEWAY /gu:$USERNAME /gp:$PASSWORD")
fi

if ! [ -z "$DOMAIN" ]
then
	ARGS+=("/gd:$DOMAIN")
fi

if ! [ -z "$LOGLEVEL" ]
then
    ARGS+=("/log-level:$(echo $LOGLEVEL | tr '[:lower:]' '[:upper:]')")
fi

echo "${YELLOW}Connecting to RDP session at ${ADDRESS}.${RESET}";

xfreerdp +window-drag +clipboard +home-drive +heartbeat +fonts /dynamic-resolution /gdi:hw +auto-reconnect ${ARGS[*]}

