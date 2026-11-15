" synID()-based verification for syntax/phh.vim, run via:
"   vim -N -u NONE -es -c "source vim-phh/test/synid_test.vim"
"
" Mirrors the discipline of every other editor's test in this project
" (tree-sitter's `tree-sitter query`, vscode-phh's vscode-textmate
" tokenization, nvim-phh's headless Neovim run): checks the real highlight
" group resolved at specific positions in real corpus files, via Vim's own
" synID()/synIDattr(), rather than reading the syntax file and assuming it
" behaves as written. This is also how the file's one documented
" limitation (no actions-array sub-grammar, see syntax/phh.vim's trailing
" comment) was actually discovered, not guessed at.
"
" -es (Ex-silent) mode requires going through the real FileType -> Syntax
" autocmd pipeline (`:syntax on` + `:filetype on` + `:edit` a real file), " synID() reliably returns empty/0 for a scratch buffer whose highlighting
" was only forced via `:setlocal syntax=ON` without that pipeline, which
" cost real debugging time to track down in this project's session log.

set nocompatible
let g:phh_root = fnamemodify(getcwd(), ':p')
" Must extend 'runtimepath' BEFORE :filetype on, since that command scans
" runtimepath for ftdetect/*.vim once, at the moment it runs, not lazily.
let &runtimepath = &runtimepath . ',' . g:phh_root . 'vim-phh'
syntax on
filetype on

let s:failures = 0
let s:report = []

" Ex-mode (-es) has no real screen, so results are collected and written to
" a file rather than echoed, :echo output across many lines can otherwise
" trigger a "-- More --" pager prompt that hangs with no TTY to answer it.
function! s:Check(label, cond)
  if a:cond
    call add(s:report, '[ok] ' . a:label)
  else
    call add(s:report, '[FAIL] ' . a:label)
    let s:failures += 1
  endif
endfunction

function! s:GroupAt(line, col)
  return synIDattr(synID(a:line, a:col, 1), 'name')
endfunction

" 1. ftdetect + syntax load.
execute 'edit ' . g:phh_root . 'phh-data/corpus/valid/antonius-dwan-ivey-2009.phh'
call s:Check('ftdetect sets filetype=phh', &filetype ==# 'phh')
call s:Check('syntax item defined (b:current_syntax)', get(b:, 'current_syntax', '') ==# 'phh')

" 2. Targeted checks on antonius-dwan-ivey-2009.phh (line/col computed
"    directly from the real file's bytes, 1-indexed, Vim's own convention).
call s:Check('line 1 col 1 (#) is phhComment',              s:GroupAt(1, 1)  ==# 'phhComment')
call s:Check('line 2 col 1 (variant key) is phhKey',         s:GroupAt(2, 1)  ==# 'phhKey')
call s:Check('line 2 col 9 (=) is phhOperator',              s:GroupAt(2, 9)  ==# 'phhOperator')
" Documented, verified limitation (syntax/phh.vim's trailing comment): no
" dedicated highlight for the variant value, it just gets the ordinary
" phhString treatment, same as any other quoted field.
call s:Check('line 2 col 11 ("NT" value) is plain phhString, not a dedicated variant-value group', s:GroupAt(2, 11) ==# 'phhString')
call s:Check('line 2 col 12 (inside "NT") is plain phhString', s:GroupAt(2, 12) ==# 'phhString')
call s:Check('line 3 col 10 (500 in antes array) is phhNumber', s:GroupAt(3, 10) ==# 'phhNumber')
call s:Check('line 9 col 3  (opening quote of an action string) is phhString', s:GroupAt(9, 3) ==# 'phhString')
call s:Check('line 9 col 20 (# Ivey, a real trailing TOML comment) is phhComment', s:GroupAt(9, 20) ==# 'phhComment')

" 3. The bug class every other grammar in this project hit at least once:
"    a literal '#' inside a quoted field value must stay inside the
"    string, not start a comment. phh-data/corpus/valid/arieh-esposito-hui-
"    yockey-2019.phh's real `event` field (from phh-std/examples.rst) is
"    the one fixture that actually exercises this.
execute 'edit ' . g:phh_root . 'phh-data/corpus/valid/arieh-esposito-hui-yockey-2019.phh'
call s:Check('event field #58: "#" at col 26 stays inside the string, not phhComment',
      \ s:GroupAt(37, 26) ==# 'phhString')
call s:Check('event field #58: col 20 ("Event") is also phhString',
      \ s:GroupAt(37, 20) ==# 'phhString')

" 4. Documented, verified limitation: the actions-array action-notation
"    sub-grammar is NOT implemented (syntax/phh.vim's trailing comment
"    explains why, a genuine Vim syntax-engine limit, confirmed by
"    isolated testing, not a gap in this file alone). This check pins
"    down the ACTUAL (not aspirational) behavior: an action string inside
"    the array still gets ordinary phhString highlighting, same as any
"    other string, with no actor/verb/card sub-coloring.
call s:Check('action string content (e.g. "d" in "d dh p1...") is plain phhString, not a dedicated action-actor group',
      \ s:GroupAt(9, 4) ==# 'phhString')

" 5. Full-corpus sweep: every valid/invalid fixture at least loads and gets
"    filetype=phh + the syntax file applied, with no crash, the Vim
"    analog of the "zero ERROR nodes" sweep every other grammar/tokenizer
"    in this project ran across the whole corpus.
for path in glob(g:phh_root . 'phh-data/corpus/valid/*.phh', 0, 1)
      \ + glob(g:phh_root . 'phh-data/corpus/valid/*.phhs', 0, 1)
      \ + glob(g:phh_root . 'phh-data/corpus/invalid/*.phh', 0, 1)
  execute 'edit ' . fnameescape(path)
  call s:Check(fnamemodify(path, ':t') . ': loads with filetype=phh and syntax applied',
        \ &filetype ==# 'phh' && get(b:, 'current_syntax', '') ==# 'phh')
endfor

call add(s:report, '')
if s:failures > 0
  call add(s:report, s:failures . ' FAILURE(S)')
else
  call add(s:report, 'All checks passed.')
endif
call writefile(s:report, g:phh_root . 'vim-phh/test/synid_test_output.txt')

if s:failures > 0
  cquit!
else
  qa!
endif
