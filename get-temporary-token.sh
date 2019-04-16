#!/usr/bin/env bash

BOLD=`tput bold`
RED=`tput setaf 1`
GREEN=`tput setaf 2`
YELLOW=`tput setaf 3`
RESET=`tput sgr0`

PREFIX="tmp-token-"
CONFIGFILE_PATH="${HOME}/.aws/config"

function show_help {
    echo "${GREEN}${BOLD}AWS Assumed Role Temporary Token Utility${RESET}"
    echo ""
    echo "Basic usage: ./$(basename $0) <command> [values]"
    echo "Examples: "
    echo "./$(basename $0) configure [profile-name] [some-user] [some-role] [role-account-number] [access-key] [secret-key]"
    echo "./$(basename $0) get [profile-name] [mfa-token]"
    echo ""
    echo "${BOLD}All values are optional.${RESET} The script will prompt for the values if not given."
    echo "You must first run 'configure' to save a profile, then run 'get' to get the token based on the profile."
    echo ""
    echo "Commands:"
    echo " ${YELLOW}get${RESET}: Get token of specified profile."
    echo " ${YELLOW}configure${RESET}: Create profile for particular session."
    echo " ${YELLOW}help${RESET}: Show this helpful message."
    echo ""
}

function show_profiles {
		TITLE=$1
		if [ -z "$TITLE" ]
		then
			TITLE="Available Profiles"
		fi
		echo "${TITLE}: `sed -n 's#\[profile '${PREFIX}'\(.*\)\]#\1#p' ${CONFIGFILE_PATH} | tr '\n' ' '`"
}

# Check if aws is available
if ! [ -x "$(command -v aws)" ]; then
  echo "${RED}AWS CLI is not installed, please install it.${RESET}"
  return 1
fi

