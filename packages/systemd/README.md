Source: systemd
Applies-To: excalibur
Kind: bootstrap-profile
Status: active

# systemd

**Bootstrap only (decision 16).** During the bootstrap, Yohane builds systemd without BPF, cryptsetup, fido2, qrencode, xen and other optional integrations (pulls LLVM/clang, the kernel tools, xen).
This keeps large build-dependency chains out of the minimal bootstrap set (they were found with
`tools/builddeps`' chain report, `T2.why`).

**How:** built with the Debian build profile(s) `stage1` the package already defines.

**Restored in the full pass,** once the system rebuilds itself; Snow Halation ships the full-featured build.
