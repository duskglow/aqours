Source: libxdmcp
Applies-To: excalibur
Kind: bootstrap
Status: planned (patch written when the package is first built)

# libxdmcp

**Bootstrap only (decision 16).** During the bootstrap, Aqours builds libxdmcp without the protocol documentation.
This keeps large build-dependency chains out of the minimal bootstrap set (found with
`tools/builddeps`' chain report, `T2.why`).

**How:** a patch removes `xmlto`, `xorg-sgml-doctools`, `w3m` from `debian/control` and disables what needs them.

**Restored in the full pass,** once the system rebuilds itself; Snow Halation ships the full-featured build.
