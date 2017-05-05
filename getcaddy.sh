#!/usr/bin/env bash
set +vx
#
# Caddy web server installer and upgrade script
# Bash script to install the single-binary Caddy web server
# Usage: bash getcaddy.sh [-n|--nogo] [-a|--arch <arch>] [-o|--os <os>]
#                         [-l|--location <path/file>] [<pluginlist>]
#   -n or --nogo lists available plugins, architectures and oses,
#                and does not download/backup/install the caddy binary
#   <arch> sets the architecture, <os> the OS; when used, the downloaded binary
#          will not be run (and might not work)
#   <path/file> is the forced install location (path + filename) for the binary
#   pluginlist: [,][<plugin>[,<plugin>]...]
#
# Full list of currently available plugins: https://caddyserver.com/download
#
# When the pluginlist starts with a comma, the plugins are added to the
# existing binary's current plugins. When the pluginlist is 'all', all
# available plugins will be added in; 'same' means: keep the same plugins.
# And 'none' means: no plugins will be included at all.
# No pluginlist defaults to 'same' (if no previous binary found: 'none')
#
# Installing Caddy by running from download (either with curl or wget):
#   curl -sL loof.bid/getcaddy.sh |bash [-s <pluginlist>]
#	  wget -qO- loof.bid/getcaddy.sh |bash [-s <pluginlist>]
#
# - Caddy homepage: https://caddyserver.com
# - Getcaddy issues: https://github.com/pepa65/getcaddy.com/issues
# - Required: bash, mv, rm, type, cut, sed, grep, pgrep, curl/wget, tar
#   (or unzip on OSX and Windows)

getcaddy()
{
	set -E
	trap 'echo -e "Aborted, error $? in command: $BASH_COMMAND"; return 1' ERR

	# Process commandline options
	local caddy_loc caddy_os caddy_arch caddy_pid nogo=0 forced=0 plugins=
	while ((${#@}))
	do
		case $1 in
			-n|--nogo) nogo=1
				shift ;;
			-l|--location) if [[ $2 ]]
				then
					caddy_loc="$2"
					shift 2
				else
					echo "Aborted, must have install location after $1"
					return 2
				fi ;;
			-o|--os) if [[ $2 ]]
				then
					caddy_os="$2"
					shift 2
					forced=1
				else
					echo "Aborted, must have OS after $1"
					return 3
				fi ;;
			-a|--arch) if [[ $2 ]]
				then
					caddy_arch="$2"
					shift 2
					forced=1
				else
					echo "Aborted, must have architecture after $1"
					return 4
				fi ;;
			*) # this must be the plugin list
				if [[ $plugins ]]
				then  # unknown/extraneous commandline argument
					echo "Aborted, unsure which are the plugins, '$plugins' or '$1'"
					return 5
				else
					plugins=$1
					shift
				fi ;;
		esac
	done

	# Determine OS, binary name and package type
	local caddy_ext=".tar.gz"
	local caddy_bin="caddy"
	if [[ -z $caddy_os ]]
	then
		local uname=$(uname)
		local -u unameu=$uname
		if [[ ${unameu} == *DARWIN* ]]
		then
			caddy_os="darwin"
			local vers=$(sw_vers)
			local version=${vers##*ProductVersion:}
			local OSX_MAJOR OSX_MINOR
			IFS='.' read OSX_MAJOR OSX_MINOR _ <<<"$version"
			((OSX_MAJOR < 10)) \
				 && echo "Aborted, unsupported OS X version (9-)" \
				 && return 6
			((OSX_MAJOR > 10)) \
					&& echo "Aborted, unsupported OS X version (11+)" \
					&& return 7
			((OSX_MINOR < 5)) \
					&& echo "Aborted, unsupported OS X version (10.5-)" \
					&& return 8
		elif [[ ${unameu} == *LINUX* ]]
		then
			caddy_os="linux"
		elif [[ ${unameu} == *FREEBSD* ]]
		then
			caddy_os="freebsd"
		elif [[ ${unameu} == *OPENBSD* ]]
		then
			caddy_os="openbsd"
		elif [[ ${unameu} == *NETBSD* ]]
		then
			caddy_os="netbsd"
		elif [[ ${unameu} == *SOLARIS* ]]
		then
			caddy_os="solaris"
		elif [[ ${unameu} == *WIN* ]]
		then
			caddy_os="windows"
		else
			echo "Aborted, unsupported or unknown os: $uname"
			return 9
		fi
	fi
	[[ $caddy_os = darwin || $caddy_os = windows ]] && caddy_ext=".zip"
	[[ $caddy_os = windows ]] && caddy_bin=$caddy_bin.exe

	# Determine arch
	if [[ -z $caddy_arch ]]
	then
		local unamem=$(uname -m)
		case $unamem in
			*aarch64*) caddy_arch="arm64" ;;
			*64*) caddy_arch="amd64" ;;
			*86*) caddy_arch="386" ;;
			*armv5*) caddy_arch="arm5" ;;
			*armv6l*) caddy_arch="arm6" ;;
			*armv7l*) caddy_arch="arm7" ;;
			*arm64*) caddy_arch="arm64" ;;
			*mips64le*) caddy_arch="mips64le" ;;
			*mips64*) caddy_arch="mips64" ;;
			*mipsle*) caddy_arch="mipsle" ;;
			*mips*) caddy_arch="mips" ;;
			*ppc64le*) caddy_arch="ppc64le" ;;
			*ppc64*) caddy_arch="ppc64" ;;
			*) echo "Aborted, unsupported or unknown architecture: $unamem"
				return 10 ;;
		esac
	fi

	# Find the curl or wget binaries
	! local dl_cmd="$(type -p curl) -fsSL" && ! dl_cmd="$(type -p wget) -qO-" \
			&& echo "Aborted, could not find curl or wget" && return 11

	# Check os/arch
	local dl_file="https://caddyserver.com/api/download-page"
	local dl_info=$(sed 's@{@\n{@g' /home/pp/download-page)
