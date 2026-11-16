# Aqours Linux

Aqours Linux is an experimental reference Linux distribution based on [Devuan](https://www.devuan.org/) excalibur. Its C
library is [Liella](https://github.com/duskglow/liella), a clean-room Rust implementation of the glibc ABI, instead of
glibc. Everything that links a C library is rebuilt from Devuan's sources against Liella, and glibc isn't installed.
Apart from that, Aqours stays as close to a plain Devuan base system as it can.

The first release is **Snow Halation**: a base Devuan system, with sysvinit, running entirely on Liella.

**Status:** the glibc baseline build is complete; the first builds against Liella are waiting on a Liella fix. Nothing
is installable yet.

- [Design](docs/design.md): how Aqours is built, published and tested, and what it needs from Liella.
- Bugs in Liella found while building Aqours are reported on [duskglow/liella](https://github.com/duskglow/liella/issues).

## Name and mascot

Aqours Linux is an independent hobby project. It is **not affiliated with, endorsed by, or sponsored by** the Love Live!
Sunshine!! franchise, the group Aqours, or their rights holders. Its name is always "Aqours Linux", never "Aqours" alone. The name (and release codenames such as Snow Halation)
are a fan's homage, used without any claim to them. The mascot is an original penguin character, not a likeness of any
member of the group.
