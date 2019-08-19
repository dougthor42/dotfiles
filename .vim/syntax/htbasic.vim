" Quite when a syntax file was already loaded
" https://superuser.com/a/844059/184616
if exists('b:current_syntax')
  finish
endif

" Keywords
syn keyword htBasicLanguageKeywords DEF FNEND RETURN CALL OPTION BASE
syn keyword htBasicLanguageKeywords SUB SUBEND ALLOCATE CLEAR SCREEN DIM COM
syn keyword htBasicLanguageKeywords READ RESTORE CONTROL GOSUB OFF KEY LABELS KBD ALL
syn keyword htBasicLanguageKeywords GINIT SUBEXIT LOCATOR WAIT BEEP
syn keyword htBasicLanguageKeywords PRINT LABEL EXECUTE
syn keyword htBasicFlowControlKeywords IF THEN ELSE END ON ERROR GOTO CASE SELECT EXIT
syn keyword htBasicFlowControlKeywords LOOP UNTIL FOR NEXT
syn keyword htBasicTypeKeywords INTEGER REAL

" Matches
syn match htBasicComment "!.*$" display
syn match htBasicOperator '\V=\|-\|+\|*\|@\|/\|%\|&\||\|^\|~\|<\|>\|!=' display
" syn match htBasicLineNumber '^\d\d\d\d\d' display
"
" From https://github.com/vim-python/python-syntax/blob/master/syntax/python.vim#L328
" syn match htBasicNumber '\.\d\%([_0-9]*\d\)\=\%([eE][+-]\=\d\%([_0-9]*\d\)\=\)\=[jJ]\=\>' display
syn match htBasicNumber '\d'

" Regions
syn region htBasicString start='"' end='"'

" Links
hi def link htBasicLanguageKeywords       Statement
hi def link htBasicFlowControlKeywords    Keyword
hi def link htBasicTypeKeywords           Type
hi def link htBasicComment                Comment
hi def link htBasicOperator               Operator
hi def link htBasicString                 String
" hi def link htBasicLineNumber             Identifier
hi def link htBasicNumber                 Number

let b:current_syntax = 'htbasic'
