Source: python3.13
Applies-To: excalibur
Kind: bootstrap
Status: planned (patch written when the package is first built)

# python3.13

**Bootstrap only (decision 16).** During the bootstrap, Yohane builds python3.13 without Bluetooth sockets (pulls bluez and through it about 200 sources) and tkinter (pulls Tk and X).
This keeps large build-dependency chains out of the minimal bootstrap set (they were found with
`tools/builddeps`' chain report, `T2.why`).

**How:** built with the Debian build profile(s) `pkg.python3.13.nobluetooth` the package already defines; a patch removes `tk-dev`, `blt-dev` from `debian/control` and disables what needs them.

**Restored in the full pass,** once the system rebuilds itself; Snow Halation ships the full-featured build.
