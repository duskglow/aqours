Source: elfutils
Applies-To: 0.192-4
Kind: build-fix
Status: active

# elfutils

**Problem.** `debian/rules` chooses a default debuginfod server from `lsb_release -is`: Debian's for Debian, Ubuntu's
for Ubuntu, none otherwise. It only creates `/etc/debuginfod/elfutils.urls` when a server is chosen, but
`libdebuginfod-common.install` always lists the file, so on any other distribution `dh_install` aborts with "missing
files". Devuan never hits this because it ships Debian's binary (built on Debian, with Debian's server). Found in the
stage 0 baseline (docs/baseline-stage0.md).

**Change.** `0001-ship-urls-file-without-default-server.patch` always creates the file. It holds the URL when one is
configured and is empty otherwise; an empty file means no default debuginfod server.

**Policy still open (owner):** whether Aqours sets a default debuginfod server at all. Devuan users today get Debian's
(`https://debuginfod.debian.net`) via Debian's binary. Until decided, Aqours ships none.
