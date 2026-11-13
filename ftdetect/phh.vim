" Filetype detection for .phh/.phhs .
" Same mapping as nvim-phh/ftdetect/phh.lua and vscode-phh/package.json's
" `languages` contribution, one filetype, both extensions.
autocmd BufRead,BufNewFile *.phh,*.phhs set filetype=phh
