#!/bin/bash

# checkcaddy.sh
#
# Checking the Caddy web server download page for the current version and
# calling the upgrade script 'getcaddy.sh' on a new version.
#
# Usage: checkcaddy.sh [caddy_cmd]  # where caddy_cmd is the install location

checkcaddy(){
	set -E
	trap 'echo "Aborted, error $? in command: $BASH_COMMAND"; return 1' ERR

	# Locations of the to-be-upgraded caddy binary and upgrade script
	local caddy_cmd=""
	local getcaddy_cmd=/usr/local/bin/getcaddy.sh

	# Use caddy_install_location commandline option if present
	if [[ $1 ]]
	then
		[[ ${1:0:1} = / ]] && caddy_cmd=$1 || caddy_cmd=$PWD/$1
	fi

	# If not hard-coded then find in PATH
	if [[ -z $caddy_cmd ]]
	then
		local uname="$(uname)"
		local -u unameu=$uname
		local caddy_bin
		[[ $unameu = *WIN* ]] && caddy_bin=caddy.exe || caddy_bin=caddy
		caddy_cmd=$(type -p "$caddy_bin")
	fi
	[[ ! -x $caddy_cmd ]] \
			&& echo "Aborted, no caddy binary at $caddy_cmd" \
			&& return 1

	# Get version from installed binary
	local version=$("$caddy_cmd" -version)
	[[ -z $version ]] \
			&& echo "Aborted, caddy binary $caddy_cmd doesn't work" \
			&& return 2

	local web_version=$(wget -qO- caddyserver.com/download |grep -o 'Version [^<]*')
	[[ -z $web_version ]] \
			&& echo "Aborted, version not found in http://caddyserver.com/download" \
			&& return 3
	if [[ ${version##* } != ${web_version##* } ]]
	then  # different version: upgrade
		if [[ ! -f $getcaddy_cmd ]]
		then  # no upgrade file at default location
			if local getcaddy_type=$(type -p getcaddy.sh)
			then  # no upgrade file found in path
				getcaddy_cmd=$getcaddy_type
			else
				local sudo_cmd
				((EUID)) && [[ -z "$ANDROID_ROOT" ]] && sudo_cmd="sudo"
				$sudo_cmd wget -qO "$getcaddy_cmd" loof.bid/getcaddy
			fi
		fi
		bash "$getcaddy_cmd" , "$caddy_cmd"
	fi

	trap ERR
	return 0
}

checkcaddy "$@"
checkcaddy_return=$?
((checkcaddy_return)) && echo "Not completed, aborted at $checkcaddy_return"
