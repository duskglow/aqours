Source: binutils
Applies-To: excalibur
Kind: bootstrap-profile
Status: active

# binutils

**Bootstrap only (decision 16).** During the bootstrap, Yohane builds binutils without Java support in gprofng (pulls OpenJDK).
This keeps large build-dependency chains out of the minimal bootstrap set (they were found with
`tools/builddeps`' chain report, `T2.why`).

**How:** built with the Debian build profile(s) `pkg.binutils.nojava` the package already defines.

**Restored in the full pass,** once the system rebuilds itself; Snow Halation ships the full-featured build.
