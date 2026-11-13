" Buffer-local settings for PHH files. Kept minimal on purpose, this is
" L0 only; see README.md for how to add L1 (phh-ls) through a separate
" LSP plugin.
if exists("b:did_ftplugin")
  finish
endif
let b:did_ftplugin = 1

setlocal commentstring=#\ %s
setlocal comments=:#
