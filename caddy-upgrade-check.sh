#!/bin/bash

# caddy-upgrade-check.sh
#
# Checking the Caddy web server download page for the current version and
# calling the upgrade script 'getcaddy.sh' on a new version.
#
# Usage: caddy-upgrade-check.sh [caddy_install_location]

# Locations of the to-be-upgraded caddy binary and upgrade script
caddy_path=
getcaddy=/usr/local/bin/getcaddy.sh

# Accommodate sourcing and executing
[[ $- = *i* ]] && Exit(){ return $1;} || Exit(){ exit $1;}

# Use caddy_install_location commandline option if present
[[ $1 ]] && caddy_path=$1

# If not hard-coded then find in PATH
if [[ -z $caddy_path ]]
then
	uname="$(uname)"
	declare -u unameu=$uname
	[[ $unameu = *WIN* ]] && caddy_bin=caddy.exe || caddy_bin=caddy
	caddy_path=$(type -p "$caddy_bin")
fi
[[ ! -x $caddy_path ]] \
		&& echo "Aborted $0, no caddy binary at $caddy_path" \
		&& Exit 1

# Get version from installed binary
version=$("$caddy_path" -version || true)
[[ -z $version ]] \
		&& echo "Aborted $0, caddy binary $caddy_path doesn't work" \
		&& Exit 2

web_version=$(wget -qO- caddyserver.com/download \
		|grep '<div class="version">Version [^<]*</div>' \
		|sed 's/.*<div class="version">Version //' \
		|grep -o '^[^<]*')

if [[ ${version##* } != $web_version ]]
then
	if [[ ! -f "$getcaddy" ]]
	then
		((EUID)) && [[ -z "$ANDROID_ROOT" ]] && sudo_cmd="sudo"
		$sudo_cmd wget -qO /usr/local/bin/getcaddy.sh loof.bid/getcaddy
	fi
	bash "$getcaddy" , "$caddy_path"
fi

Exit 0
