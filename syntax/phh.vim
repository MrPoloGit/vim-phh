" Vim syntax file for PHH (.phh/.phhs), 
"
" Plain Vim has no tree-sitter and no built-in LSP client, so this is L0
" (highlighting) only, deliberately weaker than tree-sitter-phh, and in
" one specific way documented below, not just "weaker" in the abstract.
" L1 (diagnostics/hover) comes from phh-ls through a separate LSP plugin;
" see README.md.

if exists("b:current_syntax")
  finish
endif

" -- Comments --------------------------------------------------------------
syn match phhComment "#.*$" contains=@Spell

" -- Table headers (.phhs hands): [1], [first], ... ------------------------
syn match phhTableHeader "^\s*\[[^]]*\]"

" -- Keys --------------------------------------------------------------------
syn match phhKey "^\s*[A-Za-z0-9_-]\+\ze\s*="
syn match phhOperator "="

" -- Literals ----------------------------------------------------------------
syn keyword phhBoolean true false
syn match phhNumber "\<[+-]\=\%(inf\|nan\)\>"
syn match phhNumber "\<[+-]\=\d[0-9_]*\%(\.\d[0-9_]*\)\=\%([eE][+-]\=\d[0-9_]*\)\=\>"
syn match phhTime "\<\d\{2}:\d\{2}:\d\{2}\%(\.\d\+\)\=\>"

" Generic strings, as `region`s rather than a flat `match`+nested-pattern.
" Confirmed necessary the same way vscode-phh's TextMate grammar needed it
" (vscode-phh/README.md "How this was verified"): a `region` actively scans
" for its own end pattern and isn't interrupted mid-span by an unrelated
" top-level match, so a literal '#' inside a quoted field value, e.g.
" event = "2019 WSOP Event #58", a real field from phh-std/examples.rst, " stays inside the string instead of starting a comment. Verified directly
" with synID() against that exact fixture (test/synid_test.vim), not
" assumed just because regions are "supposed to" behave this way.
syn region phhString start=/"/ skip=/\\./ end=/"/ contains=phhEscape
syn region phhStringSingle start=/'/ end=/'/

syn match phhEscape /\\["\\bfnrt]/ contained
syn match phhEscape /\\u[0-9A-Fa-f]\{4}/ contained
syn match phhEscape /\\U[0-9A-Fa-f]\{8}/ contained

" NOT implemented: a dedicated highlight for the `variant` field's value
" (tree-sitter-phh/queries/highlights.scm and vscode-phh's variant-pair
" both have one). Attempted as a `region`, start/end tie-break between two
" same-position `region`s DOES resolve by definition order in isolation
" (confirmed: a later-defined region beat an earlier one in a minimal
" test), but that priority turned out NOT to be robust against the rest
" of this file's rules: inserting one more, textually unrelated `:syn
" match phhOperator "="` rule *earlier* in the file (matching a different
" column entirely) was enough to flip the winner back to the generic
" phhString region, confirmed by testing, not theorized. Vim's exact
" tie-break algorithm here is evidently more intricate than "last
" definition wins," and not worth reverse-engineering further for a
" cosmetic highlight on this project's deliberately thinnest editor target
" . The variant value still renders
" correctly as an ordinary string (phhString), it just isn't specially
" colored on plain Vim.

" -- Highlight group links ----------------------------------------------------
hi def link phhComment      Comment
hi def link phhTableHeader  Label
hi def link phhKey          Identifier
hi def link phhOperator     Operator
hi def link phhBoolean      Boolean
hi def link phhNumber       Number
hi def link phhTime         Number
hi def link phhString       String
hi def link phhStringSingle String
hi def link phhEscape       SpecialChar

let b:current_syntax = "phh"

" NOT implemented: the `actions` array's action-notation sub-grammar
" (phh/registry/actions.json; tree-sitter-phh-actions's own grammar;
" vscode-phh's actions-pair TextMate injection). This was attempted and
" removed after real testing (test/synid_test.vim, and the more extensive
" isolated experiments recorded in the commit/session history) showed a
" genuine limit of Vim's legacy regex-based syntax engine, not a mistake
" in this file: a plain (non-"contained") syntax item is "ambient", it
" is tried EVERYWHERE in the buffer regardless of any other region's
" `contains=` list, and there is no way to make a `contains=`-restricted
" region (like an `actions = [ ... ]` array) exclude an ambient rule like
" the generic phhString above. Making phhString itself `contained`, so it
" would have to be explicitly reached through containment like everything
" else, broke multi-line region nesting in this Vim version (9.1) when
" tested, a separate, apparently real rough edge in how synID() resolves
" state for a zero-width-anchored region spanning many lines without an
" explicit `syn sync` directive. Chasing that further was not worth it for
" what this project already scopes as its
" deliberately thinnest editor target. Action strings still get ordinary
" string highlighting (phhString/phhStringSingle) via the rules above; they
" just don't get actor/verb/card sub-coloring on plain Vim. See README.md.
