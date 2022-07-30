" In newer versions of Vim, the CTRL-K shortcut for some git file types
" was removed. It was an undocumented feature.
"
" See https://github.com/vim/vim/issues/9845 for the Issue and
" https://github.com/vim/vim/issues/9845#issuecomment-1051232851 for this
" workaround.
setlocal keywordprg=git\ show\ --patch-with-stat
