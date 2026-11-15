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

**Verified:** builds and passes its tests with this patch (stage `stage0p`, 2026-11-15).

**What Aqours actually ships.** `elfutils.urls` belongs to `libdebuginfod-common`, which is `Architecture: all`, and
Aqours imports `Architecture: all` packages from Devuan instead of building them (decision 1). So the shipped file is
Debian's, with Debian's server (`https://debuginfod.debian.net`), exactly as on Devuan today. This patch only makes
the architecture-dependent build succeed. If the owner wants no default server, `libdebuginfod-common` would become an
explicit exception to decision 1 (built by Aqours instead of imported).
