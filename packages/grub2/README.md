Source: grub2
Applies-To: excalibur
Kind: bootstrap
Status: planned (patch written when the package is first built)

# grub2

**Bootstrap only (decision 16).** During the bootstrap, Aqours builds grub2 without grub-emu's SDL display, the qemu-based tests, grub-mount (FUSE) and grub-mkrescue's ISO support (pulls qemu, SDL, PulseAudio and LLVM 22).
This keeps large build-dependency chains out of the minimal bootstrap set (they were found with
`tools/builddeps`' chain report, `T2.why`).

**How:** a patch removes `libsdl2-dev`, `qemu-system`, `libfuse3-dev`, `xorriso` from `debian/control` and disables what needs them.

**Restored in the full pass,** once the system rebuilds itself; Snow Halation ships the full-featured build.
