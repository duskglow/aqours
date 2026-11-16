Source: openssh
Applies-To: excalibur
Kind: bootstrap-profile
Status: active

# openssh

**Bootstrap only (decision 16).** During the bootstrap, Yohane builds openssh without the GNOME askpass helper (pulls GTK and about 200 sources).
This keeps large build-dependency chains out of the minimal bootstrap set (found with
`tools/builddeps`' chain report, `T2.why`).

**How:** built with the Debian build profile(s) `pkg.openssh.nognome` the package already defines.

**Restored in the full pass,** once the system rebuilds itself; Snow Halation ships the full-featured build.
