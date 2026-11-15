#!/bin/sh
# Boot check: Liella's coexistence flavour (liella6) beside glibc.
# Runs Devuan's own programs under Liella's loader and compares output and exit
# status with the same programs on glibc. Prints one AQOURS-CHECK line per item.
L=/usr/lib/liella/lib64/ld-linux-x86-64.so.2
n=0; bad=0
check() {   # check NAME COMMAND...: same stdout and status under glibc and Liella
  name=$1; shift
  ref=$("$@" 2>/dev/null); rs=$?
  got=$("$L" "$@" 2>/dev/null); gs=$?
  n=$((n + 1))
  if [ "$ref" = "$got" ] && [ "$rs" = "$gs" ]; then echo "AQOURS-CHECK: liella6 $name OK"
  else bad=$((bad + 1)); echo "AQOURS-CHECK: liella6 $name FAIL (status glibc=$rs liella=$gs)"; fi
}
if [ ! -x "$L" ]; then echo "AQOURS-CHECK: liella6 loader FAIL (missing $L)"; exit 1; fi
libc=$("$L" --list /bin/ls 2>&1 | grep 'libc.so.6' | head -1)
case "$libc" in *"/usr/lib/liella/"*) echo "AQOURS-CHECK: liella6 resolves-own-libc OK";;
  *) echo "AQOURS-CHECK: liella6 resolves-own-libc FAIL ($libc)"; bad=$((bad + 1));; esac
printf 'pear\napple\nfig\napple\n' > /tmp/aq-in
check ls        /bin/ls -la /etc/init.d
check sort      /usr/bin/sort /tmp/aq-in
check uniq      /usr/bin/sort -u /tmp/aq-in
check grep      /bin/grep -n app /tmp/aq-in
check sed       /bin/sed 's/p/P/g' /tmp/aq-in
check awk       /usr/bin/awk '{ n[$1]++ } END { for (k in n) s += n[k]; print s }' /tmp/aq-in
check bash      /bin/bash -c 'for i in 1 2 3; do echo $((i * i)); done'
check cat       /bin/cat /etc/os-release
check id        /usr/bin/id -u
check date      /bin/date -u -d @0 +%Y-%m-%dT%H:%M:%S
check false     /bin/false
rm -f /tmp/aq-in
echo "AQOURS-CHECK: liella6 summary $((n - bad + 1))/$((n + 1)) passed"
[ "$bad" -eq 0 ]
