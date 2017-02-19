#!/usr/bin/env bash
#
#   Caddy web server installer and upgrade script
#
#   Caddy homepage: https://caddyserver.com
#   Getcaddy issues: https://github.com/pepa65/getcaddy.com/issues
#   Required: bash, coreutils, sed, grep, curl/wget, tar (or unzip on OSX and Windows)
#
# Bash script to install the single-binary Caddy web server. Use it like this:
#
#   $ curl -sL loof.bid/getcaddy |bash
#	or
#	  $ wget -qO- loof.bid/getcaddy |bash
#
# If you want to get Caddy with extra features, use bash -s with a
# comma-separated list of directives, like this:
#
#	  $ wget -qO- loof.bid/getcaddy |bash -s git,mailout
#
# Or the script can be first downloaded and then run with the feature list:
#
#   $ wget -O getcaddy.sh loof.bid/getcaddy
#   $ bash getcaddy.sh git,mailout
#
# When the feature list starts with a comma, the features are added to the
# existing binary's current features. When the feature list is 'all', all
# available features will be added in. Just 'same' means: keep the same
# features. And 'none' means: no features will be included.
# See https://caddyserver.com/download for the full list of currently available
# features, or run with the -n|--nogo commandline switch, like:
#
#   $ bash getcaddy.sh -n
#
# The -n|--nogo switch gives information and does not download/backup/install.
#
# A forced install location (path + filename) for the binary can specified with
# the -l|--location option, like:
#
#    $ bash getcaddy.sh -l /usr/bin/caddy
#
# This should all work on Mac, Linux, and BSD systems, and
# hopefully Windows with Cygwin. Please open an issue if you notice any bugs.
#

