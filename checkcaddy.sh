#!/bin/bash

# checkcaddy.sh
#
# Checking the Caddy web server download page for the current version and
# calling the upgrade script 'getcaddy.sh' on a new version.
# This is meant to be called from root's cron.
#
# Usage: checkcaddy.sh [-n|--nogo] [caddy_binary_location]
#  where caddy_binary_location is the install location and the
# -n|--nogo switch gives a report on the necessity of upgrading
#
# Download: wget loof.bid/checkcaddy.sh

checkcaddy(){
	set -E
	trap 'echo "Aborted, error $? in command: $BASH_COMMAND"; return 1' ERR

	# URL for downloading getcaddy.sh
	getcaddy_url="loof.bid/getcaddy.sh"

	# URL for latest version
	latest="github.com/mholt/caddy/releases/latest"

	# Locations of the to-be-upgraded caddy binary and upgrade script
	local caddy_cmd=""
	local getcaddy_cmd=/usr/local/bin/getcaddy.sh

	# If -n/--nogo commandline option, take note
	[[ $1 = -n || $1 == --nogo ]] && shift && nogo=1 || nogo=0
	# Use caddy_install_location commandline option if present
	if [[ $1 ]]
	then
		[[ ${1:0:1} = / ]] && caddy_cmd=$1 || caddy_cmd=$PWD/$1
		if [[ $2 ]]
		then
			[[ $2 = -n || $2 == --nogo ]] && nogo=1
			shift 2
			[[ $1 ]] && echo "Aborted, too many commandline options: $*" && return 2
		fi
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
			&& return 3

	# Get version from installed binary
	local version=$("$caddy_cmd" --version)
	[[ -z $version ]] \
			&& echo "Aborted, caddy binary $caddy_cmd doesn't work" \
			&& return 4

	local web_version=$(wget -qO- "$latest" |
			grep '<span class="css-truncate-target">' |grep -o '[.0-9]*')
	[[ -z $web_version ]] \
			&& echo "Aborted, version not found in $latest" \
			&& return 5
	if [[ ! ${version##* } = $web_version ]]
	then  # different version: upgrade
		if [[ ! -f $getcaddy_cmd ]]
		then  # no upgrade file at default location
			if local getcaddy_type=$(type -p getcaddy.sh)
			then  # no upgrade file found in path
				getcaddy_cmd=$getcaddy_type
			else
				local sudo_cmd
				((EUID)) && [[ -z "$ANDROID_ROOT" ]] && sudo_cmd="sudo"
				$sudo_cmd wget -qO "$getcaddy_cmd" "$getcaddy_url"
			fi
		fi
		((nogo)) && echo "Upgrade available: Caddy $web_version" \
				|| bash "$getcaddy_cmd" , "$caddy_cmd"
	else
		((nogo)) && echo "$version up to date"
	fi

	trap ERR
	return 0
}

checkcaddy "$@"
checkcaddy_return=$?
((checkcaddy_return)) && echo "Not completed, aborted at $checkcaddy_return"
