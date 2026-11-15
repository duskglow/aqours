# Aqours design

Status: **approved with the owner's decisions** (2026-11-15; see [Decisions](#decisions)). Aqours coordinator.

The name is **Aqours**, after the Love Live! Sunshine!! group, and it's spelled `aqours` everywhere.

Aqours is a Devuan-based reference Linux distribution whose C library is Liella, a clean-room Rust implementation of
the glibc 2.39 ABI. This document says how Aqours is built, published and tested, what it needs from Liella, and in
what order the work happens. The owner's decisions are in [Decisions](#decisions),
with the date each was made.

## 1. Goals and constraints

**Goals**
- A Devuan excalibur system, amd64, in which every program that links a C library links Liella, and in which glibc
  is not installed (owner ruling 2026-11-14, "route A").
- Liella's first real consumer. A failure Aqours finds in Liella becomes an issue with a minimal reproducer on
  duskglow/liella, so Aqours is also Liella's broadest test suite.
- Rebuilds that are reproducible and attributable: each failure is classified as Liella's, Aqours's infrastructure's,
  or the package's own.

**Principle** (owner, 2026-11-15): *Aqours builds on Devuan; it doesn't port Devuan.* Whatever it takes to make Liella
Aqours's own C library, or to make packages work with it, is done the Aqours way. There's no effort to stay
compatible with Devuan beyond what's useful. Every change is recorded as a patch under `packages/`, so it can be
carried forward when Devuan updates a package.

**Fixed by earlier rulings**
- **Route A.** Devuan provides the source and the policy, not the binaries. Everything that links libc is rebuilt
  from excalibur source against Liella. Liella's binary packages take glibc's names (`libc6`, `libc-bin`,
  `libc6-dev`, ...), with `Source: liella`.
- **Reference .debs.** Liella publishes them as GitHub release assets with `SHA256SUMS` on each snapshot tag and runs no
  apt repository. **Aqours owns the apt repository** and signs it with its own key.
- **Liella's ABI label stays 2.39** until GLIBC_2.41 is complete. Excalibur's glibc is 2.41, so some sources will
  need 2.40/2.41 functions before then. Each one becomes an issue, and Aqours's blockers move up Liella's queue.

**Non-goals for now**
- No architecture other than amd64, and no multilib (`libc6-i386`, `gcc-multilib` are dropped).
- No change to Devuan's policy, init system or default package selection beyond what Liella requires.
- No timing or performance runs on the build hosts (they are pure build hosts by agreement with Liella).

**The scale.** Excalibur `main` has 37,587 source packages and 68,891 amd64 binary packages. A full-archive rebuild
takes weeks of build time on our hosts, and some fraction will fail for reasons unrelated to Liella. So Aqours is
built in **tiers**, smallest first (section 5), and "the whole archive" is a long-run aim, not the first milestone.

## 2. Infrastructure

This document names infrastructure by role only. The owner's private coordination repository records the hosts, paths
and credentials behind each role.

| Role | What it does |
|---|---|
| **Coordination host** | Build scheduler and its state; repository publishing and signing; the watcher for messages from Liella. Holds the archive signing key. Used only by Aqours. |
| **Build hosts** (two, with nested KVM) | Package builds; VM boot tests and autopkgtests in nested KVM. Pure build hosts: no timing runs. |
| **Build scratch** (RAM disk on each build host) | Build trees. Lost on reboot and takes RAM from builds, so large sources build on local disk instead. |
| **Mirror** (read-only) | Devuan excalibur and Debian trixie, with sources. Trusted only through signed `InRelease` checked against pinned archive keyrings, never `trusted=yes`. |
| **Aqours storage** (shared, backed up) | Repository, build logs, images. Finite: everything on it has a retention rule (section 8). Served over HTTP to test VMs and users. |
| **Coordination repository** (private) | Messages between the Aqours and Liella coordinators and the owner. |

**Build tooling.** `sbuild` in **unshare mode**, with chroot tarballs made by `mmdebstrap --mode=unshare`. The build
hosts allow unprivileged user namespaces, so builds need **no root**. One tarball per
stage (section 4), rebuilt from the repository when the stage's base changes. Build order comes from the dependency
graph (`dose-builddebcheck`, `botch`), never from hand-maintained lists.

**Scheduler.** It runs on the coordination host and keeps its state in SQLite. It dispatches builds over SSH to the
build hosts, sized to each host's cores and memory, then collects the result and log. Built packages go to an
incoming directory in Aqours storage. The coordination host verifies and signs them into the repository.

