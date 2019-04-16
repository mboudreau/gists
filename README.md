# gists

Great centralized place to put in tidbits of scripts that can be ran from anywhere:

* **Bash** using `source <(curl -s https://raw.githubusercontent.com/mboudreau/gists/master/YOUR-SCRIPT-HERE.sh)`
* **Powershell** using `iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/mboudreau/gists/master/YOUR-SCRIPT-HERE.ps1'))`

To have these scripts referenced locally for the specific user, run `echo "source <(curl -s https://raw.githubusercontent.com/mboudreau/gists/master/YOUR-SCRIPT-HERE.sh)" > ~/.local/bin/YOUR-SCRIPT-HERE.sh; chmod +x ~/.local/bin/YOUR-SCRIPT-HERE.sh`.

### install-hashicorp

Installs the specified HashiCorp product unto your local computer, uses the latest version if none are specified.

`./install-hashicorp.sh [consul|nomad|otto|packer|serf|terraform|vagrant|vault] <version>`

### get-temporary-token

Configures profiles for the various accounts/roles to be assumed.  
First, configure a profile by doing `./get-temporary-token.sh configure [profile-name] [user-name] [role-name] [role-account-number] [access-key] [secret-key]`, then get the token based on the profile created by running `./get-temporary-token get [profile-name] [mfa-token]`.
You can check the status of your session by running `./get-temporary-token.sh expired`.

For easier environment variable setting, run the script with `source ./get-temporary-token.sh get [profile-name] [mfa-token]`.
All information is stored in the [default AWS config/credential location](https://docs.aws.amazon.com/cli/latest/userguide/cli-config-files.html) for better security.

### rdp

Connects to an RDP session for Linux/Mac using [xfreerdp2](https://launchpad.net/~remmina-ppa-team/+archive/ubuntu/remmina-next).
Simply run `./rdp [IP]<:PORT>`, it will prompt you for your username and password, or you can set them inline by using the option `-u <username> -p <password>`.

### install-p4merge-git

Install p4merge, the best god damn diff/merge tool out there, and configures git to use it as the default if git is available.  Installs the latest version (after some discovery) if none is specified.

`./install-p4merge-git.sh <version>`