#	local dl_info=$($dl_cmd $dl_file |sed 's@{@\n{@g')
	local os_archs=$(grep '{"GOOS":' <<<"$dl_info"|
			grep -o ':".*,"' |cut -d '"' -f2,6,10 |sed 's@"@/@' |sed 's@"@@g')
	! grep -q ^$caddy_os/$caddy_arch$ <<<"$os_archs" \
			&& echo "Aborted, invalid os/arch: $caddy_os/$caddy_arch" && return 12
	((nogo)) && echo " Supported OS/architectures:" ${os_archs//$'\n'/,}

	# Determine installed location
	if [[ $caddy_loc ]]
	then  # specified with -l/--location: force that install location
		[[ ${caddy_loc:0:1} = / ]] || caddy_loc="$PWD/$caddy_loc"
	elif caddy_pid=$(pgrep -nx "$caddy_bin")
	then  # most recent match if running
		local bin=$(ls -l /proc/$caddy_pid/exe)  # if running: use location of the binary
		caddy_loc=$(sed "s@^.* /proc/$caddy_pid/exe -> @@" <<<"$bin")
	else  # first caddy binary in PATH
		caddy_loc=$(type -p "$caddy_bin")
	fi

	# determine fresh install location
	if [[ -z $caddy_loc ]]
	then  # not forced, not running, not in PATH
		local install_path="/usr/local/bin"
		# Termux on Android has $PREFIX set which already ends with /usr
		[[ -n "$ANDROID_ROOT" && -n "$PREFIX" ]] && install_path="$PREFIX/bin"
		# Fall back to /usr/bin if necessary
		[[ -d $install_path ]] || install_path="/usr/bin"
		caddy_loc="$install_path/$caddy_bin"
	fi

	# Determine valid plugins
	local valid_plugins=$(grep -o ',"Name":"[a-z0-9.]*","Type":' <<<"$dl_info" |
			sed -e 's@^,"Name":"@@' -e 's@".*@@')
	valid_plugins=$(sed 's@ @,@g' <<<$valid_plugins)
	[[ $plugins = all ]] && plugins=$valid_plugins

	# Add to the current plugins (empty, comma, same)
	local plugin
	if [[ -z $plugins || $plugins = same || ${plugins:0:1} = "," ]]
	then
		# if no binary found, just install a new one with the listed plugins
		if [[ -x $caddy_loc ]]
		then  # read plugins from binary if present
			local local_plugins=$("$caddy_loc" --plugins |grep -v ':')
			# only add valid plugins in the plugins list
			for plugin in $local_plugins
			do
				if [[ ,$valid_plugins, = *,$plugin,* ]]
				then
					[[ $plugins ]] && plugins+=","
					plugins+=$plugin
				fi
			done
		fi
	fi

	# Validate the specified plugins
#	for plugin in "${pluginlist[@]}"
	local install_plugins=
	[[ $plugins = none ]] && plugins=
	for plugin in ${plugins//,/ }
	do
		if [[ ,$valid_plugins, = *,$plugin,* ]]
		then
			[[ $install_plugins ]] && install_plugins+=" "
			install_plugins+="$plugin"
		else
			echo " Removed plugin '$plugin' from list: not valid"
#			echo "Aborted, plugin '$plugin' not valid"
#			return 10
		fi
	done

#	local pluginlist=($(sed 's@,@ @g' <<<"$plugins"))
	read install_plugins <<<${install_plugins// /,}
	((nogo)) && echo -e " Valid plugins: $valid_plugins\n Selected plugins: $plugins"
	echo " Installing: $install_plugins"
	echo " Caddy for $caddy_os/$caddy_arch to be installed at $caddy_loc"
	((nogo)) && return 0

	## Download and extract
	local tmp
	[[ -n "$ANDROID_ROOT" && -n "$PREFIX" ]] && tmp=$PREFIX/tmp || tmp=/tmp
	local caddy_dl="$tmp/caddy-$caddy_os-$caddy_arch$caddy_ext"
	local caddy_url="https://caddyserver.com/download/$caddy_os/$caddy_arch?plugins=$plugins"
	echo " URL: $caddy_url"
	$dl_cmd "$caddy_url" >"$caddy_dl"

	echo " Extracting"
	case "$caddy_dl" in
		*.zip)    unzip -o "$caddy_dl" "$caddy_bin" -d "$tmp/" ;;
		*.tar.gz) tar -xzf "$caddy_dl" -C "$tmp/" "$caddy_bin" ;;
	esac
	chmod +x "$tmp/$caddy_bin"

	# Not every platform has or needs sudo (see issue #40)
	local sudo_cmd
	((EUID)) && [[ -z "$ANDROID_ROOT" ]] && sudo_cmd="sudo"

	# Back up file at install location
	local caddy_version=unknown
	[[ -x $caddy_loc ]] && caddy_version=$("$caddy_loc" --version)
	if [[ ${caddy_version:0:5} = Caddy ]]
	then  # some sort of working binary found here
		local caddy_backup="${caddy_loc}_${caddy_version##* }"
		echo -e " Backing up $caddy_loc to $caddy_backup\n (may require password)"
		$sudo_cmd cp -v --backup=numbered "$caddy_loc" "$caddy_backup"
	fi

	# Stop running Caddy, move the new binary in place and restart it
	((!forced)) && ((caddy_pid)) && echo " Stopping caddy" && kill -INT $caddy_pid && true
	echo -e " Putting caddy in $caddy_loc\n (may require password)"
	$sudo_cmd mv "$tmp/$caddy_bin" "$caddy_loc"
	if ((!forced)) && local setcap_cmd=$(type -p setcap)
	then
		echo " Allowing lower port numbers through setcap"
		$sudo_cmd "$setcap_cmd" cap_net_bind_service=+ep "$caddy_loc"
	fi
	((!forced)) && ((caddy_pid)) && echo " Restarting caddy" && "$caddy_loc"
	$sudo_cmd rm -- "$caddy_dl"

	# Check intallation
	((!forced)) && echo " Version: $("$caddy_loc" --version)"

	echo " Successfully installed"
	trap ERR
	return 0
}

getcaddy "$@"
getcaddy_return=$?
((getcaddy_return)) && echo " Not completed, aborted at $getcaddy_return"
