#!/bin/sh
# liella-swap.sh: run INSIDE a build chroot (as root) to swap Liella's system
# flavour in for glibc (design decision 12, stage 1). Used by tools/mkchroot
# --liella-swap. Arguments: LIELLA_VERSION AQOURS_REPO_URL
#
#  1. aqours-glibc-headers: a throwaway package of excalibur libc6-dev's headers
#     minus what linux-libc-dev ships (Liella has no headers yet; decision 10:
#     never shipped). It is built here from the verified excalibur packages.
#  2. Liella's libc6, libc-bin and libc6-dev at LIELLA_VERSION, from the Aqours
#     "liella" suite, installed over glibc's (a downgrade, so --force-depends).
#  3. apt is pinned to keep exactly these versions.
#  4. Installed packages that declare libc6 (>= 2.40) or (>= 2.41) keep that
#     dependency, unless every GLIBC_2.40/GLIBC_2.41 symbol their ELF files
#     need is defined by Liella's libc.so.6; only then is the recorded version
#     relaxed to Liella's. Liella's label stays 2.39 while it implements some
#     2.41 symbols, so this states the truth for those packages and nothing
#     else. Every decision is logged to /var/log/aqours-liella-swap.log.
set -eu
LV=${1:?usage: liella-swap.sh LIELLA_VERSION AQOURS_REPO_URL}
REPO=${2:?}
LOG=/var/log/aqours-liella-swap.log
export DEBIAN_FRONTEND=noninteractive LC_ALL=C.UTF-8
log() { echo "$*" | tee -a "$LOG"; }
: > "$LOG"
W=$(mktemp -d); cd "$W"

echo "deb $REPO liella main" > /etc/apt/sources.list.d/aqours-liella.list
apt-get update -qq

# 1. headers package (glibc's libc6-dev is downloaded into its own directory,
#    so it can never be confused with Liella's libc6-dev below)
mkdir -p hd/x hd/l hd/pkg/DEBIAN hd/src swap
(cd hd/src && apt-get download -qq libc6-dev linux-libc-dev)
gv=$(dpkg-deb -f hd/src/libc6-dev_*.deb Version)
dpkg-deb -x hd/src/libc6-dev_*.deb hd/x; dpkg-deb -x hd/src/linux-libc-dev_*.deb hd/l
(cd hd/x && find usr/include -type f -o -type l) | sort > hd/glibc.list
(cd hd/l && find usr/include -type f -o -type l) | sort > hd/linux.list
comm -23 hd/glibc.list hd/linux.list > hd/keep.list
(cd hd/x && tar -cf - -T ../keep.list) | (cd hd/pkg && tar -xf -)
cat > hd/pkg/DEBIAN/control <<C
Package: aqours-glibc-headers
Version: ${gv}+aqours.stage1
Architecture: amd64
Maintainer: Aqours Maintainers <aqours@koiren.ai>
Depends: linux-libc-dev
Section: libdevel
Priority: optional
Description: glibc ${gv} C headers for Aqours stage 1 (throwaway)
 The C library headers from Devuan excalibur's libc6-dev, minus what
 linux-libc-dev ships, for compiling against Liella before Liella has headers
 of its own. Stage 1 only (Aqours decision 10); never shipped.
C
dpkg-deb -Zxz -b hd/pkg aqours-glibc-headers.deb >/dev/null
log "headers: aqours-glibc-headers ${gv}+aqours.stage1, $(wc -l < hd/keep.list) files"

# 2. swap: Liella's three packages, each named exactly, then verified
(cd swap && apt-get download -qq "libc6=$LV" "libc-bin=$LV" "libc6-dev=$LV")
dpkg -i --force-depends --force-overwrite aqours-glibc-headers.deb \
  "swap/libc6_${LV}_amd64.deb" "swap/libc-bin_${LV}_amd64.deb" "swap/libc6-dev_${LV}_amd64.deb" >/dev/null 2>dpkg.err \
  || { cat dpkg.err; exit 1; }
for pv in "libc6 $LV" "libc-bin $LV" "libc6-dev $LV" "aqours-glibc-headers ${gv}+aqours.stage1"; do
  set -- $pv
  got=$(dpkg-query -W -f='${Version}' "$1" 2>/dev/null || echo none)
  [ "$got" = "$2" ] || { log "SWAP FAILED: $1 is $got, expected $2"; cat dpkg.err; exit 1; }
  log "installed: $1 $got"
done

# 3. pin
cat > /etc/apt/preferences.d/aqours-liella-swap <<P
Package: libc6 libc-bin libc6-dev
Pin: version $LV
Pin-Priority: 1001

Package: aqours-glibc-headers
Pin: version ${gv}+aqours.stage1
Pin-Priority: 1001
P

# 4. dependencies on libc6 >= 2.40/2.41: relax only where Liella defines every needed symbol
LIBC=$(readlink -f /lib/x86_64-linux-gnu/libc.so.6)
readelf --dyn-syms -W "$LIBC" | awk '$7 != "UND" && $8 ~ /@GLIBC_2\.4[01]$/ { sub(/@@?/, "@", $8); print $8 }' | sort -u > liella241.defs
log "liella libc.so.6 defines $(wc -l < liella241.defs) GLIBC_2.40/2.41 symbols"
need_relax=""
for p in $(dpkg-query -W -f='${Package}\t${Depends} ${Pre-Depends}\n' | awk -F'\t' '$2 ~ /libc6 \(>= 2\.4[01]/ {print $1}'); do
  missing=""
  for f in $(dpkg -L "$p" 2>/dev/null); do
    [ -f "$f" ] && [ ! -L "$f" ] || continue
    head -c 4 "$f" 2>/dev/null | grep -q 'ELF' || continue
    readelf --dyn-syms -W "$f" 2>/dev/null | awk '$7 == "UND" && $8 ~ /@GLIBC_2\.4[01]/ { sub(/ \(.*/, "", $8); print $8 }'
  done | sort -u > need.$p
  missing=$(comm -23 need.$p liella241.defs | tr '\n' ' ')
  if [ -z "$missing" ]; then
    need_relax="$need_relax $p"
    log "relax: $p (needs $(wc -l < need.$p) GLIBC_2.40/2.41 symbols, all defined by Liella)"
  else
    log "KEEP-BROKEN: $p needs symbols Liella lacks: $missing"
  fi
done
if [ -n "$need_relax" ]; then
  cp /var/lib/dpkg/status /var/lib/dpkg/status.aqours-pre-relax
  awk -v pk=" $need_relax " -v lv="$LV" '
    /^Package: / { cur = $2 }
    /^(Depends|Pre-Depends): / && index(pk, " " cur " ") { gsub(/libc6 \(>= 2\.4[01][^)]*\)/, "libc6 (>= " lv ")") }
    { print }' /var/lib/dpkg/status.aqours-pre-relax > /var/lib/dpkg/status
fi
apt-get check >/dev/null 2>apt.err && log "apt-get check: OK" || { log "apt-get check: FAILED: $(tail -3 apt.err | tr '\n' ' ')"; }
rm -f /etc/apt/sources.list.d/aqours-liella.list
apt-get update -qq || true
cd /; rm -rf "$W"
