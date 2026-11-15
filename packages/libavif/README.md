Source: libavif
Applies-To: excalibur
Kind: build-profile
Status: active

# libavif

Built with Debian's `nodoc` build profile (decision 14): its only route to `pandoc`, and so to ghc and the
Haskell libraries, is a documentation build dependency already marked `<!nodoc>`. No patch is needed. The man pages
pandoc would generate are not built; restoring them is part of the later ghc bring-up milestone.
