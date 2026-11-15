Source: libsemanage
Applies-To: excalibur
Kind: bootstrap-profile
Status: active

# libsemanage

**Bootstrap only (decision 16).** During the bootstrap, Aqours builds libsemanage without the Ruby bindings.
This keeps large build-dependency chains out of the minimal bootstrap set (found with
`tools/builddeps`' chain report, `T2.why`).

**How:** built with the Debian build profile(s) `noruby` the package already defines.

**Restored in the full pass,** once the system rebuilds itself; Snow Halation ships the full-featured build.
