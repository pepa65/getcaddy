# getcaddy.com

Caddy home page: **[caddyserver.com](https://caddyserver.com)**

Report issues: **[github.com/pepa65/getcaddy.com/issues](https://github.com/pepa65/getcaddy.com/issues)**

## getcaddy.sh -- Caddy web server installer and upgrade script

#### Bash script to install or upgrade the single-binary Caddy web server

Script requires: **bash, mv, rm, type, sed, grep, curl / wget, tar (or unzip on OSX and Windows)**

**Usage**:

```bash
bash getcaddy.sh [-n|--nogo] [-a|--arch <arch>] [-o|--os <os>]
                 [-l|--location <path/file>] [<pluginlist>]
  -n or --nogo lists available plugins, architectures and oses,
               and does not download/backup/install the caddy binary
  <arch> sets the architecture, <os> the OS; when used, the downloaded binary
         will not be run (and might not work)
  <path/file> is the forced install location (path + filename) for the binary
  pluginlist: [,][<plugin>[,<plugin>]...]
```
Full list of currently available plugins: [caddyserver.com/download](https://caddyserver.com/download)
When the pluginlist starts with a comma, the plugins are added to the
existing binary's current plugins. When the pluginlist is 'all', all
available plugins will be added in; 'same' means: keep the same plugins.
And 'none' means: no plugins will be included at all.
No pluginlist defaults to 'same' (if no previous binary found: 'none')

Installing Caddy by running from download (either with curl or wget):
`  curl -sL loof.bid/getcaddy.sh |bash [-s <commandline option>...]`
`  wget -qO- loof.bid/getcaddy.sh |bash [-s <commandline option>...]`

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
