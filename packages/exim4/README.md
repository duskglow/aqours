Source: exim4
Applies-To: excalibur
Kind: bootstrap
Status: planned (patch written when the package is first built)

# exim4

**Bootstrap only (decision 16).** During the bootstrap, Aqours builds exim4 without the eximon X monitor and the MySQL/PostgreSQL lookups.
This keeps large build-dependency chains out of the minimal bootstrap set (found with
`tools/builddeps`' chain report, `T2.why`).

**How:** a patch removes `libx11-dev`, `libxaw7-dev`, `libxext-dev`, `libxmu-dev`, `libxt-dev`, `default-libmysqlclient-dev`, `libpq-dev` from `debian/control` and disables what needs them.

**Restored in the full pass,** once the system rebuilds itself; Snow Halation ships the full-featured build.
