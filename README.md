# getcaddy.com

Caddy home page: **[caddyserver.com](https://caddyserver.com)**

Report issues: **[github.com/pepa65/getcaddy.com/issues](https://github.com/pepa65/getcaddy.com/issues)**

## getcaddy.sh -- Caddy web server installer and upgrade script

#### Bash script to install or upgrade the single-binary Caddy web server

Script requires: **bash, mv, rm, type, sed, grep, curl / wget, tar (or unzip on OSX and Windows)**

**Usage**:

```bash
curl https://loof.bid/getcaddy.sh |bash
  # or:
wget -qO- loof.bid/getcaddy.sh |bash
```
In automated environments, you probably need to run as root.
If you want extra features to be added into the Caddy binary, use the `-s`
commandline option with bash, or include the feature-list as an argument
to the script. The feature-list is a comma-separated list, like this:

```bash
curl https://loof.bid/getcaddy.sh |bash -s git,mailout
```
The script can also first be downloaded and then run:

```bash
wget loof.bid/getcaddy.sh
bash getcaddy.sh git,mailout
```

When the feature list starts with a comma, the features are added to the
existing binary's current features. When the feature list is `all`, all
available features will be added in. Just `same` means: keep the same
features. And `none` means: no extra features will be included.
See [caddyserver.com/download](https://caddyserver.com/download) for
the full list of currently available features, or
run with the `-n`/`--nogo` commandline switch, like:

```bash
bash getcaddy.sh -n
```

The `-n`/`--nogo` switch gives information and does not download/backup/install.
A forced install location (*path + filename*) for the binary can be specified
with the `-l`/`--location` switch, like:

```bash
bash getcaddy.sh -l /usr/bin/caddy
```

This all should work on Mac, Linux, and BSD systems, and
hopefully on Windows with Cygwin. Please open an issue if you notice any bugs.

## checkcaddy.sh -- Caddy web server upgrade checker script

#### Checking the Caddy web server download page for the current version and calling the upgrade script 'getcaddy.sh' on a new version.
This is meant to be called from root's cron.

**Download**:

```bash
wget loof.bid/checkcaddy.sh
```

Script requires: **bash, coreutils, sed, grep, wget**

**Usage**:

```bash
bash checkcaddy.sh [-n|--nogo] [caddy_binary_location]
```
Where `caddy_binary_location` is the install location and the
`-n`/`--nogo` switch gives a report on the necessity of upgrading.
