Source: lvm2
Applies-To: excalibur
Kind: bootstrap
Status: planned (patch written when the package is first built)

# lvm2

**Bootstrap only (decision 16).** During the bootstrap, Yohane builds lvm2 without cluster locking (dlm, corosync, sanlock) and the rest of corosync support.
This keeps large build-dependency chains out of the minimal bootstrap set (they were found with
`tools/builddeps`' chain report, `T2.why`).

**How:** a patch removes `libcorosync-common-dev`, `libdlm-dev`, `libdlmcontrol-dev`, `libsanlock-dev` from `debian/control` and disables what needs them.

**Restored in the full pass,** once the system rebuilds itself; Snow Halation ships the full-featured build.