COMMAND=$1; shift
case "$COMMAND" in

  configure)
		echo "${YELLOW}Configuring a profile for easier temporary token retrieval.  Please answer ${BOLD}all${RESET}${YELLOW} the following questions.${RESET}";

		PROFILE=$1; shift
		USER=$1; shift
		ROLE_NAME=$1; shift
		ACCOUNT_NUMBER=$1; shift
		ACCESS_KEY=$1; shift
		SECRET_KEY=$1; shift

		if [ -z "$PROFILE" ]
		then
			read -p "Profile Name: " PROFILE
			if [ -z "$PROFILE" ]
			then
				echo "${RED}Profile must be specified.${RESET}"
				return 1
			fi
		fi
		PROFILE=${PREFIX}${PROFILE}

    if [ -z "$USER" ]
		then
			read -p "Username: " USER
			if [ -z "$USER" ]
			then
				echo "${RED}Username must be specified.${RESET}"
				return 1
			fi
		fi

		if [ -z "$ROLE_NAME" ]
		then
			read -p "Assumed Role Name: " ROLE_NAME
			if [ -z "$ROLE_NAME" ]
			then
				echo "${RED}Role must be specified.${RESET}"
				return 1
			fi
		fi

		if [ -z "$ACCOUNT_NUMBER" ]
		then
			read -p "Role Account Number: " ACCOUNT_NUMBER
			if [ -z "$ACCOUNT_NUMBER" ]
			then
				echo "${RED}Account Number key must be specified.${RESET}"
				return 1
			fi
		fi

		if [ -z "$ACCESS_KEY" ]
		then
			read -p "Access Key ID: " ACCESS_KEY
			if [ -z "$ACCESS_KEY" ]
			then
				echo "${RED}Access key must be specified.${RESET}"
				return 1
			fi
		fi

		if [ -z "$SECRET_KEY" ]
		then
			echo -n "Secret Access Key: "
			unset SECRET_KEY
			unset CHARCOUNT
			CHARCOUNT=0
			stty -echo
			while IFS= read -p "$PROMPT" -r -s -n 1 CHAR
			do
			    # Enter - accept SECRET_KEY
			    if [[ $CHAR == $'\0' ]] ; then
			        break
			    fi
			    # Backspace
			    if [[ $CHAR == $'\177' ]] ; then
			        if [ $CHARCOUNT -gt 0 ] ; then
			            CHARCOUNT=$((CHARCOUNT-1))
			            PROMPT=$'\b \b'
			            SECRET_KEY="${SECRET_KEY%?}"
			        else
			            PROMPT=''
			        fi
			    else
			        CHARCOUNT=$((CHARCOUNT+1))
			        PROMPT='*'
			        SECRET_KEY+="$CHAR"
			    fi
			done
			stty echo
			echo ""

			if [ -z "$SECRET_KEY" ]
			then
				echo "${RED}Secret key must be specified.${RESET}"
				return 1
			fi
		fi

    aws configure set user ${USER} --profile ${PROFILE}
    aws configure set account_number ${ACCOUNT_NUMBER} --profile ${PROFILE}
    aws configure set role_name ${ROLE_NAME} --profile ${PROFILE}
    aws configure set aws_access_key_id ${ACCESS_KEY} --profile ${PROFILE}
    aws configure set aws_secret_access_key ${SECRET_KEY} --profile ${PROFILE}
    ;;

	profiles)
		show_profiles "Configured Profiles"
		;;

  get)
		PROFILE=$1; shift
		TOKEN=$1; shift

    if [ -z "$PROFILE" ]
		then
			show_profiles
			read -p "Profile Name: " PROFILE
			if [ -z "$PROFILE" ]
			then
				echo "${RED}Profile must be specified.${RESET}"
				return 1
			fi
			# Check if profile exists
			if ! [ -x "$(aws configure get aws_access_key_id --profile ${PREFIX}${PROFILE})" ]; then
			  echo "${RED}Profile '${PROFILE}' does not exist.${RESET}"
			  return 1
			fi
		fi
		PROFILE=${PREFIX}${PROFILE}

		if [ -z "$TOKEN" ]
		then
			read -p "MFA Token: " TOKEN
			if [ -z "$TOKEN" ]
			then
				echo "${RED}MFA token must be specified.${RESET}"
				return 1
			fi
		fi

		ACCESS_KEY=`aws configure get aws_access_key_id --profile ${PROFILE}`
    SECRET_KEY=`aws configure get aws_secret_access_key --profile ${PROFILE}`
    USER=`aws configure get user --profile ${PROFILE}`
    ACCOUNT_NUMBER=`aws configure get account_number --profile ${PROFILE}`
    ROLE_NAME=`aws configure get role_name --profile ${PROFILE}`

    # Unset AWS credentials that might have been set in the environment
		unset AWS_SESSION_TOKEN
		unset AWS_ACCESS_KEY_ID
		unset AWS_SECRET_ACCESS_KEY
		unset AWS_EXPIRATION

		RESULT=`aws sts assume-role --role-arn arn:aws:iam::${ACCOUNT_NUMBER}:role/${ROLE_NAME} --role-session-name ${PROFILE} --duration-seconds 3600 --serial-number arn:aws:iam::254809263639:mfa/${USER} --token-code ${TOKEN} --profile ${PROFILE}`

		if [ ! -z "$RESULT" ]
		then
			export AWS_ACCESS_KEY_ID=`echo ${RESULT} | jq -r '.Credentials.AccessKeyId'`
			export AWS_SECRET_ACCESS_KEY=`echo ${RESULT} | jq -r '.Credentials.SecretAccessKey'`
			export AWS_SESSION_TOKEN=`echo ${RESULT} | jq -r '.Credentials.SessionToken'`
			export AWS_EXPIRATION="`echo ${RESULT} | jq -r '.Credentials.Expiration' | date -f -`"

			echo "${BOLD}${GREEN}SUCCESS!${RESET}"
			echo ""
			echo ""
			echo "${BOLD}${YELLOW}LINUX / MAC${RESET}"
			echo ""
			echo "export AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}"
			echo "export AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}"
			echo "export AWS_SESSION_TOKEN=${AWS_SESSION_TOKEN}"
			echo "export AWS_EXPIRATION=\"${AWS_EXPIRATION}\""
			echo ""
			echo ""
			echo "${BOLD}${YELLOW}POWERSHELL${RESET}"
			echo ""
			echo "\$env:AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}"
			echo "\$env:AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}"
			echo "\$env:AWS_SESSION_TOKEN=${AWS_SESSION_TOKEN}"
			echo ""
			echo ""
			echo "${BOLD}${YELLOW}CMD${RESET}"
			echo ""
			echo "set AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}"
			echo "set AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}"
			echo "set AWS_SESSION_TOKEN=${AWS_SESSION_TOKEN}"
			echo ""
			echo ""
			echo "${GREEN}${BOLD}EXPIRES `echo ${AWS_EXPIRATION}`${RESET}"
			echo ""
			echo "${YELLOW}If you used 'source ./$(basename $0)', the environment variables are already set, if not, you need to copy/paste the above into your command line to set them.${RESET}"
		fi
    ;;

	expired)
		if [ -z "$AWS_EXPIRATION" ]
		then
			echo "${RED}AWS Session was never set in this terminal.${RESET}"
			return 1
		fi
		EXPIRY="`echo ${AWS_EXPIRATION} | date -f - +%s`"
		if [[ `date +%s` -gt "$EXPIRY" ]]
		then
			echo ""
			echo "${BOLD}${RED}SESSION IS EXPIRED.${RESET}"
			echo ""
			return 1
		else
			SECONDS_LEFT=$(($EXPIRY - `date +%s`))
			echo ""
			echo "${BOLD}${GREEN}SESSION IS STILL GOOD, $(($SECONDS_LEFT/60)) MINUTES LEFT.${RESET}"
			echo ""
		fi
		;;

	help|*)
		show_help
    ;;
esac
