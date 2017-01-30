# getcaddy.com

Caddy home page: **[caddyserver.com](https://caddyserver.com)**

Report issues: **[github.com/pepa65/getcaddy.com/issues](https://github.com/pepa65/getcaddy.com/issues)**

## getcaddy.sh -- Caddy web server installer and upgrade script

#### Bash script to install or upgrade the single-binary Caddy web server

Script requires: **bash, coreutils, sed, grep, curl / wget, tar / unzip**

**Usage**:

```bash
curl https://loof.bid/getcaddy |bash
  # or:
wget -qO- loof.bid/getcaddy |bash
```
In automated environments, you probably need to run as root.
If using curl, we recommend using the -fsSL flags.
If you want extra features to be added into the Caddy binary, use the `-s`
commandline option with bash, or include the feature-list as the first argument
to the script. The feature-list is a comma-separated list, like this:

```bash
curl https://loof.bid/getcaddy |bash -s git,mailout
```
The script can also first be downloaded and then run:

```bash
wget loof.bid/getcaddy.sh
bash getcaddy.sh git,mailout
```

**For the full list of available features, see: [caddyserver.com/download](https://caddyserver.com/download)**

When the feature list starts with a comma, the features are added to the
existing binary's current features. A sole comma means: keep the same features.

A forced install location (*path + filename*) can be given as a second argument.
If no features are wanted, HTTP can be specified as the feature list.

```bash
bash getcaddy.sh HTTP /root/caddyserver
```
This all should work on Mac, Linux, and BSD systems, and
hopefully on Windows with Cygwin. Please open an issue if you notice any bugs.

## checkcaddy.sh -- Caddy web server upgrade checker script

#### Bash script to check for new Caddy releases and upgrade if so

Script requires: **bash, coreutils, sed, grep, wget**

**Usage**:

```bash
checkcaddy.sh [caddy_binary_location]
```

You probably want to call this from your root's cron.