## 3. Repository and versions

- **Tool:** `reprepro` on the coordination host, publishing into Aqours storage, which is served over HTTP.
- **Suites:**
  - `aqours-bootstrap`: stage 1 output (section 4). Never installed by users; deleted after stage 3.
  - `aqours-unstable`: everything as built.
  - `aqours-testing`: packages that passed their build-time tests, autopkgtests and the image boot test. Images are
    made from this suite.
  - The first release: codename **Snow Halation**, suite name `snowhalation`. It's one word, so it can't be confused
    with the `-updates`/`-security` suffix suites.
- **Signing:** a dedicated Aqours archive key (owner decision 3). The `aqours-keyring` package ships it, and
  `signed-by` pins it in every sources entry.
- **Versions of rebuilt packages:** binNMU style, with the source unchanged and `+aqours1` appended to the binary
  version (e.g. `1.2-3` → `1.2-3+aqours1`). The suffix sorts after Devuan's version, says where the binary came
  from, and counts up on each no-change rebuild.
- **Aqours source changes** (only when unavoidable; section 6): version `<devuan-version>aqours1`.
- **Liella's packages** (`libc6`, `libc-bin`, `libc6-dev`, ...) are imported from Liella's release assets after
  checking `SHA256SUMS`, or built from a pinned Liella tag. Their version scheme is Liella's to set, but it matters
  to Aqours (section 7, item 6).
- **Libc-independent binaries are imported, not rebuilt** (owner decision 1). `Architecture: all` packages (data,
  docs, pure Perl/Python), kernel images and firmware contain nothing that links libc. They are taken from Devuan after
  verifying the archive signature and each file's hash, and republished in the Aqours repository. Every package that
  links libc is still rebuilt.
- **Following Devuan:** a daily job diffs excalibur and excalibur-security/-updates `Sources` and queues a rebuild
  for each changed source. Security updates go first.

## 4. Bootstrap: from a glibc system to one without it

A system without glibc can't be built by stock excalibur tools. They are linked against glibc 2.41, and Liella can't
yet run them (no soname search at start-up yet; GLIBC_2.40/2.41 symbols missing). So Aqours bootstraps in stages. Each
stage is built by the previous stage's tools.

**Stage 0: the glibc reference (no Liella needed).** Do a no-change rebuild of each tier with stock excalibur and
glibc, on the same infrastructure. It serves three purposes:
- it proves the infrastructure works before Liella is involved;
- it gives a baseline per package: whether the package builds and which of its tests pass with glibc;
- it measures build times, so the plan for later tiers rests on real numbers.

Later stages compare to it: a failure that is new on Liella is Liella's or the package's interaction with it, and one
that also happens on glibc is not Liella's. This is the comparison Liella's smoke run uses, scaled up. Stage 0
also covers testing Liella's reference .debs installed alongside glibc in an excalibur VM, which the owner allowed for
testing but not as the shipped design.

**Stage 1: build against Liella from a glibc host.** The excalibur chroot still has glibc running the compilers, but
links against Liella's libraries. This builds the **build-essential closure** (tier 0) and installs it into
`aqours-bootstrap`.
- **Method:** reuse Liella's `liella-cc`/`liella-c++` wrappers and the `check-elf.sh` gate from the smoke harness, so
  the build can't silently fall back to glibc.
- **Headers:** until Liella's own headers exist, stage 1 compiles with excalibur's glibc 2.41 headers. Liella keeps
  glibc's struct layouts and constants, so the binaries are what Liella promises to run, but three things leak through:
  - `__GLIBC_MINOR__` reads 41, so a configure check can enable a 2.40/2.41 feature;
  - feature-macro redirects and fortify `__*_chk` functions can bind to 2.40/2.41 symbol versions;
  - vectorised maths can call libmvec, which Liella doesn't have.

  So the gate also refuses any reference to a `GLIBC_2.40`/`GLIBC_2.41` version node or to `libmvec`, and builds
  disable fortify-level redirects where needed.
- **Stage 1 is a throwaway.** Nothing built with glibc's headers ships. Stages 2 and 3 rebuild everything once
  Liella's headers exist. Issues filed from stage 1 describe behaviour (what glibc does, what Liella does) and never
  quote glibc header text, because Liella is a clean-room implementation.
- **Build profiles:** `nocheck`, plus `stage1` where a source defines it. Tests are skipped here because the host is
  mixed; they run in stage 2.
