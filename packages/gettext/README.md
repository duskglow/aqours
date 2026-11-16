Source: gettext
Applies-To: excalibur
Kind: bootstrap-profile
Status: active

# gettext

**Bootstrap only (decision 16).** During the bootstrap, Yohane builds gettext without Java support (pulls OpenJDK, GTK 3, Mesa).
This keeps large build-dependency chains out of the minimal bootstrap set (they were found with
`tools/builddeps`' chain report, `T2.why`).

**How:** built with the Debian build profile(s) `nojava` the package already defines.

**Restored in the full pass,** once the system rebuilds itself; Snow Halation ships the full-featured build.
