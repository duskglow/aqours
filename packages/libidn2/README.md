Source: libidn2
Applies-To: excalibur
Kind: bootstrap
Status: planned (patch written when the package is first built)

# libidn2

**Bootstrap only (decision 16).** During the bootstrap, Yohane builds libidn2 without gnulib's git use (pulls git and through it Go).
This keeps large build-dependency chains out of the minimal bootstrap set (found with
`tools/builddeps`' chain report, `T2.why`).

**How:** a patch removes `git` from `debian/control` and disables what needs them.

**Restored in the full pass,** once the system rebuilds itself; Snow Halation ships the full-featured build.