- **Needs from Liella:** items 1–4 of section 7. Liella's planned checkpoint before stage 2 (an excalibur root with
  Liella swapped in, a scan of every ELF's version needs, and `apt install` of a sample) overlaps with stage 1. The
  two coordinators decide together who runs it.

**Stage 2: native, glibc-free.** The chroot contains only stage-1 packages and Liella's `libc6` packages, with
**no glibc**. Its first job is rebuilding tier 0 from source inside itself; that proves self-hosting. Then it builds
tier 1 and up, in dependency order, **with** build-time tests. The results go to `aqours-unstable`.

**Stage 3: rebuild again.** Rebuild tiers 0–1 once more in an environment made entirely of stage-2 output, then
compare to stage 2 (with `diffoscope`, sampled). Any difference is a nondeterminism or a stage-1 leftover to explain.
After stage 3, `aqours-bootstrap` is deleted and the tiers grow on stage-2/3 tools.

## 5. Tiers

The source count of each tier is computed from the excalibur dependency graph, not estimated by hand. Each tier's
gate is tested in a nested-KVM VM.

| Tier | Contents | Gate |
|---|---|---|
| T0 | Essential + build-essential closure (gcc, binutils, make, dpkg-dev, perl, coreutils, bash, tar, ...) | Builds itself in stage 2 |
| T1 | A base Devuan system: what a default Devuan base install contains (required + important + standard, sysvinit, eudev, kernel, bootloader, networking, apt), plus Aqours's identity packages | **"First light":** a VM boots to a login, runs `apt update`, and builds hello world, with no glibc on the system. **This is the scope of Snow Halation** (owner decision 2). |
| T2 | The build dependencies of T0–T1 not already in them | Aqours rebuilds itself from its own repository |
| T3 | Common server and developer packages (ssh, web servers, databases, Python/Perl/Rust/Go stacks) | autopkgtest pass rate measured against stage 0 |
| T4 | The rest of `main`, best effort | Failures tracked per package; nothing blocks on T4 |

## 6. Failures and how they are handled

Each failed build or test is classified against its stage-0 baseline:

| Class | Example | Action |
|---|---|---|
| **Liella** | Works on glibc, fails on Liella: missing symbol, wrong behaviour, crash | **Public issue** on duskglow/liella with a minimal reproducer, and a private note to the Liella coordinator (which Aqours work it blocks, and the workaround). A blocker moves up Liella's queue. |
| **2.40/2.41** | The source needs a function newer than 2.39 | Issue on duskglow/liella, labelled as a 2.40/2.41 need |
| **Package** | Also fails in stage 0 | Recorded and skipped. Fixed only if a higher tier needs it. |
| **Infrastructure** | Out of space, timeout, flaky mirror | Fixed in Aqours tooling, then retried |

**Patching packages** (owner, 2026-11-15): Aqours patches packages whenever that's what it takes, without hesitation.
The rule is that every change is documented here, so it's always clear what Aqours had to change and why. Patches
aren't sent to Debian or Devuan, unless a bug is egregious.

- **Where:** each patch lives under `packages/<source>/`, with a `README.md` saying what it changes, why, which
  failure it fixes, and (if any) the Liella issue it relates to.
- **Liella bugs:** a bug in Liella is still fixed in Liella. A package patch that works around one is a stopgap. It
  links the issue and is dropped once Liella fixes it.
- **Deliberate deviations:** departing from glibc's documented behaviour remains an owner decision.

## 7. What Aqours needs from Liella

In order of need: items 1–4 gate stage 1, and 5–7 gate stage 2 and first light. Almost all of it is Liella's planned
"system-libc" work: see `plan/system-libc.md` in duskglow/liella (branch `next`), and its scan of excalibur in
`results/system-libc-scan-2026-11-14.md`. Status as of 2026-11-15:

