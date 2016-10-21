" Doug's vimrc file.

" Copied from /etc/share/vim/vimrc and modified.

" This line should not be removed as it ensures that various options are
" properly set to work with the Vim-related packages available in Debian.
runtime! debian.vim

" Uncomment the next line to make Vim more Vi-compatible
" NOTE: debian.vim sets 'nocompatible'.  Setting 'compatible' changes numerous
" options, so any other options should be set AFTER setting 'compatible'.
"set compatible

set encoding=utf-8

" Vim5 and later versions support syntax highlighting. Uncommenting the next
" line enables syntax highlighting by default.
if has("syntax")
  syntax on
endif

" If using a dark background within the editing area and syntax highlighting
" turn on this option as well
"set background=dark

" Uncomment the following to have Vim jump to the last position when
" reopening a file
"if has("autocmd")
"  au BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif
"endif

" Uncomment the following to have Vim load indentation rules and plugins
" according to the detected filetype.
if has("autocmd")
  filetype plugin indent on
endif

" General Config (aka: I can't think of a name to group these...)
" ==============
set showcmd		" Show (partial) command in status line.
set showmatch		" Show matching brackets.
"set autowrite		" Automatically save before commands like :next and :make
set hidden		" Hide buffers when they are abandoned
"set mouse=a		" Enable mouse usage (all modes)
set number              " Enable line numbers
set history=100		" Buffer history size

" Source a global configuration file if available
if filereadable("/etc/vim/vimrc.local")
  source /etc/vim/vimrc.local
endif

" Colors and highlighting
colors desert

" Indenting
" =========
set nowrap
"set tabstop=4
"set expandtab
set smartindent
set autoindent

" Search Settings
" ===============
set hlsearch
set incsearch		" Incremental search
"set ignorecase		" Do case insensitive matching
"set smartcase		" Do smart case matching

" Commands
" ========
let mapleader="\\"
" Map '\rr' to reload the .vimrc file.
map <leader>rr :source ~/.vimrc<CR>

" Folding
" =======
"set foldmethod=indent		" Fold based on indent
"set foldnestmax=3		" Deepest fold is 3 levels
"set nofoldenable		" Don't fold by default

" Completion
" ==========

" Scrolling
" =========

