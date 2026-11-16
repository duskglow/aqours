Source: cdebconf
Applies-To: excalibur
Kind: bootstrap-profile
Status: active

# cdebconf

**Bootstrap only (decision 16).** During the bootstrap, Yohane builds cdebconf without the GTK front end (pulls GTK).
This keeps large build-dependency chains out of the minimal bootstrap set (they were found with
`tools/builddeps`' chain report, `T2.why`).

**How:** built with the Debian build profile(s) `pkg.cdebconf.nogtk` the package already defines.

**Restored in the full pass,** once the system rebuilds itself; Snow Halation ships the full-featured build.
