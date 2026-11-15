Source: groff
Applies-To: excalibur
Kind: bootstrap
Status: planned (patch written when the package is first built)

# groff

**Bootstrap only (decision 16).** During the bootstrap, Aqours builds groff without PDF/TeX output tooling and the gxditview X previewer (pulls TeX Live, ghostscript, X).
This keeps large build-dependency chains out of the minimal bootstrap set (they were found with
`tools/builddeps`' chain report, `T2.why`).

**How:** a patch removes `texlive-base`, `texlive-latex-base`, `ghostscript`, `netpbm`, `psutils`, `libx11-dev`, `libxaw7-dev`, `libxmu-dev`, `libxt-dev` from `debian/control` and disables what needs them.

**Restored in the full pass,** once the system rebuilds itself; Snow Halation ships the full-featured build.
