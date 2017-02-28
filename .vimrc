execute pathogen#infect()

" Sections:
"    -> General
"    -> User Interface
"    -> Colors and Fonts
"    -> Text, tab and indents
"    -> Buffers!
"    -> Status line
"    -> Mappings, aliases, commands, etc.
"    -> Folding
"    -> Tags & auto-complete
"    -> Language-specific stuff

" General
" How many lines of history VIM has to remember
set history=500
" Enable filetype plugins
filetype plugin indent on
" Set to auto read when a file is changed from the outside
set autoread

" User Interface

" Turn on the WiLd menu
set wildmenu
" Ignore swap files and other garbage
set wildignore=*.sw*,.DS_Store,.gitignore

" Show line numbers
set nonumber
" Show (partial) command in the last line of the screen
set showcmd
" Always show current position
set ruler
" Height of the command bar
set cmdheight=2

" Configure backspace so it acts like it should
set backspace=indent,eol,start
set whichwrap=<,>,h,l

" Ignore case when searching
set ignorecase
" When searching try to be smart about cases
set smartcase
" Highlight search results
set hlsearch
" Makes search act like search in modern browsers
set incsearch

" Show matching brackets when text indicator is over them
set showmatch
" How many tenths of a second to blink when matching brackets
"set mat=2

" No annoying sounds on errors
set noerrorbells
set novisualbell

" Colors and Fonts

" Enable syntax highlighting
syntax enable
" Colorscheme
colorscheme solarized
set background=dark

" map F5 to background toggle
call togglebg#map("<F5>")

" Custom colors for status bar
highlight ModeMsg cterm=bold ctermfg=2 ctermbg=black " set mode message ( --INSERT-- ) to green
highlight StatusLine ctermfg=7 ctermbg=9	         " set the active statusline to black on white
highlight StatusLineNC ctermfg=8 ctermbg=9		     " set inactive statusline to black on grey
" Set utf8 as standard encoding and en_US as the standard language
set encoding=utf8
" Use Unix as the standard file type
set ffs=unix,dos,mac

" Display vertical line at column 120
set colorcolumn=120

