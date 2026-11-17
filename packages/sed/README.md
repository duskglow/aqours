Source: sed
Applies-To: excalibur
Kind: build-fix (0001)
Status: 0001 active

# sed

## 0001: nodoc removes the installed info manual

**Problem.** With the `nodoc` build profile (Yohane builds every stage 1 source with it during the bootstrap,
decision 15), `debian/rules` sets `MAKEINFO=true` and then runs `rmdir debian/sed/usr/share/info`, expecting the
directory to be empty. But `make install` still installs the pre-built `doc/sed.info` from the release tarball, so
`rmdir` fails ("Directory not empty") and the build stops (stage 1, 2026-11-17). Without `nodoc` the build is
unaffected, which is why stage 0 built it.

**Change.** `0001-nodoc-remove-info.patch` replaces the `rmdir` with `rm -rf`, so a `nodoc` build ships no info
manual, as the profile intends.

**Restored** never needed: harmless without `nodoc`. Worth reporting to Debian only if it bites anyone else (the
package's `nodoc` path is simply untested).
