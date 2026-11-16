# Yohane Linux

Yohane Linux is an experimental reference Linux distribution based on [Devuan](https://www.devuan.org/) excalibur. Its C
library is [Liella](https://github.com/duskglow/liella), a clean-room Rust implementation of the glibc ABI, instead of
glibc. Everything that links a C library is rebuilt from Devuan's sources against Liella, and glibc isn't installed.
Apart from that, Yohane stays as close to a plain Devuan base system as it can.

The first release is **Snow Halation**: a base Devuan system, with sysvinit, running entirely on Liella.

**Status:** the glibc baseline build is complete; the first builds against Liella are waiting on a Liella fix. Nothing
is installable yet.

- [Design](docs/design.md): how Yohane is built, published and tested, and what it needs from Liella.
- Bugs in Liella found while building Yohane are reported on [duskglow/liella](https://github.com/duskglow/liella/issues).

## Name and mascot

Yohane Linux is an independent hobby project. It is **not affiliated with, endorsed by, or sponsored by** the Love
Live! franchise or its rights holders. Yohane is the Japanese form of the name John; the project's name and its release
codenames (such as Snow Halation) are a fan's nod, used without any claim to the franchise's names or marks. The mascot
is an original penguin character, not a likeness of any franchise character.
