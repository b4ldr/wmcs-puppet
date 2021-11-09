" These are the basics. The autocmd-loaded files further down might
" modify some of these
filetype on

" Make % recognize <p>/</p> and others
source $VIMRUNTIME/macros/matchit.vim

" This makes 'J' join lines wothout *ever* adding whitespace
nmap J gJ

" Options
set nocp " Noncompatible.
set ek " Escapekeys (everything can be used in Ins-Mode)
set cf " error file and error jumping
set clipboard+=unnamed " Use clipboad for yanking etc
set ru " Ruler (cursor position) (lazy)
set vb " visual bell
set wmnu " wildmenu, enhanced tab-completion for cmdline
set noeb " No bell for error messages
set fo=cqrt " commentwrap, gq-formatting, auto-comment, textwrap
set shm=at " short messages (abbrev all, truncate if needed
"set digraph " Might be useful when not having a compose-key
set bg=dark " dark background
set showcmd " Show command status in ruler
set matchpairs=(:),{:},[:],<:> " self-explanatory
set ttyfast " My terminals are fast. All of 'em.
set pt=<F11> " paste-toggle
" how to show nonprintables in list mode
"set listchars=eol:$,tab:>-,extends:+,precedes:+
set listchars=tab:>·,trail:·
set nojoinspaces " I even hate single spaces, double even more so
set laststatus=2 " always show the status bar
set magic " Extended Regexen for / and :s/
set modeline " Use modelines
set modelines=10 " Maximum context to search for same
set report=0 " Be verbose/chatty about changes
set showmode " show current mode in statusline
set nostartofline " Stay in current column when paging
set wildchar=<TAB> " It's called tabcompletion for a reason
set wildmenu " wild menu
set whichwrap=<,>,[,] " Make  these movements pass over <cr>
set lz " do not redraw when executing macro (lazy)
set backspace=2 " Allow backspacing over everything.
"set statusline=%F%m%r%h%w\ [%1{&ff}/%Y]\ [\%03.3b\ 0x\%02.2B]
set nofoldenable " I don't like folding

" Commands
syntax on

" Various tweaks for certain filetypes
if !exists("autocommands_loaded")
  let autocommands_loaded = 1
  autocmd BufRead,BufNewFile,FileReadPost *.py source ~/.vim/python
  autocmd BufRead,BufNewFile,FileReadPost Makefile source ~/.vim/makefiles
  autocmd BufRead,BufNewFile,FileReadPost *.txt source ~/.vim/textfile
endif

" The colorscheme for vim, gvim ovverides this (see .gvimrc)
colorscheme wombat256modmod

set title
set titlestring=%F\ %r\ [%n]\ %LL\ %p%%

" This should be near the end, after all other mumbo-jumbo has been done.
highlight BadWhitespace ctermbg=darkgreen guibg=darkgreen
match BadWhitespace / /

" For https://github.com/fatih/vim-go
let g:go_list_type = "quickfix"
au Filetype go setl ts=4 | setl noexpandtab
au FileType go nmap <leader>r <Plug>(go-run)
au FileType go nmap <leader>R :GoRename<cr>
au FileType go nmap <leader>b <Plug>(go-build)
au FileType go nmap <leader>t <Plug>(go-test)
au FileType go nmap <leader>i :GoInfo<cr>
au FileType go nmap <leader>I :GoImports<cr>
let g:go_highlight_operators = 1
let g:go_fmt_fail_silently = 1

let g:gitgutter_override_sign_column_highlight = 0
