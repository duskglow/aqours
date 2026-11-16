# Yohane tools

Everything here runs unprivileged: `mmdebstrap` and `sbuild` in unshare mode, and QEMU with KVM.

| Tool | What it does |
|---|---|
| `mkchroot OUT.tar.zst` | Builds an excalibur `buildd` chroot tarball for sbuild. The mirror is trusted only through its signed `InRelease`, checked against pinned keyrings. |
| `sbuildrc` | sbuild configuration, used through `SBUILD_CONFIG`. Build trees go in `YOHANE_SCRATCH` and are purged after each build. Every upload carries its upstream tarball. |
| `mkimage OUTDIR` | Builds a bootable test image: an ext4 root, plus the kernel and initrd for direct boot. sysvinit, with a serial console and a boot-test marker. |
| `boottest IMAGEDIR` | Boots an image in KVM (read-only, with a throwaway overlay). Passes on the marker plus a clean power-off. Fails as soon as it sees a panic, a maintenance shell or an initramfs shell. |

## Settings

The tools take the site's settings from the environment, usually from a private file each host sources:

| Variable | Meaning |
|---|---|
| `YOHANE_MIRROR` | Devuan mirror base URL |
| `YOHANE_KEYRINGS` | Directory with pinned `devuan-archive-keyring.gpg` (and Debian's). It must be readable outside `$HOME`, because the unshare namespace's mapped root can't enter a mode-750 home. |
| `YOHANE_SCRATCH` | Directory for build trees (a RAM disk is ideal) |
| `YOHANE_JOBS` | Default `parallel=` for builds |
| `YOHANE_CHROOT` | Path of the chroot tarball made by `mkchroot` |
| `SBUILD_CONFIG` | Points at `tools/sbuildrc` |

## Example

```sh
. ~/aqours/env
tools/mkchroot "$YOHANE_CHROOT"
sbuild --chroot="$YOHANE_CHROOT" --arch-all --source hello
tools/mkimage --mirror "$YOHANE_MIRROR" /scratch/img && tools/boottest /scratch/img
```

## Notes learned the hard way

- During customize hooks, mmdebstrap bind-mounts the host's `/dev`, `/dev/shm`, `/proc` and `/sys` into the tree.
  So `mkimage` copies the tree with `tar --one-file-system` before running `mke2fs -d`, and leaves `/dev` empty for
  devtmpfs to fill.
- `boottest` deletes the previous console log before booting, so it can never judge an old run's output.
- Each tool's pass and fail signals are deterministic: an exit code or a console marker, never elapsed time.
