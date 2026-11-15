# Aqours package changes

Every change Aqours makes to a Devuan source package is here, one directory per source package. Aqours patches
freely; the rule is that every change is written down. Patches are not sent upstream unless a bug is egregious.

## Layout

```
packages/<source>/
  README.md        what the change does, why, the failure it fixes, the Liella issue (if any)
  patches/*.patch  applied in name order to the unpacked Devuan source before building
```

Each `README.md` starts with this header block:

```
Source: <source package>
Applies-To: <Devuan version(s) the patch was made against>
Kind: build-fix | liella-workaround | aqours-identity | drop
Liella-Issue: duskglow/liella#N   (liella-workaround only)
Status: active | obsolete (and why)
```

- **build-fix:** the package doesn't build or work in Aqours for a reason unrelated to Liella (for example, a
  vendor check that only knows Debian).
- **liella-workaround:** a stopgap for a Liella bug. It names the issue and is dropped once Liella fixes it.
- **aqours-identity:** one of the minimal changes that make the system Aqours rather than Devuan (`base-files`).
- **drop:** the package isn't built for Aqours. The README says why (e.g. it uses `GLIBC_PRIVATE`).

A rebuilt package with an Aqours patch gets the version `<devuan-version>aqours<N>`; see docs/design.md, section 3.
