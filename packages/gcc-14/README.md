Source: gcc-14
Applies-To: excalibur
Kind: bootstrap
Status: planned (patch written when the package is first built)

# gcc-14

**Bootstrap only (decision 16).** During the bootstrap, Aqours builds gcc-14 without the Ada, D and Rust front ends and the GPU offload compilers: a C/C++-only bootstrap compiler (pulls LLVM 19, rustc, OCaml).
This keeps large build-dependency chains out of the minimal bootstrap set (they were found with
`tools/builddeps`' chain report, `T2.why`).

**How:** a patch removes `gnat-14`, `gnat-13`, `gdc-14`, `cargo`, `nvptx-tools`, `amdgcn-tools-19` from `debian/control` and disables what needs them.

**Restored in the full pass,** once the system rebuilds itself; Snow Halation ships the full-featured build.
