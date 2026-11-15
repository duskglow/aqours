Source: dbus
Applies-To: excalibur
Kind: bootstrap
Status: planned (patch written when the package is first built)

# dbus

**Bootstrap only (decision 16).** During the bootstrap, Aqours builds dbus without Valgrind instrumentation (pulls valgrind and LLVM 17).
This keeps large build-dependency chains out of the minimal bootstrap set (they were found with
`tools/builddeps`' chain report, `T2.why`).

**How:** a patch removes `valgrind-if-available` from `debian/control` and disables what needs them.

**Restored in the full pass,** once the system rebuilds itself; Snow Halation ships the full-featured build.
