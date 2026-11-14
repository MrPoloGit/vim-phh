# vim-phh

Plain-Vim (not Neovim) support for PHH (.phh/.phhs), this project's deliberately
thinnest editor target. Plain Vim has no tree-sitter and no built-in LSP
client, so this package is L0 (syntax highlighting) only; L1 comes from
`phh-ls` through a general-purpose LSP plugin, documented below, not a
bespoke one shipped here.

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

## What's implemented (L0)

- **Filetype detection** (`ftdetect/phh.vim`): `.phh`/`.phhs` → `phh`.
- **Syntax highlighting** (`syntax/phh.vim`): comments, table headers
  (`[1]`, `[first]`, …), keys, the `=` operator, booleans, numbers
  (including `inf`/`nan`), local time, and both string forms (`"..."` and
  `'...'`).
- **ftplugin** (`ftplugin/phh.vim`): `commentstring`/`comments` for `#`,
  so built-in and plugin commenting commands work.

## L1: diagnostics and hover via phh-ls

No bespoke plugin here, a
config snippet is enough since the client-side work is identical to any
other LSP server. Point any general LSP client at `../phh-ls/build/phh-ls
../phh/registry` for filetype `phh`. For
[vim-lsp](https://github.com/prabirshrestha/vim-lsp):

```vim
if executable('phh-ls')
  au User lsp_setup call lsp#register_server({
      \ 'name': 'phh-ls',
      \ 'cmd': {server_info->['/path/to/phh-ls/build/phh-ls', '/path/to/phh/registry']},
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
      "args": ["/path/to/phh/registry"],
      "filetypes": ["phh"]
    }
  }
}
```

## How this was verified, and what it ruled out

`test/synid_test.vim` drives real Vim (`vim -N -u NONE -es`) against the
real corpus (`../phh/corpus/`), reading back the actual resolved highlight
group at specific positions via `synID()`/`synIDattr()`, not reading the
syntax file and assuming it behaves as written. **23/23 checks pass.**
This is also how the two limitations below were *found*, not guessed at.

Getting `synID()` to return anything at all in batch mode took real
debugging: it only reflects reality when a buffer goes through the normal
`:syntax on` + `:filetype on` + `:edit <realfile>` pipeline (so ftdetect
and the `Syntax` autocommand actually fire); forcing highlighting on a
scratch buffer via `:enew` + `:setlocal syntax=ON` reliably returns empty,
even with the exact same `:syn` commands already registered.

### L1 (vim-lsp): one real bug found and fixed; full handshake not automated

The L1 config snippet above was actually run against vim-lsp (cloned
locally) and `phh-ls`, not just written and assumed correct, and that
caught a real bug: the snippet originally had no `root_uri`, and vim-lsp's
own log showed it silently skipping initialization entirely as a result
(`"ignore initialization lsp server due to empty root_uri"`). Fixed in the
snippet above, and confirmed the `root_uri` callback itself resolves
correctly (`file:///.../phh/corpus/valid`) for a real corpus file.

Getting *past* that point, confirming the full `initialize` handshake
completes and a live hover/diagnostics round trip works, was not
achieved in this session's headless (`vim -N -u NONE -es`) test harness:
channel callbacks (`job_start`'s `out_cb`) did not fire during `:sleep`-based
waiting in that harness, which was confirmed to be a property of the
harness itself, not of vim-lsp or `phh-ls`, the *exact same* symptom
reproduced with a trivial non-LSP job (`job_start(['/bin/cat'], ...)`,
`ch_sendraw`, wait for `out_cb`), which has nothing to do with LSP, vim-lsp,
or this project's code at all. `phh-ls`'s hover and diagnostics behavior is
already proven correct independently and repeatedly (`phh-ls/tests/lsp_smoke_test.py`
over raw JSON-RPC; `nvim-phh/test/headless_test.lua` over Neovim's real
LSP client), what's specifically unconfirmed is only vim-lsp's own
handshake completing in *this* harness. If you use the corrected snippet
in a real, interactive Vim session, check that it works and report back;
that is the one piece here that was fixed from a confirmed bug but not
re-verified end-to-end afterward.

### Confirmed, documented limitations (not bugs to "fix", see syntax/phh.vim)

1. **No action-notation sub-grammar for the `actions` array.** Attempted
   (actor/verb/card nested highlighting, mirroring tree-sitter-phh-actions
   and vscode-phh's TextMate injection) and removed after isolated testing
   showed a real limit of Vim's legacy regex-based syntax engine: a plain
   (non-`contained`) syntax item is **ambient**, tried everywhere in the
   buffer regardless of any other region's `contains=` list, so there is
   no way to make an `actions = [ ... ]` region exclude the ambient generic
   string rule. Making the generic string rule itself `contained` (so it
   would need explicit containment like everything else) broke multi-line
   region nesting in this Vim version when tested, a separate apparent
   rough edge. Action strings still get ordinary string highlighting.
2. **No dedicated highlight for the `variant` field's value.** Attempted
   as a `region` (confirmed in isolation: when two `region`s compete for
   the same start position, the later-defined one wins, regardless of
   `match`-vs-`region` order elsewhere), but that priority was not robust
   against the rest of the file's rules: inserting one more, **textually
   unrelated** `:syn match` rule earlier in the file (matching a totally
   different column) was enough to flip the winner back to the generic
   string rule, confirmed by testing. Vim's real tie-break algorithm here
   is evidently more intricate than "last definition wins," and chasing it
   further wasn't worth it for a cosmetic highlight on this project's
   deliberately thinnest editor target. The variant value still renders
   correctly as an ordinary string.

Both are documented in `syntax/phh.vim` itself, at the exact point where
each would otherwise have been, so a future attempt starts from what's
already been ruled out instead of re-discovering it.
