Source: json-c
Applies-To: excalibur
Kind: bootstrap
Status: planned (patch written when the package is first built)

# json-c

**Bootstrap only (decision 16).** During the bootstrap, Yohane builds json-c without the doxygen API documentation (pulls doxygen and LLVM 19).
This keeps large build-dependency chains out of the minimal bootstrap set (found with
`tools/builddeps`' chain report, `T2.why`).

**How:** a patch removes `doxygen` from `debian/control` and disables what needs them.

**Restored in the full pass,** once the system rebuilds itself; Snow Halation ships the full-featured build.
