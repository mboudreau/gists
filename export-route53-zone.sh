#!/usr/bin/env bash

BOLD=`tput bold`
RED=`tput setaf 1`
GREEN=`tput setaf 2`
YELLOW=`tput setaf 3`
RESET=`tput sgr0`

function show_help {
    echo "${BOLD}Export Route53 Zone Script${RESET}"
    echo ""
    echo "Basic usage: ./$(basename $0) <Hosted Zone ID>"
    echo "Example: ./$(basename $0) Z0283645FJSIFZL3FDQU"
    echo ""
    echo "Make sure you're logged in to AWS before running this script. jq is required to run: sudo apt install jq"
    echo "If you want to create an file ouput, just do ./$(basename $0) Z0283645FJSIFZL3FDQU > <your domain>.zone"
}

aws route53 list-resource-record-sets --hosted-zone-id $1 --output json | jq -jr '.ResourceRecordSets[] | "\(.Name) \t\(.TTL) \t\(.Type) \t\(.ResourceRecords[].Value)\n"'