| # | Need | Liella's status |
|---|---|---|
| 1 | **Start-up soname search** and the `dlclose` fix (the snapshot) | In flight |
| 2 | **Standard install paths, laid out as glibc's `libc6`**: PT_INTERP `/lib64/ld-linux-x86-64.so.2` resolves (merged-/usr, multiarch libdir); `libc.so.6`, `libm.so.6` and the companion sonames | Planned (layout ruled; work continuing). `libpthread`, `libdl`, `librt`, `libutil`, `libanl` exist as placeholders, their symbols in `libc.so.6` as in modern glibc. `libresolv`, `libBrokenLocale`: in flight. **No `libnss_*` modules:** NSS `files` and `dns` are built into libc. |
| 3 | **Development files** as `libc6-dev`: CRT objects, `libc.so` script, `libc_nonshared.a`, static `libc.a`, **Liella's own headers** | Everything but the headers exists or is in flight. **Headers are the long pole** (large, split by spec section); stage 1 works around them (section 4). |
| 4 | **dpkg `symbols` and `shlibs`** for `libc6`, generated from Liella's ABI tables | Planned. Each `GLIBC_2.x` symbol's minimum version is `2.x`, so a rebuilt package depends on the version node it actually uses. |
| 5 | **`libc-bin` tools:** `ldconfig` first (dpkg triggers run it on every library install), then `getent`, `getconf`, `locale`, `iconv`, `ldd`; `localedef` later | `ldconfig` in progress; the rest planned. First light needs only `C.UTF-8`, which is built in, so `localedef` can come after. |
| 6 | **Package versions** that sort correctly against excalibur's `libc6 (>= 2.x)` dependencies | **Settled:** `<abi>+liella<YYYYMMDD>.<n>-<rev>`, no epoch; `<abi>` stays 2.39 until GLIBC_2.41 is complete. `2.39 < 2.39+liella… < 2.40`, so every dependency up to 2.39 is met and every 2.40/2.41 one is honestly not. A hand-written `(>= 2.40)` or `(>= 2.41)` is either a real need (issue) or a conservative bump (an Aqours patch). |
| 7 | **Runtime data** | **No gconv modules** (iconv's codecs are built in). `C`, `C.UTF-8` and `POSIX` are built in; other locales are compiled from Devuan's data by Liella's `localedef`. NSS `files` and `dns` are built in; `nsswitch.conf` and `gai.conf` ship with `libc-bin`. Aqours's default `nsswitch.conf` uses `files`, not `compat`. |
| 8 | **2.40/2.41 functions** | One issue per need. Liella's scan found no excalibur package needing 2.40 and 37 needing 2.41. |

**What follows for Aqours:**
- **Packages that can't work with Liella are dropped.** These are the ones that use `GLIBC_PRIVATE` (libnss-db,
  unscd, wcc, zzuf); Liella exports none. `nscd`/`unscd` are dropped anyway: Liella has its own name-service cache.
- **The `compat` NSS service and external NSS modules (LDAP, mDNS) come later**, so Snow Halation uses `files` and
  `dns` only.
- **`tzdata` needs `zic` only when rebuilt.** It's `Architecture: all`, so Aqours imports it (decision 1) and doesn't
  wait for Liella's `zic`.

## 8. Storage and housekeeping

The owner asked that Aqours clean up after itself, because array space is finite.

- **Build trees** go in build scratch, one directory per build (or on local disk for sources too large for it). They are
  deleted when the build ends, pass or fail. A failed build keeps only its log.
- **Logs:** compressed, in Aqours storage. Each package keeps its latest log and its latest failure log; all others go
  after 30 days.
- **The repository** keeps the current version of each package and the one before it. `reprepro` removes
  superseded files. `aqours-bootstrap` is deleted after stage 3.
- **Chroot tarballs and VM images:** only the current one per stage or tier and the previous one.
- A weekly usage report per directory in Aqours storage goes to the owner whenever growth is unexpected.
- Aqours storage holds only packages, logs and image files. Anything whose file ownership matters (chroots, unpacked
  rootfs trees) stays on the build hosts' local disks.

## 9. Testing

- **Build-time tests** of every package from stage 2 on, compared with the stage-0 baseline. "Fails on Liella, passes
  on glibc" is the primary signal for Liella issues.
- **autopkgtest** with the QEMU backend in nested KVM, for T1–T3.
- **Image boot test** for every `aqours-testing` update: build a rootfs with `mmdebstrap` from the repository, make a
  qcow2 image, boot it, and run a fixed checklist (init reaches its runlevel, login, networking, `apt update`, install a
  package, compile and run hello world, `ldd` on a sample shows no glibc). It runs again after each Liella snapshot.
- **Results** go to a status page, built later.

## 10. Source repositories

Aqours's sources are public on **GitHub** (owner decision 6). Coordination with Liella and anything about the private
infrastructure stay in the owner's private coordination repository.