" Text, tab and indents
" Use spaces instead of tabs
set expandtab
" 1 tab == 4 spaces
set shiftwidth=4
set tabstop=4
set softtabstop=4
" Auto indent
set autoindent
"cindent
set cinoptions +=:1s " indent case statements 1 shiftwidth
set cinoptions +=>1s " indent 1 shiftwidth
set cinoptions +=p0  " indent function definitions 0 spaces
set cinoptions +=t0  " indent function return type 0 spaces
set cinoptions +=(0  " indent from unclosed parantheses
set cinoptions +=g2  " indent C++ scope resolution 2 spaces
set cinwords+=if
set cinwords+=else
set cinwords+=while
set cinwords+=do
set cinwords+=for
set cinwords+=switch
set cinwords+=case
set cindent
"formatoptions
set formatoptions+=t " Auto-wrap text using textwidth (but not comments)
set formatoptions+=c " Auto-wrap comments using textwidth, auto-inserting the current comment leader
set formatoptions+=q " Allow formatting of comments with "gq"
set formatoptions+=o " Automatically insert the current comment leader after hitting 'o'/'O' in Normal mode.
set formatoptions+=r " Automatically insert the current comment leader after hitting <Enter> in Insert mode.

" Buffers!

" Paste external text w/ <CMD>-V without tons of fucked up indentation in INSERT mode
set paste
" Return to last edit position when opening files (You want this!)
autocmd BufReadPost *
     \ if line("'\"") > 0 && line("'\"") <= line("$") |
     \   exe "normal! g`\"" |
     \ endif
" Remember info about open buffers on close
set viminfo^=%

" Status line
" Always show the status line
set laststatus=2

" Mappings, aliases, commands, etc.
" Case-insensitive :q[a] :x :w[qa] :e
if has("user_commands")
    command! -bang -nargs=? -complete=file E e<bang> <args>
    command! -bang -nargs=? -complete=file W w<bang> <args>
    command! -bang -nargs=? -complete=file Wq wq<bang> <args>
    command! -bang -nargs=? -complete=file WQ wq<bang> <args>
    command! -bang Wa wa<bang>
    command! -bang WA wa<bang>
    command! -bang Q q<bang>
    command! -bang QA qa<bang>
    command! -bang Qa qa<bang>
endif
cnoreabbrev <expr> X (getcmdtype() is# ':' && getcmdline() is# 'X') ? 'x' : 'X'

" Delete trailing white space on save
func! DeleteTrailingWS()
  exe "normal mz"
  %s/\s\+$//ge
  exe "normal `z"
endfunc
autocmd BufWrite * call DeleteTrailingWS()

" Rename tmux window to filename being edited
autocmd BufReadPost,FileReadPost,BufNewFile,BufEnter * call system("tmux rename-window " . expand("%"))
" Rename tmux window to "bash" when leaving vim
autocmd VimLeave * call system("tmux rename-window bash")

" Automatically update vimdiff
augroup AutoDiffUpdate
  au!
  autocmd InsertLeave * if &diff | diffupdate | let b:old_changedtick = b:changedtick | endif
  autocmd CursorHold *
        \ if &diff &&
        \    (!exists('b:old_changedtick') || b:old_changedtick != b:changedtick) |
        \   let b:old_changedtick = b:changedtick | diffupdate |
        \ endif
augroup END

" Folding
" Syntax-based code folding
set foldmethod=syntax
" Fold 2 levels of indentation down
set foldlevel=0
" Automatically fold on opening file
set foldenable

" Tags & Auto-complete

" Location for global tags
set tags+=$HOME/git/tags

" Function to be used for Insert mode omni completion with CTRL-X CTRL-O
set ofu=syntaxcomplete#Complete
" Only insert the longest common text of the matches
set completeopt=longest
" Use a popup menu to show possible completions if >1 match
set completeopt+=menuone

" Language-specific Stuff
" PHP
let php_sql_query=1             " SQL syntax highlighting inside strings
let php_htmlInStrings=1         " HTML syntax highlighting inside strings
let php_baselib=1               " built-in/lib functions highlighting
let php_parent_error_close=1    " highlighting parent error ] or )
let php_parent_error_open=1     " for skipping a php end tag, if there exists an open ( or [ without a closing one
let php_folding=1               " fold all classes and methods
let g:php_sql_query=1           " SQL syntax highlighting inside strings
let g:php_htmlInStrings=1       " HTML syntax highlighting inside strings
let g:php_baselib=1             " built-in/lib functions highlighting
let g:php_parent_error_close=1  " highlighting parent error ] or )
let g:php_parent_error_open=1   " for skipping a php end tag, if there exists an open ( or [ without a closing one
let g:php_folding=1             " fold all classes and methods

""let g:syntastic_php_checkers = ['phpcs', 'phpmd', 'php']
let g:syntastic_php_checkers = ['php']
""let g:syntastic_php_phpmd_args = 'text unusedcode'
""let g:syntastic_php_phpcs_args = 'encoding="' . system('enca -e' . expand('%')) . '" --severity=8'

" GO
let g:go_highlight_functions = 1
let g:go_highlight_methods = 1
let g:go_highlight_fields = 1
let g:go_highlight_types = 1
let g:go_highlight_operators = 1
let g:go_highlight_build_constraints = 1


let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list = 1
let g:syntastic_check_on_open = 0
let g:syntastic_check_on_wq = 0
let g:syntastic_error_symbol = "✗"
let g:syntastic_warning_symbol = "⚠"

let g:syntastic_go_checkers = ['go']
let g:syntastic_mode_map = { 'mode': 'active', 'passive_filetypes': ['go'] }
let g:go_list_type = "quickfix"

au FileType go nmap <Leader>ds <Plug>(go-def-split)
au FileType go nmap <Leader>dv <Plug>(go-def-vertical)
au FileType go nmap <Leader>dt <Plug>(go-def-tab)

" PHP
" autocmd BufRead FileType php SyntasticCheck phpcs

" JSON
au! BufNewFile,BufRead *.json set ft=json
augroup json_autocmd
  autocmd!
  autocmd FileType json set autoindent
  autocmd FileType json set formatoptions=tcq2l
  "autocmd FileType json set textwidth=78 shiftwidth=2
  autocmd FileType json set softtabstop=2 tabstop=4
  autocmd FileType json set expandtab
  autocmd FileType json set foldmethod=syntax
augroup END

syntax enable

autocmd BufNewFile,BufReadPost *.mql setlocal filetype=mongoql

let mapleader = ","
let maplocalleader  = ","

highlight Cursor guifg=black guibg=white
highlight iCursor guifg=steelblue guibg=white

"no more arrow keys
noremap <Up> <NOP>
noremap <Down> <NOP>
noremap <Left> <NOP>
noremap <Right> <NOP>

"TODO: after weaning myself off the arrow keys, enable hard mode
"autocmd VimEnter,BufNewFile,BufReadPost * silent! call HardMode()
"nnoremap <leader>h <Esc>:call ToggleHardMode()<CR>

function! WriteRun()
    :w | ! ./%
endfunction
command WR call WriteRun()
