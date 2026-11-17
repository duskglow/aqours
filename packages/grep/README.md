Source: grep
Applies-To: excalibur
Kind: test-fix (0001, 0002)
Status: 0001, 0002 active

# grep

## 0001: stack-overflow test accepts a non-recursive regex

**Problem.** `tests/stack-overflow` feeds grep up to 10 million `(` and passes only if gnulib's c-stack prints
"grep: stack overflow" (glibc's `regcomp` recurses once per parenthesis and overflows), or if grep exits 1 with no
output. libniji's `regcomp` parses the pattern without deep recursion and rejects it as what it is: exit status 2,
"grep: Unmatched ( or \(", the same answer grep gives for a few unmatched parentheses on any C library. So the test
failed on libniji (stage 1, 2026-11-17) although grep behaves correctly.

**Change.** `0001-stack-overflow-nonrecursive-regex.patch` also accepts exit status 2 with exactly that one-line
diagnostic and no output. Checked: the patched test passes with glibc (it still sees the overflow) and with libniji.

**Restored** never needed. It could go upstream if gnulib/grep want it; not egregious, so not sent (package patch
policy).

## 0002: triple-backref passes on a correct regex, skips on glibc's bug

**Problem.** `tests/triple-backref` checks `grep -E '(.?)(.?)(.?)\3\2\1'`, which glibc's regex gets wrong (sourceware
bug 11053), so upstream lists it in `XFAIL_TESTS`. libniji's regex gets it right, so on libniji the test passes
unexpectedly, and automake counts an unexpected pass as a failure (stage 1, 2026-11-17, after 0001).

**Change.** `0002-triple-backref-skip-on-glibc-bug.patch` drops the test from `XFAIL_TESTS` (in `tests/Makefile.am`
and the shipped `tests/Makefile.in`) and makes the test skip, naming the bug, when the C library's regex gives the
wrong answer. Checked: PASS on libniji, SKIP on glibc; the rest of the suite is unchanged.

**Restored** never needed.
