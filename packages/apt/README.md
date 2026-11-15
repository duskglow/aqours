Source: apt
Applies-To: excalibur
Kind: bootstrap-profile
Status: active

# apt

**Bootstrap only (decision 16).** During the bootstrap, Aqours builds apt without sqv (Sequoia, Rust) for signature checks; gpgv is used instead, so rust-sequoia-sq and rustc leave the bootstrap.
This keeps large build-dependency chains out of the minimal bootstrap set (found with
`tools/builddeps`' chain report, `T2.why`).

**How:** built with the Debian build profile(s) `pkg.apt.nosqv` the package already defines.

**Restored in the full pass,** once the system rebuilds itself; Snow Halation ships the full-featured build.
