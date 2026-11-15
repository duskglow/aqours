# Aqours

Aqours is an experimental reference Linux distribution based on [Devuan](https://www.devuan.org/) excalibur. Its C
library is [Liella](https://github.com/duskglow/liella), a clean-room Rust implementation of the glibc ABI, instead of
glibc. Everything that links a C library is rebuilt from Devuan's sources against Liella, and glibc isn't installed.
Apart from that, Aqours stays as close to a plain Devuan base system as it can.

The first release is **Snow Halation**: a base Devuan system, with sysvinit, running entirely on Liella.

**Status:** infrastructure being set up. Nothing is installable yet.

- [Design](docs/design.md): how Aqours is built, published and tested, and what it needs from Liella.
- Bugs in Liella found while building Aqours are reported on [duskglow/liella](https://github.com/duskglow/liella/issues).

The name comes from the Love Live! Sunshine!! group.