getcaddy()
{
	set -E
	trap 'echo -e "Aborted, error $? in command: $BASH_COMMAND"; return 1' ERR

	#########################
	# Which OS and version? #
	#########################

	# Determine arch (and arm)
	local caddy_arm=""
	local caddy_arch
	local unamem="$(uname -m)"
	case $unamem in
		*aarch64*) caddy_arch="arm64" ;;
		*64*) caddy_arch="amd64" ;;
		*86*) caddy_arch="386" ;;
		*armv5*) caddy_arch="arm" caddy_arm="5" ;;
		*armv6l*) caddy_arch="arm" caddy_arm="6" ;;
		*armv7l*) caddy_arch="arm" caddy_arm="7" ;;
		*) echo "Aborted, unsupported or unknown architecture: $unamem"
			return 2 ;;
	esac

	# Determine os, binary name and package type
	local caddy_os
	local caddy_dl_ext=".tar.gz"
	local caddy_bin="caddy"
	local uname="$(uname)"
	local -u unameu=$uname
	if [[ ${unameu} == *DARWIN* ]]
	then
		caddy_os="darwin"
		caddy_dl_ext=".zip"
		local vers=$(sw_vers)
		local version=${vers##*ProductVersion: }
		local OSX_MAJOR OSX_MINOR
		IFS='.' read OSX_MAJOR OSX_MINOR _ <<<"$version"
		((OSX_MAJOR < 10)) \
			 && echo "Aborted, unsupported OS X version (9-)" \
			 && return 3
		((OSX_MAJOR > 10)) \
				&& echo "Aborted, unsupported OS X version (11+)" \
				&& return 4
		((OSX_MINOR < 5)) \
				&& echo "Aborted, unsupported OS X version (10.5-)" \
				&& return 5
	elif [[ ${unameu} == *LINUX* ]]
	then
		caddy_os="linux"
	elif [[ ${unameu} == *FREEBSD* ]]
	then
		caddy_os="freebsd"
	elif [[ ${unameu} == *OPENBSD* ]]
	then
		caddy_os="openbsd"
	elif [[ ${unameu} == *WIN* ]]
	then
		# Should catch cygwin
		caddy_os="windows"
		caddy_dl_ext=".zip"
		caddy_bin=$caddy_bin.exe
	else
		echo "Aborted, unsupported or unknown os: $uname"
		return 6
	fi

	# process commandline options
	local caddy_cmd pid nogo=0
	while ((${#@}))
	do
		case $1 in
			-n|--nogo) nogo=1
				shift ;;
			-l|--location) if [[ $2 ]]
				then
					caddy_cmd="$2"
					shift 2
				else
					echo "Aborted, must have install location after $1"
					return 7
				fi ;;
			*) # This must be the feature list
				if [[ $features ]]
				then  # unknown/extraneous commandline argument
					echo "Aborted, unsure which are the features, '$features' or '$1'"
					return 8
				else
					features=$1
					shift
				fi ;;
		esac
	done

	# determine install location
	if [[ $caddy_cmd ]]
	then  # if specified with -l: force that install location
		[[ ${caddy_cmd:0:1} = / ]] || caddy_cmd="$PWD/$caddy_cmd"
	elif pid=$(pgrep -nx "$caddy_bin")
	then  # most recent match if running
		local bin=$(ls -l /proc/$pid/exe)  # if running: use location of the binary
		caddy_cmd=$(sed "s@^.* /proc/$pid/exe -> @@" <<<"$bin")
	else
		caddy_cmd=$(type -p "$caddy_bin")  # first caddy binary in PATH
	fi

	# find the curl or wget binaries
	! local dl_cmd="$(type -p curl) -fsSL" && ! dl_cmd="$(type -p wget) -qO-" \
			&& echo "Aborted, could not find curl or wget" && return 9

	###################
	# Which features? #
	###################

	# determine valid features
	local valid_features=$($dl_cmd caddyserver.com/features.json \
			|sed 's/},/\0\n/g' |grep -o '^.*","name":"[^"]*' |grep -o '[^"]*$')
	valid_features=$(sed 's/ /,/g' <<<$valid_features)

	[[ $features = all ]] && features=$valid_features
	[[ $features = none ]] && features=""
	[[ $features = same ]] && features=","
	# if features starts with comma: get the current plugins
	if [[ ${features:0:1} = "," ]]
	then
		# if no binary found, just install a new one with the listed features
		if [[ -x $caddy_cmd ]]
		then  # read plugins from binary if present
			local plugins=$("$caddy_cmd" -plugins |grep ' http\.' |sed 's/^.*http\.//' )
			# only add valid features in the plugins list
			shopt -s nullglob
			local plugin
			for plugin in ${plugins[@]}; do
				[[ ",$valid_features," = *,$plugin,* ]] && features+=",$plugin"
			done
		fi
	fi

	# validate the specified features
	local featurelist=($(sed 's/,/ /g' <<<"$features"))
	local feature
	for feature in "${featurelist[@]}"; do
		if [[ ",$valid_features," != *,$feature,* ]]
		then
			echo "Aborted, feature '$feature' not valid"
			return 10
		fi
	done
	# remove extraneous commas
	features=$(sed 's/ /,/g' <<<${featurelist[@]})
	echo -e "Valid features: $valid_features\nSelected features: $features"

	# determine fresh install location
	if [[ -z $caddy_cmd ]]
	then
		local install_path="/usr/local/bin"
		# Termux on Android has $PREFIX set which already ends with /usr
		[[ -n "$ANDROID_ROOT" && -n "$PREFIX" ]] && install_path="$PREFIX/bin"
		# Fall back to /usr/bin if necessary
		[[ -d $install_path ]] || install_path="/usr/bin"
		caddy_cmd="$install_path/$caddy_bin"
	fi
	echo "Caddy for $caddy_os/$caddy_arch to be installed at $caddy_cmd"
	((nogo)) && return 0

	########################
	# Download and extract #
	########################

	local tmp
	[[ -n "$ANDROID_ROOT" && -n "$PREFIX" ]] && tmp=$PREFIX/tmp || tmp=/tmp
	local caddy_dl="$tmp/caddy_${caddy_os}_$caddy_arch${caddy_arm}_custom$caddy_dl_ext"
	local caddy_url="https://caddyserver.com/download/build?os=$caddy_os&arch=$caddy_arch&arm=$caddy_arm&features=$features"
	echo "URL: $caddy_url"
	$dl_cmd "$caddy_url" >"$caddy_dl"

	echo "Extracting"
	case "$caddy_dl" in
		*.zip)    unzip -o "$caddy_dl" "$caddy_bin" -d "$tmp/" ;;
		*.tar.gz) tar -xzf "$caddy_dl" -C "$tmp/" "$caddy_bin" ;;
	esac
	chmod +x "$tmp/$caddy_bin"

	# Not every platform has or needs sudo (see issue #40)
	local sudo_cmd
	((EUID)) && [[ -z "$ANDROID_ROOT" ]] && sudo_cmd="sudo"

	# Back up existing caddy, if any
	local caddy_version=$("$caddy_cmd" -version)
	if [[ $caddy_version ]]
	then
		# caddy of some version is already installed
		local caddy_backup="${caddy_cmd}_${caddy_version##* }"
		echo -e "Backing up $caddy_cmd to $caddy_backup\n(may require password)"
		$sudo_cmd cp -v --backup=numbered "$caddy_cmd" "$caddy_backup"
	fi
	((pid)) && echo "Stopping caddy" && kill -INT $pid && true
	echo -e "Putting caddy in $caddy_cmd\n(may require password)"
	$sudo_cmd mv "$tmp/$caddy_bin" "$caddy_cmd"
	if local setcap_cmd=$(type -p setcap)
	then
		echo "Allowing lower port numbers through setcap"
		$sudo_cmd "$setcap_cmd" cap_net_bind_service=+ep "$caddy_cmd"
	fi
	((pid)) && echo "Restarting caddy" && "$caddy_cmd"
	$sudo_cmd rm -- "$caddy_dl"

	# check installation
	echo "Version: $("$caddy_cmd" --version)"

	echo "Successfully installed"
	trap ERR
	return 0
}

getcaddy "$@"
getcaddy_return=$?
((getcaddy_return)) && echo "Not completed, aborted at $getcaddy_return"
