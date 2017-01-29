# getcaddy.com

## Caddy web server install/upgrade script

### Bash script to install the single-binary Caddy web server

**Caddy home page**: [caddyserver.com](https://caddyserver.com)

**Report issues**: [github.com/pepa65/getcaddy.com/issues](https://github.com/pepa65/getcaddy.com/issues)

**Script requires: bash, coreutils, curl or wget, tar or unzip**

Usage:

```bash
curl https://loof.bid/getcaddy |bash
  # or
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
Or it can be first downloaded and then run:

```bash
wget loof.bid/getcaddy.sh
bash getcaddy.sh git,mailout
```

**Full list of available features**:

* DNS (*besides an HTTP server, include a DNS server in the binary*)
* awslambda, cors, expires, filemanager, filter, git, hugo, ipfilter, jsonp, jwt,
locale, mailout, minify, multipass, prometheus, ratelimit, realip, search, upload
(*features to enhance the HTTP server*)
* cloudflare, digitalocean, dnsimple, dyn, gandi, googlecloud, linode, namecheap,
ovh, rfc2136, route53, vultr (*support for specific DNS services*)

For all the options, see [caddyserver.com/download](https://caddyserver.com/download)

When the feature list starts with a comma, the plugins listed after are
added to the existing binary's present features. A sole comma means:
just keep the same feature set. Examples:

```bash
curl https://loof.bid/getcaddy |bash -s ,dns,hugo,gandi
  # or:
source getcaddy.sh ,
```
It is also valid to just specify `none` for no added features.

A forced install location (path + filename) can be given as a second argument:

```bash
bash getcaddy.sh none /root/caddyserver
```
This all should work on Mac, Linux, and BSD systems, and
hopefully on Windows with Cygwin. Please open an issue if you notice any bugs.
