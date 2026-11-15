Source: apparmor
Applies-To: excalibur
Kind: bootstrap
Status: planned (patch written when the package is first built)

# apparmor

**Bootstrap only (decision 16).** During the bootstrap, Aqours builds apparmor without the Apache module mod_apparmor.
This keeps large build-dependency chains out of the minimal bootstrap set (they were found with
`tools/builddeps`' chain report, `T2.why`).

**How:** a patch removes `apache2-dev`, `dh-apache2` from `debian/control` and disables what needs them.

**Restored in the full pass,** once the system rebuilds itself; Snow Halation ships the full-featured build.
