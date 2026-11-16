Source: libidn
Applies-To: excalibur
Kind: bootstrap
Status: planned (patch written when the package is first built)

# libidn

**Bootstrap only (decision 16).** During the bootstrap, Yohane builds libidn without gnulib/documentation tooling (pulls git, Go, graphviz).
This keeps large build-dependency chains out of the minimal bootstrap set (they were found with
`tools/builddeps`' chain report, `T2.why`).

**How:** a patch removes `git`, `graphviz` from `debian/control` and disables what needs them.

**Restored in the full pass,** once the system rebuilds itself; Snow Halation ships the full-featured build.