One repository to start, **`duskglow/aqours`**:
- `docs/`: this document and later operating notes.
- `tools/`: the scheduler, build and import scripts, image builder, test checklists.
- `tiers/`: tier definitions (seed package lists; the closures are computed).
- `packages/<source>/`: Aqours's changes to Devuan sources (section 6), one directory per source.
- `packages/` also holds Aqours's own packages.

**What makes it Aqours rather than Devuan** (owner decision 2: minimal changes):
- `base-files`: `os-release` with `ID=aqours`, `ID_LIKE="devuan debian"`, `NAME="Aqours"`,
  `VERSION_CODENAME=snowhalation`, plus `/etc/issue` and `/etc/debian_version`.
- `aqours-keyring`: the archive key.
- apt sources pointing at the Aqours repository.
- Liella's `libc6` family in place of glibc's.

Nothing else is renamed or rebranded.

`packages/` can split into its own repository later if it grows. Liella issues are filed on duskglow/liella.

## 11. Milestones

| | Milestone | Needs | Done when |
|---|---|---|---|
| **M0** | Infrastructure | Build tooling installed on the hosts; HTTP serving of Aqours storage | sbuild, repo, signing, scheduler and the VM boot test work end to end on a stock excalibur package set |
| **M1** | Stage 0 | M0 | T0+T1 rebuilt with glibc; per-package build/test baselines and timings recorded |
| **M2** | Liella snapshot in Aqours | Liella snapshot | Reference .debs imported and verified; tested alongside glibc in an excalibur VM; first issues filed |
| **M3** | Stage 1 | Liella items 1–4 | T0 built against Liella, `check-elf` clean, in `aqours-bootstrap` |
| **M4** | Stage 2: first light | Liella items 5–7 | T0 rebuilt in itself; T1 VM boots with no glibc and passes the checklist |
| **M5** | Snow Halation | M4 | Stage 3 matches stage 2; T2 complete; Aqours rebuilds itself; first published image |
| **M6+** | Breadth | | T3, then T4, with pass rates tracked against stage 0 |

M0 and M1 don't depend on Liella and can start at once. They also produce the baseline that every later Liella
report rests on.

**Tooling for M0:**
- Build hosts: `sbuild`, `mmdebstrap`, `uidmap`, `devscripts`, `dose-builddebcheck`, `botch`, QEMU with OVMF,
  `autopkgtest`, `diffoscope`, `zstd`, and access to KVM.
- Coordination host: `reprepro`, `gnupg`, `sqlite3`, `zstd`.

## Decisions

The owner's decisions, 2026-11-15.

| # | Question | Decision |
|---|---|---|
| 1 | Rebuild libc-independent binaries? | **No.** `Architecture: all` packages, kernel images and firmware are imported from Devuan after verification ("no point in rebuilding things that don't need to be rebuilt"). |
| 2 | Scope of the first release | **A base Devuan system with the minimal changes needed to make it Aqours instead of Devuan** (tier T1, built and self-hosted through T2). |
| 3 | Signing key custody | **The Aqours coordinator, on the coordination host, for now.** The owner will move the primary key somewhere safe later. |
| 4 | Aqours storage on the coordination host | **Yes**, so publishing and signing happen where the key is. |
| 5 | Serving the repository | **HTTP, from the existing mirror server.** |
| 6 | Where Aqours's sources live | **GitHub** (public). Coordination stays private. |
| 7 | Spelling | **`aqours`**, after the Love Live! Sunshine!! group, everywhere. |
| 8 | Codename | **Snow Halation** for the first release (suite `snowhalation`). |
| 9 | Init system | **Devuan's sysvinit**, chosen for having fewer moving parts. Integration with larger distributions may come later as a separate experiment. |
| 10 | May stage 1 compile with glibc's headers before Liella's own exist? | **Yes, as a throwaway only**, to unblock the short term. Nothing built that way ships; stages 2 and 3 rebuild everything with Liella's headers. |
| 11 | What environment are packages built in? | **Build like Debian, ship like Devuan.** Devuan publishes Debian's own binaries for about 99.7% of its packages, and Debian built them in a full Debian environment. Rebuilding them in a Devuan-only environment caused failures neither project ever sees (build dependencies on systemd parts, Debian vendor checks). So Aqours builds in Debian trixie with Devuan excalibur layered over it, preferring Devuan's packages, and ships Devuan's selection (sysvinit, eudev, no systemd as init). Not shipping systemd still matters for Liella: its name-service modules need loadable NSS modules, and it is the most glibc-dependent PID 1. |

