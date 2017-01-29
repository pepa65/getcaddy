# getcaddy.com

## Caddy web server installer and upgrade script

#### Bash script to install or upgrade the single-binary Caddy web server

Caddy home page: **[caddyserver.com](https://caddyserver.com)**

Report issues: **[github.com/pepa65/getcaddy.com/issues](https://github.com/pepa65/getcaddy.com/issues)**

Script requires: **bash, coreutils, sed, grep, curl / wget, tar / unzip

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

If no features wanted, specify 'none' as the feature list.
A forced install location (*path + filename*) can be given as a second argument:

```bash
bash getcaddy.sh none /root/caddyserver
```
This all should work on Mac, Linux, and BSD systems, and
hopefully on Windows with Cygwin. Please open an issue if you notice any bugs.
