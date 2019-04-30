# getcaddy

### Caddy web server personal edition installer and upgrade script

**Bash script to install or upgrade the single-binary Caddy web server, personal license**

*Caddy binaries before version 1.0.0 (starting with 0.10.9) were no longer Free software;
this has been resolved, and the binaries are open source again, starting with 1.0.0
(Only version 0.10.9 of the Caddy binary was adware.)*

* Version 0.22
* Caddy home page: **[caddyserver.com](https://caddyserver.com)**
* Gitlab page for getcaddy: **[gitlab.com/pepa65/getcaddy](https://gitlab.com/pepa65/getcaddy)**
* Download the getcaddy script: **[4e4.win/gc](https://4e4.win/gc)**
* Download the igetcaddy script: **[4e4.win/ig](https://4e4.win/ig)**
* Report issues: **[gitlab.com/pepa65/getcaddy.com/issues](https://gitlab.com/pepa65/getcaddy.com/issues)**

* Required: **bash sudo coreutils(mv rm type cut readlink true) sed grep procps(pgrep) curl/wget tar** (or **unzip** for OSX and Windows binaries)
* Optional: **gpg** (for verifying downloaded binary)

**Usage**:
```
getcaddy [-b|--bw] [-h|--help] [-n|--nogo] [-x|-optout] [<plugins>]
              [ [-a|--arch <arch>] [-o|--os <os>] -l|--location <caddy> ]
  -n/--nogo:    List available plugins, architectures and oses,
                does not download, backup or install the Caddy binary
  -q/--quiet:   Surpress output except for error messages
  <pluginlist>: all | none | [,]<plugin>[,<plugin>]...
                Previously installed plugins will be installed again if empty
                or the listed plugins will be added if started with a comma
  <location>:   The install location (path + filename) for the Caddy binary
  <arch>, <os>: Sets the architecture and the OS; <filepath> must then
                also be set, and the downloaded binary will not be run
  -x/--optout:  Don't participate in telemetry
  -b/--bw:      Don't use colours in output
  -h/--help:    Display this help text
Returns success when upgrade possible or install successful
```
Full list of currently available plugins: [caddyserver.com/download](https://caddyserver.com/download)
or run:

`bash getcaddy -n`

#### Installing *getcaddy* at `/usr/local/bin/getcaddy`:

The `igetcaddy` script makes it somewhat easier to install getcaddy.
(The `getcaddy` script makes it easy to download Caddy,
but much easier to check for upgrades and upgrade it!)

`wget -qO- 4e4.win/ig |bash`

Or manually:

```
sudo wget -qO /usr/local/bin/getcaddy 4e4.win/gc
chmod +x /usr/local/bin/getcaddy
```

#### Installing *Caddy* by piping into bash (either with wget or curl):

`  wget -qO- 4e4.win/gc |bash [-s -- <commandline option>...]`

`  curl -sL 4e4.win/gc |bash [-s -- <commandline option>...]`

#### Usage in *crontab*:

The first example can only be run with sufficient privileges:
```cron
# Check each Monday at 05:00 am for an updated Caddy and install if available
0 5 * * 1 /INSTALL/PATH/getcaddy -q -l /usr/local/bin/caddy
```
Where `/INSTALL/PATH` is the directory location of the `getcaddy` script and
`/usr/local/bin/caddy` is the optional install location of the *Caddy* binary.

An unprivileged user can run this, depending on where cron is sending output:
```cron
# Check every day at noon for an updated Caddy and alerting admin if available
0 12 * * 1 /INSTALL/PATH/getcaddy -q -n && echo "New Caddy version available!"
```

# buildcaddy

### Build caddy with plugins from source

* Usage: `buildcaddy [<comma-separated-plugins>]`
* Required: **bash go coreutils(mktemp cut rm mv mkdir cd cat) wget grep sed**
