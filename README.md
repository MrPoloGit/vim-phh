# vim-phh

Vim support for PHH (.phh/.phhs).

## Install

Add this directory to `'runtimepath'` (e.g. with a plugin manager, or by
hand: `set runtimepath+=/path/to/vim-phh` in your `vimrc`, before
`filetype on`/`syntax on` run). Needs `:filetype on` and `:syntax on`
enabled, which most `vimrc`s already have.

**Not listed anywhere.** This repo is pushed to
`github.com/MrPoloGit/vim-phh`, usable today by any plugin manager that
takes a plain git URL (`Plug 'MrPoloGit/vim-phh'`, Packer, vim-pathogen,
etc.), but it isn't listed on vim.org, vimawesome, or any other curated
index, nothing has been submitted anywhere.

No bespoke plugin here, a
config snippet is enough since the client-side work is identical to any
other LSP server. Point any general LSP client at `../phh-ls/build/phh-ls
../phh-data/registry` for filetype `phh`. For
[vim-lsp](https://github.com/prabirshrestha/vim-lsp):

```vim
if executable('phh-ls')
  au User lsp_setup call lsp#register_server({
      \ 'name': 'phh-ls',
      \ 'cmd': {server_info->['/path/to/phh-ls/build/phh-ls', '/path/to/phh-data/registry']},
      \ 'allowlist': ['phh'],
      \ 'root_uri': {server_info->lsp#utils#path_to_uri(fnamemodify(lsp#utils#get_buffer_path(), ':p:h'))},
      \ })
endif
```

**`root_uri` is not optional**, despite being absent from several of
vim-lsp's own simpler config examples: without it, vim-lsp silently skips
initialization entirely, confirmed directly against vim-lsp's own debug
log (`:let g:lsp_log_file = '...'`), which recorded exactly
`"ignore initialization lsp server due to empty root_uri"` for a PHH file
opened with no `root_uri` key set. PHH files are typically standalone, not
part of a larger recognized project, so the callback above just uses the
file's own directory rather than searching upward for a `.git`/project
marker that may not exist.

For [coc.nvim](https://github.com/neoclient/coc.nvim) (also works under
plain Vim via its separate node-based backend), add to `coc-settings.json`:

```json
{
  "languageserver": {
    "phh": {
      "command": "/path/to/phh-ls/build/phh-ls",
      "args": ["/path/to/phh-data/registry"],
      "filetypes": ["phh"]
    }
  }
}
```
