Source: cmake
Applies-To: excalibur
Kind: bootstrap-profile
Status: active

# cmake

**Bootstrap only (decision 16).** During the bootstrap, Aqours builds cmake without cmake-qt-gui (pulls Qt 6).
This keeps large build-dependency chains out of the minimal bootstrap set (they were found with
`tools/builddeps`' chain report, `T2.why`).

**How:** built with the Debian build profile(s) `pkg.cmake.nogui` the package already defines.

**Restored in the full pass,** once the system rebuilds itself; Snow Halation ships the full-featured build.
