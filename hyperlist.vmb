" Vimball Archiver by Charles E. Campbell
UseVimball
finish
syntax/hyperlist.vim	[[[1
1038
" Vim syntax and filetype plugin for HyperList files (.hl)
" Language:   Self defined markup and functions for HyperLists in Vim
" Author:     Geir Isene <g@isene.com>
" Web_site:   http://isene.com/
" HyperList:  http://isene.org/hyperlist/
" Github:     https://github.com/isene/hyperlist.vim
" License:    I release all copyright claims. 
"             This code is in the public domain.
"             Permission is granted to use, copy modify, distribute, and
"             sell this software for any purpose. I make no guarantee
"             about the suitability of this software for any purpose and
"             I am not liable for any damages resulting from its use.
"             Further, I am under no obligation to maintain or extend
"             this software. It is provided on an 'as is' basis without
"             any expressed or implied warranty.
" Version:    2.4.1 - compatible with the HyperList definition v. 2.4
" Modified:   2019-10-06
" Changes:    Updated to be compatible with HyperList definition v. 2.4
"             Included full tutorial/test suite (thanks to Don Kelley).
"             Improved LaTeX export.
"             Improved GotoRef() (mapped to 'gr' and '<CR>')
"               GotoRef() now also opens files if the format is <file:...>
"               GotoRef() handles the new relative references like <+2> and <-5>
"             Some other minor changes and clean-ups of the documentation.

" INSTRUCTIONS {{{1
"
" Use tabs/shifts or * for indentations
"
" Use <SPACE> to toggle one fold.
" Use \0 to \9, \a, \b, \c, \d, \e, \f to show up to 15 levels expanded.
"
" <leader># or <leader>an toggles autonumbering of new items (the previous
" item must be numbered for the next item to be autonumbered). An item is
" indented to the right with <c-t>, adding one level of numbering. An item
" is indented to the left with <c-d>, removing one level of numbering and
" increasing the number by one.
"
" As a sort of "presentation mode", you can traverse a HyperList by using
" g<DOWN> or g<UP> to view only the current line and its ancestors.
" An alternative is <leader><DOWN> and <leader><UP> to open more levels down.
" 
" To highlight the current part of a HyperList (the current item and all its
" children), press <leader>h. This will uncollapse the whole HyperList and dim
" the whole HyperList except the current item and its children. To remove the
" highlighting, simply press <leader>h again (the fold level is restored).
"
" Use "gr" when the cursor is on a reference to jump to the referenced item.
" A reference can be in the list or to a file by the use of
" <file:/pathto/filename>, <file:~/filename> or <file:filename>.
"
" Use <leader>u to toggle underlining of Transitions, States or no underlining.
"
" Use <leader>v to add a checkbox at start of item or to toggle a checkbox.
" Use <leader>V to add/toggle a checkbox with a date stamp for completion.
"
" Use <leader><SPACE> to go to the next open template element.
" (A template element is a HyperList item ending in an equal sign).
"
" Use <leader>L to convert the entire document to LaTaX.
" Use <leader>H to convert the entire document to HTML.
" Use <leader>T to convert the entire document to a basic TPP presentation.
"
" Use <leader>z encrypts the current line (including all sublevels if folded).
" Use <leader>Z encrypts the current file (all lines).
" Use <leader>x decrypts the current line.
" Use <leader>X decrypts the current file (all lines).
" <leader>z and <leader>x can be used with visual ranges.
"
" A dot file (file name starts with a "." such as .test.hl) is
" automatically encrypted on save and decrypted on opening.
"
" You can add item tagged with future dates as items in your Google calendar.
" Use <leader>G to automatically add all items with future dates to your
" default calendar. Change your default under USER DEFINED SETTINGS below.
"
" Syntax is updated at start and every time you leave Insert mode.
"
" Much more information is found in the documentation (:help hyperlist.txt)

" Initializing {{{1
if version < 600
    syntax clear
elseif exists("b:current_syntax")
    finish
endif

let s:UNIX  = has("unix")  || has("macunix") || has("win32unix")
let s:MSWIN = has("win16") || has("win32")   || has("win64")     || has("win95")
if s:MSWIN
  if mapcheck("\<c-a>","n") != ""
    nunmap <c-a>
  endif
endif

" USER DEFINED SETTINGS (change these as you wish) {{{1
" Change this to add events as reminders to your Google calendar:
let b:calendar      = "geir@a-circle.no"

" Programs to handle opening of files with "gf" (programs must be in PATH)
" Add more programs if you want and make additions to the function OpenFile()
" If you are running Linux/Unix/MacOSX/win32unix
if s:UNIX
  let b:wordprocessingprogram = "libreoffice"
  let b:spreadsheetprogram    = "libreoffice"
  let b:presentationprogram   = "libreoffice"
  let b:pdfprogram            = "zathura"
  let b:imageprogram          = "feh"
  let b:browserprogram        = "qutebrowser"
endif
" If you are running MS Windows:
if s:MSWIN
  " Add the path to the programs if you don't want to mess around with a path variable
  " ...such as: '/Program^ Files^ (x86)/Microsoft^ Office/root/Office16/'
  let b:wordprocessingprogram = "winword"
  let b:spreadsheetprogram    = "excel"
  let b:presentationprogram   = "powerpnt"
  let b:pdfprogram            = "AcroRd32"
  let b:imageprogram          = "i_view32"
  let b:browserprogram        = "firefox"
endif
" You can add programs to open other file types - and add the opener to the
" function "OpenFile()" (see example there). Example::
" let b:scadprogram           = "openscad"

" Lower the next two values if you have a slow computer
syn sync minlines=50
syn sync maxlines=100

" Settings {{{1
let b:current_syntax="HyperList"
let b:highlight="false"
set autoindent
set textwidth=0
set shiftwidth=3
set tabstop=3
set softtabstop=3
set noexpandtab
set guioptions+=t
set foldmethod=syntax
set fillchars=fold:\ 
syn sync fromstart
autocmd InsertLeave * :syntax sync fromstart

" Functions {{{1
"  Folding {{{2
"  Mapped to <SPACE> and <leader>0 - <leader>f
set foldtext=HLFoldText()
function! HLFoldText()
  let line = getline(v:foldstart)
  let myindent = indent(v:foldstart)
  let line = substitute(line, '^\s*', '', 'g')
  while myindent != 0
    let myindent = myindent - 1
    let line = ' ' . line
  endwhile
  return line
endfunction

" Highlighting {{{2
"  Simplified Limelight - thanks to Junegunn Choi for the inspiration
"  (https://travis-ci.org/junegunn/limelight.vim.svg?branch=master)
function! HighLight()
  if b:highlight=="false"
    echo "Highlight ON"
    let b:fl=&fdl
    set foldlevel=15
    let b:highlight="true"
    autocmd CursorMoved,CursorMovedI * call HighLightHL()
  else
    echo "Highlight OFF"
    let &fdl=b:fl
    autocmd!
    autocmd InsertLeave * :syntax sync fromstart
    let b:highlight="false"
    execute 'syn clear HLdim0'
    execute 'syn clear HLdim1'
  endif
endfunction

function! HighLightHL()
	let start_line_number = line('.')
	let end_line_number   = start_line_number + 1
	let start_line_indent = indent('.')
	while indent(end_line_number) > start_line_indent
		let end_line_number += 1
	endwhile
  let start = start_line_number
	let end = end_line_number - 1
  execute 'syn clear HLdim0'
  execute 'syn clear HLdim1'
  execute 'syn match HLdim0 ".*\%<' . string(start) . 'l"'
  execute 'syn match HLdim1 ".*\%>' . string(end)   . 'l"'
endfunction

"  AutoNumbering {{{2
"  Mapped to <leader># and <leader>an
"  When activated, <cr> increments the next item on the same level
"  <c-t> indents the item and adds one level of numbering
"  <c-d> de-indents the item and renumbers it.
let s:an = 0
function! ToggleAutonum()
  if s:an == 0
    echo "Autonumber ON"
    imap   <cr> <cr><esc><up>yypf D<left><c-a>gJ:s/\(.*\d.\)\s*/\1 /<cr>A
    imap   <c-t> <esc>>>f <left><left><c-x>a.1<esc><end>a
    imap   <c-d> <esc><<f <left>T.diw<left>x<left><c-a><end>a
    let s:an = 1
  else
    echo "Autonumber OFF"
    iunmap <cr>
    iunmap <c-t>
    iunmap <c-d>
    let s:an = 0
  endif
endfunction

"  Renumber {{{2
"  Mapped to <leader>R
function! Renumber() range
	let l1 = a:firstline
	let l2 = a:lastline
	"If the first line is without a number, add a 1 in the front
	try
		if match(getline(l1),'^\t*\d\+') != 0
			exe l1 's/\(^\t*\)\(.*\)/\11 \2'
		endif
	catch
	endtry
	"Get the indent and store it in 'tabs'
	let tabs = substitute(getline(l1), '^\(\t*\).*', '\1', '')
	"The first part of numbering (like 1.2.) in 'initnum'
	let initnum = substitute(getline(l1), '^\t*\([0-9.]\+\)*\d\+\.* .*', '\1', '')
	"The numbering after initnum starts with 1
	let numx = substitute(getline(l1), '^\t*\([0-9.]\+\)*\(\d\+\)\.* .*', '\2', '')
  "Get the last period"
  let period = substitute(getline(l1), '^\t*\([0-9.]\+\)*\(\d\+\)\(\.*\) .*', '\3', '')
	"Start from first line 
	let lx = l1 + 1
	"Loop until the last line
	while lx <= l2
		"If the indent matches (we will not number lines with greater indentations)
		if match(getline(lx),tabs."[a-zA-ZæøåÆØÅáéóúãõâêôçàÁÉÓÚÃÕÂÊÔÇÀü0-9<>#()\*:]") == 0
			let numx += 1
			silent! exe lx 's/\(^\t*\)[0-9.]* \(.*\)/\1\2'
			let startline = substitute(getline(lx), '\(^\t*\).*', '\1', '')
			let numline = initnum . numx . period
			let endline = substitute(getline(lx), '^\t*\(.*\)', ' \1', '')
			let wholeline = startline . numline . endline
			call setline(lx, wholeline)
		endif
		let lx += 1
	endwhile
endfunction

"  Encryption {{{2
"  Remove traces of secure info upon decrypting (part of) a HyperList
function! HLdecrypt()
  set viminfo=""
  set noswapfile
endfunction

"  Underlining States/Transitions {{{2
"  Mapped to <leader>u
let g:STu=0
hi link HLstate NONE
hi link HLtrans NONE
function! STunderline()
  if g:STu == 0
    hi link HLtrans NONE
    hi link HLstate underlined
    let g:STu = 1
  elseif g:STu == 1
    hi link HLstate NONE
    hi link HLtrans underlined
    let g:STu = 2
  elseif g:STu == 2
    hi link HLstate NONE
    hi link HLtrans NONE
    let g:STu = 0
  endif
endfunction

"  Checkbox and timestamp {{{2
"  Mapped to <leader>v and <leader>V
function! CheckItem (stamp)
  let current_line = getline('.')
  if match(current_line,'\V[_]') >= 0
    let time = strftime("%Y-%m-%d %H.%M")
    exe 's/\V[_]/[x]/'
    if a:stamp == "stamped"
      exe "normal 0f]a ".time.":"
    endif
  elseif match(current_line,'\V[x]') >= 0
    exe 's/\V[x]/[_]/i'
    exe 's/\V[_] \d\d\d\d-\d\d-\d\d \d\d\.\d\d:/[_]/e'
  else
    exe "normal ^i[_] "
  endif
endfunction

"  Goto reference {{{2
"  Mapped to 'gr' and <CR>
if !exists("*GotoRef") 
  function! GotoRef()
    normal m'
    let current_line = getline('.')
    let ref_multi = 0
    if match(current_line,'<.*>') >= 0
      let ref_word = matchstr(current_line,"<.\\{-}>")
      let ref_word = substitute(ref_word, "<", '', 'g')
      let ref_word = substitute(ref_word, '>', '', 'g')
      let ref_end  = ref_word
      if match(ref_word,"^file:") >= 0
        let ref_word = substitute(ref_word, 'file:', '', 'g')
        normal 0
        call search(ref_word)
        call OpenFile()
      elseif match(ref_word,"^[-+][0-9]") >= 0
        let ref_word = str2nr(ref_word)
        let dest = line(".") + ref_word
        exe ":" . dest
        normal z.
      else
        if match(ref_word,"\/") >= 0
          let ref_end = substitute(ref_end, '^.*/', '\t', 'g')
          let ref_multi = 1
        endif
        let ref_dest = substitute(ref_word, '/', '\\_.\\{-}\\t', 'g')
        let ref_dest = "\\s" . ref_dest
        let @/ = ref_dest
        normal gg
        call search(ref_dest)
        let new_line = getline('.')
        if new_line == current_line
          echo "No destination"
        else
          if ref_multi == 1
            call search(ref_end)
          end
        endif
        normal z.
      endif
    else
      echo "No reference in the HyperList item"
    endif  
  endfunction
endif

"  Open file under cursor {{{2
"  Mapped to 'gf'
function! OpenFile()
  if expand('<cWORD>') =~ '<' && expand('<cWORD>') =~ '>'
    let gofl = expand('<cfile>')
    if gofl =~ '\(odt$\|doc$\|docx$\)'
      exe '!' . b:wordprocessingprogram . ' "' . gofl . '"'
    elseif gofl =~ '\(odc$\|xls$\|xlsx$\)'
      exe '!' . b:spreadsheetprogram . ' "' . gofl . '"'
    elseif gofl =~ '\(odp$\|ppt$\|pptx$\)'
      exe '!' . b:presentationprogram . ' "' . gofl . '"'
    elseif gofl =~ '\(jpg$\|jpeg$\|png$\|bmp$\|gif$\)'
      exe '!' . b:imageprogram . ' "' . gofl . '"'
    elseif gofl =~ 'pdf$'
      exe '!' . b:pdfprogram . ' "' . gofl . '"'
    elseif gofl =~ '://'
      exe '!' . b:browserprogram . ' "' . gofl . '"'
  " You add more file openers here by using variables defined in the user
  " settings at the start of this script. Example:
  " elseif gofl =~ 'scad$'
  "   exe '!' . b:scadprogram . ' "' . gofl . '"'
    else
      if has("gui_running")
        exe '!gvim '.gofl
      else
        exe '!vim '.gofl
      endif
    endif
  else
    echo "No reference"
  endif
endfunction

"  HTML conversion{{{2
"  Mapped to '<leader>H'
function! HTMLconversion ()
    try
        "Remove VIM tagline
        execute '%s/^vim:.*//g'
    catch
    endtry
    try
        "first line of a HyperList is bold
        execute '%s/^\(\S.*\)$/<strong>\1<\/strong>/g'
    catch
    endtry
    try
        "HLb
        execute '%s/ \@<=\*\(.\{-}\)\* /<strong>\1<\/strong>/g'
    catch
    endtry
    try
        "HLi
        execute '%s/ \@<=\/\(.\{-}\)\/ /<em>\1<\/em>/g'
    catch
    endtry
    try
        "HLu
        execute '%s/ \@<=_\(.\{-}\)_ /<u>\1<\/u>/g'
    catch
    endtry
    try
        "HLquote
        execute '%s/\(\".*\"\)/<em>\1<\/em>/g'
    catch
    endtry
    try
        "HLcomment
        execute '%s/\((.*)\)/<em>\1<\/em>/g'
    catch
    endtry
    try
        "HLindent
        execute "%s/\\(\\t\\|\\*\\)\\@<=\\(\\d.\\{-}\\)\\s/<font color=\"purple\">\\2<\\/font> /g"
    catch
    endtry
    try
        "HLmulti (+)
        execute '%s/\(\t\|\*\)+/\t<font color="purple">+<\/font>/g'
    catch
    endtry
    try
        "HLhash
        execute "%s/\\(#[a-zA-ZæøåÆØÅ0-9.:/_&?%=\\-\\*]\\+\\)/<font color=\"yellow\">\\1<\\/font>/g"
    catch
    endtry
    try
        "HLref
        execute "%s/\\(<\\{1,2}\\[a-zA-ZæøåÆØÅ0-9.:/_&?%=\\-\\* ]\\+>\\{1,2}\\)/<font color=\"purple\">\\1<\\/font>/g"
    catch
    endtry
    try
        "HLmove
        execute '%s/\(>>\|<<\|->\|<-\)/<font color="red"><strong>\1</strong><\/font>/g'
    catch
    endtry
    try
        "HLqual
        execute '%s/\(\[.\{-}\]\)/<font color="green">\1<\/font>/g'
    catch
    endtry
    try
        "HLop
        execute "%s/\\(\\s\\|\\*\\)\\@<=\\([A-ZÆØÅ_/]\\{-2,}:\\s\\)/<font color=\"blue\">\\2<\\/font>/g"
    catch
    endtry
    try
        "HLprop
        execute "%s/\\(\\s\\|\\*\\)\\@<=\\([a-zA-ZæøåÆØÅ0-9,._&?%= \\-\\/+<>#']\\{-2,}:\\s\\)/<font color=\"red\">\\2<\\/font>/g"
    catch
    endtry
    try
        "HLsc
        execute '%s/\(;\)/<font color="green">\1<\/font>/g'
    catch
    endtry
    try
        "Substitute space in second line of multi-item
        execute '%s/\(^\|\t\|\*\)\@<=\(\t\|\*\) /\&nbsp;\&nbsp;\&nbsp;\&nbsp;\&nbsp;\&nbsp;/g'
    catch
    endtry
    try
        "Substitute tabs
        execute '%s/\(^\|\t\|\*\)\@<=\(\t\|\*\)/\&nbsp;\&nbsp;\&nbsp;\&nbsp;/g'
    catch
    endtry
    try
        "Substitute newlines with <br />
        execute '%s/\n/<br \/>\r/g'
    catch
    endtry
    "Document start
    normal ggO<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
    normal o<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en">
    normal o<head>
    normal o<title>HyperList</title>
    normal o<meta name="creator" content="HyperList plugin for VIM: http://vim.sourceforge.net/scripts/script.php?script_id=2518" />
    normal o<meta http-equiv="Content-Type" content="text/html;charset=UTF-8">
    normal o</head>
    normal o<body>
    "Document end
    normal GO</body>
    normal o</html>
    set filetype=html
endfunction
"  LaTeX conversion{{{2
"  Mapped to '<leader>L'
function! LaTeXconversion ()
    set expandtab
    retab
    try
        "Remove VIM tagline
        execute '%s/^vim:.*//g'
    catch
    endtry
    try
        "Escape "\"
        execute '%s/\\/\\\\/g'
    catch
    endtry
    try
        "Escape "{"
        execute '%s/{/\\{/g'
    catch
    endtry
    try
        "Escape "}"
        execute '%s/}/\\}/g'
    catch
    endtry
    try
        "HLb
        execute '%s/ \@<=\*\(.\{-}\)\* /\\textbf{ \1 }/g'
    catch
    endtry
    try
        "HLi
        execute '%s/ \@<=\/\(.\{-}\)\/ /\\textsl{ \1 }/g'
    catch
    endtry
    try
        "HLu
        execute '%s/ \@<=_\(.\{-}\)_ /\\underline{ \1 }/g'
    catch
    endtry
    try
        "HLindent
        execute '%s/\(\s\s\s\|\*\|^\)\([0-9.]\+\s\)/\1\\textcolor{v}{\2}/g'
    catch
    endtry
    try
        "HLmulti
        execute '%s/\(\s\s\s\|\*\)+/\s\s\s\\textcolor{v}{+}/g'
    catch
    endtry
    try
        "HLhash
        execute "%s/\\(#[a-zA-ZæøåÆØÅ0-9.:/_&?%=\\-\\*]\\+\\)/\\\\textcolor{o}{\\1}/g"
    catch
    endtry
    try
        "HLref
        execute "%s/\\(<\\{1,2}[a-zA-ZæøåÆØÅ0-9.:/_&?%=\\-\\* ]\\+>\\{1,2}\\)/\\\\textcolor{v}{\\1}/g"
    catch
    endtry
    try
        "HLquote
        execute '%s/\(\".*\"\)/\\textcolor{t}{\1}/g'
    catch
    endtry
    try
        "HLcomment
        execute '%s/\((.*)\)/\\textcolor{t}{\1}/g'
    catch
    endtry
    try
        "HLmove
        execute '%s/\(>>\|<<\|->\|<-\)/\\textbf{\1}/g'
    catch
    endtry
    try
        "HLqual
        execute '%s/\(\[.\{-}\]\)/\\textcolor{g}{\1}/g'
    catch
    endtry
    try
        "HLop
        execute "%s/\\(\\s\*\\|\\*\*\\)\\([A-ZÆØÅ_/]\\{-2,}:\\s\\)/\\1\\\\textcolor{b}{\\2}/g"
    catch
    endtry
    try
        "HLprop
        execute "%s/\\(\\s\*\\|\\*\*\\)\\([a-zA-ZæøåÆØÅ0-9,._&?%= \\-\\/+<>#']\\{-2,}:\\s\\)/\\1\\\\textcolor{r}{\\\\emph{\\2}}/g"
    catch
    endtry
    try
        "HLsc
        execute '%s/\(;\)/\\textcolor{g}{\1}/g'
    catch
    endtry
    try
        "ldots
        execute '%s/\.\.\./\\ldots /g'
    catch
    endtry
    "Document start
    normal ggO%Created by the HyperList vim plugin, see:
    normal o%http://vim.sourceforge.net/scripts/script.php?script_id=2518
    normal o
    normal o\documentclass[10pt,a4paper,usenames]{article}
    normal o\usepackage[usenames]{color}
    normal o\definecolor{r}{rgb}{0.5,0,0}
    normal o\definecolor{g}{rgb}{0,0.5,0}
    normal o\definecolor{b}{rgb}{0,0,0.5}
    normal o\definecolor{v}{rgb}{0.4,0,0.4}
    normal o\definecolor{t}{rgb}{0,0.4,0.4}
    normal o\definecolor{0}{rgb}{0.6,0.6,0}
    normal o\usepackage[margin=2cm]{geometry}
    normal o\usepackage[utf8]{inputenc}
    normal o\usepackage[english]{babel}
    normal o\usepackage[T1]{fontenc}
    normal o\usepackage{alltt}
    normal o\usepackage{fancyhdr}
    normal o\pagestyle{fancy}
    normal o\fancyhead[RO]{\raggedleft FIXME }
    normal o\fancyfoot{}
    normal o\usepackage{pdfpages}
    normal o
    normal o\begin{document}
    normal o\begin{alltt}
    "Document end
    normal Go\end{alltt}
    normal o\end{document}
    set filetype=tex
endfunction

"  TPP conversion{{{2
"  Mapped to '<leader>T'
"  See https://github.com/cbbrowne/tpp
function! TPPconversion ()
    try
        "Remove VIM tagline
        execute '%s/^vim:.*//'
    catch
    endtry
    try
        "first line of a HyperList is title
        execute '%s/^\(\S.*\)$/\r--title \1/'
    catch
    endtry
    try
        "second line of a HyperList is a new slide
        execute '%s/^\(\t\|\*\)\(\S.*\)$/\r--newpage\r\r--header \2/'
    catch
    endtry
    try
        "HLb
        execute '%s/ \@<=\*\(.\{-}\)\* /--boldon\r\1\r--boldoff/g'
    catch
    endtry
    try
        "HLi
        execute '%s/ \@<=\/\(.\{-}\)\/ /--revon\r\1\r--revoff/g'
    catch
    endtry
    try
        "HLu
        execute '%s/ \@<=_\(.\{-}\)_ /--ulon\n\1\r--uloff/g'
    catch
    endtry
    try
        "strip two tabs/indents
        execute '%s/^\(\t\|\*\)\{2}//'
    catch
    endtry
    "Document start
    normal ggO--bgcolor white
    normal o--fgcolor black
    normal o--date today
endfunction
"  Show/Hide{{{2
"  Useful for easily showing e.g. a specific tag or hash 
"  Taken from VIM script #1594 (thanks to Amit Sethi)
"  zs    Show all lines containing word under cursor
"  zh    Hide all lines containing word under cursor
"  z0    Go back to normal HyperList folding
"  :SHOW word/pattern
"        Show lines containing either word or pattern
"  :HIDE word/pattern
"        Hide lines containing either word or pattern
"        Pattern can be any regular expression

command! -nargs=+  SHOW  :call <SID>ShowHideWord('c', 's', <f-args>)
command! -nargs=+  HIDE  :call <SID>ShowHideWord('c', 'h', <f-args>)

function! <SID>ShowHideWord(mode, show, ...)
   if (a:mode == 'z')
      if a:show == 's' | echo "ShowHide Show" | endif
      if a:show == 'h' | echo "ShowHide Hide" | endif
      let cur_word = '\\<' . expand("<cword>") . '\\>'
   else
      let i = 1
      let cur_word = '\\<\\('
      let binder = ''
      while i <= a:0
         let ai = substitute(a:{i}, '\\', '\\\\', 'g')
         let cur_word = cur_word . binder . ai
         let binder = '\\\|'
         let i = i + 1
      endw
      let cur_word = cur_word . '\\)\\>'
   endif

   let myfoldexpr = "set foldexpr=getline(v:lnum)" .
      \ (a:show == 's' ? "!" : "=") . "~\'\^.*" . cur_word . ".*\$\'"

   set foldenable
   set foldlevel=0
   set foldminlines=0
   set foldmethod=expr
   exec myfoldexpr
endfunction

"  CalendarAdd{{{2
"  :call CalendarAdd() will take all items containing a future date and add them 
"  as reminder to your Google Calendar. If the item includes a time, the event 
"  is added from that time with duration of 30 minutes.
"  This function requires gcalcli (https://github.com/insanum/gcalcli)
"  The function is mapped to <leader>G to add events to the default
"  calendar - defined as b:calendar at the start of this script.
"  To add the events to another calendar, do :call CalendarAdd("yourcalendar")
function! CalendarAdd(...)
  let l:count = 0
  let l:cal = a:0 > 0 ? a:1 : b:calendar
  let l:date = strftime("%Y-%m-%d")
  let l:tm = ""
  let l:linenr = 0 
  while l:linenr < line("$") 
    let l:linenr += 1
    let l:line = getline(l:linenr)
    let l:line = substitute(l:line, "\t", "", "g")
    if match(l:line,'\d\d\d\d-\d\d-\d\d') >= 0
      let l:dt = matchstr(l:line,'\d\d\d\d-\d\d-\d\d')
      if l:dt > l:date
        if match(l:line,' \d\d\.\d\d') >= 0
          let l:tm = matchstr(l:line,'\d\d\.\d\d')
          let l:tm = substitute(l:tm, '\.', ":", "")
          let l:tm = " " . l:tm
        endif
        if @% == ""
          let l:filename = ""
        else
          let l:filename = " <" . @% . ">)"
        endif
        let l:title = substitute(l:line, '.*\d\d\d\d-\d\d-\d\d\( \d\d.\d\d\)*: ', '', '')
        let l:start_line_number = l:linenr
        let l:end_line_number   = l:start_line_number + 1
        let l:start_line_indent = indent(l:start_line_number)
        let l:tabs = repeat("\t", l:start_line_indent/&tabstop)
        while indent(l:end_line_number) > l:start_line_indent
          let l:end_line_number += 1
        endwhile
        let l:start    = l:start_line_number
        let l:end      = l:end_line_number - 1
        let l:dlist    = getline(l:start,l:end)
        let l:g_desc   = ""
        for i in l:dlist
          let l:g_desc = l:g_desc . substitute(i, l:tabs, '', '') . "\n"
        endfor
        let l:g_cal    = " --calendar '" . l:cal . "'"
        let l:g_title  = " --title '" . l:title
        if @% == ""
          let l:filename = ""
        else
          let l:filename = " <" . @% . ">"
        endif
        let l:created  = " (created by HyperList.vim" . l:filename . ")' "
        let l:g_when   = " --when '" . l:dt . l:tm . "'"
        let l:g_desc   = " --description '" . l:g_desc . "'"
        let l:gcalcli  = "gcalcli add --where '' --duration 30 --reminder 0" . l:g_cal . l:g_title . l:created . l:g_when . l:g_desc
        call system(l:gcalcli)
        let l:count += 1
      endif
    endif
  endwhile
  if l:count == 0
    let l:msg = "No events added"
  elseif l:count == 1
    let l:msg = "Added 1 event"
  else
    let l:msg = "Added " . l:count . " events"
  endif
  echo l:msg
endfunction

"  Complexity{{{2
"  :call Complexity() will show the complexity score for your HyperList (mapped to <leader>C)
"  It adds up all HyperList Items and all references to the total score
function! Complexity()
	let l = 0
	let c = 0
	try
		redir => l
			silent exe '%s/\S//n'
		redir END
	catch
		let l = 0
	endtry
  let l = substitute(l, '\_.\{-}\(\d\+\)\_.*', '\1', "")
	try
		redir => c
			silent exe '%s/<\{1,2}[a-zA-ZæøåÆØÅáéóúãõâêôçàÁÉÓÚÃÕÂÊÔÇÀü0-9,.:/ _&@?%=+\-\*]\+>\{1,2}//gn'
		redir END
	catch
		let c = 0
	endtry
  let c = substitute(c, '\_.\{-}\(\d\+\)\_.*', '\1', "")
  let plex = c + l
  echo "Complexity = ". plex
  return plex
endfunction

" Syntax definitions {{{1
"  HyperList elements {{{2

" Identifier (any number in front)
syn match   HLident     '^\(\t\|\*\)*[0-9.]* '

" Multi-line
syn match   HLmulti     '^\(\t\|\*\)*+ '

" State & Transitions
syn match   HLstate	'\(\(^\|\s\|\*\)\(S: \|| \)\)\@<=.*' contains=HLtodo,HLop,HLcomment,HLref,HLqual,HLsc,HLmove,HLtag,HLquote
syn match   HLtrans	'\(\(^\|\s\|\*\)\(T: \|/ \)\)\@<=.*' contains=HLtodo,HLop,HLcomment,HLref,HLqual,HLsc,HLmove,HLtag,HLquote

" Qualifiers are enclosed within [ ]
syn match   HLqual      '\[.\{-}\]' contains=HLtodo,HLref,HLcomment

" Properties (formerly known as Tags) - anything that ends in a colon that is
" not only uppercase letters (which would make it an Operator)
syn match   HLtag	'\(^\|\s\|\*\)\@<=[a-zA-ZæøåÆØÅáéóúãõâêôçàÁÉÓÚÃÕÂÊÔÇÀü0-9,._&?!%= \-\/+<>#'"()\*:]\{-2,}:\s' contains=HLtodo,HLcomment,HLquote,HLref

" HyperList operators
syn match   HLop	'\(^\|\s\|\*\)\@<=[A-ZÆØÅÁÉÓÚÃÕÂÊÔÇÀ_\-()]\{-2,}:\s' contains=HLcomment,HLquote

" Mark semicolon as stringing together lines
syn match   HLsc	';'

" Hashtags (like Twitter)
syn match   HLhash	'#[a-zA-ZæøåÆØÅáéóúãõâêôçàÁÉÓÚÃÕÂÊÔÇÀü0-9.:/_&?%=+\-\*]\+'

" References
syn match   HLref	'<\{1,2}[a-zA-ZæøåÆØÅáéóúãõâêôçàÁÉÓÚÃÕÂÊÔÇÀü0-9,.:/ _~&@?%=\+\-\*]\+>\{1,2}' contains=HLcomment

" Reserved key words
syn keyword HLkey     END SKIP

" Marking literal start and end (a whole literal region is folded as one block)
syn match   HLlit       '\(\s\|\*\)\@<=\\$'

" Content of litaral (with no syntax highlighting)
syn match   HLlc        '\(\s\|\*\)\\\_.\{-}\(\s\|\*\)\\' contains=HLlit

" Comments are enclosed within ( )
syn match   HLcomment   '(.\{-})' contains=HLtodo,HLref,HLhash

" Text in quotation marks
syn match   HLquote     '".\{-}"' contains=HLtodo,HLref,HLhash

" TODO  or FIXME
syn keyword HLtodo    TODO FIXME 

" Item motion (uncomment if you want this syntax feature)
"syn match   HLmove      '>>\|<<\|->\|<-'

" Bold and Italic
syn match   HLb	        '\(\t\| \)\@<=\*.\{-}\*\($\| \)\@='
syn match   HLi	        '\(\t\| \)\@<=/.\{-}/\($\| \)\@='
syn match   HLu	        '\(\t\| \)\@<=_.\{-}_\($\| \)\@='

" Cluster the above
syn cluster HLtxt contains=HLident,HLmulti,HLop,HLqual,HLtag,HLhash,HLref,HLkey,HLlit,HLlc,HLcomment,HLquote,HLsc,HLtodo,HLmove,HLb,HLi,HLu,HLstate,HLtrans,HLdim0,HLdim1

"  HyperList indentation (folding levels) {{{2
if !exists("g:disable_collapse")
syn region L15 start="^\(\t\|\*\)\{14} \=\S" end="^\(^\(\t\|\*\)\{15,} \=\S\)\@!" fold contains=@HLtxt
syn region L14 start="^\(\t\|\*\)\{13} \=\S" end="^\(^\(\t\|\*\)\{14,} \=\S\)\@!" fold contains=@HLtxt,L15
syn region L13 start="^\(\t\|\*\)\{12} \=\S" end="^\(^\(\t\|\*\)\{13,} \=\S\)\@!" fold contains=@HLtxt,L14,L15
syn region L12 start="^\(\t\|\*\)\{11} \=\S" end="^\(^\(\t\|\*\)\{12,} \=\S\)\@!" fold contains=@HLtxt,L13,L14,L15
syn region L11 start="^\(\t\|\*\)\{10} \=\S" end="^\(^\(\t\|\*\)\{11,} \=\S\)\@!" fold contains=@HLtxt,L12,L13,L14,L15
syn region L10 start="^\(\t\|\*\)\{9} \=\S"  end="^\(^\(\t\|\*\)\{10,} \=\S\)\@!" fold contains=@HLtxt,L11,L12,L13,L14,L15
syn region L9 start="^\(\t\|\*\)\{8} \=\S"   end="^\(^\(\t\|\*\)\{9,} \=\S\)\@!"  fold contains=@HLtxt,L10,L11,L12,L13,L14,L15
syn region L8 start="^\(\t\|\*\)\{7} \=\S"   end="^\(^\(\t\|\*\)\{8,} \=\S\)\@!"  fold contains=@HLtxt,L9,L10,L11,L12,L13,L14,L15
syn region L7 start="^\(\t\|\*\)\{6} \=\S"   end="^\(^\(\t\|\*\)\{7,} \=\S\)\@!"  fold contains=@HLtxt,L8,L9,L10,L11,L12,L13,L14,L15
syn region L6 start="^\(\t\|\*\)\{5} \=\S"   end="^\(^\(\t\|\*\)\{6,} \=\S\)\@!"  fold contains=@HLtxt,L7,L8,L9,L10,L11,L12,L13,L14,L15
syn region L5 start="^\(\t\|\*\)\{4} \=\S"   end="^\(^\(\t\|\*\)\{5,} \=\S\)\@!"  fold contains=@HLtxt,L6,L7,L8,L9,L10,L11,L12,L13,L14,L15
syn region L4 start="^\(\t\|\*\)\{3} \=\S"   end="^\(^\(\t\|\*\)\{4,} \=\S\)\@!"  fold contains=@HLtxt,L5,L6,L7,L8,L9,L10,L11,L12,L13,L14,L15
syn region L3 start="^\(\t\|\*\)\{2} \=\S"   end="^\(^\(\t\|\*\)\{3,} \=\S\)\@!"  fold contains=@HLtxt,L4,L5,L6,L7,L8,L9,L10,L11,L12,L13,L14,L15
syn region L2 start="^\(\t\|\*\)\{1} \=\S"   end="^\(^\(\t\|\*\)\{2,} \=\S\)\@!"  fold contains=@HLtxt,L3,L4,L5,L6,L7,L8,L9,L10,L11,L12,L13,L14,L15
syn region L1 start="^\(\t\|\*\)\{0} \=\S"   end="^\(^\(\t\|\*\)\{1,} \=\S\)\@!"  fold contains=@HLtxt,L2,L3,L4,L5,L6,L7,L8,L9,L10,L11,L12,L13,L14,L15
endif

"  VIM parameters (VIM modeline) {{{2
syn match   HLvim "^vim:.*"

" Highlighting and Linking {{{1
hi	        Folded	  ctermfg=none ctermbg=none cterm=bold term=bold guifg=NONE guibg=NONE gui=bold
hi          HLdim0    ctermfg=241     guifg=Grey
hi          HLdim1    ctermfg=241     guifg=Grey
hi          HLident	  ctermfg=Magenta guifg=Magenta
hi          HLmulti	  ctermfg=Red     guifg=Red
hi          HLtag	    ctermfg=Red     guifg=Red
hi          HLop	    ctermfg=Blue    guifg=Blue
hi          HLqual	  ctermfg=Green   guifg=LimeGreen
hi          HLhash	  ctermfg=184     guifg=#aaa122
hi          HLref	    ctermfg=Magenta guifg=Magenta
hi          HLkey	    ctermfg=Magenta guifg=Magenta
hi          HLcomment	ctermfg=Cyan    guifg=Cyan
hi          HLquote	  ctermfg=Cyan    guifg=Cyan
hi          HLlit     ctermfg=none ctermbg=none cterm=italic term=italic guifg=NONE guibg=NONE gui=italic
hi          HLlc      ctermfg=none ctermbg=none
hi	        HLb	      ctermfg=none ctermbg=none cterm=bold   term=bold   guifg=NONE guibg=NONE gui=bold
hi	        HLi	      ctermfg=none ctermbg=none cterm=italic term=italic guifg=NONE guibg=NONE gui=italic
hi link	    HLu	      underlined
hi def link HLsc	    Type
hi def link HLtodo	  Todo
hi def link HLmove	  Error
hi def link HLvim     Function

" Keymap {{{1

if exists('g:HLDisableMapping') && g:HLDisableMapping
    finish
endif

map <leader>0         :set foldlevel=0<CR>
map <leader>1         :set foldlevel=1<CR>
map <leader>2         :set foldlevel=2<CR>
map <leader>3         :set foldlevel=3<CR>
map <leader>4         :set foldlevel=4<CR>
map <leader>5         :set foldlevel=5<CR>
map <leader>6         :set foldlevel=6<CR>
map <leader>7         :set foldlevel=7<CR>
map <leader>8         :set foldlevel=8<CR>
map <leader>9         :set foldlevel=9<CR>
map <leader>a         :set foldlevel=10<CR>
map <leader>b         :set foldlevel=11<CR>
map <leader>c         :set foldlevel=12<CR>
map <leader>d         :set foldlevel=13<CR>
map <leader>e         :set foldlevel=14<CR>
map <leader>f         :set foldlevel=15<CR>
map <SPACE>           za
nmap zx               i<esc>

map <leader>u         :call STunderline()<CR>

map <leader>v	        :call CheckItem("")<CR>
map <leader>V         :call CheckItem("stamped")<CR>

map <leader><SPACE>   /=\s*$<CR>A

nmap gr		            :call GotoRef()<CR>
nmap <CR>	            :call GotoRef()<CR>

nmap gf               :call OpenFile()<CR>

nmap g<DOWN>          <DOWN><leader>0zv
nmap g<UP>            <leader>f<UP><leader>0zv

nmap <leader><DOWN>   <DOWN><leader>0zv<SPACE>zO
nmap <leader><UP>     <leader>f<UP><leader>0zv<SPACE>zO

nmap <leader>z        :call HLdecrypt()<CR>V:!openssl bf -pbkdf2 -e -a -salt 2>/dev/null<CR><C-L>
vmap <leader>z        :call HLdecrypt()<CR>gv:!openssl bf -pbkdf2 -e -a -salt 2>/dev/null<CR><C-L>
nmap <leader>Z        :call HLdecrypt()<CR>:%!openssl bf -pbkdf2 -e -a -salt 2>/dev/null<CR><C-L>
nmap <leader>x        :call HLdecrypt()<CR>V:!openssl bf -pbkdf2 -d -a 2>/dev/null<CR><C-L>
vmap <leader>x        :call HLdecrypt()<CR>gv:!openssl bf -pbkdf2 -d -a 2>/dev/null<CR><C-L>
nmap <leader>X        :call HLdecrypt()<CR>:%!openssl bf -pbkdf2 -d -a 2>/dev/null<CR><C-L>

nmap <leader>H        :call HTMLconversion()<CR>
nmap <leader>L        :call LaTeXconversion()<CR>
nmap <leader>T        :call TPPconversion()<CR>

nmap <leader>h        :call HighLight()<CR>
nmap <leader>an       :call ToggleAutonum()<CR>
nmap <leader>#        :call ToggleAutonum()<CR>
vmap <leader>R        :call Renumber()<CR>

map  <silent> zs      :call <SID>ShowHideWord('z', 's', '')<CR>
map  <silent> zh      :call <SID>ShowHideWord('z', 'h', '')<CR>
map  <silent> z0      :set foldmethod=syntax<CR><bar>:echo "ShowHide Remove"<CR>

nmap <leader>G        :call CalendarAdd()<CR>

nmap <leader>C        :call Complexity()<CR>

" Sort hack (sort the visual selected lines by the top item's indentation
" The last item in the visual selection cannot be the last line in the document.
vmap <leader>s <esc>`<^"iy0gv:s/^<c-r>i\S\@=/<c-v><c-a>/<cr>gv:s/\t/<c-v><c-b>/g<cr>gv:s/\n<c-v><c-b>/<c-v><c-x>/<cr>gvk:!sort<cr>:%s/<c-v><c-a>/<c-r>i/<cr>:%s/<c-v><c-x>/\r<c-v><c-b>/g<cr>:%s/<c-v><c-b>/\t/g<cr>

" GVIM menu {{{1
let s:HL_RootMenu  = 'HyperList.'
exe 'menu '.s:HL_RootMenu.'HyperList <Nop>'
exe 'menu '.s:HL_RootMenu.'-Sep00-  <Nop>'
menu HyperList.Toggle\ fold<Tab>SPACE              za
menu HyperList.Set\ fold\ level.0<Tab>\\0          :set foldlevel=0<CR>
menu HyperList.Set\ fold\ level.1<Tab>\\1          :set foldlevel=1<CR>
menu HyperList.Set\ fold\ level.2<Tab>\\2          :set foldlevel=2<CR>
menu HyperList.Set\ fold\ level.3<Tab>\\3          :set foldlevel=3<CR>
menu HyperList.Set\ fold\ level.4<Tab>\\4          :set foldlevel=4<CR>
menu HyperList.Set\ fold\ level.5<Tab>\\5          :set foldlevel=5<CR>
menu HyperList.Set\ fold\ level.6<Tab>\\6          :set foldlevel=6<CR>
menu HyperList.Set\ fold\ level.7<Tab>\\7          :set foldlevel=7<CR>
menu HyperList.Set\ fold\ level.8<Tab>\\8          :set foldlevel=8<CR>
menu HyperList.Set\ fold\ level.9<Tab>\\9          :set foldlevel=9<CR>
menu HyperList.Set\ fold\ level.10<Tab>\\a         :set foldlevel=10<CR>
menu HyperList.Set\ fold\ level.11<Tab>\\b         :set foldlevel=11<CR>
menu HyperList.Set\ fold\ level.12<Tab>\\c         :set foldlevel=12<CR>
menu HyperList.Set\ fold\ level.13<Tab>\\d         :set foldlevel=13<CR>
menu HyperList.Set\ fold\ level.14<Tab>\\e         :set foldlevel=14<CR>
menu HyperList.Set\ fold\ level.15<Tab>\\f         :set foldlevel=15<CR>
menu HyperList.Toggle\ State/Transition<Tab>\\u    :call STunderline()<CR>
menu HyperList.Checklist.Toggle<Tab>\\v            :call CheckItem("")<CR>
menu HyperList.Checklist.Timestamp<Tab>\\V         :call CheckItem("stamped")<CR>
menu HyperList.Goto\ reference<Tab>gr              :call GotoRef()<CR>
menu HyperList.Open\ file\ under\ cursor<Tab>gf    :call OpenFile()<CR>
menu HyperList.Show/Hide.Show\ Word\ under\ Cursor<Tab>zs :call <SID>ShowHideWord('z', 's', '')<CR>
menu HyperList.Show/Hide.Hide\ Word\ under\ Cursor<Tab>zh :call <SID>ShowHideWord('z', 'h', '')<CR>
menu HyperList.Show/Hide.Remove\ Show/Hide<Tab>z0  :set foldmethod=syntax<CR><bar>:echo "ShowHide Remove"<CR>
menu HyperList.Autonumber.Toggle<Tab>\\an          :call ToggleAutonum()<CR>
vmenu HyperList.Autonumber.Renumber\ visual\ selection<Tab>\\R :call Renumber()<CR>
menu HyperList.Next\ Template\ Item<Tab>\\SPACE    /=\s*$<CR>A<CR>
menu HyperList.Highlight\ Toggle<Tab>\\h           :call HighLight()<CR>
menu HyperList.Presentation\ Move\ Down<Tab>gDOWN  <DOWN><leader>0zv
menu HyperList.Presentation\ Move\ Up<Tab>gUP      <leader>f<UP><leader>0zv
menu HyperList.Encryption\ (Requires\ OpenSSL).Encrypt<Tab>\\z :call HLdecrypt()<CR>V:!openssl bf -pbkdf2 -e -a -salt 2>/dev/null<CR><C-L>
vmenu HyperList.Encryption\ (Requires\ OpenSSL).Encrypt\ Visual\ Selection<Tab>\\z :call HLdecrypt()<CR>gv:!openssl bf -pbkdf2 -e -a -salt 2>/dev/null<CR><C-L>
menu HyperList.Encryption\ (Requires\ OpenSSL).Encrypt\ All<Tab>\\Z :call HLdecrypt()<CR>:%!openssl bf -pbkdf2 -e -a -salt 2>/dev/null<CR><C-L>
menu HyperList.Encryption\ (Requires\ OpenSSL).Decrypt<Tab>\\x :call HLdecrypt()<CR>V:!openssl bf -pbkdf2 -d -a 2>/dev/null<CR><C-L>
vmenu HyperList.Encryption\ (Requires\ OpenSSL).Decrypt\ Visual\ Selection<Tab>\\x :call HLdecrypt()<CR>gv:!openssl bf -pbkdf2 -d -a 2>/dev/null<CR><C-L>
menu HyperList.Encryption\ (Requires\ OpenSSL).Decrypt\ All<Tab>\\X :call HLdecrypt()<CR>:%!openssl bf -pbkdf2 -d -a 2>/dev/null<CR><C-L>
menu HyperList.Conversion.HTML<Tab>\\H             :call HTMLconversion()<CR>
menu HyperList.Conversion.LaTeX<Tab>\\L            :call LaTeXconversion()<CR>
menu HyperList.Conversion.TPP<Tab>\\T              :call TPPconversion()<CR>
menu HyperList.Add\ Calendar\ Events\ (Requires\ gcalcli)<Tab>\\G :call CalendarAdd()<CR>
menu HyperList.Show\ Complexity\ of\ List<Tab>:call\ Complexity() :call Complexity()<CR>

" vim modeline {{{1
" vim: set sw=2 sts=2 et fdm=marker fillchars=fold\:\ :
doc/hyperlist.txt	[[[1
1445
*hyperlist.txt*   The VIM plugin for HyperList (version 2.4.1, 2019-10-06)

HyperList is a way to describe anything - any state, item(s), pattern, action,
process, transition, program, instruction set etc. So, you can use it as an
outliner, a ToDo list handler, a process design tool, a data modeler, or any
other way you want to describe something.

This VIM plugin makes it easy to work with HyperLists. It has a vast range of
features - from (un)collapsing whole or parts of lists, autonumbering of items,
checkbox toggling, jumping to referenced items... to encryption, presentation 
modes, export to various formats, automatically transferring of items tagged
with future events to a Google calendar... and many more sexy features.

The VIM plugin version numbers correspond to the HyperList definition version
numbers with the VIM plugin adding another increment of versioning, e.g VIM
plugin version 2.4.1 would be compatible with HyperList definition version 2.4.

This documentation contains the full HyperList definition. For a more
comprehensive manual that also includes plenty of examples, read the official
definition document:

	http://isene.org/hyperlist/

Here you will also find HyperGraph - a Ruby script to graph both State
HyperLists (like mindmaps) and Transitions Hyperlists (like flowcharts).

HyperList was formerly known as WOIM. The ftdetect file contains the file
suffix ".woim" for backward compatability so that these file types are also
treated as HyperList files.

==============================================================================
CONTENTS                                                  *HyperList-Contents*

    1 HyperList VIM Plugin....................|HyperList-Plugin|
    2 Background and definition...............|HyperList-Background|
		3 HyperLists..............................|HyperLists|
		4 HyperList Items.........................|HyperList-Item|
		4.1 Starter...............................|HyperList-Starter|
		4.2 Type..................................|HyperList-Type|
		4.3 Content...............................|HyperList-Content|
		4.3.1 Elements............................|HyperList-Elements|
		4.3.1.1 Operator..........................|HyperList-Operator|
		4.3.1.2 Qualifier.........................|HyperList-Qualifier|
		4.3.1.2 Property..........................|HyperList-Property|
		4.3.1.4 Description.......................|HyperList-Description|
		4.3.2 Additives...........................|HyperList-Additives|
		4.3.2.1 References........................|HyperList-References|
		4.3.2.2 Tags..............................|HyperList-Tags|
		4.3.2.3 Comments..........................|HyperList-Comments|
		4.3.2.4 Quotes............................|HyperList-Quotes|
		4.3.2.5 Change Markup.....................|HyperList-ChangeMarkup|
		4.4 Separator.............................|HyperList-Separator|
		5 A self-defining system..................|HyperList-Self-definition|
    6 About...................................|HyperList-About|
    7 Changelog...............................|HyperList-Changelog|
    8 Credits.................................|HyperList-Credits|
    9 License.................................|HyperList-License|

==============================================================================
1 HyperList VIM Plugin                                      *HyperList-Plugin*

One of the most feature rich VIM plugins ever created.

This plugin does both highlighting and various automatic handling of
HyperLists, like collapsing lists or parts of lists in a sophisticated way. 
It includes encryption functionality.

The HyperList plugin for VIM consists of the main file put in the "syntax"
subdirectory.  It also includes a file in the "ftdetect" directory so that
files with a ".hl" extension is automatically detected and treated as a
HyperList file.

For a complete tutorial, go through the file HyperListTutorialAndTestSuite.hl
in the documentation folder (~/.vim/doc/HyperListTutorialAndTestSuite.hl).
This file also serves as a complete test suite for releases of this plugin.


WHEN WORKING WITH HYPERLISTS IN VIM:

Use tabs/shifts or * for indentations.

Use <SPACE> to toggle one fold.
Use \0 to \9, \a, \b, \c, \d, \e, \f to show up to 15 levels expanded.

<leader># or <leader>an toggles autonumbering of new items (the previous
item must be numbered for the next item to be autonumbered). An item is
indented to the right with <c-t>, adding one level of numbering. An item
is indented to the left with <c-d>, removing one level of numbering and
increasing the number by one.

To number or renumber a set of items, select them visually (using V in VIM)
and press <leader>R. If the items are not previously numbered, they will now
be numbered from 1 and onward. Only items with the same indentation as the
first selected line will be numbered. If the first item is already numbered
(such as 1.2.6), the remaining items within the selection (with the same
indentation) will be numbered accordingly (such as 1.2.7, 1.2.8, etc.).

Use <leader>u to toggle underlining of States (prefixed with "S: " or "| "),
Transitions (prefixed with "T: " or "/ ") or underline nothing.

Use <leader>v to add a checkbox at start of item or to toggle a checkbox
Use <leader>V to add/toggle a checkbox with a date stamp for completion

Use "gr" (without the quotation marks, signifies "Goto Ref") or simply press
the "Enter" ("<CR>") key while the cursor is on a HyperList reference to jump
to that destination in a HyperList. Use "n" after a "gr" to verify that the
reference destination is unique. A reference can be to an Item in the list or 
to a file by the use of <file:/pathto/filename>, <file:~/filename> or 
<file:filename>. It can also be a relative reference like <-5> which would
mean "jump five lines up" or <+2> ("jump two lines down").

Use "gf" to open the file under the cursor. Graphic files are opened in
"feh", pdf files in "zathura" and MS/OOO docs in "LibreOffice". Other
filetypes are opened in VIM for editing. All this can be changed by
editing the function OpenFile() in the file "hyperlist.vim".

Whenever you jump to a reference in this way, the mark "'" is set at the
point you jumped from so that you may easily jump back by hitting "''"
(single quoutes twice). 

Use <leader><SPACE> to go to the next open template element
(A template element is a HyperList item ending in an equal sign).

As a sort of "presentation mode", you can traverse a HyperList by using
g<DOWN> or g<UP> to view only the current line and its ancestors.
An alternative is <leader><DOWN> and <leader><UP> to open more levels down.

To highlight the current part of a HyperList (the current item and all its
children), press <leader>h. This will uncollapse the whole HyperList and dim
the whole HyperList except the current item and its children. To remove the
highlighting, simply press <leader>h again (the fold level is restored).

Use <leader>L to convert the entire document to LaTaX.

The LaTeX conversion includes color coding of the various elements similar to
the colors used for HyperList files within VIM.

Use <leader>H to convert the entire document to HTML.

The HTML conversion includes color coding of the various elements similar to
the colors used for HyperList files within VIM.

Use <leader>T to convert the entire document to a basic TPP presentation file.

Top level of the HyperList will become the presentation header. First indented
level will become headers on a new page. Other indented levels will be
preserved.  No HyperList coloring will be done. Bold, italics and underlined
parts of the HyperList will be preserved.

See https://github.com/cbbrowne/tpp for information on TPP (Text Presentation Program)

Use <leader>z to encrypt the current line (including all sublevels if folded).
Use <leader>Z to encrypt the current file (all lines).
Use <leader>x to decrypt the current line (mark all subsequent encrypted lines).
Use <leader>X to decrypt the current file (all lines).

If you enter the wrong password while trying to decrypt, you will end up with
garbage characters. To fix it, press "u" (undo) and try decrypting again with
the correct password.

If you want a HyperList to be automatically encrypted upon saving and decrypted
upon opening it, just prefix the filename with a dot (like ".password.hl"). It
then turns off viminfo and swapfiles to ensure security.

When using encryption in a HyperList or for the whole file, you will be asked
for a password - twice when saving the file and once when opening it. You must
have OpenSSL in your path to take advantage of these features.

When running gVIM under Windows, encryption will spawn a DOS window where you
enter the password for encryption/decryption. This window may be hidden under
other windows.

Syntax updated at start and every time you leave Insert mode, or you can press
"zx" to update the syntax. 

You may speed up larger HyperListS by setting the the global variable
"disable_collapse" - add the following to your .vimrc:

  let "g:disable_collapse" = 1

If you want to disable or override these keymaps with your own, simply add
to your .vimrc file:

  let "g:HLDisableMapping" = 1

To use HyperLists within other file types (other than ".hl"), you can use
"nested syntax" by adding the following to those syntax files (like the syntax
file for text files (".txt"):

  syn include @HL ~/.vim/syntax/hyperlist.vim
  syn region HLSnip matchgroup=Snip start="HLstart" end="HLend" contains=@HL
  hi link Snip SpecialComment

If you add those three lines in your .vim/syntax/txt.vim you will be able to
include HyperLists in files with a ".txt", and the following example would
become a HyperList with correct syntax highlighting and folding:

HLstart
This is a HyperList test list
	Here is a child to the above item
		Here is "grand child"
	Here we are one level back
		And here's another level down
		[5] Dance steps
		[3] Hurray
		Smile
HLend

The "HLstart" and "HLend" must be at the start of the line.

You can show/hide words or regex patterns by using these keys and commands:

	zs    Show all lines containing word under cursor
	zh    Hide all lines containing word under cursor
	z0    Go back to normal HyperList folding
	:SHOW word/pattern
			Show lines containing either word or pattern
	:HIDE word/pattern
			Hide lines containing either word or pattern
			Pattern can be any regular expression

This functionality is useful for easily showing e.g. a specific tag or hash. 
The functionality is taken from VIM script #1594 (thanks to Amit Sethi).

To sort a set of items at a specific indentation, visually select (V) the
items you want to sort (including all the children of those items) and press
<leader>s and the items in the range will be alphabetically sorted - but only
the items on the same level/indentation as the first item selected. The sorted
items will keep their children. This is useful if parts of a HyperList is 
numbered and you get the numbering out of sequence and wants to resort them.
One caveat, the last line in the selection cannot be the very last line in
the document (there must be an item or an empty line below it).

By doing :call CalendarAdd() all items containing a future date will be added
as reminders to your Google Calendar. If an item includes a time, the event is
added from that time with duration of 30 minutes.

This function requires gcalcli (https://github.com/insanum/gcalcli)

The function is mapped to <leader>G to add events to the default calendar. The
default calendar is defined as b:calendar at the start of the HyperList.vim
script. To add the events to another calendar, do :call CalendarAdd("yourcalendar")
The title of the calendar is the item in the HyperList without the date/time tag.
If there is no time tag for the item, an event is created at the start of the date.
If there is a time tag for the item, the event is created at that time with the
default duration (30 minutes). The description for the event is the item and all
its child items.

If you want to know the overall complexity of a HyperList, use <leader>C
The score shown is the total of Items and References in your HyperList.

GVIM users can enjoy a menu with most of the commands organized in submenus.

==============================================================================
2 Background and definition                             *HyperList-Background*

Having worked extensively with flowcharts, relations diagrams, Warnier-Orr
diagrams and other ways of representing processes, states, instructions,
programs and data models, I knew there was something missing. It would have
been great to have a way of representing anything -- any state or action -- in
a way that would be more conducive to collaboration.

Most people know about flowcharts. But there are other ways of representing
data, states, actions or processes: UML, Sankey diagrams, Decision trees, Petri
Net, Organizational charts, Mind maps, Process Flow diagrams, Feynman diagrams,
Data Flow diagrams, Concept maps, OBASHI, Task lists (or Todo lists),
Warnier/Orr diagrams and various other diagrams. More than we can list here.
They have various uses, various strengths and shortcomings.

Most methodologies for representing states or flows were born out of specific
needs and were not meant to be used as generic methods for representing
literally anything as simple as possible. What if there were a way to represent
any state, set of things, actions, flows or transitions? What if the method
were simple? What if it were also Turing complete?

Enter HyperList -- a system for representing data. Any data. Static or dynamic.
It can be used to describe any state: a thing or set of things, an area, a
concept or collection of concepts, etc. It can also be used to describe any
action or plan, transformation or transition. In fact, it can describe anything
-- with one complete markup set. HyperList can be be used as an outliner on
steroids or a todo-list managing system with unlimited possibilities.

After searching for a complete markup methodology for both states or things and
actions or transitions, I came across the Warnier/Orr diagrams. They seemed to
be the best foundation for what I needed. The methodology was expanded to be
capable of describing anything as easily as possible; I removed the graphical
parts of Warnier/Orr and expanded the system substantially. It turned into WOIM
(Warnier/Orr/Isene/Möller) and later got the more descriptive name of
HyperList. Egil Möller (http://redhog.org/) helped in the early refinements.

Besides being the name of the system, "HyperList" is also used when referring
to a list or lists conforming to this system.

The strengths of HyperList are many:

 * can represent any state or action with any number of levels
 * Turing complete
 * text-based 
   (it is wiki-able -- i.e. it is easy to collaborate when creating HyperList)
 * not graphical 
   (although it can easily be made graphical for ease of consumption or eye candy)
 * an easy syntax, humanly very readable
 * very compact
 * can represent negatives ("NOT:" = "don't do the following actions")
 * can represent any number of choices in a decision (hard to do in a flowchart)
 * easy to do loop counts
 * easy to show attributes such as time or timing, location, person responsible, etc.
 * potentially easy to map to other representation methods (graphical or otherwise)

In its simplest form, a HyperList is just a list of Items -- like your regular
shopping list -- but it can be so much more if you need it to be. A couple of
examples will give you the basic idea.

An example of describing a state:

	Car (example obviously not complete)
		Exterior
			Paint
			Chrome decor
			Windows
				Rubber linings
			[4] Wheels
		Interior
			Seats
				[2] Front
				[3] Back
		Mechanics
			Motor
				[6] Cylinders
				[24] Valves
			Brakes

A transition example (task list):

	Walk the dog
		Check the weather
			[?rain] AND/OR:
				Get rain coat
				Get umbrella
			Dress for the temperature
		Get chain
		Call the dog
		OR:
			Go through the woods
			Walk the usual track
		AND: (concurrency)
			Ensure the dog has done its "tasks"
			Ensure the dog is exercised
			  [5+] throw the favorite stick
		Walk home

And this can all be done in collaboration on a wiki. States are described,
processes are mapped, plans and todo lists are forged. It's rather easy, and
HyperList can accommodate any level of complexity.

------------------------------------------------------------------------------
3 HyperLists                                                      *HyperLists*

A HyperList consists of one or more HyperList Items.

------------------------------------------------------------------------------
4 HyperList Item                                              *HyperList-Item*

A HyperList Item is a line in a HyperList. It can have "children". Children are
HyperList Items indented to the right below the Item.

A HyperList Item consists of an optional "Starter", an optional "Type",
"Content" and a "Separator" in that sequence. All the various parts of a
HyperList Item are described below and in the sequence they appear in an Item,
as outlined here:

	4.1 Starter   
	4.2 Type
	4.3 Content
		4.3.1 Element 
			4.3.1.1 Operator
			4.3.1.2 Qualifier
			4.3.1.3 Property
			4.3.1.4 Description 
		4.3.2 Additive
			4.3.2.1 Reference
			4.3.2.2 Tag 
			4.3.2.3 Comment  
			4.3.2.4 Quote
			4.3.2.5 Change Markup
	4.4 Separator

Look familiar? Yes, it is part of the table of contents at the beginning of
this documentation -- even that is a valid HyperList. 

------------------------------------------------------------------------------
4.1 Starter                                                *HyperList-Starter*

A HyperList Item may begin with a "Starter". A "Starter" can be either an
"Identifier" or a "Multi-line Indicator".

An Identifier is a unique indicator that can be used in referring to that Item.
A numbering scheme such as X.Y.Z can be used, e.g. the first Item in a
HyperList would be 1. The second Item would be 2, etc. A child to the second
Item would be 2.1 and the second child of 2 would be identified as 2.2, whereas
the child of 2.2 would be 2.2.1.

A shorter form consisting of mixing numbers and letters can also be used, such
as 1A1A for the first fourth-level Item. The next fourth-level Item would be
1A1B. When using this scheme, there is no need for any periods. The Identifier
"21T2AD" would be equivalent to "21.20.2.30", saving 4 characters.

An Item that spans more than one line must have a Starter. It does not have to
be an Identifier. You may use a "Multi-line Indicator" instead; just prefix the
Item with a plus sign ("+"), to show that it spans more than one line.    The
second line of an Item will be indented to the same level/indent as the first
with an added space in front.    If you use a Starter on one Item, then all the
Items in that same group of Items on the same level/indent must also have a
Starter.

In the example below, the first child begins with an Identifier and the second
a Multi-line Indicator. A Multi-line Indicator can also be used for single-line
Items when other Items on the same level span more than one line and thus
require a Multi-line Indicator.

	Multi-line Indicator = "+"
		1. Following lines are of the same indent with a "space" before
		 the text
		+ If one Item on a certain level/indent is multi-line, all Items
		 on the same level/indent must start with a plus sign ("+") or <Identifier> 

The angle brackets near the end will be discussed later in this article.

------------------------------------------------------------------------------
4.2 Type                                                      *HyperList-Type*

If it is not obvious or for clarity or strictness, prefix an Item with "S:" if
the Item is a static or a state Item (i.e. something which does not denote
action). Use "T:" for a transition Item (an Item indicating action).
Alternately, you may use "|" instead of "S:", and "/" instead of "T:". The Type
indicator comes after the optional Starter.

Children of a certain Type (either state or transition) inherit their parent's
Type unless otherwise specified.

------------------------------------------------------------------------------
4.3 Content                                                *HyperList-Content*

A HyperList Item must have some sort of Content. The Content can be an
"Element" and/or an "Additive".

------------------------------------------------------------------------------
4.3.1 Elements                                            *HyperList-Elements*

An Element is either an "Operator", a "Qualifier", a "Property" or a
"Description". Let's treat each of these concepts.

------------------------------------------------------------------------------
4.3.1.1 Operator                                          *HyperList-Operator*

An Operator is anything that operates on an Item or a set of Items. It can be
any of the usual logical operators. It can also be other Operators, such as
"EXAMPLE: ", "EXAMPLES: ", "CHOOSE: ", "ONE OF THESE: ", "IMPLIES: ",
"CONTINUOUS: ", etc. The Operator "CONTINUOUS: " makes an Item or set of Items
run continuously. An Operator is written in capital letters and ends in a colon
and a space.

The Operator "ENCRYPTION: " indicates that the sub-Item(s) are to be encrypted
or that the following block is encrypted. The encrypted block can be properly
indented in the HyperList, or if indentation is part of the encrypted block, it
will be left justified. This is the only Item that is allowed to break the
indentation rules. 

If you need to include one or more lines inside a HyperList that include
HyperList expressions you don't want to be interpreted as HyperList
expressions, then use a "literal block". This is equivalent to "pre-formatted"
text in HTML and some word processors. To include such a block of lines, simply
mark the start and end of the literal block with a single backslash ("\") on a
line. Example:

   \
   This is a block of literal text...
   Where nothing counts as HyperList markup
   Thus - neither this: [?] nor THIS: <Test> - are seen as markup
   ...until we end this block with...
   \

Literal blocks are useful when you want to include, for instance, a block of
programming code in the middle of a HyperList.

------------------------------------------------------------------------------
4.3.1.2 Qualifier                                        *HyperList-Qualifier*

A Qualifier does as its name suggests; it qualifies an Item. A Qualifier limits
the use of an Item. It tells you how many times, at what times and/or under
what conditions an Item is to be executed, exists or is valid. When an Item is
to be included only if several conditions are met, you put all the conditions
into square brackets and separate them by commas. If an Item is to be executed
first for one condition, then for another and then for a third, etc, you
separate them by periods. The usage is best described by a few examples:

* Do Item if "the mail has arrived" = "[The mail has arrived]"
* Do Item 3 times = "[3]"
* Do Item 1 or more times = "[1+]"
* Do Item 2 to 4 times = "[2..4]" (the user may choose 2, 3 or 4 times)
* Do Item 2 times while "foo=true" = "[2, foo=true]"
* Do Item from 3 to 5 times while "bar=false" = "[3..5, bar=false]"
* Do Item less than 4 times only while "zoo=0" = "[<4, zoo=0]"
* Do Item 1 or more times while "Bob is polite" = "[1+, Bob is polite]"
* Do Item a minimum 2 and a maximum 7 of times while it rains and temperature
  is less than 5 degrees Celsius = "[2..7, Raining, Temperature <5°C]"
* Do Item in the context of "apples", then "oranges", then "grapes" =
	"[Apples. Oranges. Grapes]". With this you can reuse a procedure in many
	contexts.

You can add a question mark before the qualifier statement to make it clearer
that it is an ``if'' statement. These are equivalent:

   [? Raining] Bring unbrella
	 
   [Raining] Bring unbrella

To indicate that an Item is optional, use "[?]". Example:

   Receive calls at reception
      Pick up the phone and greet the caller
      [Caller does not ask for any specific person]
         Ask who the caller wants to speak to
      [?] Ask the reason for wanting to talk to that person
      [Person available] Transfer call; END
      [Person not available] Ask if you can leave a message
         Take the message
         Send the message to the person

The special word "END" and the semicolon in the above example will be explained
later, under "Reference" and "Separator", respectively.

Use a "timestamp" to indicate that an Item is to be done at a certain time, in
a certain time span, before or after a certain time, etc.

A timestamp has the format "YYYY-MM-DD hhmmss", conforming to the standard
ISO-8601. The time/date format can be shortened to the appropriate time
granularity, such as "YYYY-MM-DD hhmm", "YYYY-MM-DD hh" or "YYYY". One can add
a timestamp Qualifier such as "[Time = 2012-12-24 17]" or simply "[2012-12-24 17]".

Timestamps that represent an amount of time may be relative, such as:

* Length of time to wait before doing the Item = "[+YYYY-MM-DD]"
* Less than a certain length of time after previous Item = "[<+YYYY-MM-DD]"
* More than a certain length of time after previous Item = "[>+YYYY-MM-DD]"
* Length of time to wait  before doing next Item = "[-YYYY-MM-DD]"
* Less than a certain length of time before next Item = "[<-YYYY-MM-DD]"
* More than a certain length of time before next Item = "[>-YYYY-MM-DD]"
* Length of time to wait after doing referenced Item = "[+YYYY-MM-DD<OtherItem>]"

The last example introduces a new concept, the "Reference". References will be
discussed below.

Other obvious timestamps may be used, such as:

* "[+1 week]"
* "[-2 Martian years]"

Some practical examples:

* Wait one month before doing the Item = "[+YYYY-01-DD]"
* Do Item less than 4 days before next Item = "[<-YYYY-MM-04]"
* Wait one year and two days after Item X = "[+0001-00-02<X>]"

It is also possible to have recurring Items in \hyperlist. The strict format is
"YYYY-MM-DD+X DAY hh.mm+Y - YYYY-MM-DD hh.mm". The first date marks the
starting date and the last date marks the end of the repetition interval. The
"+X" is the repetition (i.e. the number of days between each repetition) in
relation to the date, while the "+Y" is the repetition of the time (the amount
of time between each repetition). "DAY" represents the name of the day(s) in
the week where recurring Item occurs. You use what you need, i.e. if there is
no repetition within a day, obviously the "+Y" would be skipped.  
Some examples:

* "[2012-05-01+7 13.00]" = 2011-05-01 1pm, repeated every 7 days
* "[2012-05-01+2,3,2]" = Every 2, then 3, then 2 days, in repetition
* "[2012-05-01+2 - 2012-05-01]" = Every second day for one year
* "[2012-05-01 13.00+1]" = 2011-05-01 1pm, repeated every hour
* "[2012-05-01 Fri,Sat - 2011-10-01]" = Every Fri & Sat in the repetition interval

You can also use all possible intuitive variations by leaving certain parts of
the timestamp unspecified.

* "[YYYY-MM-03]" = Every third of every month
* "[YYYY-12-DD]" = Every day in every December
* "[2011-MM-05]" = The fifth of every month of 2011
* "[Tue,Fri 12.00]" = Noon every Tuesday and Friday

Here is a complex Qualifier example:

   [+YYYY-MM-DD 02.30, Button color = Red, 4, ?] Push button

The above statement reads "2 hours and 30 minutes after previous Item, if the
color of the button is red, then push the button 4 times, if you want to".

If you use HyperList as a todo-list manager or project management tool, there
is a nifty way of showing Items to be done and Items done; simply add "[_]" at
the beginning of the line for an "unchecked" Item and "[x]" for a "checked"
Item. An unchecked Item is to be done and is indicated by this "placeholder"
Qualifier, while a checked item indicates the Item is not to be done anymore.

You may add a timestamp for the completion after a checked Item ("[x]
YYYY-MM-DD hh.mm:"). In this way, you combine the Qualifier with a timestamp
Tag. The timestamp as a Tag does not limit when the Item is to be done. It
supplies information about when it was done.

------------------------------------------------------------------------------
4.3.1.2 Property                                          *HyperList-Property*

A Property is any attribute describing the Content. It ends in a colon and a
space.

Examples of Properties could be: "Location = Someplace:", "Color = Green:",
"Strength = Medium:" and "In Norway:". Anything that gives additional
information or description to the Content.

------------------------------------------------------------------------------
4.3.1.3 Description                                    *HyperList-Description*

The Description is the main body, the "meat" of the Item. Although an Item may
not have a Description, such as a line containing only the Operator "OR:", most
Items do have a Description. Many Items have only a Description, such as those
in a simple todo list.

------------------------------------------------------------------------------
4.3.2 Additive                                            *HyperList-Additive*

Additives can be used alone or in combination with Elements. An Additive can
either be a "Reference", a "Comment", a "Quote" or a "Change Markup".

------------------------------------------------------------------------------
4.3.2.1 Reference                                        *HyperList-Reference*

A reference is enclosed in angle brackets ("<>"). A reference can be the name
of an Item, another HyperList or anything else. An example would be a Reference
to a website, such as <http://www.isene.org/>, a file,
<file:/path/to/filename>, or another item <The referenced item's Description>.

There are two types of References:

 * A redirection or hard Reference
 * A soft Reference

An Item consisting only of a Reference is a redirection. For a transition Item
this means one would jump to the referenced Item and continue execution from
there. If the redirect is to jump back after executing the referenced Item (and
its children), then add another hash at the beginning, such as <<Reference>>.
This makes it easy to create more compact HyperList by adding a set of
frequently used subroutines at the end of the list. For a state Item, a
Reference means one would include the referenced Item (and its children) at the
Reference point.

There are two special redirections for transition Items:

 * An Item consisting only of the key word "SKIP" ends the current HyperList level
 * An Item consisting only of the key word "END" ends the whole HyperList

If the Reference is only part of an Item, it is a "soft Reference". It
indicates that one would look for more information at the referenced Item. An
even softer Reference would be to put the Reference in parentheses, such as
(<Reference>), indicating that the referenced Item is only something apropos.
Parentheses are used for Comments and will be discussed later.

A Reference can be to any place in the list, up or down, or to another list or
to a file, a web address or any other place that can be referred to with a
unique name used as the Reference. Although the Reference is valid as long as
it is unique and therefore unambiguous, you should note the following best
practice for a Reference: 

If you reference an Item higher up in the HyperList, a simple reference to the
Item is all that is needed. One would refer to the Identifier or to the
appropriate Content, usually the Description. Examples:

	The first Item
		A child Item
			A grandchild
				<A child Item>

It would make sense to use an Identifier for an Item if the Description is long
and you want to refer to that Item: 

	The first Item
		1 A child Item
			A grandchild
				<1>

If you refer to an Item further down the hierarchy, you would use a forward
slash ("/") to separate each level (like the "path" used in a URL):

	The first Item
		A child Item (<A grandchild/A baby>)
			A grandchild
				A baby

If you want to refer to an Item where you first need to "climb the tree" and
then go down another "branch", you start the path with the highest common level
and reference the path from there:

	The first Item
		A child Item
			A grandchild
	Another branch
		A leaf
			<The first Item/A child Item/A grandchild>

Or, if the referenced Item has a unique identifier, simply use that:

	The first Item
		A child Item
			1 A grandchild
	Another branch
		A leaf
			<1>

You may use a unique concatenation of a path to shorten it, such as 
<Somewhere higher up/One lev.../Ref...>. The three periods indicate
concatenation.

------------------------------------------------------------------------------
4.3.2.2 Tag                                                    *HyperList-Tag*

A Tag is a "marker" for an item. It tags an item and is used just like hashtags
in Twitter. Examples: #TODO #RememberThis #First #SandraLyng. No spaces are
allowed in a tag.

------------------------------------------------------------------------------
4.3.2.2 Comment                                            *HyperList-Comment*

Anything within parentheses is a Comment. Comments are are not executed as
HyperList commands -- i.e. in a list of transition Items, they are not actions
to be executed.

------------------------------------------------------------------------------
4.3.2.3 Quote                                                *HyperList-Quote*

Anything in quotation marks is a Quote. Like a Comment, a Quote is not executed
as a HyperList command.

------------------------------------------------------------------------------
4.3.2.4 Change Markup                                 *HyperList-ChangeMarkup*

When working with HyperList, especially on paper, there may come a need to mark
deletion of Items or to show where an Item should be moved to. To accommodate
this need, Change Markup is introduced. Change markup is a special type of Tag.

If "##<" is added at the end of an Item, it is slated for deletion. To show
that an Item should be moved, add "##>" at the end followed by a Reference
showing to which Item it should be moved below.

To indent an Item to the left, add "##<-". Indenting an Item to the right is
marked by "##->". It is possible to combine moving and indenting an Item, i.e.
moving an Item and making it a child of another: "##>><Ref>##->".

To signify that an Item has been changed from a previous version of a
HyperList, prefix the Item with "##text##". Inside the hash signs you may
include information about the change done, e.g. "##John 2012-03-21##" to show
that the Item was changed by a certain person at a given time.

------------------------------------------------------------------------------
4.4 Separator                                            *HyperList-Separator*

A Separator separates one Item from another. A line in a HyperList is usually
one Item, and Items are then usually separated by a "newline" (hitting the
"Enter" on the keyboard). But it is possible to string several Items together
on one line by separating them with semicolons.

By separating an Item by a newline and then indenting it to the right, you
create a child Item. A child adds information to its parent.

A Separator between two Items with the same or less indent is normally read as
"then". If a parent Item contains a description, the newline Separator and
indent to the right (a child) reads "with" or "consists of". If a parent Item
does not contain a Description, the Separator and indent to the right (a child)
is read as "applies to", and a Separator between the children is read as "and".
A few examples should suffice:

	A kitchen
		Stove
		Table
			Plates
			Knives
			Forks

This would read: "A kitchen with stove and table with plates, knives and
forks".

	Time = 2010:
		Olympic Games
		Soccer world championship

This would read: "Time = 2010: applies to: Olympic Games and Soccer world
championship".

	Walk the dog
		Check the weather
			[?rain] AND/OR:
				Get rain coat
				Get umbrella
			Dress for the temperature
		Get chain

And this would read: "Walk the dog consists of Check the weather consists of:
If rain, AND/OR: applies to children: Get rain coat, Get umbrella; then Dress
for the temperature, then Get chain". Or more humanly: "Walk the dog consists
of check the weather, which consists of either/or get the rain coat and get
umbrella. Then dress for the temperature and then get the chain."

Now consider these four examples:

   Production
      Station 1
         Assemble parts A-G
      Station 2
         Assemble parts H-R
      Station 3
         Assemble parts S-Z

   Production
      Station 1; Assemble parts A-G
      Station 2; Assemble parts H-R
      Station 3; Assemble parts S-Z

   Production
      [Station 1]
         Assemble parts A-G
      [Station 2]
         Assemble parts H-R
      [Station 3]
         Assemble parts S-Z

   Production
      [Station 1] Assemble parts A-G
      [Station 2] Assemble parts H-R
      [Station 3] Assemble parts S-Z

The first and second examples say exactly the same thing, but the second
example is more efficient as it uses the semicolon as a Separator instead of
using a line break and indent. The same goes for the third and the fourth
examples -- they are equivalent. But how about the difference between the first
two examples and the last two?

When you use a Qualifier as in examples three and four, you accommodate for the
tasks getting done in any chosen sequence. In those two examples, the
production could go, for example, "Station 1", then "Station 3", then "Station 2".

The first and second examples read: "The production consists of: Station 1
assembles parts A-G, then Station 2 assembles parts H-R and finally Station 3
assembles parts S-Z".

The third and fourth examples read: "The production consists of: if or when at
Station 1, assemble parts A-G, if or when at Station 2, assemble parts H-R, and
if or when at Station 3, assemble parts S-Z".

As you can see, there is a subtle but distinct difference.

------------------------------------------------------------------------------
5 A self-defining system                           *HyperList-Self-definition*

Now that we have covered all the possibilities in a HyperList, it should be
obvious that HyperList could extend into a vast array of descriptions. It is
even possible to write a parser or compiler for HyperList and use it as a
programming language.

Is it possible to compact the descriptions above into a HyperList? Yes, indeed.
The HyperList system is self-describing.

HyperList can be done in many different ways -- from informal to strict and
from high-level to very detailed. The power of the tool resides with the user.

To illustrate the flexibility of HyperList, we will show the definition of this
methodology in three steps -- from a very informal and high-level description,
to a more strict but still high-level -- to the fully-detailed definition of
HyperList.

First, here is a simple list showing what HyperList is all about:

	HyperList Item parts (in sequence): 
		Starter (optional)
			Identifier or Multi-line Indicator
		Type (optional)
			State or transition
		Content (can be an Element and/or an Additive)
			Element
				Either an Operator, Qualifier, Property, or Description
			Additive    
				Either a Reference, Tag, Comment, Quote, or Change Markup
		Separator
			Newline or semicolon

Now, that's a very simple HyperList. Let's make the same simple list more
strict by using the system concisely:

	HyperList Item parts
		[?] Starter; OR:
			Identifier
			Multi-line Indicator
		[?] Type; OR:
			State
			Transition
		Content; AND/OR:
			Element; AND/OR:
				Operator
				Qualifier
				Property
				Description
			Additive; AND/OR:
				Reference
				Tag
				Comment
				Quote
				Change Markup
		Separator; OR:
			Newline
			Semicolon

That wasn't so intricate either, and that list is more easily parsable by a
computer program if one wanted to automatically create graphical
representation.

How about the full and complete definition, including all imaginable details of
how any HyperList could conceivably be structured. Fasten your seat belt.

The following list shows the legal structure and syntax of a HyperList. It
covers all you have read above. 

HLstart
HyperList
	[1+] HyperList Item
		[?] Starter; OR: 
			Identifier (Numbers: Format = "1.1.1.1", Mixed: Format = "1A1A")
				[? Multi-line Item] The Identifier acts like the plus sign ("+")
			Multi-line Indicator = "+"
				+ If one Item on a certain indent is multi-line, all Items on the same indent
				 (including single-line Items) must start with a plus sign ("+")} or <Identifier>
				 and all lines on the same indent after the first line must start with a space
		[?] Type
			OR: 
				State = "S:" or "|"
				Transition = "T:" or "/"
			Children inherit Type from parent unless marked with different Type
			Can be skipped when the Item is obviously a state or transition
		Content; AND/OR: 
			Element; AND/OR:	
				Operator
					Anything operating on an Item or a set of Items
						[? Set of Items] Items are indented below the Operator
					Can be any of the usual logical operators
					Is written in capitals ending in a colon and a space
						EXAMPLES: "AND: ", "OR: ", "AND/OR: ", "NOT: ", "IMPLIES: "
					Can contain a Comment to specify the Operator
						EXAMPLE: "OR(PRIORITY): "
							Sub-Items are to be chosen in the order of priority as listed
					To make the Item run continuously, use "CONTINUOUS: " 
						Item is done concurrent with remaining Items
						The Operator can be combined with a timestamp Tag
							EXAMPLE: "CONTINUOUS: YYYY-MM-07:" = Do the Item weekly
					To show that an Item is encrypted or is to be encrypted, use "ENCRYPTION: "
						OR: 
							 The encrypted block can be correctly indented
							 The encrypted block contains indentation and is left justified
									This would seem to break the list, but is allowed
					A block can be included of "literal text" negating any HyperList markup
						Use a HyperList Item containing only the Operator "\"} to mark start/end
							EXAMPLE: 
								\
								This is a block of literal text...
								Where nothing counts as HyperList markup
								Thus - neither this: [?] nor THIS: <Test> - are seen as markup
								...until we end this block with...
								\
				Qualifier
					Any statement in square brackets that qualifies an Item
					Specifies under what conditions an Item is to be executed, exists or is valid
					Several Qualifiers can be strung together, separated by commas
						All Qualifiers need to be fulfilled for the Item to be valid
						EXAMPLE: "[+YYYY-MM-DD 02.30, Button color = Red, 4, ?] Push button"
					Successive Qualifiers can be strung together, separated by periods; EXAMPLE: 
						"[Apples. Oranges. Grapes]"
							Do Item in the context of "apples", then "oranges", then "grapes"
					EXAMPLES: 
						Do Item 3 times = "[3]"
						Do Item if "the mail has arrived" = "[The mail has arrived]"
						Do Item 2 times while "foo=true" = "[2, foo=true]"
						Do Item from 3 to 5 times while "bar=false" = "[3..5, bar=false]"
						Do Item 1 or more times = "[1+]"
						Do Item 1 or more times while "Bob is polite" = "[1+, Bob is polite]"
						Do Item up to 4 times only while "zoo=0" = "[<4, zoo=0]"
					Optional Item = "[?]"
					Timestamp Qualifier = "[YYYY-MM-DD hh.mm.ss]"
						Shorten the format to the appropriate granularity
					Time relations
						Length of time to wait before doing the Item = "[+YYYY-MM-DD]"
						Less than a certain length of time after previous Item = "[<+YYYY-MM-DD]"
						More than a certain length of time after previous Item = "[>+YYYY-MM-DD]"
						Length of time to wait  before doing next Item = "[-YYYY-MM-DD]"
						Less than a certain length of time before next Item = "[<-YYYY-MM-DD]"
						More than a certain length of time before next Item = "[>-YYYY-MM-DD]"
						Length of time to wait after doing referenced Item = "[+YYYY-MM-DD<Item]>"
						Other obvious time indicators may be used; EXAMPLES: 
							"[+1 week]"
							"[-2 Martian years]"
						EXAMPLES: 
							Wait one month before doing the Item = "[+YYYY-01-DD]"
							Do Item less than 4 days before next Item = "[<-YYYY-MM-04]"
							Wait one year and two days after Item X = "[+0001-00-02<X>]"
						Time repetition
							Obvious/intuitive repetition
								EXAMPLES: 
									"[YYYY-MM-03]" = The third of every month
									"[YYYY-12-DD]" = Every day in every December
									"[2011-MM-05]" = The fifth of every month of 2011
									"[Tue,Fri 12.00]" = Noon every Tuesday and Friday
							Strict convention
								Format = YYYY-MM-DD+X Day hh.mm+Y - YYYY-MM-DD hh.mm; EXAMPLES: 
									"[2011-05-01+7 13.00]" = 2011-05-01 1pm, repeated every 7 days
									"[2011-05-01+2,3,2]" = Every 2, then 3, then 2 days, in repetition
									"[2011-05-01+2 - 2012-05-01]" = Every second day for one year
									"[2011-05-01 13.00+1]" = 2011-05-01 1pm, repeated every hour
									"[2011-05-01 Fri,Sat - 2011-10-01]" = Every Fri & Sat in time interval
						Checking off Items
							Unchecked Item = "[_]"
							Checked Item = "[x]" 
								[?] Timestamp Tag after ("[x] YYYY-MM-DD hh.mm:ss:")
				Property
					Any attribute to the <Content>, ending in a colon and a space
						Gives additional information or description to the Item
					EXAMPLES: 
						"Location = Someplace:", "Color = Green:", "Strength = Medium:" and "In Norway:"
				Description
					The main body of the HyperList Item, the "meat" of the line
			Additive; AND/OR: 
				Reference
					+ An Item name or Identifier, list name or anything else
					 enclosed in angle brackets ("<>"); EXAMPLES: 
						Reference to a website = "<http://www.isene.org/>"
						Reference to a file = "<file:/path/to/filename>"
					+ There are two types of References; OR: 
						Redirection (hard Reference)
							An Item consisting only of a Reference is a redirection
								For a transition Item = Jump to referenced Item and execute
									+ If the redirect is to jump back after executing 
									 the referenced Item (and its children), then add another 
									 set of angle brackets (<<Referenced Item>>)
										+ EXAMPLE: Use this when creating subroutines at 
										 the end of the list
								For a state Item = Include the referenced Item
							An Item consisting only of the key word "SKIP"
								Ends the current HyperList level
							An Item consisting only of the key word "END" 
								Ends the whole HyperList
						Soft Reference
							Reference is part of an Item
								Look at referenced Item for info only
							Even softer Reference = have the Reference in parentheses
								An Item that is only something apropos
					+ A Reference to any Item upward in the HyperList is simply a
					 Reference to the Item's <Content>
					+ A Reference containing several levels down a HyperList needs a "/" 
					 to separate each level, like a "path" (as with a URL) to the Item
					+ To make a Reference to a different branch in a HyperList, 
					 start the Reference from the highest common level on the list
					 and include all Items down to the referenced Item
						EXAMPLE: Reference from here to <Hyperlist Item/Starter/Identifier>
					+ For long Items in a Reference, concatenation can be used
						The concatenation must be unique
							EXAMPLE: Reference from here to <Additive/Comment/Anything...>
				Tag
					A hash sign followed by any letters or numbers, used as a marker (#Tagged)
					Is not executed as a HyperList command
				Comment
					Anything within parentheses is a Comment
					Is not executed as a HyperList command
				Quote
					Anything in quotation marks is a Quote
					Is not executed as a HyperList command
				Change Markup; OR: 
					Deletion
						Remove the Item by adding "##<" at the end of the Item
					Motion; OPTIONS: 
						Move the Item by adding "##><Reference>"
							This moves the Item just below the referenced Item
						Move the Item one level in by adding "##<-" at the end of the Item
						Move the Item one level out by adding "##->" at the end of the Item
							EXAMPLE: Move an Item as a child to referenced Item = "##><Reference>##->"
					Changed Item
						Prefix an Item with "##Text##" to signify that a change has been made
							Add information inside the angle brackets as appropriate
								EXAMPLE: To show who changed it and when = "##John 2012-03-21##"
		Separator 
			OR: 
				Semicolon
					A semicolon is used to separate two HyperList Items on the same line
				Newline
					Used to add another Item on the same level
					Indent
						A Tab or an asterisk ("*")}
							Used to add a child
								A child adds information to its parent
								A child is another regular <HyperList Item>
			Definition
				A Separator and the same or less indent normally reads "then:"
				[? Parent contains <Description>]} 
					The Separator and right indent reads "with:" or "consists of:"
				[? NOT: parent contains <Description>]} 
					The Separator and right indent reads "applies to:"
					A Separator between the children reads "and:"
HLend

Read and re-read the HyperList above and you will be a HyperList master after a
while. It's all there. The whole markup.

==============================================================================
6 About                                                      *HyperList-About*

The author of the VIM plugin for HyperList is also the chief maintainer of the
HyperList definition itself; Geir Isene <g@isene.com>. More at http//isene.org 

==============================================================================
7 Changelog                                              *HyperList-Changelog*

VERSION 2.4.1			2019-10-06
	Updated to be compatible with HyperList definition v. 2.4
	Included full tutorial/test suite (thanks to Don Kelley).
	Improved LaTeX export.
	Improved GotoRef() (mapped to 'gr' and '<CR>')
	  GotoRef() now also opens files if the format is <file:...>
	  GotoRef() handles the new relative references like <+2> and <-5>
	Some other minor changes and clean-ups of the documentation.

VERSION 2.3.17			2019-08-14
	Added a GVIM menu. Full rework of the color schemes for VIM & gVIM.
   Improvement to Goto Reference (gr) and Autonumbering.
   Several minor changes and improvement in the docs.
   Thanks to Don Kelley for the gVIM suggestions and for extensive testing.

VERSION 2.3.16			2019-08-03
	Improved the CalendarAdd functionality to include the item and all its
	children in the event description and the filename in the header for easy
	reference

VERSION 2.3.15			2019-07-31
	Added function CalendarAdd to add items with future dates as events to your
	Google calendar (mapped to <leader>G)

VERSION 2.3.14			2019-05-17 (Norway's Constitution Day)
	Added function highlight/focus the current part of a HyperList

VERSION 2.3.13			2018-10-24
	Added function Renumber() to (re)number items on same indent

VERSION 2.3.12			2018-06-18
	Minor fix to bold/italics/underlined elements

VERSION 2.3.11			2018-02-23
	Added TPP conversion (info on TPP: https://github.com/cbbrowne/tpp)

VERSION 2.3.10			2018-02-13
	Prettified LaTeX output

VERSION 2.3.9			2018-01-26
	Fixed bugs in LaTeX & HTML conversion (to accept space in refs)

VERSION 2.3.8			2017-10-27
	Added a sorting function: vmap <leader>s To sort a set of items at a
	specific indentation, visually select (V) the items you want to sort
	(including all the children of those items) and press <leader>s and the
	items in the range will be alphabetically sorted - but only the items on the
	same level/indentation as the first item selected. The sorted items will
	keep their children. This is useful if parts of a HyperList is numbered and
	you get the numbering out of sequence and wants to resort them.  One caveat,
	the last line in the selection cannot be the very last line in the document
	(pthere must be an item or an empty line below it).

VERSION 2.3.7			2017-08-11
	Autonumbering now works also with numbers ending in a period
	(both 4.2.1 and 4.2.1. now works for <cr>, <c-t> and <c-d>)

VERSION 2.3.6			2017-06-15
	Added basic autonumbering (with <leader># or <leader>an)
	Suggested and tested by Jerry Antosh

VERSION 2.3.5			2017-01-16
	Added the function Complexity(). The score shown is the total of Items and 
	References in your HyperList. To get the overall complexity use:
	  :call Complexity()

VERSION 2.3.3/4		Minor fixes

VERSION 2.3.2			2016-06-30
	Added the functionionality of Show/Hide of words or regex patterns

VERSION 2.3.1			2015-06-30
	Added the function OpenFile() to open referenced file (mapped to 'gf')

VERSION 2.3			2015-02-08
	Version upgraded to HyperList definition 2.3
	Made the changes necessary to accommodate for Twitter-type (hash)Tags
	New markup for References (and included "@" in references)
	Fixed bold/italic/underlined
	Changed the Change Markup
	Updated Latex/HTML conversion
	Updated documentation

VERSION 2.1.7		2012-10-17
   Fixed bugs in Identifier and Multi
	Cosmetic fixes

VERSION 2.1.6		2012-10-15
	Improved the GotoRef function.

VERSION 2.1.5		2012-10-13
	Speed-up. Also added a global variable that can be set if you don't want the
	collapse functions active, set this: ("g:disable_collapse") - it will
	considerably speed up large HyperListS.
	Fixed syntax highlighting for the first line in a HyperList.

VERSION 2.1.4		2012-09-25
	Added "zx" as a command to update folding (to update syntax)
	Added <CR> as an alternative to gr (Goto Ref)
	Added a mark (m') to gr/<CR> to facilitate easy jump back 

VERSION 2.1.3		2012-09-23
   Changes: Included more accented characters
   Speedup; Adjusted minimum and maximum lines of sync'ing
   Fixed identifiers

VERSION 2.1.2		2012-07-07
	Important security upgrade: Removed traces of encrypted data upon
	en/decrypting (part of) a HyperList.

VERSION 2.1.1		2012-04-28
	Upgraded plugin to reflect the new Hyperlist version (2.1)

VERSION 2				2012-03-28
	Name change (from WOIM to HyperList)
	Complete overhaul of the definition document
	Complete overhaul of the plugin documentation (this file)
	Underlining of States and Transitions now toggles with <leader>u
	Included "|" as alternative for "S: " and "/" for "T: "
	Upgraded LaTeX export
	Lots of minor fixes

VERSION 1.7			2012-01-01
  Expanded "gr" (Goto Reference):
    Made it possible to reference external files by the use of
    #file:/pathto/filename, #file:~/filename or #file:filename
    As long as the reference is prefixed with "file:" after
    the "#", the command "gr" will open the referenced file.
  Added HTML conversion vith the use of <leader>H.
  Improved LaTeX conversion.
  After an HTML/LaTeX conversion, filetype is set to html/tex.
  Changed the color of multi-indicator (+) from red to purple.

VERSION 1.6			2011-12-08
	Added marking of literal regions with special marking of start/end ("\")
	Added <leader><DOWN> and <leader><UP>
	Fixed syntax marking for State/Transitions where indent is "*"
	Fixed escaping "\", "{" and "}" for LaTeX conversion

VERSION 1.5.3		2011-09-18
	New feature: LaTeX conversion: Turn your WOIM list into a LaTeX document.
	             Mapped to <leader>L (feature suggested by  Shantanu Kulkarni).
	Added "set autoindent" to plugin settings (thanks to Shantanu Kulkarni).
	Minor fixes.
	Updated documentation.

VERSION 1.5.2		2011-09-08
	Added "presentation mode" where you can traverse a WOIM list with
	"g<DOWN>" or "g<UP>" to view only the current line and its ancestors.
	Changed Quotes and Comments to only cover one line (before when it
	covered several lines, the plugin became very slow for large lists).
	Added instructions in doc file on using WOIM list in other file types.

VERSION 1.5.1		2011-08-16
	Minor updates to the documentation.

VERSION 1.5.0		2011-08-16
	Added encryption via OpenSSL:
    <leader>z encrypts the current line (including all sublevels if folded)
    <leader>Z encrypts the current file (all lines)
    <leader>x decrypts the current line
    <leader>X decrypts the current file (all lines)
    A dot file (file name starts with a "." such as .test.woim) is
    automatically encrypted on save and decrypted on opening.

VERSION 1.4.7		2011-06-02
	Modified the GotoRef function (fixed a bug and included feed back)
	Better syntax highlighting for folding in gvim
	Updating the README_WOIM and documentation files + other cosmetic changes
	Added the possibility of disabling/overriding the WOIM plugin key mapping
	Added an ftdetect file into woim.vba
	(Thanks to Sergey Khorev for the last two improvements)

VERSION 1.4.6		2011-05-31
	Minor fixes due to a bout of perfectionism.

VERSION 1.4.5		2011-05-30
	Overhaul:
	Created the documentation, including the whole WOIM definition to make it
	easily accessible within VIM. Added the INSTALL and README files.
	Created a Vimball file ("woim.vba") for easy install. Simply do:
		vim woim.vba
		:so %
		:q

VERSION 1.4.2   2011-05-29
	Fixed "gr" (Goto Ref) for references with single quotes ('')
	Added the search pattern from "gr" to the search register so that "n" can
	successively be used to test if the referenced destination is unique (which
	it should be).

VERSION 1.4.1   2011-05-27
	New feature:
	Goto Reference: With the cursor at a WOIM reference, press "gr" to jump to
	that reference in the WOIM list.
	Now you can navigate more easily in WOIM lists.

VERSION 1.4	    2011-05-23
	This could have been the long awaited version 1.0 - but instead I decided to
	synchronize the version numbering of this VIM plugin and the WOIM description
	itself. From now on the releases will be synchronized, with minor fixes in
	the VIM plugin released as minor releases (i.e. a fix to 1.4 would be 1.4.1
	and would still be on par with the WOIM definition version 1.4). The version
	1.4 of the WOIM definition adds time repetition as well as "checking" of
	todo-list items.

	This release:
	New feature: Added the option of checkboxes for items (Thanks to Christopher
	Truett (VIM script #3584). You can now easily add a checkbox in front of any
	item by <leader>v and subsequently toggle that checkbox via the same
	(<leader>v) or <leader>V if you want to add a time stamp to a box that you
	"check" (this also toggles the timestamp if you "uncheck" the item).
	Fixes: Some minor cleanup.

VERSION 0.9.9   2011-04-17
	Fix: Fixed interference between Operators and Tags

VERSION 0.9.8   2010-12-14
	Feature: States (S:) is underlined by default.  <leader>s removes the
	underlining, while <leader>S turns on underlining of States.  Transitions are
	not underlined by default.  <leader>T turns on underlining, while <leader>t
	removes the underlining of Transitions.
	Fix: Removed unnecessary "contained" to make lists syntax marked even within stub lists.
	Fix: Small fixes in grouping and containing of elements.

VERSION 0.9.6   2010-12-03
	Feature: Added "*" as possible indentation
	Fix:     Changed Multiline indicator from "*" to "+"
	Now compatible with WOIM v. 1.2

VERSION 0.9.3   2009-12-11
	Christian Bryn caught an important bug/lacking setting. The syntax file
	now sets noexpandtab.

VERSION 0.9.2   2009-10-25
	A few needed minor fixes.

VERSION 0.9.1   2009-08-21
	New_feature:
	Added highlighting of item motions:
	<<       means "delete this item" (put at the end of a line)
	>>#1.1.  means "move this item to after item 1.1."
	->       means "indent item right"
	<-<-     means "indent item two left"
	>>#1.->  means "move item to after item 1. and indent right"

VERSION 0.9	    2009-08-10
	New_feature: Accommodated for the use of subroutine calls (##ref)
	Fix: Cleaned up syntax variable names to fit modern WOIM
	Fix: Multi-lines have consecutive lines start with a <space>
	Fix: Quotes or Comment can now span several lines
	Fix: Comments allowed in Operators
	Fix: Comments and references allowed inside Qualifiers
	Fix: Identifier must end in a period and then a space
	Bug_fix: Allowing a period to be part of a tag
	Bug_fix: Fixed wrong markup for astrices not used for multi-line

VERSION 0.8.6   2009-07-24
	Bug fix: Corrected attributes ending in capitals that was treated as a WOIMkey
	Bug fix: Fixed references containing a hyphen

VERSION 0.8.5   2009-07-23
	New feature: Expanded Attributes to include relative times and
					 greater/smaller than.
	New feature: References with spaces are now accommodated for by putting it in quotes.
	New feature: Made references in attributes possible.
	Bug fix:		 Fixed references that includes ampersands ("&").

VERSION 0.8.1   2009-07-22
	Bug fix: Fixed highlighting of attributes with a colon (like time stamps)

VERSION 0.8	    2009-07-21
	New feature: Expanded folding to a maximum of 15 levels with folding levels
	set with <leader>a to <leader>f for levels 10 to 15.  Improvement: Better
	syntax highlighting for indexes
	Bug fix: Fixed syntax syncing when entering the document in the first place

VERSION 0.7.2   2009-07-15
	Better syntax highlighting for references.
	Added unobtrusive highlighting of vim bottom set-lines.

VERSION 0.7.1   2009-06-16
	Bug fix: Fixed an error in syntax highlighting properties containing a "-"
	(like ISO dates).

VERSION 0.7	    2009-06-13
	Added macro to jump to next point in a template and fill in the value. A
	template item is an item that ends in an equal sign and where the value after
	the equal sign is to be filled out. Example:
		ExampleTask
			 Task name =
			 Responsible person =
			 Deadline =

VERSION 0.6	    2009-04-13
	Some minor adjustments, but a needed upgrade if you are a WOIM user.

VERSION 0.4	    2009-01-16
	Initial upload

==============================================================================
8 Credits                                                  *HyperList-Credits*

Thanks to Jean-Dominique Warnier and Kenneth Orr for the original idea of this
type of markup system (the Warnier-Orr diagrams).

Thanks to:
Egil Möller for helping to cultivate the first versions.
Axel Liljencrantz for his input in outlining the early WOIM methodology.
Christian Bryn for testing of the plugin.
Christopher Truett for his Checkbox VIM plugin.
Noah Spurrier for his OpenSSL VIM plugin.
Amit Sethi for the Show/Hide functionality (VIM script #1594).
Jerry Antosh for suggesting autonumbering and testing it.
Don Kelley for testing, improvements and for the Test Suite.

==============================================================================
9 License                                                  *HyperList-License*

I release all copyright claims. This code is in the public domain.  Permission
is granted to use, copy modify, distribute, and sell this software for any
purpose. I make no guarantee about the suitability of this software for any
purpose and I am not liable for any damages resulting from its use. Further, I
am under no obligation to maintain or extend this software. It is provided on
an 'as is' basis without any expressed or implied warranty.
doc/HyperList.hl	[[[1
181
HyperList
	[1+] HyperList Item
		[?] Starter; OR: 
			Identifier (Numbers: Format = "1.1.1.1", Mixed: Format = "1A1A")
				[? Multi-line Item] The Identifier acts like the plus sign ("+")
			Multi-line Indicator = "+"
				+ If one Item on a certain indent is multi-line, all Items on the same indent
				 (including single-line Items) must start with a plus sign ("+")} or <Identifier>
				 and all lines on the same indent after the first line must start with a space
		[?] Type
			OR: 
				State = "S:" or "|"
				Transition = "T:" or "/"
			Children inherit Type from parent unless marked with different Type
			Can be skipped when the Item is obviously a state or transition
		Content; AND/OR: 
			Element; AND/OR:	
				Operator
					Anything operating on an Item or a set of Items
						[? Set of Items] Items are indented below the Operator
					Can be any of the usual logical operators
					Is written in capitals ending in a colon and a space
						EXAMPLES: "AND: ", "OR: ", "AND/OR: ", "NOT: ", "IMPLIES: "
					Can contain a Comment to specify the Operator
						EXAMPLE: "OR(PRIORITY): "
							Sub-Items are to be chosen in the order of priority as listed
					To make the Item run continuously, use "CONTINUOUS: " 
						Item is done concurrent with remaining Items
						The Operator can be combined with a timestamp Tag
							EXAMPLE: "CONTINUOUS: YYYY-MM-07:" = Do the Item weekly
					To show that an Item is encrypted or is to be encrypted, use "ENCRYPTION: "
						OR: 
							 The encrypted block can be correctly indented
							 The encrypted block contains indentation and is left justified
									This would seem to break the list, but is allowed
					A block can be included of "literal text" negating any HyperList markup
						Use a HyperList Item containing only the Operator "\"} to mark start/end
							EXAMPLE: 
								\
								This is a block of literal text...
								Where nothing counts as HyperList markup
								Thus - neither this: [?] nor THIS: <Test> - are seen as markup
								...until we end this block with...
								\
				Qualifier
					Any statement in square brackets that qualifies an Item
					Specifies under what conditions an Item is to be executed, exists or is valid
					Several Qualifiers can be strung together, separated by commas
						All Qualifiers need to be fulfilled for the Item to be valid
						EXAMPLE: "[+YYYY-MM-DD 02.30, Button color = Red, 4, ?] Push button"
					Successive Qualifiers can be strung together, separated by periods; EXAMPLE: 
						"[Apples. Oranges. Grapes]"
							Do Item in the context of "apples", then "oranges", then "grapes"
					EXAMPLES: 
						Do Item 3 times = "[3]"
						Do Item if "the mail has arrived" = "[The mail has arrived]"
						Do Item 2 times while "foo=true" = "[2, foo=true]"
						Do Item from 3 to 5 times while "bar=false" = "[3..5, bar=false]"
						Do Item 1 or more times = "[1+]"
						Do Item 1 or more times while "Bob is polite" = "[1+, Bob is polite]"
						Do Item up to 4 times only while "zoo=0" = "[<4, zoo=0]"
					Optional Item = "[?]"
					Timestamp Qualifier = "[YYYY-MM-DD hh.mm.ss]"
						Shorten the format to the appropriate granularity
					Time relations
						Length of time to wait before doing the Item = "[+YYYY-MM-DD]"
						Less than a certain length of time after previous Item = "[<+YYYY-MM-DD]"
						More than a certain length of time after previous Item = "[>+YYYY-MM-DD]"
						Length of time to wait  before doing next Item = "[-YYYY-MM-DD]"
						Less than a certain length of time before next Item = "[<-YYYY-MM-DD]"
						More than a certain length of time before next Item = "[>-YYYY-MM-DD]"
						Length of time to wait after doing referenced Item = "[+YYYY-MM-DD<Item]>"
						Other obvious time indicators may be used; EXAMPLES: 
							"[+1 week]"
							"[-2 Martian years]"
						EXAMPLES: 
							Wait one month before doing the Item = "[+YYYY-01-DD]"
							Do Item less than 4 days before next Item = "[<-YYYY-MM-04]"
							Wait one year and two days after Item X = "[+0001-00-02<X>]"
						Time repetition
							Obvious/intuitive repetition
								EXAMPLES: 
									"[YYYY-MM-03]" = The third of every month
									"[YYYY-12-DD]" = Every day in every December
									"[2011-MM-05]" = The fifth of every month of 2011
									"[Tue,Fri 12.00]" = Noon every Tuesday and Friday
							Strict convention
								Format = YYYY-MM-DD+X Day hh.mm+Y - YYYY-MM-DD hh.mm; EXAMPLES: 
									"[2011-05-01+7 13.00]" = 2011-05-01 1pm, repeated every 7 days
									"[2011-05-01+2,3,2]" = Every 2, then 3, then 2 days, in repetition
									"[2011-05-01+2 - 2012-05-01]" = Every second day for one year
									"[2011-05-01 13.00+1]" = 2011-05-01 1pm, repeated every hour
									"[2011-05-01 Fri,Sat - 2011-10-01]" = Every Fri & Sat in time interval
						Checking off Items
							Unchecked Item = "[_]"
							Checked Item = "[x]" 
								[?] Timestamp Tag after ("[x] YYYY-MM-DD hh.mm:ss:")
				Property
					Any attribute to the <Content>, ending in a colon and a space
						Gives additional information or description to the Item
					EXAMPLES: 
						"Location = Someplace:", "Color = Green:", "Strength = Medium:" and "In Norway:"
				Description
					The main body of the HyperList Item, the "meat" of the line
			Additive; AND/OR: 
				Reference
					+ An Item name or Identifier, list name or anything else
					 enclosed in angle brackets ("<>"); EXAMPLES: 
						Reference to a website = "<http://www.isene.org/>"
						Reference to a file = "<file:/path/to/filename>"
					+ There are two types of References; OR: 
						Redirection (hard Reference)
							An Item consisting only of a Reference is a redirection
								For a transition Item = Jump to referenced Item and execute
									+ If the redirect is to jump back after executing 
									 the referenced Item (and its children), then add another 
									 set of angle brackets (<<Referenced Item>>)
										+ EXAMPLE: Use this when creating subroutines at 
										 the end of the list
								For a state Item = Include the referenced Item
							An Item consisting only of the key word "SKIP"
								Ends the current HyperList level
							An Item consisting only of the key word "END" 
								Ends the whole HyperList
						Soft Reference
							Reference is part of an Item
								Look at referenced Item for info only
							Even softer Reference = have the Reference in parentheses
								An Item that is only something apropos
					+ A Reference to any Item upward in the HyperList is simply a
					 Reference to the Item's <Content>
					+ A Reference containing several levels down a HyperList needs a "/" 
					 to separate each level, like a "path" (as with a URL) to the Item
					+ To make a Reference to a different branch in a HyperList, 
					 start the Reference from the highest common level on the list
					 and include all Items down to the referenced Item
						EXAMPLE: Reference from here to <Hyperlist Item/Starter/Identifier>
					+ For long Items in a Reference, concatenation can be used
						The concatenation must be unique
							EXAMPLE: Reference from here to <Additive/Comment/Anything...>
				Tag
					A hash sign followed by any letters or numbers, used as a marker (#Tagged)
					Is not executed as a HyperList command
				Comment
					Anything within parentheses is a Comment
					Is not executed as a HyperList command
				Quote
					Anything in quotation marks is a Quote
					Is not executed as a HyperList command
				Change Markup; OR: 
					Deletion
						Remove the Item by adding "##<" at the end of the Item
					Motion; OPTIONS: 
						Move the Item by adding "##><Reference>"
							This moves the Item just below the referenced Item
						Move the Item one level in by adding "##<-" at the end of the Item
						Move the Item one level out by adding "##->" at the end of the Item
							EXAMPLE: Move an Item as a child to referenced Item = "##><Reference>##->"
					Changed Item
						Prefix an Item with "##Text##" to signify that a change has been made
							Add information inside the angle brackets as appropriate
								EXAMPLE: To show who changed it and when = "##John 2012-03-21##"
		Separator 
			OR: 
				Semicolon
					A semicolon is used to separate two HyperList Items on the same line
				Newline
					Used to add another Item on the same level
					Indent
						A Tab or an asterisk ("*")}
							Used to add a child
								A child adds information to its parent
								A child is another regular <HyperList Item>
			Definition
				A Separator and the same or less indent normally reads "then:"
				[? Parent contains <Description>]} 
					The Separator and right indent reads "with:" or "consists of:"
				[? NOT: parent contains <Description>]} 
					The Separator and right indent reads "applies to:"
					A Separator between the children reads "and:"

doc/hyperlist.pdf	[[[1
1526
%PDF-1.5
%ÐÔÅØ
96 0 obj
<<
/Length 698       
/Filter /FlateDecode
>>
stream
xÚT]oÓ0}Ï¯ðc"a×ß±÷ì6[B¬5­QëviA_Ïuì®Í(T)vãsoî=÷R4AôëËa18S±p¦$~A\SÂµEÚ¢(CÃ1úT^T¯Rºæ""'FLøXaÍË·ðdåi·¿ÙqvêÂ¦IWe)±Òn!Öm÷>Â%±uhÎ¨&8ãv'ÊUGÖp °PÉ<w¾­0W´¼\¹àiX­»h)T!ÁYiiòÜG0-æPP¢ Ôøl'h÷çæ<&íiE®y_mº^/'¹83`î 
9¬V%¾«%|¨K7Nr¿9ðXZ¢Í»_¹&àÅÜÿðÍ%öÊÐ²iwm%iù,½}]qUºÜz^¼iÛxÄ"¶"ëÖI÷tâg	vÝ¸"È
9ñwpø4eïl1õî~ñ£bpyV¼ò³¯.Ú&¬fÀuÓúÙ&dô}ÛL¹oBÊB/J-UN N×¹±_û093×OröË¶(ÏWÿ¾b®]ùE8ª°`´äD&úUSf1£*øÇzÕß¹ Â²×1,=ÇÀÆV»È\X¹¬|¼5^5O6EñØBBÓ+¨A£yñP@I©;ÄÞ¶;âzièµ%ªOsNÅ;øý>o`¨À.öHÞBl£ÀÛ0ð^ÝhQÑU$µº&³°
bD6Û÷ÎÐÇõjI`/ey¼#è+HFmÊ&ÓfÙºî-xLN/íûnË$ØBg÷\l®½ò«uJù²@þk*À°5ÛQ×v2FùÈþÅ
endstream
endobj
93 0 obj
<<
/Type /XObject
/Subtype /Image
/Width 200
/Height 177
/BitsPerComponent 8
/Length 46340
/ColorSpace /DeviceRGB
/Filter /DCTDecode
>>
stream
ÿØÿà JFIF     ÿá*øExif  II*         J       R   (       1    Z   2    f   z     2     2   GIMP 2.10.6 2019:10:05 20:25:38              â       à                            æ       
*         ÿØÿà JFIF      ÿÛ C 		

ÿÄ µ   } !1AQa"q2¡#B±ÁRÑð$3br	
%&'()*456789:CDEFGHIJSTUVWXYZcdefghijstuvwxyz¢£¤¥¦§¨©ª²³´µ¶·¸¹ºÂÃÄÅÆÇÈÉÊÒÓÔÕÖ×ØÙÚáâãäåæçèéêñòóôõö÷øùúÿÄ        	
ÿÄ µ  w !1AQaq"2B¡±Á	#3RðbrÑ
$4á%ñ&'()*56789:CDEFGHIJSTUVWXYZcdefghijstuvwxyz¢£¤¥¦§¨©ª²³´µ¶·¸¹ºÂÃÄÅÆÇÈÉÊÒÓÔÕÖ×ØÙÚâãäåæçèéêòóôõö÷øùúÿÚ   ? óª(¢¾Àû ¢( ¢( ¢)QE QE QE QE QE<C!ÈìM'$·brKv2»4ðyÄìíV#
íÅS`U=EeJ´j]-Ó3§UNöè%Q[Q@Q@QH( ( ( ( ( ( ( )¯¸))·?íTÎjr}Ô"äú	$=½É<Ö¥¶1KvÊæ0HÜHÇ­ éKªYÉ!Ú.A;sxÿ =+"KÉ#¹¸UÌP¾Ö}»vó_?<î.RQºù[ô<yæOMRCiö©#[¨ÕW,Ã Æ?´4{ÌUm:+vÞ\}xùeaÇºõ«ÚµÇÙmíÓ&m¤³¯Fcéë^}LéÆ¢¦ýå§á}}_SXé½«C
'32ÄËM£nÖµ^{Í2),üdRÀîè=~BÝfì¢,P3ç?Ö´TKËâ5\?Ä~µñu¥R=R×Óµº¼å%wéä>ZtÒ%ã'¼OZÕ­L |ÁN}9¤XI<«DeyçÕH 'Èv Ù9Ç½{j¥X§ì¹·vëÜõJ±Oo¿¯qá²pIqÉô¦TApA§\ÙÄGmv²mÀàyÇëN°ó¢gûJ­ÒSÆUÎ)êïÏ©T±ê.ÒÖäTSæ)çC× ÎsM
IÀìB¤ecÔHÉ\J(<QVXQE QE QE% QE
ZJ(h¤¢J(EP2å½¤mf×rIÂ><¼ãN3Û­M¯ÚØÅtFæ{GàÀ þf¨FªË#1 " u'ÒÂöÿ jóNÌ?r=»WiÕ´ª=w],ÿ á¿ÈÆÔ9ZRzïécsPµLð´¢X¤Iñ, j¾®jpéòèé46Èã÷ùË«zc½g\Þ¬AÈ#Û»ÀÇN·ñÝÅ:<±GÂ$ÞHË¾oIJ*F­·Ñ¾Í¥¡äT½Èºom®gÝéwåÂFý¡ÇBkr;kË«¯Ý^@ È2]°ß§^)-#XíìàóYnTí\ý¹ªQÇ}nÑ+©¶òßr8Æ<wí\s¼ãËuÌ$´Ð]f¨/dñcóxíçòªªÍ$ûI7¢{é4´Ä¶£s}/YgvÀyÆGCÞ¬i¶:ÅÅÂ\>ä\ã* ÀüóY¼Z§Wtì;-ÎY¶ÓÍë(î$·d	 V¿sÅPOµ¾ÌqØy
?È­=\ý³\ÑBV0±ÈÃ(Ïÿ Æ¢Ó4´-ÃNn¿Óñ¯S I=wêßùR«+Þú?ÄÙ³Ð|Ý>	bÒ$c¶1æ	ÏEÁäõ¨·¨Ék v m-¼ã8¾µ6©¶¬Á4ÄÏRHå8Î:iu=Uu}Zîö+o²¡uu]£¨ úgñ©¡BØ%w7ó¾ë«EBæSKúìU¶+k(gPvtZÂèÛÝK'ÙÑÄñÙyÏ¥F[nifó %GSý*$ËFÄ)ds_MWòiÇÞ²ZíoOÀö'IU­ïinÖôüRÿ hp_¼ySM¢½HGZ÷=GZ÷J*Ê( ¢( ¢( ¢( ¢r-ó¶Õîje%Í-4¶VãÚk	%p2e\zã¯­6óLL¹)<v7ç¨È>ÕRÝK*DJ¹`}?É¯=b)ÖjÞÉ}Ç
¯
Ê5/kZY½Üæ8ùsÇZÓ÷®¨	
O½"»ÄäÆä³kkÚË<ô$9ÇÝ§ô¥ÄO	jß2vI}ýJ¯VxuÏ{§ÐËÞ)¦t3ÀÃ~=jÜþv·§[ÙXØº_¼G%½1ýj(#K«UVã¦vg'==êÊÞK¤´AÜ«o2côõ5òÜELBÖéÝ+½¶ùëÐð15]fäýJRi°[Y½Y>Ýä·PqÜc54wwÚ¶eep¦DRªt\ç"¶5Èl'Ô-rZÙÜ´ÈËÈÈþu8±û±ÅëÉ¶]Ü!;9÷ãó¯5N3dþ-õé¿õù(¤ô%Ð5Û]#Ä-
êÑ´©ìlne&9Æ	ç85wWB$µX$ãÌä7'Ö¶íe·±Í|h
ó=ñéõ©.RÆYÚ|Ëåäù'9ÏÑíyf¡%?2lC¢hPj7°Çsu±ÇÌ%lg¿Z³¥Ý¸´]*I£Kæ'í1íÜÜr_Ò³HC(D{¥]eoºÞµgTiÄÈvphÏËÏJÊqr¥ªé~cZ"Þ§áÛ­>;s
³°º]¸:¡=uQz??@£QÁëÑX@ëM,8
CÎè*=*âK5¹´w2.íÊ9ÈéÇã[:q­M2	bÅÔH2O tüké¿µ¨ÂÕeoîÓÌ"â¾\ÀFä¶~`½9=è­=wAºÐµ_±\\@îFñåÎª]Wlq¼òF:
Û
½?i+ÉrßD·ºzÞßâxª¤9åwîôKõ±QBÇá~¾Ði÷PÚ[Ém:í¶¹¸«r:g\VzßXÉ%Gýè)´í;ô#n£
þÙöÚ!'Ç^
XÇ<D£
«Ý{yõ]wùte×ê8©­:y¸¿kmöË#CÉcØq­%ÝûÛ¡7t¾sÿ Öö¥ÔÌWpÇ%¿Ì¬H òryÿ >Ý"EOìÛ7[2Øô¯âéÅ¨í¿_ÃcÊÄIIFËcr+´Õ"¹õDò¬BEö`~uÎÚ1³	d´V._(À·èkv}*ßCØZMþ±âbÀ/n¼TÜY¾©mod«le~WhÎÝÐ÷ú×JªMò+Å¯±»âÝR×^ÒVòÓH[sÈw1ª° tªºÑ®´hfÝ¡»µÉxëÎy5¤ÐµÕÃ+mµG*®8ÈÀÉ4í;ÃzVöá¨LfMX¼Ò	_Q2k9T§
~É]Yém[_Óù®S±¿¶²¼[yôï2ÌîáA
< °uÍo[Úö¾º?S9+´[H¼:ÛYKl<÷_2B$ÀÇLV×:d¶¢;UÑÁÜ'x}{sUï5[©g»E?i|ôÆQ}9íV..o<CS²­¼DI" S 8Ï<ñÒµ©NµNXÔµºúØ§Öu6á¬ky4ÛM8I»)f`\1MH¡[Ö2´ `îçvö«æy+rñÍC+¡Xç°r}ëÓ§Ó§Ý
c¤ßÈN¾Ì	kHå#úIõ)Z~`S;¶³Jt#3*Gü÷Ç£9ÅT¸È169*ã+ÀóJx:¤æZ.ïô6Ò3Ý-/&¾¹ûT÷d»Û\Õ+Æï¥yâ	!?¥X¼G±]2 lvaCU'KL¹öÅ{m9Ô¶\­+wÿ ëäÏKÎ\óJÖ#¢+Ý=p¢J@-PEP ¢(Vumhîb,­§ëTbË*  8É­oìøíì®cªáº×Ô à¨U»çÑ[_Á«IER©{ËEbÜMkgzo±%Õtßµw`vüªKÌ³I¥jp=2á·¶#Ë*ýÞ½k2Áîe°Ö(ÑÌd¶
?úÕwRµÝcx·^PÇçqN+ä±og]áçy'÷ù5ç~§R¥7KV³Û½Ä«kæmíä³õeíÚ%,ßädV¾¬±ux¬¢%UÊi2Ù¼sUß°¼ºÚ3!RBçn89õïW,V.TÕ¬»þdÔ­QÃÙÄÊ½Xí&6äJbàùq°Î>¸«o£CîÖIÅ³±¼¬§Ðà
§mfÃT]KPºPùQ¢òyã>é÷·2FßfÝ9ãÊVP ,y=}`ÔÕ£÷ÿ Àô9ÒGB'ißÙQªJé$éÎ =oÿ Ud¦r÷6³L¬²!Þ¼¸­Áhl¬âI"7°&Ù
KË 1ÓzWAæ¡y7ë0±<óßÿ yõoJ>ÒÑÞ÷Ó_ø,Ù£Õo$û7öyThE§56·þóyG&F9`¼à¹µf§ç[¶Hü0íEfiºhÁ$/k,bÀÌyÀ#ö«·IòòÁ+Ýy_K¿òùQ³Ü¿.5­ü	s#Jdà
59gmeø]}O=FmIõ41Q!¸'®*[$êòù°ÌÁÛ?R	Ëòs\ýïCúRÆ²ÚHdürØè1ØÖ¢êÑär³èÍaO²v"Ôôhî%kÚR»£ß8ëÚªi,Õtæ¶ËsbÇds1È­ëûo
Æò" |Ù5gh>Ë,SL§ç,Ñ6ÍüÍqÑ ù1îúÛ±ÎáÊìËzx²¼¸óJ«D¡1ÁëVøÑôÒ4Ço']L¯Ç9 Ï|w®æÊM-öËÌI$å¢Iük§ðÆ¹nº¬Wr.!ÚõSüë8óSwqí»ò3M6ZÔ Õ¬n[Nh¢e\>p=jÇMutÝbÔ´Â
ü5ÒJ¥ªFÅ÷H,Æ·Ó,íï&¿½)4£ð8ÕWVÖÝáÊêkI®Y%åÌöVÆÞ9]deÀ°1î;yâ}=ÒkëÛåÇhóÎAÇN?Ä¶¶ûmëC¾]¹O5Ü!`kZÒÆÖÒ/´É ºTù[i<þTN§u%Ý7}4¿ë¿ÜiîJ*ÏSU¿¤±ºî&
À9 Åû£6õùnÌsÓ¯ÒòÆö!¦G?JÐÒ4¶¾2ÌÛ|¨yÇõü«ªUèÒ¦¥=NRb®­c0:Jµ¨^-ÝÑ+
Æ ÀÐÕZí£QÎ³ìuÓn÷
)(­M¢ (¢B
(¢
(¢Fãç]©]húEÊº³Ü*¡?x3þ5È$Ô¨;¿Jè­/-4ûEóæO:,á[xü«ç³ºu«rSäæ{-ß[ùY£ÊÌYN1åº}·Ûð3î'´ËÙÂ#±¸õ9­i±¼³_ÚmØîTöÇé\Á¼ÌÆ ÅuZ4WgJ[ÈnÊÜIª¦Óßò®<ÞÕpVOG½Ýû?ÔÃAÑq~LÅÜ^jó¥¡Vra¾	Àúô­Kè¡Òôeí/¥;d·.+ýî©ÞÒ}QmBE0È8%ÀÎ>¤*¦§âhõ
½¨è/§i-^ùÒ³+°Aò°È9ÍI¬ø)tx-,dqº=©9 sÅaÅb±q§gk7gÑ~]É£*õRÕ\æÞA¸;7ô¨êGY#XÝÉEû£Ò£¯¨¡	Â»=0#i;°¢+cP¢( ¢ Z)( ¢
UVs¼RTÊbü§÷2nÏqJöÓsJÇHT¾Ì,jïî{ÔVZöàÛ±R7q=*[^E¹tÂÐÃ*(£¯çøU½K0D$HË¶c'êq^%véÓLUv´zÛªwß_æÔN0s«­ö]JW°ÌÐ$wA8Ëzóø~UHD³,a=}ë¯ÒíÚúDÔo×íñJ£AÏðýMGâk6æy¬#û>]Z%fÎàzàkó×X7{{­·ûû´«s¿dµwéý3'Iiz¼R\)mª]qÐú«_ûjòóJ¿¸Ó- 9ê§xÈü«Ôµo·¥¢¤"A	RrÇ * 'DÑ	FÇ,¹àïþËx¸s«|¬÷Zîÿ ±a';Jo]
Ôß"zÉ}×Ó»×Q<J¶­}ÈaÜ©q§Þ4ð\m¶wÍc óÖ§º½îESóªÜ:éUëÞÁa%AÊR´èü6TmïÐ(¢»Î±h¤¢J( ¢BJ(h¢QE :9)RE?2Ãê+¥ÿ Ýü7<Å¿Q±æÆ7g<{q\ÅÍÂRÄ8ºX´×Ëôò2©J,åÐ´ºÚ)TIÓ4íGS¹Õ.k§ê»F NÕQ¦¤¤¢®pºAEVV4U
ðÚ4aØÚ¹½M.qöÆ7õORñ¶úÛZÜy¨r98¨.îI9Rü\,¬ÃåúWÔöç³9p*ªObZ*5wmÄ*²¯R­~TäueXí_OKN¯Àî{´ëÓ©ð;¢+cP¢( ¢( ¢) QE QIE
(¢QL( ( ( )É*BáÞ&à\sùÔN|rµÉ¹bäZ²Ó¥½ÜÀáAº(¨N§¤ÚÉµ öEÈ$ð¬{qüé³Þ\ÞGÄ6å'OÆ¢
`  ¯;Øb1>õYr®Ëõ8}lF³|«°Ïím\Ö-cäÂ²õ(#ÝüÒóIÜÖÅbëH"^ùþªàéP£'«3¯§FÕ¦Ø[Íhîã{HéKd}éRÚ>qÊ´, Ö±Æ8ÉúÔ²EË¶DVfªYzÇiõ*1[I¾¨¸ÓäÆàÊßwëM·).ê2çcÿ ëÕhÞ!N§¬yàÖÌ»5[1¨Û Vé4]Ôý+¹*F+é%úÂ,Ô*®WÑ£>(¯pö( ( ( ( ( ¢¾¥ÿ yáú Úß'ükÃ>(iv:7f³Ó­ÚÜCÓ $s\T1­.T*ØÖ*GEvt«gÆi¨ÚÇsn`oÓ#5î
Ão$iÑFÐk®¨K*K©Õ	©ÅIu*
*æ¦\ë}¸¶ ?Lÿ JöàÕ¥·ÕÃ\\,,ÂðN;õ'ô¬+b!KâzVÄÓ£ñ=O¢×ðß®üO¬&fUde,YºÉýkYIE]JJ*ìÈ¢½_öî¬ôËË¥¨#ð#ü«ÎêiÕON¬*|,û.¼âÃ-sÅ*S°Å h F
ùßÅ<ÕüYkoo¨ÂÂÅ6Î:Â¾ð_üúýxCÿ  
1P©QUÝÃ
£QÝÜðß?òPîë_ú
pQvºZ|ð¡XÖà>:ùäþç^:øaqá{vÔlçûEÆàTùä{×¤Ú|:¼Ñ5	¯´MvtbÅãæC^æ¸¿iÞ=±±¯5»ÓOögm¡{îSÛð¥B¬ý¢J¥×8z³ö*^fÇÂOé7:5ä_í§+	Þ8éô5ë2Æ³Bñ>vº8ô5óÃoTÆN¡r¶3¶å'Ó­}|Ì}Ë)*ËGPpkle¾ó½Ì1°jûÎ÷ÛÐðï>Ðü+¢YÝiqLËså±yK
ÊúÞçÙóÆOù(Sÿ ×¼_Ê+ÊËÿ ò<¬¿øß!ßä Gÿ ^Òÿ !_E·Ý?J(£0þ7È3ã|ëê »?ô¶v,|¢2N{(®¬ËàÕü%ðâ*ê>"Ú ÄÄtôÂñïÇÆ6«´Y©<}æ¢çÂ¼/OÐçÂ¼/OÐê>ÿ ÈUÿ ¯¥ÿ ÐjÇÇ/ùì¿ëðè-E?÷ßßûïÌâ¾
Èí'ý{?ô¯]øHð¯ôvþF)âÿ ÞWÈ1ïKädü'þý¨ÏI$ÿ ÐÚ»ê(®LGñeêÎLGñ¥êÂ¹Ïÿ È­ÿ ×£ÑEE?zOã^§ð+þE­Oþ¿?öE§ürÿ bÇþ¾¿öSEÛÿ 1¿3·þc~g×Öÿ Bÿ ¯ôEÑ|:3?>§übÿ uÿ \"ÿ Ðkè?þA¶¿õÅ?¢æÅ§ùØ¯àÒôÿ #æoòQuúê¿úÖÿ Â­B÷ûGìßkÈ^yhéÛ8¢ë­þíEù¿Ýcè¿#èû£éY¾"PÞÔÃ GÙdàÿ ºh¢¼x|Hñ¡ñ#ç?òR´úîÿ úWÒÚün¿ëÿ #EÝÿ zÙñW§ùÑEíØQEÿÙÿÛ C ÿÛ CÿÂ  ± È ÿÄ              	
ÿÄ             	ÿÚ    ë¯¶{@  P    8Ù@ @  @P P@ O>~üòmÐjÆ"ìr¬;Q«VÀÃL|Ü·   8TPP  ¾u§*êÊW	ÃVcÍãZ,Ý;q;Çð¶K]ßíûIºc' EQ@ yI×9VÛRÁ X¬Hæ#häìÉl%¿EB+^çè([D¡-ï£ú "  (óikú»:<ó©jYLÅ<íÒSmm¬2ÐÖ^7·W¹SÄk©.üÓÞ×7G  @P 8°1gEãÙ»NNuÄ/ëÌtmQ±WR,¹Ù]ðøgÀÿ ¨<çÁxòÍÖW>}4~Õ dÈ 	å@WÚöÕ^Àó,+Ýå
ùÅÚ7"³q«åç2V¦Ñ=c¬ºîåhsÉúõ7k@/;
ÂÀ:þÏut @ 8ø@Q@ P1©¿!PÄj-M­ûcGÞMÑl}ìyê     	ÇÏPP  É©kLJÄûllRôå1qÛ×MUXÍ÷ÝØì¹Ø   nL6¦	ÙEbÍ$³fÎ (  Dâ1	dº`Ô@ 5ìJË5fää 1ÓÓnm{-ãþ:òkÔýWéÇy§¡Ò÷«Ý,VöøÞÝ¡ ßÞÌæ»¯
ÂpÔ`Ó ä6?fZ0VE`lüv«T¸¢0P!DÃvSnjýý¸22M1°Í*ÐK_(÷MâjòqjJtXb®YPïì5Mö
ÛK	µÝK:ÂFû½¥í}¤ô¤ ºìùWÆ®ñ #:·«Î:õñ,Z
¸ìÆEJZ£S,#í ûµ9WÇÑF¬¼Èd~Y7Ç³§¡×çõqNÝjß>°<Û<0µxF<ûCµÃ "¸é'hR
yVO6°"®-%&ä8·NÄÐé³ê6`2ÉÈÛci¶Äá¶¡ÌCºÀ<^<]úê÷õ
éTÀégð÷ÿ g¸
ÜÌ#ÿ ½LÕå¾¡ëÅGC¡CÉ·áÅÎD¨Ö2:+ÒáIS(aæ,ÅøX9"Ò=#ÇIÉM÷ÓI5SÏ/Ñ7³ü}åßÜÊM±^bÂ`d\'ÜÉÉD¨ñý¾÷Õªc¤°ñW_vê/ìþòT!È'·äQäN,²qÔ®¹^ëéxÂþîÃ·~F	Å·þE¬,ê·Ûÿ $YC±võÉUá*!ãÝ¸ò®|'q¢"äo{uþ¡uÏÿ ¼yV;~äk8»läµPøñç!<qTjO PñÃ%bÈ:,X×òz\ÀFËÆ¶æÏ}Æ×pûý?q/l%ÎÃ»äÇ¼|«/L¹Tãå?ÈëØüZê(÷ñW_ë¢W»¸ØÇ¨Ö9¬\#|{Ú7]Äþc?ÒºÕv­s¢²Üywº°-M6Õq±Ý-³ØÒÅ$²M'|yÈÿ !½øo>#íSä.íÿ àíkãùCáÌä/=|K×#üyÚ7]ÕüÚ÷ýþ»ùSþ<ñÿÄ P     !1"A2Qaq#B¡ $0356Rrs±²@TbÁðCD¢³ÂÃÑÒá%7tñÿÚ ?ü0}<¦±xÜH;Hí?Í¤¡%k0óHh¾µ &gHÞgËÛgcÍ¶í;É_0( 	XNöñßË4¾×­0¦iÔrÜ)ImI ©2|R üáíÿ I_}P1Ñ8´T<½bÄÖQ&LOÓ1ubxíº¼¶ïzúªA*L¢áb°ÚAN¶êuIv¶ÓJë©ªHI"â¤¹2ìÊ6¥smD0`ïþ;íüË¸ï¨äIaÖIXR¡=Õiëí5ÚÒ2ÿ -
Pn2].6¦ü"N ÍÃeDo8ªâÿ Ø¯£×âBB¾tç®qYTTÓ3¨PUi(P¥$®6Ð¤D\DÁÅ0¥BÍ*

¸6ólýfm¸Á®R@X½)¼§º|
 ~l'{zÍT:©äÀBQD$O}bÀa-%E³¦³ÎÓÿ 2
Jí×JAÞ%7,³ikÜnºìRÊ9Ë#±q6·)nù)¸¢fáé½	f\*2Oy>g¿¿¿¿æ;-,vú4ÿ cRHð¤tÓA¦¸¨©M+í¶p2´týXeÇjâêãC:påeb)§ERÐÀ2¤
Õ­O¬BÈPlÔô§¶ÀÅofRÑ:¶.'Cå;OÓø.#ÎånWt+XnýDUÞ6öáßQâ¦ië]æ´³ 2à]¨ n¥$Ln'ç
ãÈÛ®c.«aöw¡¾H ÀØ±tùè£@)["=Ài§ÙñRÛn?xíôÍÅ3#´~)BMÀuOÿ ¸¯¡õúoT.Lj7Î2úÆêé~Q¨>d
%õØmBHë
M³x?á'=6VÎ^â³wTnJ`Ú¤+H²§rz`âÛ/U:sÕå)uiJR¶ËIëYR¾rMÂþT(°BN§&VÖK5·À!!72Àñä¹e%];u1V*UÐ|¡¼j4×IÆCÄ4yHÙ
Î·ÓØyÌâ¹91üº[-¥!"uV×¦R©e@D©:çÙ­NlPõæÀSä£ ®vU³áùØf±-UµGQªÊJí=]ö1Ý¶ÓSµ¦]@nëÔ#Ì :	tï¦É}¤>Ò¥*÷·Ü¸Æafõ*è¼rú6ÆÉPT@#¼pB¬ïÈO-[(¡(ê:ùwÂ*¦¡»º3$inL} t8 ®i¯XËÝ@PtÐOJ¨ðëôîpÍU¹òUpJÛC/Â¥ÜGRBT
IÊG\ª\ÅÊe;Ë§VR¢àÍªP

iTÁ1n¥TLÔS8QFQêëi(RDÊvö¦×HÛáN'î3³:²çÔBII´Á¼Úcx'$ôbÝesÕI]KÄ¥µ8 [Ô´Î§©](4ÇðK4¹Í´íE7.åh¯kh¢H~rbÝqÄuY&TÆZ[KXKéOEÃ¥Fzn¨×´T¬)×uCKå¸¨YA"ÅMòN¶¨êFKú³¿åuè(¬B\w
£«	ZaÔÊÒW'Ù±·HBJS+¸ojòêÐHÕ;¨I'_ê	YH	êÐÁs./CüÈ±[n#RmÞØ×^úyÊZR>!ª`Û;÷Ó÷÷Âx#Pâ*«)OÅn5ÉÔ¨o`X27V±Ø,m,õ|è9Âp@l%*]Êt7k{ÃfÄª/@'¶3ÌÚ+z¡½ÝÐ¢DÁZi2M°5¶(Ý[´:äÜR¢£¸ì|ÇlOà*x|;ù6BB.m®-N¥*1 Ißò¶ÚÍÌ+Ô¥Ò¸<
*(æ'T§õg®ÉÖÕ{°ý*hyÜ¤9~á^# Rí0à
l¹A@õEbóZ¥!56-(X¸ªÓ%N\a^HBcld¾³2ºå)-ZJãQÐT(UÌ¸+ôg¥xÎr¼oúÕè§¦a
.¥FulJTd(»p·¸ò§zÃ4óÍzÃ/R$¤%Å®Ä$­Rÿ SiÐ¥úÃEi¡¦4Û}p9V#éþì%¥HHnãÛî|d|SQOXíg$¥¥Ä$¬¥÷ÖdÌ:ÌÞ{ôÆT¬¿ÖÐÅJLr×EÄé:)ÀÆMVæôôo £cm({À"}ã!U]ÂÈg(âòÚ|¬´I*
«E$û~ªª:î®TÊu³c)(IaK\.Å)IQJ´06Åy·FÌ©IZNËRèAT5³uh±CUf/ÓçN)ÏT+-XÀv[¿(£nÃÈãu}Ìâq8qßQWU¤(²n#å¡f|>Í~òc0¥_!Þ}Ë%°&u¥&ôGn¢¤¤â·5ÌTÊ3:~HmnZ¡Ka/$AºÔ÷JÎ§Å# -L+Ú¥ç¶Ò 1:á§23;gmKÆT#ÂB¢í/·¨@>ÒÇq^]åmRVk¨©@rfâ-LÁ¿p²IÚx$É¥dÔÛÕW¤&tRoNä¦ÕZ¹;¨d=8àì²»3ÌÝk+úQ)\Lu¡*ÓÌ ª&u¡ ²::)ªrVË É*ó88Y5k«m¢¥]PÚ$é°:vgõJ¦â&3t³4´z:Gbè½´«Þ<´âÒ½Z¬­Ô8[Zôæ¶¦Ö¶QBFÎ*ø«Ë¢R
éB¤»ÔN Ô©Ò{¤#Ò}FVý1/t	;J5tÈÌ{+²õÐ8/½N:»Qt$ÚRO+tþhN'îø³²-¦b°ÛCé}VtóIIJõ¤IßM#|U/&á6é(RÃ=@)E)¥7.z>gI;c²!â<áª.EòÑJ
Ð
ºz»Î8cr¿v½°òR¤«r@Ö&Î¥¾jdøkò`ù¥
î}÷úçòU	X/T¥GO!08·1ÌZÌ²üêÓFR¢VJR`o²®À"Ãá>e»kÕiùKûAQ½6ó$yj<<'ä<=´ BÒ¤é)LnwØ $o~ÝÞ¯Ï^v5«p¶$¥ZBÂ¬XUn¾xã¬Å
­o.¤m*qÁjéùï!gÂ@&é#AÚAÅ
6ßÊ²îKm[R¿~»	PI0
UvÚâ*ó'¨³zÛÔá.ÚD¤¶«· ¤@	·IS+DÂ¨
\\Rs-¢¹ßÇnßF+=å5¢s6T¤uó±_³ºDê 4#M0Õj·ôUO5U^A	úÉ?ðàÌi¾3JPæK^RNªmµÞaD%+êJtMÀvÆKGYSJxYSm2ç)N·"ÑxXæ`¸±w0%F+TÂCÃ5u^][ú#V<ËIÜÆ!IZ¿Wm-e~j¨5nT¦þ[ÐwVÖ&?KêÔ2^«{1¢D<ìN²¢'P5>Ó¤í÷sÄâq83À´í×Ô¡j½Æìå÷¸R=È Bº BDøxTRÑ¥µó9¤EÊ17y ÆßYÇ¯­ÑÝDý¸ôR¡÷ò?gÿ ÁÄù%I²»O®-Aµ8wCk&å§Ú	ÔUlFÊ2VrÒ²TCdìËT~±¾ÀÃàN'ÄüüÆW¸á¢#Ïßõqú)ýÿ OÜN'Äâq8zAÏ~+ÉUHÂ¾]îæóÕÓý¬#¤upG5g!u*¶Ájð ÷ò'¹æM\ï"©µ¯É*ýXN'Äþ2Í(rcW^å©ûIò¹Åg¤¼Þ²¡Ldtý;µû û ûÎ)¸O8¼TæhR¼N9¸Äïî»¦PÅ?üAHTQÌJ1:Äös¦õÇðªøf±!¢¥S/Â£çÝ&4ãiã! Í©Á£Ì9uàèA=­X;ý³=1®8B»¹®e\DÂºßX¶áÒ¯0F»ÏàçÄâq8N*8+0Ï3æ<EP9 PðöbßlI>x¦¦¥¢dSÒ6ØpuÍxÂ¿<¨Õ--QúÊ$© ýy¦*Z,Ô )pDïÿ £'.¯È	iñ­0åú'ì÷oâæí+-Ì4«kyùÑ¡þÐùß_N'Äâq?ù@á/éì9ÿ f'qÂô¥¨© c`ìßÕ,ÕÓ¢ªÊóH:ëÄâ~äê#Ã®ðæ^¶jTêÕ&6ý~8«:n²ÁëèÇÝ ¤d¼ñqQòþ4vËæÞ*b'ÂÆUeÙÕ9ªË½ Û0¡¬ó=Æ'ÅNcEF¦Ûªt%K!)ê¢L ¿êïÄâ~åÿ Ngÿ µõÆ|ãog´ R]p5 ùa<EIÃ1ÔV¶µ!M6: 0y`ë*NúÇ»?Åw}D(âBÌD)^XÎ¸ï'ÈëÕU!Å-16¨ê½¬âÜ¾%c=}·9N Ý¨Q¢Oq=!pëÔj¬qJ@!@\£ì	*ÓÌÆ[ÇÜ=ÔT-HYÐ^ ¤=ÓcÇü9<X.7°OÛ }¸Ëý ðæ`ðc[QÚñëôÊ¶èhÝ®wT6£ÂDéH¹
QÝD%@é'êØc ÏèøU´IPHQOP È ö'MqÅtôïg¯<óì¸òNº¶h=@7=õ8áGZébëH>5\¡Ôt»Idÿ V>äDÿ m¿ûñPÃ´µ¥|BÐJHò ÁÛMðîV3b¾Ce?¬>½½Ç3Pâ4°¿  û÷h§ÜÎ"â·×ù×`~¬À?Bqé-¦Øáªvº=Áµp
Ø·ü_íòûÌp/ç]'öÿ Ý«? 3ûdÿ ôSøÊïsñãÒoç
?dâ^3_ý´¡ý§÷»ððæiþ»ýÊqÀßTõ¾ü¿Cûfÿ cÒ¿úúßùxô_ùïÛ+øÇ¤ÏÄ·ðz;üØoõûñÃßèlßñ¸ÿÄ R    !"1A2#Qa 035BRqs¡²6Cr$@DTb¢±³ÃÑ%&47tÁÂÒðÿÚ ?ürÔ@Ó52¸2.	\|c>àÊ]Î âZ ª§p±(ÜX($  êO8§ÔZÊxjhjREKEµóõ&>½ØõÇ®i±5];ÁNÊÅÞRªbe#
ê{ÙHÁN/^*KOYk¦°Û%*ªVìjúÉqÉ0r@^¸ÉnJnpø«
£WmíQäVïR½Ã'õrN8ûþ´ÖÇµhäü ¥i)åòcq!pw	Tc%J
oÊ`2ª®åb»»·\ý"}?Kx³ÖØ~ø`·ÑóayR^X8Û2.Ç¼N`TÃ©ë"Dm=º§ÐçAòê~³4·×¯DG21}GPR9Aò1~ÜbÇf¹Ô·­_¦këªd0ÉN«ÌHà2T2²´D±@ù
Ûê8º^hí
xvÁ¹bwÉ]íïyzþýKM
(¤Ò¬	&PÆfBÈÆPpØ÷ÄRlÕß|t:uÉ-W2h \ ËÙP~P,{Â$ÜñCrjýJºkY(123Ä1[çIæcÖMìýÒu^.uÔõkk°UDÓ{>õA&	<6V
W*Ië»Ô5v ¹è`«Dxbm\&$
`FÙ6£¼
»HXIHÙNcs"1nb®F{ÜÊ%â=QjÓÔjX½­é$h¡XZ'È¼7þå²GËË¾>ÁÏàkaÕ5O{iv¶öÁfR.ª_*<Õ·`qiºÒÖÃ
Ò-;DwróÊïes¾½iÆáçÄ÷OÆ¶ßª¡:xãÌuèª§«(ÊÙ@Ø;	OOn(®ÚJ¿OKtzçÀ¤»Ü`d`÷cÈy¦§RÚad4Ò*wBGs¨U}Ö_|÷¯^)týfBªÆâVFèølÀèX2ÍÅö[j-T5Í
Î1æJ¨8,RÇ ´Ë×ÒëAJ?-}|730Í+³å¤b\õ@£wÏÓñÄx 47ÚUÛëýùD÷¦*j
<K"ý£ÞW8XàáÛEMº·W
abp{UàvÈTå03¦®7C{×~²´vÐÏ¶aPsDÝ­±0vçzáo²ÏKt²Öé­EH³,À
¹~r®YpS<ó×Ã:Ëæ¼Uiïøå4â9
H»g;ÙrÛEGÆá)bø@Xh;5-£QÔÀ=lÑò**Dk!& Ç$¿'&ÐëQËè}PÆÆ&ÂãÃZ¹n¶:{
IKD¢H}zuX¤VÃÒ@«!Æ?u·Ew¶Ïk¨fXåRQ¶¶`íaÔz£ÓáõÂHkkÞ¬IW9)ÊÛXÆ4ýÍÜÃ;wÂv5vÉõ£M4Û6{ÛÎ,ægI	,²6õUrÀÜµN_Q­*,6§KmJËÑ$ÊÁ%u(#Y{$`Ça=FãÅU¾Óh·|Z¬^ªÉ/.C²w$oo6Á\áÓóeMA¬*#b¥`Ý	åIæÈe!6U¸y4Ë^!ªØqKJ*¹ .YäúgèxÕBëvå¦ë<\ØåÃ[ª<ª+H ÜpVË.ôc´õYKt·[HX§£«,Ï 2IÙÐà dvXâÁ©íKm5®´72=Ê$ ¹rîVîRWÌtÇJ:`ht»YWsª»©Á#¨û8·Òë{Ýî_µ<ûgçBñ´QÏP¥7çäBU0ªU3	:bÙ5Æynºz·GM2&Â$)À.ó°AU!,¥
²y²³Ò××üqY<±Jôø#RÌåeS¬¼²Ê]OPÀ-»?ÜÇ[-Æ²xd[§ÞDïtÚ7Ä$æ¶BË&:Y ;x±Z¤¿@ÔJ½±/*F.õB°\Bá»²ó#Û=qÅöºíCg±;YyØ Ø22#vç$íÀëåÅ5$RÉÅA9=G¨ô?8ôü,ñ3ÅEe¿¶ ¡"DÜ3·lÒüÊÀ(ÃNsÇÝf¤ÓºÂÄ-KY3Y9Ed¦of+«Gº?Ò\ü³.í¸úcÕpÑSQ¾Íxå$2
r]@êsÆxÏü/5Õ%Ê£Z$zjTÀRØBVGG@Äà¸ãqÙçá6°ÀlurUR/ýdXb´ddNdb1!lo2Æ¼x©}ÕÕ÷j=9[ÔPÒÖoE«\Bë(Û3B%ÙUÞÊ_Èxâe=,R,Q¤pÇRícß.çå0Ãî\É
wù2±4·zoN[¡´WÊ«´ÓÌÅTÀì\©¹ `ä$glÁÕv}9K:ÜæëKÆ¨ND.émJ°Y2¥O¾¬9°l¨æ7\dñáUñs¿NjëàäÀæÂc#«DÎ9°ØÈÈ¨°PVÃIo"E´Yw6	;n$ñpû|#¹]Ö{{+i
: ì-Úv·-{|R»I<jdUÑê$u%¿"b<Ç´ ]ÊIå.ÂØôo£¦­»Ð×RÓVZ¤ILNKôæ£tvxÁ@Ü2½	Î^/^1Ú Ôzö¿i¸8ÛBM®võ2îzÝ#0ÀRØ¼Vøëu²iª¸%³É-|rÆRd\í;
É0Ûj1ÉRé¤.WåÓÓÛ+ÙX¦Mò¼ÏM'|jUaWnpCy×Øµí
À*¶%}Ç, ì«¥ÐzæÃ
ªÇ$g,Á6åC¶bYa¤Q±dXÓl"íÄÀ{áF
ý?GN+<ÓRêµÕvùæÞÑ,Hç,¸À={IÁìp ÀÀãQf±¢?Hû8û Ïr®ýU?õ?Ãoñàç¾|\î^^M7pxÅdc{CÜ+0Xå!NÑ¸«ÚÅ[=¼ZmµuÔm£ã
2~O,»é_tÎ¯ª¼Z©ÂTÔí2ä
:MPÒ¶æÞÉ¼VY>U!uðkÃ[ÅeÂªÕ¤UFÊ6ü¨ÁîÇ¼JÒFqçñ3Æ©Ou_BXý¤ñ÷:6)î±~äÿ ½ã<kí)t5TúBÑAñ¼<µ¾:Gv2´}Ã½Kg=NÜ®;x²Ù#³Ak!gÇ-Ü°@réýAøñ3øÈ±úºiZfyq÷=Á4U·qÐ¢3|ü<ñ3ÆxÏágñ3ÇZâM<ðÂàM7oP¿¦ßgOÚx®T«¨D qoO£¯M¥õËá`v¸ÇÍî·ÔqI~³\%äPÕFïó+©?fxÏüF?xÏâó|µØ(ZãvGùý~=OÐ8«ñ[U]å)¥hÄ}ÖpYÏÌv©Àé×x@ëSsJÍBí´à±pú¾gè qq°ÐÑj£e¡S·q»»h>y8×:FM9T$¥^dL;Y¼óê¤_QåûjÇf¿@©I]ì×u=#nÜ·¦ÆÝÝ£¸~¯¯"ã¬EDÖ]ULÝ+7£ui>Dú=Ïã<gñÁÏüEWUzþ÷}YS¾~N$Î!×Ë>m}x¥¥¦¢SÒFàÑôé««¯sõ;cûLHbü8j#0Ô d>`õ5WÖËmWgù9ÇUË#õO®<º><?Ö{
[§ÒqÅ·^éëH¥FdcÐoë¾ÇÁq×ºvÝ)Èdaç°gøäãÅ¿_éÊùD;Ìl|·´ÖGQÑQË[/TE,qçéÅvé0èKÁqûüÃO}gh½×{}ýOUéëæ{óýï£þqÇ?z|yÎþ³o+gùÝ¿êÆ>4Äÿ Iñ/3Ì9æíÝ»j~¯LcNsÅË^éëlæ¹ÀûIì<Qø§*å9xóêàcí±ÅóPQX(¾¨3#0Q³Ì¤`qIt^`ºÜ¤Ì|Ø`zgøzqb¿ÑêF­¢V
ovÈ úóñª §û4ÓOBü²¼lh= Ã¯¯SÆ)¬ÒÁ»iß;wºd%ÿ 7Þ«ÿ %ÿ ^?ÿ |TA-,ïK8Ã¡*GÌAÁòâK_Ç
 ;ùþÐ@GÛåû\=Q,îÊ
}~cø}|Ws5©bþ¶\ìç ýJ8ñ&$MÓÁÂ¬ªìühM9E~ªîcÜã%³ê:ôÁòãXÙiìWKIù6PÀLäc?´qt¿Õsè+ü¬¸_Ò
~Ï³´Ø/6h) æÒ.
w7¦GsÓ$`ùyc§x"ª»ÒÒÎ2")8,òâÙi·Ù 4¶Øö!;±zàÒ'æT[­õ®r?YAÿ háUQB À üÿ ]ûé?ñ§ÿ 0Pþæ?äQKcÿ Ä÷hoéU'íoän<OüÁïù$ãÂ¿ÊW~Èÿ ûñâ_ô?t¿Ìü]?îÖ÷üËðéèÏý7ûãCÿ Ji?k#|óýï£þqÇ¿âéáñáæ	¿|ßÉ%~J?ÃÏèÌÚöñ§ÿ ?Q~ú?çàñÿÄ X 	   !"12AQ#aq$0B3Rv´ @brs¡±ð%6c¢¥µÁÅÔá4CEPSduw³ÂÃÑÓñÿÚ  ?ÿ Ä TÈ×Lz"hÒÄ;y¦li[S#yQ¼9z§Nµ!Ósq$0· ßUoé¢ä)]ñZî
ßÅeé}¿xHZc\¦$¸6ã3# ú;ë}DTîaÑu_«w¹K±4Ô»Â¯©½Ôé´/ª½6zRH»N*ä¿hZZ9÷TpE?ÈºôEVç¿9D"£æÃï8ã8ª d#ÄQ,~«ñÔ¹2¥ÌîRØ¶7©¦â8àªXQ3+¸<WÇÉt<n º
C`çzlçrË½¿¯Ç®ªMFÈ¤äóO:faKVÞoèM&h^h%}Xò\±ä<oæ¾ñûðe«ò,ûD¨®Hol¡UÝPEÅ¾Þ_
ª*âDÛLÆë¾F
cèëÒdµy,´ûÉÇá.â¨(¸¹×/´Ìê¯U`Ýô»¬¥s1e	²û9',¶²¨êSìÔùµYógÌìWÚ6Ææeâ %ÑCBECël´Ü°§Ò\"öRÎ7=9¢¶ke;Xét¿oå1ªÎ|Æ=Ôî¥*Ù¸6m³,Râ^RÚr#	56ÊVd"¤ê&CâLrÅìú¦gÒÚÁ' ycÊÄI**¡¢^ÉêV¡ Dóý!ÌexdF¶ ÷qKõßRd3¥I#¼Ñn,Ut^òU¿¦Üÿ £B)öEÒÿ ©g)ÝÅÉbjÂsQß§[omG¢ÀXõ±ã9Ýö»q]pc²­üï©Ð%SfC`±ä°ûÜH¸NªäÌOïë·a£ÜôQÊC´à²ûÏ©ÝKªßç ÄdÚqdÀA²¢ªÝy1O/_»N{ÚaÓOá=BW¼6ºn¨¢+¾I®ÏÃ(Ë1ãjT©?KÐ«jN*°¹&dõ±4¶Â*©ê
µSbÑ¤¯A"àæ;¥÷D%ûKµújt&"
(ròâ"Eb]Q¡Ye®çÐÞ~1G%3CN7PÙRöÍV×['DMDv#.8®Êë\7ÂTÊùs"øvÛ¦ÿ UÁ½ÒË2³(ÑóBP·­×Ôzh)ûHäô+TèÀÛæR¹ÎÞK¯6
f»Ý=5
|¨ôB?g´(×uöÃ½%Î¹;ïä]rðâI­Ö¦R#%1	Å2xAyRÊ9"ð××tå¶¤Ë}¸åÙÞùì¹2¦5&C#ÈdÐU
ÂémU_¢71"ÝNT³ÝÅãZ7Aº
»muµÓ®½´øArJOÀJy°2º
ª §¯ÃÓMOZêý?»AxÍR4	bÄ7¥XBH¢
ôßhR¶1eTF?Ø¡w5eòåÿ Ó¨oÓFq$¹PZîAÄ9- â8SëÄm¾È¡/hå¸ý*¤ µ"ÝdR®N¶£t\³Q]¾ÍÖÖòëIÅhÝòF.û°q¸\ÝZÉËaÖå½Öúq©*YFeôøìÉâ4²ô[**uO©1Áo/ÏQcE±b´røÙ.Î;ðM^e¸ò°8"ã2ÙÛ<LöPTððü¯±c°óí,±iô(3qø.*cï¿]P&;"QL9js uàC+|×SZm^n,Xñ"³ áEk;2Ê
¯2´6ÝVÞhºH°ÆY5:#ãÚã #®r {¼VÊIÏÕ/©ô×R5@âJrÔ7é4×IáMÖÊ¸ô_³µ·¼ZLbh`Ò$0÷}£<üeµGVÜ­âH«|vOª?èÜh8G6
y¯M¾©^*	¸*£KõÓH1b{EÉ( }Ë¼J ¥ºy'ªíñ]J¥¼Er3èF(ÉÇÙnãdÙÙDG{¢%üüNB-î¹=ÇD{·¸AÂê+Ù/ÖËuÜtëHÝA¶Øø*dRõ5$1Ëÿ ­Ý¥ÍW$»ÞÄIÑmnê¥Ö¿M>ºªøÔös1wâa%±,xnù"§\n«téÓAe"¥g;àjqBul;"¦öóÓQ 5?ão½Û#¼E®:ôg·^eÉW+oÒöMEv£ aSõÿ #\L1å¿/[iá¥¸	
¢Ä8Ê8£4ÐÝrÅ:n¿éa9Waö*KÃÔÇÃ÷­p5Å"k4ô,h°`N²¥ÞáÙfÎÙ[~-qÖëé rxÒÇf¥¨
\ÿ »ñ/ËÙzßQøl¼²Nè2[QT^duûVè¨£dòÒ( ëïUAnÉYyt½®¶õÐRßzÅçå7/¼bcq0KzùõOÑõ1ÞïìSå6ãr"$_¤¨ª8(<Éé¿UO-Kr¡MÌ¤ÍiÖæÊ}Þ"Ü²MÊj|¯åªë©ì¹r$À$mÇ\F'SÝ±8rè¡âò\môÜIg$9>og»±÷Ú¬q¹q#¦CwGr¸ôô~¨Ü9C}Åaf¨?*q[4&)d(¶^¸üôãÁ
wCjä-¥¶URµ|[mñ¶¦Â1xØ(ñ
©±:78ã8_Ã½ï·.ú0íE
Ej2[N ÈþÄ61a²sÙÝÉÄ*yÆ«Ñc%1fÓ?$`X$×A!ä"MWò=>²-R3!9ù1ä4ý=ã³0.¸µ½¹¯lÿ ­5&¥*$·bR\ióîííï3;.X""Ûu/µS«È4Y¢FN§UìHÕx¨¼\UQy²½­ªÍ5þ?µ!Ô)ê.4d¸Ê)dK
Ù£Ó(_ãôUÉÑ{ÉQ7ùå×C
¨­U.©õ$Ó¦ãÅé½ú>ýN·3²ë$:{*» Àñ±ªx _¢®Ûj¡ø+Hö§²ø]ûéñ ð8üNã\ßçþ¥vìÉò!A¦;Û2hÆÐ²hÈ|MZ÷åýÅBE*2lzL'*59,²«-8fëåÙw[mÜÿ h}³ÿ ÊóüõØ¸Øz,¸½§GCJÄî6DÀÁwEEEém}Òé´JÈ¨©M&jòad6µ¾G|UB÷·ãT´¯?Jqub¿I}çÙgÄøÞ
ê7i)S{=·eªKÌ8F­X4¶BI×ì®«½§Ôû<U^ÏFrLÙ*BRÏã
g¦R`0Û]Ò.Hã"GªÚäEe_£Pëi¥Ê¦U·)O:ütlÝy¤EWÊìoª,8t.ÙÑtÙ.j;+ÙH=§§×_6¾Â &ìò]vò¥¨òZm×hðFÿ £³Â* ¥ÄEüaÞþÛ¿È5?ö}@ªÓÝï*pÚ¨AkËÀ6x!%ÄlHªítB}¾©Äªz,Wæ¾ÛÊ¾¸¡fÓRj9#³³¬´AºKî_²úbïÕ=é`ìOÒòñ$p¸ÎÌÞ5þ6»G>[ì©½.K«ÕÇ¨@3/Òªº¡1ÙÃf5J½!ÿ §½e,V£#Y`9¾.È»y U«×µ!T¤Myø-Ë&Á§Ì:"¨¼¶×EéÓUÚ)D¥vyÇ{M
þ 2îÇ~H¶Õø	}G÷=Ùú\ó}VmB»Ä5e´MF\%^ªi²'Çi}Ðfö~¥PÑaÏ «ÆoÑà&[$Têrèß²}Å¡b=o´´j÷±Á¶ÍÙàÛÖþ3üÍuZí,¸áGRáÇsÀÓyydd#,µLVN§Æ¦Êr_
rLÐÈ·Íßô®Þ~fU?b_tðWúË]QkOE¦ÌÆ9ñn©4ÝyÜQSOþöà7XýíÑ÷cs"äõÙERèIuð®½Bí·fûJäu#johi¯3\y£|U7_×rÕ~°o/gûa38»Ò"&\Riã÷$ÚµÎ­´ysuºä·ímVïwLìÌú'ðx/3×<IVÄ(¶$TÓ5^ÓÔ}§><1§´ÿ tb,¸à- ×ö¿6?h+tÝÆiµWà´çÌ@FóÎ®ºjã¸Jn8Kºª¯¯ßìæe/ö5ÛÏÏ:§íÏê©ÿ wW]¯þJ'íñuXüÌûu;]þV¥ýu7óªOìðõÛßÍÿ þ*Wßûÿ ÏrµÛä"þÝïvóó2©ûúû ÖZ£~fGý¶£ªòû~õOþÌÿ  íçæeSöÿ qÿÄ &        !1AQa 0q@¡±ðÁÿÚ  ?!üÞþ;ñlÿ Oöþy«@Uðbñzö|P_®+Æ¹´Û¹hÑÝ&Vm|oU(À\ìG_5¼îaÈS_Èÿ D«#rh²JN¡wmZÒf·Rº|ÛWÔÌ©&Lzç~|[ÝLWF©­ûN	êÎaçª¼(m0ê{ÇE"q°ÐJFðm7_èÿ £Üé¦»P)8-Ö²=0ÒxÃÛtä¼`N×Ô:#¿xÂè4¶#· cTäTMz!5Aúçï±e$¤'rlÕ»RB¦ÑèÄc!éjNõn	¤îðÿ L?×ãôh­lú¤lQ°ì(V³¯?ÃY\h`-Ê½@DÞÙRiÖ&[ÒE)à<©TZvtj
+Cçzm N0\%g¤iTu¸ uZ%V0K ¦¨\¥\aûÄôÝÊ<ÿ . /T
ìAvÿ xoF
qè/.FK/;>£lâ ¦Àî=-BÖb'èåÀ¡Ð¸WçLY$²26óðÂioTÈrW))ôR GÀ^] Q8uPÅ« (¡ü
^hDòM¡2Æ¨ân©pG·^y$IRFÏáâÌûCÇUÖ©wJ³¡ð,/eudË¹·0ÖIâ'\-Åxïw/

ÂîU5nã(¥³
Ù4-É¸uwÒ ¥³¨»Kq¬ ÖWUÎP7[ë±¹råûÿ ý4»¥	4­6TÃï%â#yÒï¶y]À#é&àç«ääOõÜ6ÁiÁûµC@_G8[ôúµè!´ÚÜ!vÌJwÑñq«?%£>=ÿ _Ê(Ùçhm?Â®í­\4ÀL&íNFì EN "u°»L3E#<ÑÙÞØ³ÀbPPÖÝV¤Upßáßq­Q¿UøÍ[úÑàB ? ¹¶ÛybH^¢Ã¥ÚO#+ë{P¦»8Û»`°­] ñ&lvÒçz
MÖCðç×Á·9ó5V7(¸ÃÏà¹~¯üläý2:ÏÞHSK.\¹qhõ:F=èý¹rå¶ú¼Á¤9ÁYò/E?Xu-x¸	ß=ZÏ"D[è´Y¶$'Zû±øí(hD!HLçUõKw6¸§6 »ÓÂ}v÷A
BúðS¾6f©DÌ$		ïhAã¦<mÕuÂu<¯®¬EÑtäMOèÇïPúAã!Ö5@$rhp¥Î*ëééb ÿ ëE7ü	÷ê×#ÞÅ;e@î½LÊos <.y%ÂmYô¶. iãª'´s}e± ÕhLÇ®ÇOì~«ü}Õuô2:Â6F:Ê>Ëºûä=â9æbCÿ úç[
Î£åoç)¾´k°N²`ÁãÔAFØÁü/Ë?ÒÁQov¤H
è6òÚ¼Óhßçéo7þ]èZ_£FOù4tFößHMú~hÒ,ymI&>\ úDMg°´Ô¨ð, kð¯ç­±òcøán«êUÚ¿ 
jaü+í¨¤ M>
Èk{qA»§Aig$7·ö7wÅ®$ øP 	Ä¶Ø~aÏ`C±÷!a¶Íi±	|	 nHIs'jL´OMäd´.ÇnD¿Ú ^TQLË"¬FÚ
°-º»pJß~ÂÛ7iDÿÄ '       !1AQa q0±ð¡ÁÑáÿÚ ?ýâåËb(\ÑP¬¿¥Dø	U`Õ] m^1»°RLµ07fSwÂGFå®RiEdttB%( @Û\¤aþ¡!,PB7*A é4ÈT/×råë/×Ê>; z5²6°P´¬Ï(#F 4Þ%È&½Ý¢e¹ð%z¡@í#w4|D¨jº1 °P´Á	ÜCA"¶Ò
æd|TÄ+a~ÅËÁõåËâK*UâZ yU¸``lKîFÄDz£Sh!¾×w&4A@èM«É8%°ÉÕÖ±Gu*Õ4'u¼Ê½¹Ð´FÖL6$;×¢¨Uó¤
b?qdàÃ!¼R'\gÆs¼×x8QsBDM`TÂ^¨(%"JIâ·fs¢*+#JhuÏ
P°'9\[Ä¢¨§´A66¯ *ªÐØäFÚkÔØ|zÂèÜ>]~W{yrgÃ -i
GI ¯/Nõë@{áK¬ó6®ë9à!ÈÍòQïxÝP){l§9*©z@øõ×ç.BÊ(×5ï7ÑFuFMè¨ÎáK vEX
Q>)ç[  Q&òzÊ
A4:äÕ6 !ÄëÙ$Ý$Á¨_@7OüÀf^
ºbknº1ðZ
DæóZµÆßÊ2¬B"ZcÙM¡£ìÿ êN¿Ö:½é@ eHÊ¨ ë©t`M¶æä¢"®¢¥Â'Iq@Ü¢pG´ÈPQ.X DD´5 íN³á/È}b¶@¤Å
Ä%7qT(	,JÀ¨ôCWÂ±R²9$ÅÎÜÐ	h 	"p[Uúd
&D4²Uà°FDG;5 Ëb\Äïp¦[íb å2uè-5®ûÚPµ¸LE[ª°Î'²[a Ý
Ûöà_%³+ð<dl E¦Àk.]«Ìdñ¡!d°Èç1,ÀTR=*0áPí¦Ò £õDpx{ýÛAa¯H®'? ;ç,íB $04f%±.f -¬ s	±°"ÝdÞè¸¢` FñA+{èYÛZºYÁÑQLJÐà¯'ç2Wê;hhÙ"L@CíÃKk¹è¬ÕBF¨©ðØ©ÃAÆ)QFÑH: Àäj¸¨z¡>ðm«¬gf5±ÐÊQñàÓ(µÀU +
Æ¢ØÕ!FFE:]¢¶õsJr"NwzÙØ(Ð¸_Ð3É¦Íj ÐÁm<>ÑK.è0mÓú4ÊåeeåáçÎ.0¹w)²P¬­Ãp0Oççåï#Ç¤SN51ªÓbÁèã'C³ð"5²ÓÎ$*&¢À<¨9§Ôåer¾Fï¥V
¢" nÒFÄÄdd9å2L¦
V9³ºXi6ô¢²´Êbï u¶Xj°oç÷ß$dîêÆWk­)A8&¡7-ädarÛÔ
ª
«´¥ ·R´(Ò*%è­m¦ªëögÀÈË²T°bJeÏ%²
¨©\	»®;ÖJõÞ²à5!$ÑÖÄ¦$t"ZÞÍuª·ãVª¢Ø|í$yP%9Ë,uµhjxPCT*àane	 p 8éÏû¯\ÿ 3ÁÅý¿Óà`ry×ø_ïÇ÷Þÿ NÿÄ &      !1AQa q0±Áð¡ÑÿÚ ?ºë¯ß]æ¿ÐpXÂ@c?BåË¹û9~·¸~ÚÝu¾a@%UUxªðûåûÂ°R³UN¶â=QòL«x¾Ê¥Îx5 %UOVcÚ,ú ¨F¹feYEu×]uþ×]~øÚò~bÖP+!°¢mØ9HúÕeÛ´qÝReËTûY%@Ô­ÐÐ¡º½aÝ@üÌÌ§9ìÅUÞøN°L~ bÕ²sJWLxåPû^+uþ°7-øÆs¹f Qt¥äª:OÙ>Ø(PCe¼0J<
"£8cPR'Ò ¤=4|F
¢.%©ÍÅ0Ûc7öD¶<$0EùÍ®óÎ`Tº+ Pê é}jrËÝñåâá)å}þðp
ãX+õà¦dðu_îàr®*	ßX é4f8°µi*à¶hÒE"T9DÐãæÆ%µ¸êÜU¹Í</Ø#¯#Ö2i0=%ú³¶Á@^´²çJP,ºÕó¸Ôp>Kü þ=	.!>B"Í·+~¡Ð¢"
°|ähTã½¡Mv©ùM:Sgv:m§5ZÐuV­4x8#Zî	,dÔÜq¨h½âØlR°w¾R¡p­R±­#PEcÅºH¬nþ!Ã¸Cê ©§àOú6ÃldÙêÛ0/Ò
»+!"ËôQ$ 
 T17d\	12Ô64x=L½Úâ_
Ì*Çêú¤Àlõ	!
T1÷ë>(FæÉÖHÞ-È?ÏXp2Qjá>@f:³p0uÐ JÊ0SÑ¥üKD	bÛ(Ý
qÔèQ§U_FR¨n|®D¢	s<Ë÷ d	,PbxÖmóýUÈõsTÑRÁYôN÷¤J«! ä@bÑÈç¼G.È¬Æ³ U0F%(!Á°øwtDPB^Tøý×ôE
TJF28	 ÇóUUj@±,.Sdtj`±cÜ*AÀàÞÍ	#òPwÇ*(!1)áÕ@	u@Ô9[E"!Ä" Í T
¡*)KUÒµ¥fôÀ.¡ºùÍÀ..Â©òÔd¬? â,Ïcïjè\`!×>\L2)\^ÄêÖâoAÞwLIÉc8ãúW
)oûr0Ñ¯ëÅK
 ÁA\ûh¸t A}v¢|6Ø"ku¶×F¬pmG_K]ùÖÉAH¶ØóÓöQÓÛèÁçþÿ Æ!ä:r0H!ÁV¦>2ÀÀædf DFï

(óÊie h°ë-Q~K Õ F	BiÈIzÁðÎ¹ZºáÔÔýõ§èû:!±7eép³ùjV¯Zºáøìgoä¼ÆÇ£ù»/ï!Ðùë«çY²Ð`wPX|
>%]uûêjk¯Û[ô5ºæséy«uìÕó^ÇB¯?ÀáF«óö½þ/úýüSûþêÙôW+uã5Ãã®û/ÔK®®­_P¢¬xüxãfæÇ_ä>÷ã>rz¹çÄßR»bO>aÎ]Zµuu~ï©¨{¤×ç]pÍZ¦­N÷Ô½]@¿9ç}|r1ò¤b<o+I(6Ñõ.2.àý
=GÁ'¾¿
¾?aG+Q)ä»?
"	7;ëê-ÔÕ«Ï¢½Ãö×ÃsSNMCß­u×æD_>@| ø, Þ°ðOïë®eC/¦rc=U¦ÙOÂa}=©îTú"Ó|iÄ¢GÆ#.º¿Je>thÓõÛ´½"°UP%}Ü´©$dA<AÕÕ«V½zò"gP÷KAYWå^¼ #)mãáEoø4dù¥¼±«D"}V'}¶V­\Ì&IèAB î¯è0Q>ðDDE¦)Ø@$
/«9];è¤ì
Ó"×â³à?qL=C(uÜ¿X"?kJ|Å=¦«x²ü3ó$=
K)AêÓ¯iÞJ ©sÀÂ´0x5	ß¢ùÏÿ &ü¾2çY)ûVÿ gÝr$üéóHñè(_Ìgåòta¸òcÑ}!;ä#`Jù yí£Ïô_#`µòAy}
BED8ýÏÑî¾Ô°TD¢ÂìËø}~Ô[÷3&/Çùü;MVß³û0ø4 &ûÀ`çJÔ rB©Ø"é¶r¥%:ÅìAT­2åQUû!$øª¬ <W¨PÕJâH£ÑQ(·¯E5W_Ùû¤W¯°b%5%!¢BàtÈïÖ,wV
@U\Uä U@ÈeÈ§¢lá¦_¢´ºTx­Y)Ë.îeX8[ÝMsÉfêfDº7 ¹évWRÃ5¯à¹yï½2ùÖMå°  ,Æ²RÕîÑýL;Pb0p¬ÆÕ9ã>AykTjÉQæHî o&Üp¹/t"	èøüSªWçZ¨@ÄCÈ¸¼þxËÏï¿^ÜO×zËôõ50~¸7ûËþåþ¯¯aÜ`JÓÜSå?Â>¸Ð@å8¢dÌE@^³*)A&Úºº¹y,écjV©X³
M)ÂÈ&}iáb®%Yb±³^MhzdR¦¼b-LÚ6´©F=I5Ø¸¡}Ý¨êmdtìK7._ûë¾þY~¾};ïYgùåïÓ½àÿ ¹}ï^þø»Ñz¢!%.^|eõé­èÂØ çQ½@<g¨]Ö")dÝ:/Ô#1áÚõªà_[Àv×2äâÙ`UVæÁ±1DïbÈKùæÓÜèy,­ª6Ë¾@s]ì$ WBU?uªÆªZï`Huqw÷÷ï¿õç2=("<HÅ¼«	ñ!Z6WE* @ FB­±êRJ#ÿ «Y¢8aë_G!eSUá,|ì,zòÊn
 xxñÆðë:"P´hßE½Hÿ øÊ@Ðc'á¢=êÙ¾ ÉiãåBdõ!½-)$à]¨É(B©}f±Xà¶
Àb"
Q¼(ýïÓËrø×¿a&QÀRMD/JHÀÌO±ìp
'NÙªm
åqFÇ!Pd0và*!2Y#%Ý5"°; ÆTÎ[°íÉä¤K7EÑ¨Ø²Ñ«a OªùøbrÒõdPAöë ^e
±À*Ù)ÎÓ}iÖgåÅàT¡JØÙò¢ d¿Vå )/_?¦WÓþwÓ£×ÓïöïówXXBW$RãrYÂàAàÈ¸dÎéh@t
Æd½2M«Ê@ªÞ1t, ØTqEQÎiWLYr/Þ8.-1×¢Ð¡Ó÷0 h#ãÅ
Ã,À=¤íæ¬pêë÷ºªn 2!±B«£RxrZ´)mBÒ9ÚH¼	Á[-b}Y24Ê»ÁcÏ*¬Òà½¢AþÌS`K²ør	$rÞÖ¯Ä#M6QÐÂy§I£xò1XöëéíßÏËre?`¢°+®\ÎÛ¥ÒBüÄgoC¬Ê`!
(õ¥Z* .MÐËØØ(eZ ]ö"ÞótP*¦Uáb
ÛÕw÷x¹XÙÆÀ%7X)dÁ¹ðo.{åÿ 2¿YY_üäe>O1úÀVÑlÀ>êµ0j¡UUUU|ÁÜ$"2hÛtÆôRäD=#$þ[¬@,¯D`Óh nVËL¡Ë>9LÞ²O~\ekV±#¹1;µêHÜ*åe}2²ó¿L¹ïA!¡z0Eh
 <)Yròç¾n//S ,	º0";[£ï2Xì8ÊýetÊäöfæÙJèëëáN÷âÙ)k~P"½y¨/¨s(&øtFìø;8»
$XîmB¦5(ÈØP+iQP#«iÎ1 LÀ¨°ycb»AH.5OK$@	R&#I²ÞÙ7ø 'aáæÓqÌ¦PÏ¨vS¡PqM
'mi¥2:
S, Hã6Æ-»q ò÷ß5ß10_%ùË^¶SÂóxrxÚq4ÈáQøÛín73³g
Ý£O2ò#s¹[©  fP
±Q}ÞÂªxFpklî´¼àÚªÕÚªtyY8¨ÅÙJà¥Èf©°RÂ2ó1¹YÊ÷Üë:±Ç(M] «c
hG¨ ª¿Êpãì5¯]÷Ç#â~|0«ï_×Î´çÿÙ
endstream
endobj
129 0 obj
<<
/Length 2203      
/Filter /FlateDecode
>>
stream
xÚíZKÛ¸¾Ï¯à-TÕ
A"-{w¼-ÇözJ¥Æ>p(Hb,
Ie¢Ð¤HJ~ÍìÄv­.Ùxt£¿îF7,üzñtvñã3-M´â*-HX	³ypþüêåìòåìzònöÛÏ"Ýë,µ JÊõä¶ËÅåìâßh4`é(¡LÙæâæ
1B Ï÷[S½ÈëÆ£J¹pêqJ°ûQ×YF:L{øBñpü2ñTO¼T1¡IâeÂ^WÙÔ#¥1$ZvJ´¦;Le,HLã`Ê`
Ù¿]{nP&z®Í~m>ÎTÞiLgÍÃ²\×Å¥Uwÿd2å*éË#E((zªù±Onë¦J³æ3Dº?Óp¥áA)PÖçÝÑxLX,íi¨V¼N¦¯áîùM7ä09Ó$»1/NLvçÎWn¢k7é¬ëæ0w.
q#Q<PÞFëL#B³ç¢]¯Êl+S»³t¨,0µqx7aï=­)=qî¾ÜìYØòtß¬¼UBû[ÎÕ Íë&mp°ãvÀ£¨Ý¡·õíHWoË6O//P²Ê) ºË]e|Û:¯ýÅ  {Scªö¾Ë»û?_eW{ÿVåÙªu¼Íáÿ&µ\¼mú+`Þþ¡=VDÇÖP 
jçDØè }  (£4 
ä»ÇÖî3kÛe6_,ßG6 W»fmõ;ô|nÒG^+ø>èè¯»(´¯ýáðOee|ØK`¦dè§³
«ÇN{Vt¨²À`føtÐÊO¾hx^Þa®_ªxì6Ùl1+n0_z8ë-WÝÌÇF³U5í«~FïoN&0ï@Ò¶áïï[Sµ\f¥w·9y¹<"éÝ-·{¢»[îîò``»ï.*&QÄ¥	D¯6Ãð¦cÊ|I&ðN{KXôÒ(+­õÒÃ5å&;Õu»ð0{¼öJpUB¾,ü½z¬öÆÞKêû9p®ýaÓ/ûR¤Xüöê:
ÁzPKN£Ñ
1±îUÝ6Å/ÛJånV£këÛõ®jeiùwÁ:ïÔ¦Æ³v]ñ£Öpòô°¡
zÆTÀ®Î= ×ý©OÇä±ý6¡}b
endstream
endobj
147 0 obj
<<
/Length 2208      
/Filter /FlateDecode
>>
stream
xÚXmÛ6þî_¡og±¬wYù¶é5Åm
¿È¢ÌÛì½4
´zÏFlpWÎu­TÔ;Úë63`Ô6²T¢¢ýFýý·àuqÿ	QåuÄsgÀºj5-}
ó%Cwø*EÛñ¸Dû¥lå
À±¾IÝ­ê\
CØ¡Ð¥N´|Ü".|dRX´¶whMîq©JÖ,Jct)ÛÖ !¿#ÿ#Ëò¸¡u'8ÑwöýÇ´6,V{nÝÜ9Ý«©Z]ï_	Aõ×@ÇÅØH$ ¬\ðû»4ÏÊÖv ýbF`/ÒZ(¥ÖÈ<üöuV¹çQlÁ4È £¡Ê\UCð$È¶ ä3P½"Íf§s#êV¹öèÿK©FéX¦øÛdêôAb÷AqèÀ;$°íí*M«!»+¶¬Ñ'çò#RP$/chó°¸u"ª
Á=bn9§§¶ÝÓÇsùÔwB'n*OKm0lPhÁhÍ4.[ú-Nnµ0»¡3yÒÚÎô5Í¨ÛÓ¾³Uý[-Á	EÅÕJÀü,:)]Q¶nÛKC8eV¶ÓwÑEY¥miÇbMApÛîø·Õ®ï­Õ¾»ºjVUb«)^÷üXáÉvQÌþ"B/ÐMvö<í2ÎÀè=þAR^ãÜ4»µÙ+ÙÒV3H'¯Ã÷$÷CxTà1yM ¹ASÀUr]«ö²RÁî¨®ßH¼ÈRÛEkv
´géÜ©pX rÒ!Q Ó
*xï¡ºrèÙÝ;@
üR«<Í>Ïüd%
qg
½úBIµ8ôEÛ|yY!{t5ß&kì§AxWXk¡X¦õµ9¬.êI­~ p?hs}ÏúOïá°¨b·¸yI|_<Ü6Æï¿Má<òÓuüý
onQ¯ig>~)|Â«QcñªÅð ²j²öQFîÔkF½Ëî Óÿ g=T
endstream
endobj
143 0 obj
<<
/Type /XObject
/Subtype /Image
/Width 1050
/Height 552
/BitsPerComponent 8
/ColorSpace /DeviceRGB
/SMask 152 0 R
/Length 52876     
/Filter /FlateDecode
>>
stream
xÚì½
e 4KCl>LlMQÚ&0O¤cGì Hqºß·íÓéW;ôk3c¯HôÅrõûçù§÷lOÕ­{{ïs¿_­³îª:uêTÕ­:çì_í}ö>î8Ù-oxÃözÙ÷ã¿ì»ï>Ïôe¿½9Ù7ø¬øgø}ýÌg°ùòÜ½&ÿMÝoïgMö
¯õÇýá_SÍÇ,]Ó|^h& 	h& 	h&F&B¡ ±@pæzPJfËÿ&¬Ñð±N>0|CYë!(³(SÕÆ¤oå.Â©á¼Ð4M@Ð4M@Ð4M¥S @¶)rNÕlAÖ2TKL2³JOµÖmaÕp^h& 	h& 	h&FpÞÄW~ÍR}&YªÏ£k}:YËP;µ!6wó¾­¹Èó#ÎM@ÐÄ¸ÐÄÞóÒeo:pÅÛ_´véËæbVµ:4M@Ð4114!0]rê$Z³'ÒkèMÔÞÓÄøt*fC{SÅYºFÉQò3MÄTkkÖD3 \ClÚeSFK5·wP­Z'OÓ{~GíB·¦¦m~Ñ[bq£ÿ®¶¢	ßÎÜuýJz¾zÊzÖ­.u^ÑâözFZNZ°oßGá7¼ô9ªy.& 	h
MÇbé%$Á\5Mdbe!mV4!´°wÊ3µ|:åIÙ+Tè;Â
?âétA¡ôéú{×4Ñ%Z½~Ú}Í5M2«S¯fÒ°Ëw]4ÉÚ¬ÃfXu;PýëæM\qÂAfoQ¦\æ¤ûZa¡bYg¡M%× E+Ú,ÀD9¶Ò¯Ö>uÊÃ¼J+ç½þùµWªM%¡	h& ±£	¶ùëbÃw¨¥¯ø>\ÐD>$<5¸ú$Møbüq>$lÿ/Õ0µ©ò¡é?ÇÁ£³©X/B4Q+gæé!Áùªx:³²tr
UW/4qL"ÐaÿIsÊw­;2)X1Æu³m>ÜóZ}jWó&²T/é]ý×ÎE1ßÁvP^É?ËüçxÓçM¨wMLZ×)#øBÉëùz 	h& ·tò`]È^lÌ æ,ÏD¨ÒDþè×VG0`È³<3±pîXCDQN"ùÔQ*Ö @½øtÊóÁãÕ
ÁØOD¿z:æ»È:]£Dw4®ßâÓzóëS]TCÞþ£|;^"s£·½º	ÿó>]ÇIÃ®PKÅÿ1fÛÜ£Ì+¬.©>OÄUÿlõô¿võ²¶ÂÓ.£a7i"3AV¢×±	M@Ð4Mþ,lÿvû_-ÀXxrÁG¿ë©\Ï§vþo«¡ßT8ïä[îÐÒX:õ&aªÄòö_àcfº_ÑÎi"Ð8ýwçÙ©Èâwµùõ+9a´â"ÈHý¢	×Êü¼òÞÚfÒvW(P²URqã7Ãb
¶ÿù<o¢(%½¬9Zqò^C×uT®!ÂÈL2T%:Ê§³U¶& 	h&F&ü)¯Ö{jDIÂ¤A£v¶-Éßð;¡ü8+ëô¾ÓD³ã¾âjkãÄùÖ
£	'½8&ZÍÁ²jæ'Ç³óÓé&¬}³Nh7²ïÜÐVBÑg²7¿~E++ ßëj°þgü®z3¤tkâÚÆl¦øÝx{ÝÐLZí
²+BcXÐDÍ0^$ûÛGe?½ój¶Äþ<7Á
[(MØ)m2YQfEÅéLAÐ4M@£9ÛÆÏ¶Ê1Cl°÷,Ì&ò÷ØQ ðj{6Õhçü%¶°Ûï( f[÷0qÉBþ×¿<ÏÖÒ©°ÌÉú.Lº x»â^²æ¥ð-»ñÚJùnÔù/­è&Zé:344Ú]ÙÄ+§JùÉvÒRÅ½ÏðÇÿ`Bò(
k%Û> ÔÒÄ8PTiÂ'
É6>ÉvmïM´Uº³lÔ#M¹Tw`ØØøx ´¥ÐeÄá6ô
«°¸»hÑñ} âÎÊ)Y¦Qýñ64æT¸oÍWÿ·Îaµá.m»£©©ß\´èõ^xzÎÔ¦2µk4iÂ¼`ùÙÌNÅäIõ6^
»£ZÈ³³³¨LqRNe¼ËpÚOòâðûëéMüÃ·ÿôÿTÓÿû?:§ÒÈÖëÞÚGÐÕêu/=^*ùûõw×îõ)ZíUÚvÃâ¾Ð]_.ih¢ú*êÖýÜ¥#{#
ãmïeÆñÀh"G$Ìoi~ZtÕyá©ÕKâ¿B
óSè&V¬¸Xr¦6W\<F±°%Þ#h¥ »ZÑ¡£XQÄÂl3ÇÒ6^w4ñÿý¯¿©U¨í\{ãÉ!³ê}sº«¿M¨6]³î¥GáPèÚj÷ú­öv$þ5_g4ñý[ÎôRmß½âè	 V¯âhâRós¬¥Úìúj~!½wîZq[a%¾Ý³{ñ??F³°«_}+îF9\,ÖZÅÞÖãHY:Ýá¼bRgÎgåPh4O6¾!2VZ×4B~!	çÆwtL­açyY7È°?
Wÿ(Ç¤ÖfÃ%Oí¨2ú469µÅn	Ü{ñß@íªï""Ã¬hÂM¬xI"óÛ¾~*¯wÏA+jwqxïa3M4Ø+»jIÛ]VnVwåÞ¶Ú¿+,qîhbçÎ?]¾üe*iE¹ð5ó®lµnÝ:\¿Þ;[0éÜ§ÓøZ2wMµ6ß¿åLI#YÔ¤­Q$ãIÞ³¹
êWÉÖQV|Fåw!êtHqúõå`;%Éá!©
 ûýUïóõK¬
oÊ¬µ
kuvÕ¯Óù:ýÿôBÁµb­ÏU{yº?5ÝZaGÏ+ÿ-Å?V<kUê&W±ÈlõÊå]º?ÊxÁ¼\}±[=JtyW'Ï±&ò
ÇÞøl°Úêì®¿­-Y'4ákÓ)tÒxY®.M\¶ø¨ØvDù~ýrrücñøTOí:Ñ#tNr}ºx@­^9È»âÏ¯­¹ ÃVR÷wÿÆNc4A\U¶ï*1¼xçóÞ¸©&ZÝc(YrSÕ)ª-wV4ÑÉÌÙO¦PaÁ[Éä]aQ
£åloMÙó¦õï|@& ÎçMdÿüD	hÏ4!0Ø`iãÆ5ÙõòÅÞÔ.ÃETëõ9^7i¢ð¥¢iÈÞ±î]sòù,zYJ
#óÌðMuS>cõìQ,ÍUÃx3÷Zo¶Eá³÷eÞjÎÂa¨B)Pµò®êÙã"3>äèÓù@Ýr>mÓ!6ÓDñ<H¶ùó!qmµO¤&¥	Eëv¾åz7Q`{º*ºWër{¬îÍ´i¢áiÞ¨õO«Þe(=&òzujp
gÐ4ÑãìÓç÷S¤\HM@ÐDçM,Yr¢
»ÓM}²UXª9ù¼Íåsl¸Ç¹ ®
°ÿÏV>ªXc'fWÎi"¼Dæ ÍÈM@Û8óÛÐE¡	hèMòÔé;ÿtjê7+\^6m\äM&âÃfÏâóx­'¨1¢	]°­JfEaJTl2 håIµð¬´-Sõì³ê}.½kïÈ{»E-*QÍ:<°¢­Û«çMjÀO§ù+mÖMd5Só£Ï>ÇçM4ûhªøß@yZSn
Qù<o"Ø ´×¤ î¤ïnëH³P`M~C
±¹È·ÌÛ®
¦Z×Fñ@«3ÐcOd¯GÅ®¶ØO§<½ö+n¹P dÛ°ÎexÈæd¶Ï±/4¯¼zÙÙTÛ6Øêç&º^WÕM8@[çM´¢ª×¦<W"¼îXKRW$MB®î"¾óHÑ¯?'ý½Õù/ñ×B@ÒñÂôë MT]Å»×ök°åU«Ôã]Çsëw¸;hÕÝß$;¤	û¸÷MÍª_ú¯BçO.>Ká¢kµi¢B`'ï]³æcyï»V[hs¶aûEjíT
Ï±.øÁÐDíyEUÏcN*Ó;MuÎMäXE¾ÛN­ÿÞçM&b¢Ä×Îñá/~íÚÃUÀãïy¯¾ñÁUÅÏén¨& 	h\UTí
jæ(Lò%SC;å½Z)"ßN¦µK_æ]Ø& 	h&NÙæ<»ÉÃtaÝoÁãà8ÒDíE0ß°	2yòE_br5ÓDuÒG­×©.R×ÁL1 ¼¢i~Z3[ÝHÙ9MÏ:,©àÓ)~+ZVñæ©êñ)ÓXØ³ªsælVí.º£â¼Ejh¢!Y%éªÊü_;ÿÚ%R(¦ZSukë&U«ÍOòbh& 	hb|çM¼kÙstoýjÔögÞb?gë\L}­~îöçôVf*¡	_óGxÊx
E8W6èÊwíXÒ½k%:§	ÏPÊSæ{¼¤	¿Õ©(ÖDä§S}pU·½ñVßaÿ
0q%­þPùÃï¬¼M(ü­;¬ÚÚ2\ÖÙ²ÈIëý2Ã°SüJ]¨f 	h& 	h&æ!M>6ódÕ 0[Ê1õ³áÑe¿ýÎJZ/è"
ÒÄT¿V|H¡Ck(.RåµâÓÕÞNçò®©©©|8Ê×¦z¢ÂÐMø¡Éµ
Ö8h%ô*¦ÌHÅ¼	\yã-*Óì	ª&.ºuhâÏ~û÷¾²}X4¡F·yûã
ÙH»
Ð!¶tÒoÔãYW¾ÊØèÈÈÓM4ßQMáÕ.ìÛt¨Í§ÐoAÈ6X:¥Ó;.&hqsK*æÁ¢Ï§ 
bÆr6o}Ä+mdh´âg;o¢# 	hÞ&zYüÝÞu¸Ù .æOvö.Ï?Q1Y+ù\¿TvnjfÙ½gCH>våp±«z®¼ùâÅ½xR=º)N¹fÏ¹Öb>Ú\	²
K'UåJ°t&ß¡	h ·A¶& 	ZÜ| l¡dXð¯hbÁaGãCÐöf Ð!âh`|& 	hÞÙ&hqL¢ Ï}0lß±Ë±5Ê.PJ
M0¾¸·ùÑOôëwÉïþ_¯zÐëW®ÞM@Ð½
ûøãÓâ 	Æwh¢&´nFX¿aV.^v©w9â>+]4MÐÛ Û@Ð41¦-nzz:BÔÑâ 	Æwh"Ó Aá$@Ð{åü?ûó¿05ª9è& 	h& 	hb´¸ÇÜ4ñ©O}M0¾CU#h}ý-~µ2)1h& 	h& 	Z4ÁøM¥ÂKS«Vg&±C5& 	h& 	hM0¾CyÞ0áÎ»îY¿ayÁd!j¨æøXh& 	h& ¹kqSSSÉ«ìüØaÑíCòôÕ¼Ù¹W?ûó¿Pêâ3/4ÁøÞ;M¯±PÂÔ LAùS5ÇÐ4M@ÐÄ<§Íß{\4qõê-Ð4¡åû?¾{Ý£=ÿêÑ÷Þâ-Z´qãÆNJjxÝ¶m[wÇêÀ+V&ªÎpº 	ÏlUêâ3/4ÁøÞ;M½&èm 	h¢Çå=ÿï¢wþÖ:hbÓÄOýô¦/mÕËé_ø®2ûB&­gdÐzðBÎw±Lg¯[a]³fÍòåË{Qdx|¿èÖ
PyDhW¦	QclOâ|®@ïÐ4MÐÛ@ÐÄpiâ=ÿïïÿÿCPbê	hbibñUViBéæ[níMXw055%#(ÇeÖÍ,.©½B|¬0aÍ59GGWâÌÞÇ÷|×f¶4!^0(;(iÓ3U&BþÇþ¡È4a$	Ïÿ·>â a M0¾CÐ4AolMMX1ñ÷ÓOzöâ«z5ø»þc-JôØøX¦	È¿~­V(¸cÅÌâ(¶0-+ö,.#Ö:7o¼ï·ðï>vÿ+µ¥ò%ÿ¯¼ñ¬Ê(hB+­hBiû]
E. 	Æwh&èmm ®iBïø1Yî»ï>hb\hâÉ§~ÚJ¢¾ñæÛú¢hEÛ¶m[»vm&4àºX0¹ªV4ÑûøïzñUÞ~ÿ÷¾ýðÿ3ÛyÅZÈ®ûynØ¦MâÎ» 	Æ÷ÞiÂ¦tz3â& 	hÞxxÚ äø&Àû=41j4¡å_øn%.»cS¿æMdð®©©)óBÐ'P¬Y<o"v9GjiBe
P]Ó9âG?yrw·bí6SIB';4aÐbÙC¬±ÂÉS-<S;ÏË&ß{¤	½9z'íå5c/4M@ô6Ð4MÐâº¦	ÉÏÞô­ÚTf_âMü¯ÍÐ5<);JÚÝ«6ï­,_¾\BÝ{æY¸R15³ô8¾gð2¬èuÄXÆ÷9¢	©YÕióÖGì1,Y[!Ü%VLásÌúÍ@Ð4M@Ð41oib÷½Ó½í¸rõæËîØt÷ºG§ÿé©Ýó)væáÒñ&ßç&ìI¬ú:þ«ê¸Ø9
~Ðã{4A,lh ·& 	hM&"þµ­Ê·ïØåµÛ¥+ieóÖGÌÛ9¶!ñ¯sÄ)6JG7ÁøM@Ð½
³C¶-÷!fWp§QÆ 	Æwh&èmm 	h&æ	Mx³0)x6k8Ø´R`#èd¢tws+:,M@Ð4M@Ð4Ñ&¦V­o"{Ëñ7ÞâY«E×%ÕÒD¸åGZ4³èO^±bÅÚµkÛ²dÉ¶9],µlÛ¶­­t·sçÎ	 	ÏÁÑËÙy¯ßíæb13& ¹^Ô#-_¾\ªú´NzÔ#-Ò±ýz	§§§ÝÉkþ& 	hbþÐDR¡Gd÷1çÚ6=É:çËÍ4áØÄU!p\hB¡ñkãÌ²fÍ¶þT¦mÎ¬.@§öJu¯véòFj#Ð«¨w¬:-M`éM@D	õÞÕw:
V',è]øwçéNuÝÌÒcm½tòÐ4M@ãK#ÕâsÉô?=5²47µ¨7Û¶mVô«L
ëìµ$2øÞæþèÝ±ióöÇ» ªc«${`si"ëÚÄ¶s\uqx87& 	h¢¿¼Y2TÿæuwêÇr_§_ueî£õ!.æM÷QF¨ÂèÝûªJ½ëº=KõTòÝVÇ]·+umùjsÜáe<hSõûâ¨Qc¾ÑÄ97|óAÐ4MtHê4$ùÔ2ÅèÐþj7Êtoµ»¤úg+Îq (zëú}¬¿ÑÙ°*_
J\ÊXW¢>ÖåÃf 8DxÇåë2StBAÂ¯ØY}8't¹¤}9ÆjÓ&Ð4MÌÅ¢~¬¶;R7eWT9êl­N/ú:õ~î£¯2®$·BDÚTUñ¡Æuq
h& V-î°7;%×>7ß±©ÐMÄPâÑ!x!h¢ÈáßEiA­Oji"jF;qxqÓÄM_Ú:
i5yñ'iÂqLL¶JZyã-µÞ£÷*we:8cÌßQ/ªqx¦O­'h¢Uo£^Z÷þ1Y°ÐDß«þ§§Î¸®M¿­^¨ª*h-9z°¢ÛÜ&8d(úÞ¶4!©^=¡ýih
¨^CaGZÐDa>¯ÖGYã¼df)hÂ§¶U®PKîÀÝÖ¶òÙn|éô­zó"h&F&:tÙ]ê¤òÚ÷ÀÆÇÎ¹áê09:ºð aKÝê hmuÎypMd/(ÙÒ)¾_UÏ2²º	hj«äá¸êÙØÅlË¤b¹L^a{'×4ÝÔFo&&I
Mô½Zý·jÑô¨ù*,6«Ýf+È}rZ­$kÚê&|xMdôÐJ\@ÐD>¶ªð©s%&ãÙêí­ãÐæ¡a~ê&«êÐ¾ò§_C7M@£@}÷uS0Û64@ÑâÎþõÔrÄèÓDÌ¡ðti²ïOp.3,:¤	×ã|JbÌÑ³z]'PMd#Ø¶4!!¿íçVkSàiÔ¶rf8ÄúwÝ%
N°g»=õ&È6µ4QuóM@ÐÄHÑD[yã-¦3^s»Wü:D{íç?ûðw
4AoM@Ð4M@Ð4ÁøM4ÓDS±JB¢¶  	hÞ& 	hÈËÔÌâõmÛ¶-Z´(Ç´ä¢\:.ãûÊo±a	4MMxq ÷p8¡¡ÑqåÔ!Íe4M@Ð4M&|ê§Jµ-Îáì´ õVB{àÁÿ	º°7MØC,4MÌMÔF°\ªWËs"lÑ«½ÊwÎæ­:f5WèMtÑ«@Ð4M@ÐÄÀhBqïC;Î¼~½e«·páB¯,Y²díÚµú-òÅ¢íòæ5k´îLÓ £ª¤È|À;wîô.ÓÊôôt®éEmDäóª°6<³¥ÏÿñÿxÙ+ihq¨²LkbÓ5ÃÝM.8ç±z3hÂ§¨è
M@½Ð±°'&Â§t¬+Ùut&>*{¢n^& 	h ÅÍ&#Þqù:¥þÕ+êÒÚ
Iï¡¶ehWÀv	@
-r|ÔòåË':\+*/ÐúÚEUé@W³qfÑ.ÕetVL1zß:§6>¦^ýÊßýÚ+i9¾Û¹ÍWÿváE3ÂXÛ<\ß f$dç2Bn9¾ý}jÔ	h&æ-Mä°ÛwìZµ:¦Ã){í
7\[çÚ
h& 	hhKG´¥	ð×;)Éß `
°6!ä|SÀî¤³ÐL£@^BÚW%)Î,ª¡&"ÇòQ¾Â¶ã»9â¦/mÕ½7ïÿãc`áWÓÊhy(/hÂJ
Ûè7ÁÍ¡é& 	h¨¥¬znDzêÒ&¬`m6­& 	h& fJ\¹zsææ´yûãÌ/YôZîÞc¡äéØZ7bx1Gd°ÆÁÆHZY8³Xø÷®À (oèp~MXýiB+.ïë+¾7ÿÀ_úòNöfcCbÎzöØ_¥B02ÜU¿ýpFmh& j¾º#»°u¥Í<±¥&Ü5[=AÐÄü¡ÓOÿågÉòº×½&FJ7¡eýÃ».ºuCº	ËðÂYªùÚ&Ârizz:W¨2Î£²n"ÅëÐDæu¥ËîØ¤¤æñ]oÃtö5gEöú¡DU~& 	hÈ¹ °bªÒ¿u¨kÂÒ	&ªË	oyK¸¡ÐÐ9j½è+9tÃ·ÿZ+ú=ôÐWAÐÄ¨ÑD):§	³@Ý5bZ×`BA»÷<ªå[aiBá½Z´Ëi}F+2ji"êÔ2«YØf_ÿÄ¼òmhÂ>35(0Uò^
Q¥	sÀÁì L:\+& 	h¢ðj»íÊwPÑá"b64M@Ð4Aë;Md¦h¦3KlnÛ¶-ë,ÞGäí|©È,]Å4íØ Í|Þ(_\Iqmï_}póË_Ñdéd|ÐïðÙ¯¦6ÿë7lqÃ§;ÇeTðÁ¶Ð:ÜGo(hè&ü¦¯×x2kÓï¡~õúy¯
4ë&þÒ»Dzôé£B^& 	h&hqÐ4M@ÄÂ4ñ;<ÓmY7á!â¯Ì*¡	h& 	h&ß¡	hbòhÂaÕlÞúH¡ð4yI.î:}þ¬æV@ó&&~& 	h& 	hb¸4~eOSSSö,+V¬Ð¦ówîÜ¹dfñúòåËU@k×®`02x^¼ãÛäiû]Z÷JX:C`ýBcM7n\8³¸!Ô¾TY¶mÛ6==Ý¼KÍPM@Ð4M@Ð4Ñ£× ¾ÐBâÓÆ=Ë3óE`²DÚûô¸¹hQ×@1G4ñ£<Ù¯ÞFáYØâMBõà©vlï[.¬Ä,ì	 àh½TæèÁ/jw­H!v©U¦n¢Ú¡	h& 	h-MHòÓv2!sÆô^KªZ"Ìï{¡¾üÿáþ§§º£B¬ÒøhÅVÔU&¢¢ÅW=xûýßËÑëèmº¦	/Ú´Ð®?Úw5<Ì©LwZÑ¦¸{Í5>DÕª±h%LÔf.ÂjZÑáÖlY\Ò°wùDÕk+j<MÜô¥­Ý±ióöÇ¡	h& 	hè&Â}¨}þ8h±B4a P"°¢?ºCMH|¸n¦èE71==½|fÑd~UÌM¼ãòuJbÛîÛ¦¿ ·é&Ü(Ô:<¹Íÿl
ÇBùfqOwÕ^[µ¶ÁÓ£býÃ» 	h&æ&^òíJqÙ%9émïðú¤­øä¯=Êëê
9¿V71Ã¢&ô
þÏ³P?Ä*MxæK(§¼+GIÓstµÐÄ°hÂHg»@ÐD±LMMi0]¸p¡~W¬XÑ¶¼Ê¨píª|ý.Y²dãÆÐ4M@ÕeúR¯uÑ­.¼é[øÂwô'KO¿ð3àd@ê~KjzÄÝÑD¸¯/rrù0"96ÜÅxÎuöàäÌk0DØØÉZ	Ï÷¦5My¾|¶a+©ðk ô±~ÜÐÄ°hÂO$ü;AÐD
ßP & ùLOô×¯×éëú»þãiBcî5kü3ÕÆp¬~rÉÌ²mÛ6ÿ÷fâòQ Ê©©)¢Rù*é2ÑåªéEµ*©qZéäÔÊ
M@ÐÄÒDÕyoÄ´=[yÉþ¸ì"K§¡¿zôÇ­zþo¬ÿVMÃSíØªÇÒDäÄHêYO[W¶¡42BÐ41î4¡GÖ&ÞsÕ{Î¼ìML¶ý½ç_gù|V4¡Å_E¬x]4³(¯bò·&¼äîÑàÐL­Níîú?¯{tÀ¦ÓÑï½åÂ¾U<\ÅÿîßCÐ4114a^pxÁ<ÆÉÊÏ iíJ¨'oÕóÿÓ¡_Èz
ÿ3ÐÄài"ÛÆDÐ:ÛØëùkvß<ëì_Ô&4ÆNÜBÐ4M@Ð4MLÞrÛm·Áì&oé#M¯KÒDv_É¼aÑ­îýÜ­xÒ³3TiÂähÝK=våçÐ4M5M|ìc{ôÑG¡	h& Çwh"h"]mß±«Èñº'{ViÂßº&üÛÖPM&lBïI»aE¯w@ÏÅ¦MUð_§8ÄO¶éùÐ4MMX¶& 	h&&&,O}Î	«û0­°jóööYÍÇB¡<-Â%Â¨~Cï ~ôÃRyk <k¾°t
Ì& 	h& 	h& ¹N9AsD¢ ëÂ+U
'y¹sÂmWh7¬ÈÈq
M@Ð4M@ãNáÇÉî¡ Ñ¡ìø×®·f+¨@Ð4Ñ!MdçÛî;ì6[ô& 	h&&&"tEó¸¡ïvFEàBh&úHElÏDSeh2ëì.é;ëì;x½VbW5 (4M@Ð4M&"LË£Æ5®ËõèsÈìÚqÌø®ç®RBhFÙ[¬£«Xh&fE	´6ßd¡èÿG=¤18õÖM¸*bMBÐ4M@ÐÄÐi"0Øs!p:vzú5äC"Úuÿ:t*ï#üø.	DÏóòsÑÂRJm& iÂjZh½ê´Ù¡ZúLgMA¢pmÍÐ4M@ÐÄ\/·ÝvÛÚµk¡ÚñÝÃ0ï1ËùÝÁ«&/ÞA!¾Z&Eñ
~5
CÐ4M@±ìÜ¹sãÆÛ¶mÛÍ2$ð4S5S«VÇ°µ}Ç®Ly¤ë&#ZÉ¥ÐÄ Æw?Ü0`ÅÒ2O+Ûoh&:¤	7+Jª)é7w1/;Ì¢ÂÉê	Óõ¹µbéM@Ð4¹ö,K,é>Ö¬Y;ô&ò$O³%kÎQÏøÚkkÞV4vM=ÑjR641ñÝÏ±øjê'.(YÚi`@h&Úzõ)ù¯P[ËA÷nê$ü19ÂmÐw\¸­§Yh& ÓÄúwMÿÓSÃ¢mÛ¶-\¸0ÅÔÔTÛ£6nÜ¸bÅ
Ø¡s¸âª6ë&bß_Æóp] ¸Câë5ÂÀÞ~G%jo|Òäø^5á¶ïJÓÅÏ£÷óõSò»
¨¼éÃR}âPÉP7dð ¨8ÈÂZ¾ZI¾B5ÁÿN-:ß+7ßó×g\÷®6sÉpuD¯& 	h& 	h x`ãcwF&Dùc~öÊ4XVß=3ÃB9V@dP
 	mZg	ßSZW~TW¸~Ã¡ÓÄÕ¿¿eñUyýúÏ~u;4M@ÐÄhÒ$*ÙÙQµ@+×
Äléd3ªêëÈÍíG?yR¨}ïC;®þè5ý¥ÁÛõÐ4M@
4¢ï³°ÃhÛ±;'N]D5ÐË_¨bÄ×ÐÄèÐD®ídÌs¬¬ªÄô«\¦aNÖPhB×£««Êþ
	£ÛºÝ,=ÓË¯¸zV4a?áA&
/@øòð§ÏÁ q¡ Äæx»cAêÜ_õ`F3¯_ÿäS?&F&ôëäp69`M29<ÊÐ£K8/xéÙç[4áß!¼4Ûvøm¶3çê!Ð4M@£CßÛ.kÖ¬	ó'¾ÐD'±°½°¡m:Bè FpõyÐt±°dP°ÐÄÑþjºà z
×"¼uÄ«*Ì¬Èê'¯Gy4qK§B=QUL@Ã¥	ËÞY(È"B´,æ2£I¾ÚÜF ¦ÿEwáÈqËQ2,¸ìÌ¹8& 	h`qÈzy¦YÕzAyÐôXé½±MÌMø[eÄ%÷GNÉ!þz1
· 	¿ÕJ±«ì&âö}µAÜ£)åÉ#ÖD¸©@Ð4M@_<¾5M<i­D8%¬ú»w+Ð!ÐUÌfQÌÂ MÄµY<?¬,ä¨¤~3t´¥,¿ÅÔøÊZû)xÔhÂêV	hbôiÂSü¡ÃïgA£féMt&5¢hnV£h¦	mÚÔP¿6_ô±a Î& 	h&F&<Ù¦%Lv5¨YµgøL1hZ!µCÏÐD4ÿs¯l,ØP-
[zÃ­}Ð¯E8Öásyå×êFÐCìí÷¯b"M¨Ç¨ÈBr°#S½F7ùH}£?ÈxúX7áÆ-È7è×e´nú©gÕC 	hè]x¾ì²Ë=öXâ5¯yÍYgµuëÖq¡/~ñ'tÒf­h&F&ü,ô\A¦jãMhÐ,¾rg-?41§43X-ðûfÞk{l=Dó çPÛ??üúpc73Äoº+©õ%;4ñW\}ÕG¯&F&M¼	h"Mè_zÕ«^µdÉK/½ôÓþôW^yî¹çªÿä'?9â4!_øpÜqÇ-[¶ìE+ÚT¦vAÐÄÐD±íÚz&úH5ÖÑëÎ=ï¼Ë~ëj%­@Ð4M@Ð­[·ª¯þé]n½õVåýìgG&=öØ÷¿ÿý®,ÊÔ.h:MÌ6¶lm/ÑÖ#:4M`yâ'D·ýîg|1ZÑ¦2½wÃ_ÿ½9bù¼®Lh& 	hb²iBÁë_ÿú+¯¼òÓuâCièKÿøÇO=õÔO·X´K 	hb¸41¦ãû¼¥	;w&jÓN;=P"Bïÿ`º)[Ð4M@ÐÄdÓþ#<òÓ­O>yåÊ£I/ùËÅ­®ük®Y°`4M@ÐÄØï£FêßñÎw~ñËk«§Lí²eéuÿNF	mæJ ¹£ÙÎîÂÞ²c}¤	»Sö\³ÙïQÛ8`YuáÕ hi24¡?í~éhâýïÿ)§24¡Ák¿ýöûtã¢]Ï& 	h&ÜpÂ[Þó§¥¬Þ¢bz"+& 9¢	OÞïÝ¢²9µÿ50të®sa»GAn4a¾M­t`¨rXhM\sÍ5/nÈ-[vÒI' M¨×:øàiâ zì±Ç 	h& ®{ZÂ×üVóEª©p¨'
Å414a!ßrµuÎ)«ý¯Cò®\CQÆ³·KùVÞxKÈÌ·>ãÓiÅ9á6-»S+JvÀn`4QüÉ&K«§éßo~%=41t¸ó®{ìÊ/´~v<nÿá³U5&î»ï¾£>ºA ÷»ßý¡}hiBËþûïóÍ7·ºríR^>ÇAÐ4MÌgÐ¹ï %(TøëùÝZÅ414á ìÂæÖþ¬-iÄ_ï0ÅQT
åÊØ­qD?±§bËíÎñz¸MñÌ#}þo§Í./­Z2bü§ó6hvFáeºÐÉ|¡GaO\ñJøÀ\09z_ÔÈ±ñÙç
%;(S91¿Õwgï%ön0">ta¾HiÅ|?E~ÜJµ)YT73G´«Z.Mäþ»<Y)ÞFoj×l-¨Bªç{î©3Ë'xäÌòÊW¾òiY°`óUÀ%uÈ^ô¢áï"S÷,'|ò{|åf"-G}´K¾ûÝïþùÿù¯~õ«Ð4M@ÐD«eõê§¿öªJþ3¤<´ã¯»ýþïAý¥		°"2DhOy°v!3GaåûC¨jÐat¡LWUë­tðñ&
w7V.D¦jËv#ù^òá­<ß1Þ¿QëBþÏÏÅÑ(´7ÞßR3}ûµ¡^ÏP9Û *C¡/~ñÇwÜ§»Z8âo~óÃßÍA·ÞzkWþÞ÷¾÷}ï{4M@Ð4Q»<ÝOunHU¨j|ê§ÑEúíB=M{.û[/Ó6¦±°¡ÐD¸ç²Îb,âMqÆ\pAw4±xñâk®¹fXã{/ôñüå/94M@Ð4Q]®¹æÚó/øµ¹ÇUíÒ÷}äöû¿'¸÷¡zB>ûÕíÐ4Ñ/è<vU £4Ñy|¡^>ïkJ,X°`Xã{/4[Å
4M@ÐÄ<¡K.¹ô²ßºzîò^ú[¸øC¢	+)¬PþM_Új4Mô&ú 	hb`41F±°óç}1Å{ßûÞNäð_ù_	 9øàz¹ß:÷ÜsÂdÄòáøÊ+¯ìB±M@Ð41hâÜóÎûø'>9×Nñ¯^¼{fÅÍ_þks4M@Ð41^4?ïK ñ_Ü	Mè¼áõSNY±bÅàÇ÷öÞ{ïK/½´íüñqÔ¬+Ð4M@MO<ñÄi§~Ûï~¦ÁhÄ^Gì	?¤hØ¾tìi³y¼ÓüoO}×
4M@ÐÄÓÄÓ(qÚéû/5S«VÛ×.(-ÿD,;±tN¬ÐuºÞvÊÒëÌ4qæõë7o¼!½öØSÏþÀÍeúþêÑø!ö&º{¥gçCº8v4×914Ñ¹ü¯okNßµM@³]ôÜ|óÍ³;§!tÐc=Ö|¢_þå_î°Å©ª#8¢YÈ/8è¸ãë&óçt®X& 	hTPÿvÂ	oùâ×¶O²cDxþ/mu(é¤:õ®Ûf/O#hé4ø¥kÐ¦½Ø p©jÒö»ìå5r"9þËÛÕªVÍ!×3tëÌWUh+ªHäø|w
Ç)TqLbðÃ½Clb¿XWR8BµÄe,d$¶1ØoÆVÚ`þ,B	Z@*Cû$KÁÌe61¶-¡·QThí¨b¶bJEíûïé¼Ã½===3;3==ß­®©îÛ·oÿ¹ç_sïåKÐÿz.¶÷ÖhÂBÚ"ÅW¥U49-Z´
·øíPp° Ëj<@J¢ª¼¾ó¥_Ö mðó}ðÀ^þr
k]¬ ~{K	+4ïËmÁÁ7U{ï	¿Äád··WÍË}ÔM´&¶ÿäÀ«v®xô§0M}týyóì?7ýîTDUaÝ¼îETÞwÍÎ"m/0ÞR¾´´ÞÙèâÛ}4Y£fKôwXÂÎ<q+³Èöâ[º~jx³ox¦ÈÞ»åsaô®Sz®{"¶¥=MpX`<bÏS8v#n¯Þ~pfðrÒæá'¿¼àæçý}hÄ\ØÞã ¹°@ô;$zÜrE'|òôéÓ/½ôRäsª&èã¸üòËO=õÔ|°A(áf?*±|ë­·ZS
£Ú¨¼g,Òo&óðÝ&Å³-'6XdãÍæ`0eôÁcãV-VUìb×­ÐíiÂfô#STo¢â|vM£SN}Ã7+È3§	.öN!M4âNÁËH\)AÝXDíK©|Î^·qãFâÓ¦M;é¤øy¿Çú¼yó°²~ýúÏ|æ3
£Ú±î¥
A
9#hdã¾æ9ñk'
?íò=ð2båìÃþ>Ô?ßÄæo?ï9¢4aiÓ»Øuá>øM4&pÃ99£l2 ²Zsr	NÌ|\·6hÓ å&-[6þü,4qöÙg'ÞÞr@QÏìuYP"»Wån8ýôÓÓÚ¼yóÝwß}³K?üpÆ5ëwÑDËSOOOú´VùICCC=¥Ô¸ù²E¦É¿xÁó«
WhA°Álr´ ®	3Ô¨Xº¼íHÜUqX³ÍÆ MøIaÐggÄ'Í±ùÍTHËÜ;G­Ly¬Í½SW£|©½y,ÖÙ,j»4¿íª-<÷'eLÎÆÍ^WMØeòðLQy>nìâåÈ7ÑßµD¾¥~èWk_Ì:ÎÉ)&}#µï6Ìl_77oÞå_ßwÜqMgÉÍ(j¦CÎóªô÷÷W¦å»H0-_¾<}VVÑDèw%ÑDh@qÎ¹çÞsïU1Ó%óãX0Rz¢«¸ 2¨RÅO7¢óMÐ,á_ÎKnV´mç<ÑD<Ve3\ó³'Ìlî¥m¤LqÞðQ¨X"MÄ!Mø/v<ItþiÂ&¿æ
îA2Ëµ&DäîÄx<ÿ®¡9ãW1 rç&fÍÊ6.[¶ì´ÓN«X Em4}ö«¯¾úSúTPÉ«®º
¯AUaZ6E¥»ï¾;KÏkÑD'ÐDÊ;\tM)&:&/Y(üwi³HaÀAMµMj 26SN¶1¦	,{ö° &ûJo¡kÈÌ¯£|Ä\R:k4&lªëªh"£	×^4ß«éNâ`mGt9ÙâçïNÿ@QÕtMðMÄ¸Hª¶1MXy£Ä`¡U«Vüñ'|rlwÜqg|3 ÀÛX-MT5^bìüãoyË[.]ZUÖÎ;×¬Y0EUý¯EEMSï9L)ú]4QT P,½þÆÝ9­c5Õ×qõd
dD	ÑDðÖ²E¼Xmr7{H¶Ý:¿øõÖ+¡4á#ëx9ÞB£_Ìça7üÒà4ªâ} +-°ÊÚ&üe<ÄtUei·&èÿ"
Ñ)¼¨ýhR\fM¦	6TU²h¥ØÀç¬H|q{Ù7ÌÒDb°Ltê'tÒ­·ÞìúÀ>ÑÆ<yÿûß_MüÖoýVUsj'zU GK,{,^¼xÑ¢Eé:tèÅ_0 Ø¼y³hB4!M&&ßè4wÓ5_^ZQÓFe×?Æfó³ZßN
HÚL!MpñKixs¡
Ióæ/hPà8Q
Âë(O4Q&^ã ÷Sûìü\ç-¡	?jhýW«eÓDÅ§Pl°á8/áÿÚú/íBh£ÇbpôA U4ÝqÇÇ¼}?xðàqÇÐÄüùó-[ÖZýèU5kÖúõë-O<+_
D±(\Ò¦q4Áhj?ÑT-féq,&Ó¬JìòQ.5Ìè¯"î¾2jP~h¢¶ù\Ú&lð"ßG ÔÛÆ{èÇ`W56l«hÛËÁ×¡8X(í:î¦=U±ëÑïxÊg}v<GÁJt¬T¦uàÀÒÄÀÀhB4!M&³çL%P (X'J&Òi	z²¨ÁÖÊ2HiKhÂ[û¨¿«Mh.ì¦Ñû³ÔñQ²§yì3
V²ÉÖHù¼B}}}Á¤Øýýý¿÷{¿×Zý¾hÑ¢ÅÇsdø<ãããoûÛøð?¼ukQ»@[4!M&
O¥ÙfÌùÌ¶Ô¯¾QJ1/%m¦&{Ø¬~Î5ol¬ÐA Á:'¦ÙÃ]°ØÍÓav,çÈNôz4&, 3køÙ1lQÚoö);c1'M5?%·ÇîæÐÎÎû+
Õß_xðÑù¹'é&hMànà¡p` +<5óVp°&¶²`\\Î§\ñAKh"1X(þt?22O}â'Ö¯êÑï±W%±5Ø!»Ú0-ÑhB4!è4à×9sæÖ	8 (IÒD`o'NÍéw}N¬pödaX\:óGl^Ú±-ôM°XhtùY¿É>~^l£^2`ÅÓ-jèûùòÆÚ4ÙÍ§	¢Ým>;Öuãu1ïlwÉæG³	S.M4Ñ8àCÐãk8,øÒ2|+Ã®
Ãá,.¹ÐD,ÞgçnØ5ë÷ÄÞp&Å®6LK4!èd
m¡»iyì¾¡,&hM=¶fOÜG ÿ28ø¶78vëýª«®:ë¬³ZE±WÅ¦ÀÎâXyûÛßÝó.Mt8MXGZÈáâ /¨:tÎ¹çÞsïÙ2ãæèMÔLìL `¨6~zä1ldT­:iÂJk9MÐ¦ÆøsÆø¾®vChy°/°|3üÏØdàwlÞméäóÄ!^4;-g¹´üÐñ×oh4¦	îÂ
= ë¸D@Î2òsói"J=5ÛÏ×|~Mä:»ª0-ÑhB4!èd`Z¼dIF @6d´i2MX=cZ,
Ö\ØSNq°PÊç}¤õë×Ï5+eª¸¦ÑDìUñS`gq¬T¦%M&D¢	¦eËnJ
ìBIÑhB4&vÅOñÖ[ÄxåcXyÛ]æ±û¢VÑD,´jÕªiÓ¦¥¹Â¨Mî'§H÷e4&6nÜ8}úôô92Ò+Ui&D¢	ÑhÂÅÂEãg
ùpâ'ú£N8á]»v5&¦M°:|ìcK##v¬,\¸Ð=eÓM&D¢	ÑD¶lÙ
ÀIÑD«hÓÕÙ\Þå?µOÜå2&ZéÌ~RBÖ}v-ØÎ6³F9û<4ágÞL®è©]hbdddÖ¬Yué[nÉràW^é:ë¬³²OÜ0Uú}Ñ¢E¾óæÍË2AÒ·¾õ­¾9=òÈ#¢	éwÑhB4Q»âá'°HÚ´&üpñà°Ð8ýÏÏo¼ß¾ÒZÃ/òøéf[kiÂ_,çïh"4Q¤ÙëÐjÈAì?Î9¯ÍÝ`4asa³Mq°bÕÊ2°Xeãý·vöº§¶Ðï¢	ÑhB4!HL7¯{¤MËiÂÓdÏä
ßí9£V°`g¸§±£áÍr8?<Ï4ÁÉÚxQ~QlM&M¢
¯l~Q+ÁT~:¬pP\lÂÇqü±BHáÎ*ÂÒ©XD¢	ÑhB4!h#xùs®{V$mZNühéÏôñ?æ X«	lO6å}êOéqÐZ°ÅOôfìÃéD¢&ÐhýAlòqÒùøl»E:SÒ4H
ùË£,¸¢\¼S®za£ª¿ GQs¢H§ÓDU®¢ÓÚu8òý&¬×=¾[Q£ã²Ë}m1MXSµîQ¢bÐÄá#¯ßþÍ¯[W<úSl,<M  æ5Ïõýû÷Ãì)n69AÀ¶ø|áRJ¤	¿qºÄCPÿ²ØøìqUBH[¶léÀKûÄóûðÞN9M@`BâÑ·ëiò¦ùvñË¿ÇM´&ÇDÓÜ¢r4á½<mÍòØ2²þÖ!Â·ÉA8ýX1ÓdÞh®5´â}Ð|9§	?ÇD<ÈGóªò+5mØ`ä4s"ø]Vy¿]l|Ó22â hkX÷ôX¬[WoÚ]x K"øté8À:¡	 ·p#,y¢ytpÐÓ¸°¿¾Ú¬«ILÀ/·ÄUÅ
NÊcQ=V CúM,½ÞÛo÷LQ-MÁ¢ö1Bß[&HaÌ;2Ñh¢å4±ó¥_Bèaé½®c£h¢U4¡¹°5v»Ó½Hd½ ôÎº!Ì¿À2fÃ´Å|[41µ41ÿ«ÛbÀrÇ]«
ßo9LzóS`úÍ[a»hó³=ÁyRÀÀÀÙ´í=>àåï:¬d_©{QÉR8V9«_Â¹N:'Ò4ÁÅ¢ß$ÓÕK7®ú^~¸lìb~!qzSÑDKhÂHÁÒ´Ó&D¢NtJ¤	~hòe"@4!hø÷ÿø¯D(ü2øf+Æ<ºÞhº[ì¿ùÂpÃG(Á÷%x÷÷M ÛE¢±Äì(fK¤ ª¼
ºQ&^Øs°è¹Ñ0EýN&¼j`~Ó; 	»L2æY4!M&D¢	ÛÂl©6nM4!È-M>òz9óì¶;î)¶oÂ÷YðNoü°000À8"+!1uèÞ_J4AL çÂ\±(ß#Å7T.	òJîXßûÕ¾üÊDý4aãÆPÐÑ7m4a®jöG3mÂ¡òE¢	ÑhB4!ð4aå×ÐuB4!È-M ­xô§1JÀ6ë~°ºaÿÓDÇ
4>¶3ÞÂLÚóF²Chÿc#Í~ëèÓF+Y	f]X
F4%VÇ2ÏpÍ5×tMx¨&*êýX§×<¾hB4!M¤Cnà&rH8#t  óºZh¡o"pÜWEU(hk,Å;=ñü¾Ö¾ lÃ³{'~}d²3f¯Ë²¸¦z©hü¢ß1¶hB4!MÔO´?ØÅ[~8M£	Ë)ÐìuM¦>{Muºã­w9½üÀÊhN¯«h¢Ýi"?ú])H£££uZ ½®A4á×M&D¢hh@Ûq/ì¨e#È(l:0?'»oB4Ñ|àtuë!ÈÒ}wBÆ¿xW³øbD¢	¥Ü&ÑDhBsa&D¢ú}~èNæGÙf£=p?ÚrÕÎV ML!MØ:ç¡ãlMñ°·äeR¢H'ÑDSáõ;uhB4!M&rHÀÁE8(í´ ¢S¡&D-§	nÇ/;£ì~4ÑhB4!èpàÇr´ÀDK@4!M&bßÄÊÛîâ´5	4Ì¼Í¶}çi¶AÂdÔF4ÑÀS¨a&ëâÑ±E:á¶p`+:Ñì
ðÓêÍëd¥qE4!M&DmJ$7Bv R`ìAÐÑL4!´M&
O~¦?Z¯Wæ³àâ4Á-sóÇâ/ÎN=8G¡hB4!M&Ú&èXyÛ]óæ/à÷"öN@ÿµhbÊÓ;D¢	Ñh¢-h½à)i"ä4¦	Ël4A¯xTUÑhB4!Mä&³J§¤ÙH	ï£`'ÑDJí>z{{ûúúöïßÏ]hkØÈ¿ÌÑhB4!h`·wï°ðUÁ "ª¥	+-Qq&D¢	Ñh"4ÁÕyóøÁ]m
õÜHÐ°îØ~áFÂ¢cGîêê>@@nÇ
~±NÐ`4@¬&D¢	ÑDÎi_lB?á¶P;°·.Pô3T¤	+ßza´;MT5±hB4!M´/MäD¿þ¡3±Rð[ðwttÈÁÁÁE¢	Ñh"ÿc:üHà¶ÅG%ñ³øÇøË<ìOa»âÎ*R12NZ'M&D¢)ÑïÿcÆÇ.îßqû7G¢}}hÂv@V`¾¾¾à(ÑhB4!Ð\Ø¹oþzÎAG]öæpgv!!
ñ/Ý43ÅFÆ]M&D¢	ÑDôûSÃãLÑ^4ëb¬ }±£#&KaN¢	ÑhB4!È3Mpì?Ïµuë`ÿAÎÞÎ7qYüÇZT°ïfbã®&D¢	Ñh¢úý?üÈ9×=kËü·ù¿m´@X¤Óàà Ö'&&<M°k¶LÈ6øôXKj|´iMÀ*ø6IÐzÐ5HXwír»l¢¿Ñ>	µMÔé G°÷iý9?»u95Ø ì!yM».M&D¢Æ}-ÜþW¬Úyóº_~e¢}}¾ßÄe¥äiâ
ðK¥ãÙz°ææÆ]M&¤ßE¢aj¦ÌìNäv§	ü2,¹'ïÄ®Ù¢	Ñh"H¯¾vxþW·A,Õ¶Á¥AÜ&ðÛÌËlMÀ®¶¾ÕåÆ5J.·4a¡Ó³àl&iÉ4cpÇ]M&¤ßE¢jÇ©ÈBï?ãÌDh; Pø¿û÷ï,MEá7" ÚØ«B4!Miõ¦ÝÇk²{¢iÒî	\`3
ÁÆ [âSc"3j¿\MqÅª7¯{1&`ê8-)Í¹@p MØðàXA A:Mpº"<ÒbúP¤h¢]jñâ·@ÔP0BÑò§Ð³¯½¥J<J'PB¥hÔ-¸9ü¢ÂÌ°9td&D¢	Ñh"G&¼3µHg:ÎØÈÀíñ'5l¤§ì@ÇËÁ
®wa`CY¾?µim$M±¯Ó;&#^~eb²L¤¬}NWMËûÎ?ôÈc~Ó& Ì°gß&°Å·ÎÊM&Ú&¥¢÷Ö¾í21"ÈBV&E®}9M&D¢	ÑDÎi(qÃÚ<Ghé½é8ó#Pì ÐC°â½ÿ´üí/ìaå,L/3`eNuÄñÆ¾¤Ø®/4AgwRÐï@4ih8Q©ù&È7sxâù}j#ËàÓc;þv3:\Û.ú/ØÕ¢ðéonþz'?ù_Ýö³½¿M&D¢üû&ì®|±Z$[ÁLzë(AG~é§lþÁÁA¯pA%ÔÈ<6À
îò§F!äãô ãòM¼üÊÄÍë^ÄËWz²|/lvg ¬¼í®Ø§P&nÔ>ÒQ{öð`Åt+¯ºÖÎ%h9M¬{z|ßFì¯ù@³ÐI's¦Ð£§üÉÎeG{[t²o¢lÑhB4Q°^Ø)DÞD£¼¬øåÖ>ì|¼ÏüÇ¾AQ<ÐA. n¥µ~AgmÓ­¶Ë0ÅªßD ß)ÊÑ-v&MÀøÇ_nhâ¡G#°CDz¿	ÂÑý2D¢¶HY©cÓe¤	oÈ@QÐÝìUÐ¿ð¤ê7!M&DmG):&%ê83ïm('Ûä	ÿ  Gù-Á±þ¯?5ÛQr'íd0¦H!ÖS §ÍQ%o@ÁÁÈæ]<ÓIasOp YÛ(M´Eeðñ»(¬L<ZÎ@ñ(/E'K_zlÛHÚ&D¢	Ñh"?ú='4Q¤¤ù&4¶h"1Ý2ø,6J¢	ÑhB4!MH¿&D¢ªÒ«¯ÿÕmX°"i£$M&D¢	Ñô»hB4!ÈVoÚ}áòíX°"i3%é?ÿó?{î9ÑlÑhB4!M&D¢bÓÄ«¯¾¸Ç[÷`ÁJsÜ6Ôï¢	Ù6¢	ÑhB4!M&DÅ¦Õv?ñü>öÂÆJsÜ¢	ÑlÑhB4!M&D¢v§	:&y}ù}ßÂæ¸'D¢	Ù6¢	ÑhB4!M&DíNH¸ç[¶lýØì9X°¿6¢	ÑhB4!M&¤ßE¢	ÑD8oþÑ±cÁ
þJÚ&D¢	ÑhB4!~M&DÓÚµkA{Çòæc±QÒF4!M&D¢	Ñô»hB4!HGJP`c£B4!m#M&D¢	ÑhB4Ñ¾4±lÙM r»AÒF4!M&D¢	Ñô»hB4!Qbéõ7¦?dhP&D²mD¢	ÑhB4!M&Ú&/YR%(YÒF4!M&D¢	Ñô»hB4! JÜsïÙ27(D¢	Ù6¢	ÑhB4!M´M@:a¹oÍºw¼ã®çg±êÝÒ÷uÑD#¤Í¡CÎ9÷ÜªPÂâpIÑhB4!M&D¢ÕïK\íeÖÇ>vê©§r=?ËIïz­ßyç¢)~¿þñ¡ÚôÄá(DÒF4!M&D¢	ÑhBú]Ò¦£h¢oÎ¹5£
* MHÚHÚ&D¢	ÑhB4!ý.i<³íõk7¢P ¤hBÒF4!M&D¢	éwIÂÓÄØØØ3§%(P ´MHÚ&D¢	ÑhB4!ý.iS`Øµk×ì9s©p§pA(KÚ&$mD¢	ÑhB4!~´)$MÀÚï=õ(a@Âë
Ñ¤¤hB4!M&DÒï6ù¤;:öóÆi:SàD6¢	IÑhB4!M&¤ß%m
C[¶lýÄÙçC·Ýõ77þ-¨ªoç{¦¶h6Ø^¬`ï#cé@át6¢	IÑhB4!M&¤ß%m
@k×®=oþ½ãËi¨gÎ7+øüì½òªkO{ïûÌH\p"'´MHÚ&D¢	ÑhB4!ý.iÓÖ4«~á¢Å)(A^ 8Øßoç{&ü^¬_ôÙKÒUNV¢	IIÑhB4!M&¤ß%mòC+V¬U_QCUE@	ÿ7eÁ©QIÑ¤hB4!M&DÒï6mGËÝtÍfÑPàÓÞû>üÚD:a¯-~AP
þìÏþ¬ØxM)I¿wM|ñò/-½þÆ
¼påU×~û;ßÃ²}ç-¢)ðM`/hâ¡G«Jý¡¨¤MÐ¤hB4!M&:&$m
F,ùú]C±Låhº@±gßª4 **IÚtMHÚ&D¢	Ñh"Ïú½««k``Àþöôô'æä÷}¥ÄÁ!ÏPgêîîFöïß²gÄue¯jÅ1çÐÐ~§ðÔ6Í§Csî¹÷Üû@U*;M°ßDUÁN\P%TÕMä³n)â´ÎTHZÁ+M&Dy¦	<Ç_M4&¼<Qýa#5ÑD)ù£££Õ_PBÊHßÓD¹£	Óøï¤MÞh¶úç¯|¨Z
¨§ø]+È9888PJ¨?þ"3d»ú)¿È£â&Kßíy
þEQ8)êí
Q <Dâü ¡4£xá¢¸NÁ+M&Dù§	ã.¢Ð55Õ¿kÑsa¸Ì]Îf¢[	d
üñâEÍaÅvþ2¦	å¤)ã^ÌR¶TKYo'HX ¢	Ñh¢N±{BN­t2õfÂÑBìû¿a##sÊÑ)5zÒí¯tò%Ðo°@÷G9HÏÓOd§NñM ^©ínÄwç,uf´bÅyxFs÷Xùñc3CÒ¦Éú_õ! &3Ïy]Î
z^¿02ÆQ°Rgá~ìÀ=¡H§<D:kæ
|µLðrà8
Dq=WÒF4!Mä&b¦M´&¨³ MøY®
j"ZÂú¥6¤â³
©Ì»ÁùìëÇ-q	ýe¶É7y+µÌ¦¦¹Wa§,?B¬ÏFø;@5íOdy¬ï9ÿÚ©í¶X$h"oú¦ø=Gy}íÚµüÕ§÷eÃÃJöÞ÷
ÎÓ6"ìo U¡ªJ»Æ}bñ§®^%´M&D§,-N4¡$=.iÓýîÓ-[»gÏûyUjûÎsº>{É¼ù<2à/PÂg·dYP%TÕëdi#´M&D¢	ÑR«R«|ú6íEH;vì¨( =ò­Ca%®¼êZ¬·ÂfÍ®a"l¢*ÖáÒ¦ÝiBRHÒF4!PM&~±/ðJIú½Chi×®]ÓgÌ¤VÍ²öÞ÷=&°`cÐEbà¾µ5 ªÊ J6íN66¢	ÑZhB4ÑÜRÒÜR~ï@=gnF yæ,óAØK4v¥ô%P
AQ6¢	IÑhB4!M&¤ß%m:&¶lÙzÞü5Äá(DÒF4!i#M&D¢	Ñô»¤M§Ñbú£c?¯V©á8(!´´M&D¢	ÑhBú]Ò¦½hi×®]Ý³çþø¥Ë®Ñà@IÑ¤hB4!PM&D6Lé3fRW\
þb£¤hBÒF4!M¨Å&¤ßEÒï¢,@±xÉp¬4%D66¢	ÑhB4!MH¿KÚ&ÀX$mD66¢	ÑZhBú]4!ý.´MHÚHÚ&Djq¢	éwÑô»ô»¤hBÒFÒF4!M&¤ßEÒïSn¹å½{÷øwìØÑßß_ìxÏ=÷
þÖ|¾¾>® Ü1Üo$c[w+ò±^g£ë+¥ª®1c±h,þ=éííÍùG
C¸e¹Û¸Qï§hB4Q0ã?&DjquÒÄ{#ü²ý'D¢öÕïx¬Ô[J0Ì Ã

§>é>¹¶¶û n]qy,¶ð%D6+y-%T!CPmOL4/­´*y^^ ó[æ&üÀIyÉ«ÄáVïX|ÆàÎÇcqvE¾å.4?¸øýÒD|Óü£aãA<{FÁS8$ûxzâÂ¸¦>o¿	ØÅ·&ÞÏàM&yÍx8Y?Íàå4ßD|sìåäKÂ£Êù}D¢ö¢	Z;`
¬Ã|M&Ôâj¦	Py\>ÿ·ýñiÝÓc^¦/øÊ§®^Uìk|o÷%Å¾À³ÝÅoyâï3³Í¿ôÆ4{Éw¯ÝÅp´½	ØV¦ÙWöyßãtÚÃö½ÚÇíðXsÐ^åy~¦i¿Ìñ{ýYè£ñÖ¾Üfyò$r4aówpF_>û#áàÍx3ÈË]xßÑ<¸øq ½Üß´&ìxoTüÔâ'NãÜÜ%Á{bì`gÇ=ñIþÙq=¾Á,gÎ)ffðrZiñÍ±[4'·~7nËÜÖ5çÒN6Å[ðñ(|WÞº¶Íwïl0LYÑhB4!M&H0¼l¯i'}¬f@í·Àö¦²#Å¶¥YtÞd½¬Ù<1MXµKcßÕQ?JûÀ!«9
-RKé4açµùÈL<	:$ÒG*Kq¤]~"M'"øÂ&_£/ÓJnZ@æ¢§ZüÄYUk.&[Bñý¬HDøÎÇOÓ¿&#M&D¢	ÑDÍNÜü¼"éÔÖ±fÆ
hñk0Ì$FÀFzCºvw[¹tMGûËºö±=Ñ¶¤åæ
éDP¤hB-®NØþ1M<5<.M´»~·¸\1[]Mñ×º³{©Yõt
iÍoÚÖ÷XÏÑÄßìRëIÍÁÆ¯î<;(%,OäË·oõ´Hí³u§e=}5èqð=yþÂh4Ú®Øì÷)¸G{+'1Èàï ìU_ï Íf_Ä·;?¸øù ØÛwº·fÉõWÇø©ÅOÜîaÐ¡#ØÂ
Ûõ9¹%å~ÆwÌ¼WÁíõ½Îã§¼|\n¿'¾WKâd¢	ÑDÛÑqhB4¡W3M í|é.ßn^	 Ä¤FMN¿7>¯öMü:ÝîWØ,êÀÑDht>¦b?MÑh¢hâÙýÂshB4¡W?M0ýûü×Ë¯L-N4!~ï´ÄnàS2£YË
¼L_ðO]½ªØ×øÞîK}g-º	K±¯±kÎ¥ËÜç>5<N³t ¾ZûfðsHÙ°N '¿°´é§°_KÈÌ¾(nÄ¹ ¡w$mò°àÅ*i#ióÅl5[ö|eõað %¸ë?%M&jóMÇÑD¢	éwé÷zhá£É
MRCfnÐA¡ßNVÚÄÄ/ÂßÛwþXÒF4!i#¨&þá©ÿÓ¿ágó¿ºíÂåÛÜº[þä#¢	Ñh¢öH§)é¤H'ÅHÚT`ÿCUÙ_ £À/#ðË-ÈÆa ÂDb+
ÙL¸KÒFN6tª-ÒéÕ×¯Þ´ûâþO<¿oöE:&Ôâê¢)D¢	éwIì	6¿w=L
MIÚ&Ôâ¤ßEÒï66¢	IIIÑhB-Nú]4!ý.i#i#i#´´M&Ôâ¤ßEÒï666¢	IIÑhB-N-Nú]4!ý.i#i#´´M&ÔâÔâ¤ßEÒï66¢	IIIÑhB-Nú]4!ý.i#i#´´´M&Ôâ¤ßEÒï666¢	IIÑhB-Nú]4!ý.i#i#i#´´M&ÔâÔâ¤ßEÒï66¢	IIÑhB-N-Nú]4!ý.i#i#´´´M&Ôâ¤ßEÒï66¢	IIIÑhB-Nú]4!ý.i#i#i#´´M&ÔâÔâDÒï666¢	IIÑhB-N-Nú]4!ý.i#i#´´´M¨Å©ÅI¿&¤ß%m$mD666¢	ÑZô»hBú]ÒFÒF4!i#i#i#h(M¼­ý®bÚ´io+nzë[ßú¿ùo+t:æcÞò·ûÑÜRÒ+¥Â?DII'¼¢666yH¸@\f/ð¸ã;öØcûûûïjÿT«HO+W®,ö®X±¢ð±ð/ê×KIQÒFÒF/ª¤¢¤M'\ R±=hJJJJJJJJJJJ
endstream
endobj
152 0 obj
<<
/Type /XObject
/Subtype /Image
/Width 1050
/Height 552
/BitsPerComponent 8
/ColorSpace /DeviceGray
/Length 584       
/Filter /FlateDecode
>>
stream
xÚíÁ1   Â þ©g                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  àon¼
endstream
endobj
162 0 obj
<<
/Length 1250      
/Filter /FlateDecode
>>
stream
xÚµWÛÛ6}÷Wè
#ÊÀMô0ÞªÃ8ûr¯\yTzãÑåÝ¾¬UkòÒ§pÓ×«`ÑéJY«îÿÿaAÄ²PUæÑÖ ¦óíÙBó ~u\}S&¢kÝ¥)uó
ÛØØö¾¯Ly4R¨uÙY¥d±çr½?©5
¸ëv{e¿®¼ª»÷aÁÙHPÌy"	´/Gø¬1·ê{¯:¤7}ÌÏªª>j¹o¹7Ë?'Ãñ+­¦I./Ì>¸46¯Õ¡;þº[ÝÞ_{w nSÈÀÀGÊ.t
,«WRÎF\ò¬WÔ6õSW


endstream
endobj
157 0 obj
<<
/Type /XObject
/Subtype /Image
/Width 680
/Height 666
/BitsPerComponent 8
/ColorSpace /DeviceRGB
/SMask 167 0 R
/Length 35720     
/Filter /FlateDecode
>>
stream
xÚì½ÕþÝLFg¾$æ?/¹~(bL¼$#â ·ÑD`(0b¤$Ñ
x¡¡	7ô4¨Ü±í øqÛ`K@@âgWVß#ÏÊûß³ëÓçRçªsw½ë¬ª]»vÕ©Ûo¿ïÞûÝG©©©ùêIÿ°eÄ)R©T*JKUÁzÿÈ#<òHD"H$RÜ_¸páß~òºqÏó7ºD"I&úä'xà#Gýüýû¿+¤«áùä
&¦xþ¹>p÷â²=äH´W/õ[ì¾îkBc ;=5ûV¤à>òãYugfþ+'÷-½ïLÇ%rWÓü yå#'ÿ¯{¥ÒrßÌ
cæ¼v´`3Djîó«âîåj2î{ |ÓñóÛÉ¸¸nîª½àé|ÐÜï*^£F!¤â~úõÎ&¬Ó½Ìç¾2îkÈU¼4LøæÂ×5jûlÅC
7Y[·j¶W`Üçù»®~]íd¸Ì6±æïOwOÑÞ!îK³ã>áâòÅÞ©Ï?ßã5·Ëýo±Vl²ÎrV!AbÐße(4ÚB­÷qVÈÙ<½ÔÜ·º]®2g»ÂN¯¼åd!æKL³-C*þ8>|IØkÅ«{ïrÏNqnËö)p¹´zÜ&<{+¶÷¥É}¾¶P{IÝO¨UæQ2R\_mj··¸/ÍûnZ÷
Kÿõòáüèß±ð­k{}÷^ßüî·ªêC,À&LX¸páÁC¹Ys¯á±ÇÛ]
¾â~dåÆû7î|ëÐÍ³6oÝupÆò×®ßå³Íû:txG
¸/Íû\~sÛïÀý}û$ËyCá¾ôo¼÷Åýãþ/f~Ü¯OÜdÄ}Ü¿æk`þã)·Þzkß£ÂúÀÔ©Szè!d3¸/õ¸OÅêöÅë Ýº_ûà}XÅ26qÙÛä*7ßà·ucúë)w$ä>ó»
¹Ü·:­=ÌÌ`'éV£°Jïi5PÎG%3¿g¤X9Ä½¸/îgäçÇíÛ1¶K¹ï:ñ¾dêÝ?f}|Ùì{hßR,ìÚó.ùÏ}ÁøAC
?¬ï¥ßÛ_Ü÷³ã>ËJ)¾0öàñùde)ÌlÐÇ.xhù0£ÔÜZ.Wß}þ­òd·gBn[5¡÷5÷Åýttïâñî|i÷*Øþ®Fûx¼Y=¶
¹n5Ø,D{¹/^+{ã¬æÌ7ï5}®OÜO-õõõ:uJ³Ç¾ùöqqµ]ß>n6¹o7)é÷öÇYáÜÄ}q?îÊñLã®ùÏº¨qßm`ÁjîgßbÝ«÷ºÜ·çû2A×Þ#(îûÚû	LýÅâ>=]tõ[ÀªÁV·­ÆVíýâ¼×ôËë Üª¸Ì±yee·î=2ê±OûÅµbøcM 5÷3òíà¬pn8ÃÂ»ýÅý¸sßl²Û¥<~a¹[
óÜÅå>ÔûÖØ5ÞÔÜgT·!MÖLÄ}q?Sî{f~ì}Ïx$Ü|<ñÂº¼07ßD«¸mg¬Z³z	ÄýÔýNÎùh]¦WJ»¼î÷51ûVsÍ®ôgó,°Û_Ü/îó)%s½/çç·JÛsÕüùöl»I·yË·Õ¬ç%÷Åý#ÙÆíÙ1¶qþð½ârßjàÞ_>üÖÏßÅ:o¯IBî³M
âõi_ý¨iÜþâ¾¸/îK¢Æýdq{`ïïk&îû%àØ/¢Û_Ü÷Å}I4íý`ÜÙûâ~ÑûlÙµç]öµ£Û¿XÜÇs{·&ëÝµ
µd4Éµ÷m44Òé)e(à(i><ìB.{nÿkZS\®¹?dòú+&¬«ýÍ.ýóÄ}»/¼ÔnhÞ^Ò`»¤fï[N>Æ+Ê»òîMÉEGvÙè§¼Ëå)¶â	¿ý
Áª[Z¦¡<·?.Ú]u3¥Üç½péî3<l°
ýìÁg,))ô®ÇÖuêùÃv³õ%¿ñÝÍlØBï{|}þWm4èêìûø1 y²¸Ç®Øåµe('ß=î[%M<F± ï;ë_vþUºý¿?ìÓØKôórM¿%õE¦â^àx÷èç¿¬¿âi`µòöuî½ ýÿöOçÃÞÇkbwÊ¦1ðFïÅs£¹Ü^L¯¨Á®CáÔM£ïúÁ-3p¦/~×
:¹ö%»ÔOoöpÐÐÐÃâ¾=¢üGvÅøg­sâM<í:@¼Ùv/1õ
û¶×ÝÁPê×ædüÖ±¦0î±}úpk¸°feQ ¶â.x­ÃL´¡äç`~~YZöë³+ì^v6cñÂºWÒé%ìÉKjóa1'çáuö
»v§_o¿>û§üGæbw;k¦¸¯	±n·#õå1Å
®=fÍëeë"nUzDn7ÅíÚH±P¥·Gqz§WÜ÷SÇëÝ8¾QÞ¯¬âôûâ¾¸/î§ÙÁ/£î|ñâ¾7¯¸¯yy4/¸/÷ËûÈÏr°©@ñùKûáºý·¶´±%ÅZvíy7Y½×¦cÝ5­Q&ýæææ©S§º)uGEÜ/Oî/]¶Ê#¨^üq_Üow^ÝsªhïcMüâ¾¸·?±CÅÙKTY®t÷e´RÖWÇ~×®]zè!.ãÚvìØq¿<¹ÝQuS¦¸_nÜoØ;8ï¶Qgí<¼/lØR;ïqÕ%ß¼´{gsnÅÿO<	éÐªªñyjõºrã¾¹ýÿùüY·!»ðæ^ÜdÜçÐ?Ûäv°Ìú#sÆ§éØ¯¯¯ëqU±|Í5×xæ¿¸_&Üg÷KÜ

Ü9ù°ÜaÂ~,»¬/>ªø/¨3qFçá7þïQ9p2iÒ]:qÿôY¡±ÇíCûf98IqKp8Omÿ±k×®°ú·oß.î÷iG'þíE'¶FöÜ·	nV¼¢tÃWÚ=1ÍPäâ¾¸î]<wð½¦E ?gãeû>§åMgfÞØqÏ9èÜáSªªª`¹xZZZpýO9åT3QKûtûtunFse$ó ÷ml>Ã&Àe/}Ç>Î0ëû·Þz+¬~õç/Cî»O&]ýn>n
É}ûvî|&Þ) 9ô¯Äîýñ²ÃîîÓ§O¸.ý¼J|¹Ûv
¿¢ôÞïÚó®AÜ÷í»ùÛå~îý`¯þì÷û¥Ñß¼R|ðlvi78S¬×½íBïYå6ÊÞYACÞü`yxÉ09_ _ã÷Åýôõ5³·­ùî|©0óðzq ù¸ã>Wù½«f>Zcd<É÷ÜûÀ%ß¼ôØc½öÚaÁnùâ~4{ûçÞW3Ç¾âõû×'î0÷¬ázÀý½?Ø²2áä¼yå>åàÁ.8p* Ý{ô~ãOïtºøà#Û¸Û'
ècõ-+Å}q?
nÿx9öÅ}i:Ê~}â¾¤(Ügþóðª?¿¸_t·ìûâ¾TÜDûîø}W£9~_Ü/mîC6oÝN·ÿ£uKèØGJ|ÿ¸/÷%Ñ´÷9~ßWö¾¸_x¹«nó3ÞX±bÅ¥¿x¿+^ÜuÏ-â¾TÜ÷%!¶ïÛø}ó 0b¿Ú÷ÅýÂËÆWþpý½ÍX¸tt#~±q_*îû¹oã÷y+hü¾¸_TûÈ&ùà>~±ëÿ"îKÅ}I4¹Ïñû`=¬~ß÷£`òûq7öÅ}©¸/2÷Aü}
Gö>k<nîè÷eìËØÿ-+Õ¯OÜÏ÷vñdwÐ' @#ùÌÏÏz¨íqì(XfÉ.÷±û1Ïº§A©rÓ¦Mîjkk«}©ý²â¾§Ô/îûaµïé0º_çAîc/lE%Á³÷­u hï»Üºý{QÜO&:urÑß½{w¯& c_*c¿´¹ÐÿÏÛo´Lìåw¾Äpýï5-÷Åý¹"ÛwXwMtûsé.÷
 èÜ±}Vk]ÃÝGèn²e,¢²Ë:ûtÖ½½°Õ6ÉØäÎ},¼³f¸/îKËû­­­HÇ2* >R¸JÁ2w,÷+Gc°N}Â¼[øeNü¢b`N-·Â]ðker,*û¬²ñËZÐ°j)íÆ²±/î§öó¿1óG»çTaß59ÄO~~q_ZªÜ÷ôÝU,ÀêgÅé&¥Äý}ËK­².¦Æ}3ÿÙú5¾õ_õüü.÷éËÂ*[üÍ'`½V#Xeìûq_Ã4À}¬ ¨_¸/-UîÃ¢¯¬¬QåéÓ§ææç?tèS¬><æç±OÖ{Ü·^(üuÍ|,Óx7
èe~Ö+è¡-Iîñ/Ý-gîñ®ßóÑÿ¢hü2öÅ}oü¾Ë}wYÜ÷Ûå>élaôØëÉº!m¸{AÓ@î[fÆáwG({CXM¾ãFùKèÌç¼lì¾¸pß#>µrÂz$¡Þ9ï~ãÖ
fW¢_Ü/CîwûÞè'ù/c_Üç<¼ >»óû­SûqvµïûÉ¸O'9çÏµ&{#õi5ôó'ã¾
¿Ìo{1ê¾íÂt·Xq_Æ~èJß}Æ¼YªÙoß}J/ß{ÝæG";¨e_
÷·ÇUöëSû¾¸áÃ¸´ÇégO$Z@ìöLÅ
¹Ï!Ïî@æ ÷±£uÞKhï»»°Q@Ü±/ÄËØ÷3ÛcÚî¼â¾¸oËØu9Yû>ºíûä>Ã±Y?÷m öp;¸±M¬¦!îËØÊØ÷ÅíÜßY3«uj?èÞÅãÙÊoa|ÚWÜ÷mÖ²ÞmµgÄQ¶ï»¡Ëmü¾E8GNOv#»môÈéíe±`ã¡¬Î`ý¥s îËØ±/)1{ßÉËq|éwí÷Åý|ÖW¼>}ûP¸â'²G{_Ü÷ÃR<WÜÈØ±/)"÷wíÌÞo×½/î÷OîpJõèqÅÕá·Ü÷óÑã±ðãÑ¿Æï¨Ñný«¢®¸cÿò+®,úB½û'£§Þ4ú®÷Ú\/c_ÜwÇïò{÷Ú÷Õ¿¬¸¿gÏÛn»íæbËnyhð-³±péèFüb)E?«I&½ûÚÚÚ	ÑÊ±Ë«ÇÿòÆÛf¹u¡­æÐÔ"î¾×´èg9XÀªÆñ÷#"oí{ðä^oÛîãËHïß÷%4½òîÄºí«6íÿÕã-\Ö5ûÖÖï9üÅ}q¿ðR·¢å¾Ç·ûøÅr¬ÿ¸/	Ê÷o±üup;ß:¤")
÷wíòÎY¯ebïôgä÷Åý<üà~Ü}q_Ìäï7nÝÀ»dìKÅý7fþÈ
~@ÿ3Çü
ã.»WÛ*«VNÒ-
èûâ¾¸/îK$¨q?ô§¾¸/îûâ¾D" ÷³C¿ýsN<&}q_Ü÷Å}DMîg~úuøû
fàÏ1£sç3ÏïÒõþéïÞ·cæ£u|óÒSN9õî»§Èü÷sá~Ö*îûâ~)øN9eÜIÛ^{ñô©Õë
]°¤²2ÿ³nÁw¹Ïª=ü¼°¨¤ïuù/îûâ¾¸_ò~°¤ iû+ôó[{½ùð-w¦`GzÎà^¸çîæ[pµÌÿÜ»èãº²ÆeéV
wqõyyp¿x#8;irF)¦?ßü½>â¾¸/îûeÂýÔùïqÓÇÆõ[4¦p8"qîÎÖÈ\F.ØÅÏÎügÈ\1käE¢«$_¦xS#¹yÞ7Ësì{u¿Xî÷Å}q_Ü/mî·¶¶îÛ·ÏK9t(±mùûÀfÑ¥ÁèDk]%ôê3ð¯ëL&ôÓ1öÓÎ»JDîr¦æ¿9á-1/¼ü0bþ{¹7wJv»«gÓ¦Mí¦ûâ¾DÜ÷)
\î¿ûÆhr?Mó?!÷-*¯õÇKy\¾{ö~{n0ÞÖÖV«¬666ºU5q_Üûâ~P:Ï&>Ó§OG #&3ÿÍ§EOxÜgK={1ûô°­ÙæÃë	nû>2qu>Ë²DûíÿAî³«ïkh)R8ýqÂ<\`×ÞOèäÏS>îª¬¼e¼Yâ¾¸/÷ÅýBo?¾¹´_ùß½GO}È]¿»l-ûHä²ûË¾âüeü²Yßòê»ÐÏÂÀrÓ¦M¸84!cÁý ù?nÂ¤m¯½khvº]%,Ì¿Ä½h	SxÁSìÅæ~»_Á{ÑÚvà{ÀÉäo¶Ï9#îûq_Üo÷³¾?µÀF5÷±M÷Ãëaßå>xöAw4YºèûG6Lþ«Äëaù?fÌÜÊï]µ`ICáþ?µzÝ ÁCqÃßÉß?¥g&÷rÄ}q_Ü÷Ëû¹ô
l:Xv°ïÎïÒÕÌÿ\Ðo3ðØæ5aSéÓ§báÂ}úôépÊ)4ÿó{3ð/èÚµ¶¶öðáÃùþ¸S9¶ìûâ¾¸/îû¡Hsss¸æÁÆà»×¤¡¡¡¢¢"¾Ü§´µµåÛü//îûq_÷aÌæØ!ªæüÔ×¤ººzúôé¥ñnþÞÀ÷w*»^©â¾¸/îûåÉýI(æìì°ù_,?O"îûâ¾¸/îGÇüÏ·_¶ù_t_Ü÷%â¾$FÜÏÔüó¿Ä|q_Ü÷Å}q?:æ¿üèÿ¥jàûâ¾¸/îû1ÿeàÝü¿iôdÜË¯zÕ¿Ý¸eÛ+¯ö¿÷Å}q_Ü÷eþËÀ/®|ôç¿àYzÿOÝR³üç¿¬ÿÏCÿÅUq_Ü÷Å}q_Ü¤,]¿gÆò×ëÖ´A¹\òYÜ÷Å}q_Ü¹Éÿ@}ëc+v}/ÐSâ>ûâ¾¸/îKÄ}I!Mþ~ãÖ
C§Â<[(vdi?y+TÜ÷Åýä>àûæ¶ßqù×SîÐ·	ù_ î£Â3´#|UqßàUÜwÿÂOTBównýz_î®áì®®8Ü'ÇÓ/'ÿºÎ=[ÔÄ}q_Ü/aîÀ½­¢ K ,³X jeæÇ*Sè |Íú&÷i[ptÆ2~Q>7á7îc¯ÕõÜòQË´
 OÒõ	àè^¤xgn{ñÏûËgNL¯¸qÖ£°	PKh/#
e`
òð-/ÝÁ+6DîãÐÞ?²JÏy°s0c§MÌÃBp)¬å ÷AR,Ã³´©H ÎvüÒ`'Ä^;Âöâ.f¤ûó^¤ÙÞ·r°{DBËH·óÖ<ZïUPí};.bÉn
òàdÜ;[UÂó÷%â~Ñ¹.ÐnÀì}Úõ¥#'7îÈFFòÇ7^1 rMÿÈÃ£01SîÛÑ½¶~+
Æ*ê8=«*°÷åa
È±ºÌ_aµs[pï8ÒÜ'Ýá·÷¸¬{×-&Á>¨HÍòÝ<LA!($%÷­X¨ÕCÂòóó(ìº Xã<ÝÿÈC»$sZ0²ñ¯awDì}óóSéçÍQ¤ülì·ª`p4¿@³yï¹/[Þ±/RØûV>Ë!¸-J¾ÿÒr)æ°æ1?ê!â¿¸/÷#Ò¯
VÒÚõüüÀ´5©»Îyd`6ã>J 7Q FÙËCæÚrXÜ·¢p8Ö+x2¬Òûnÿæ:`ýÄí6½\7H!¹oì£w4oÂ@97aÁv	úù4d~0L÷òxM,Ð%5öb9ÙqhF(Áê¬x¸å»çÀ³
 p³÷Ãâ>8îzàqè2Êæ	Ý	¹Ê¾º÷ÑØp¹[D#ýÁAg)¸ÏÎó.ÓYm`ómêdÜ7Þ¸ÏVª;¬ k??Ðo
 26!Ås5¤9ín·|þOU¤xyl¸"ó°râöHÄ¦Â÷ëÎ\Âjæ¨g/;ú[i[ì7m_zþ½<ÖyøkÅ²×j Y÷ë³æ@À4»íY=Ö[ÂÓpÿ«ÖÀ­K°¢$;¦oîèÞ:ð|´.yÖPÎ£¤õ=Åì_ïØç¬aËä>Û¬|fæÐÓÎ& 
õà^5Ö³(VWâå±²Þ.wþâ¾DÜNû~¹ÅëÙÍÑu_2ñú@XT-\Ã¹ñú²½XñúBëWôx};û²r¢q|â¾¸/îG-N¯Ú³ÎÿåÉ}Èî8q_ÜÏNÙë~jë^Üûâ¾âó+>¿âó+>¿¸/÷Å}q_Ü÷Å}q_"îûâ¾¸/îûâ¾¸/îûâ¾¸/îûâ¾¸/îûâ¾¸/îûâ¾¸/îûâ¾¸kî¯yù@åÄõ ¾«HAº¸/îûâ¾¸/îû¥gïO[Üâq)²÷Å}q_Ü÷Å}q¿$¹ïüq4öÅ}¸/îûâ¾¸ÉGc_Üûâ¾¸/îûYü15öÅ}¸/îûâ¾¸ÉSc_Üûâ¾¸/îûüC§6ÇÔØ÷%â¾¸/îûÑçþ#­$¿;æ¹õ/ûâ¾¸/îûâ~Ép¿æÑú»õ8ðþaiPqep}Ä}q_Ü÷Å}q_Ü÷Å}¸/îûâ¾¸/îûq_Ü÷Åýrìmwt<ít*e;I¸ÀíÛ¯ÿêµ/fgl¯¥ËVûâ¾¸/îûâ¾¸ÔÁCA¹¼kÏ»]/ì6eZM2Ë}«]î§ÈûÈ¢ö"îûâ¾¸/îûeËý­-m=bv=ê`=q?}æläôÐ ¬å6mÜÆÕ#«¥ ^Ác:È%YStÚÎçÜËØÄeo¸/îûâ¾¸/î3÷AC01uOÃPf ½ïâ&6RiÐ ÷R.[ÒvíyÜd)<Ìã6IÐ;Ázå¡­cö~p¸/îûâ¾¸/î3÷Avã¾ÛÊO^#e 3!÷­=ÙiîæÙ^
ÍN'£Q2ÓiÈó$tûÛãÜXÇýà&q_Ü÷Å}q_Ü/gî7mÜæ¤ö¸õûd«Kyj0Åe:3¸Ü¢*Ìû<d@"~çÎ_âq?¸IÜ÷Å}q_Ü÷Ë¼_Ml×@Daøø¥7>÷a\
¬f¦°2 <ÅªÙÝä>Ò­¶0wþ×Ä®=ï
òsØrÄ}q?wîÏ­áï9¦"2òNÐÉ|ö¸Oo÷Å}q?¦ÜôAOØp	zb0CAjRÙ z 6;¹Ô"ÅjA'?2· 0m^ò±Òz¤2Ö:S¸l¬- òÀÝYÀ*±!öµÝÅ}q?wî×<Za·º	W×GÜ÷Åýrd'gTÏ¯"ÑõêªLAm»Óiô$þÈÃ&~ËCÏ v7[ÞN9Y[0|ÓGµ¾« ¸ylwn÷Å}q_Ü÷Å}q?a98Ò¨'÷ò¬¸L's­&@w«^ÿ:·@.[9ÈÏÃ±Á7\¦3ÐçIb_dNÆý4{ûâ¾¸/îûâ~rÜôåÙòîzïWÃºyþÉ}Bß3±é°ö},¸Üwy´÷Iy×l§½<+û<\Üí}¶_¸ê¦»â¾¸/îûâ¾¸÷A×L¦N³Ý«ÖÏÆz3Ï]Ï?3ñ1®~óó£LÖ
ÈqüAîód vPvØãC6ý»Ü·­ô	Äûlá7;ZàÛB»ÙO9|Ä}q_Ü÷Åý¹ÙÏ×®±I{«ßÝÑs¸4Á^nb¬4þº6¬9
ìÌg§¬Zg){qä~pÐ¢õ¸HH£UBÏ?
péZç*ù ÝR,s°Ø ÷Çà¦ÙRX`e¦+ÛX¯à!¶^k;
:~ê,7ýò«®Ef(÷íxúøã(°vÞã/lØ"îûâ¾¸/îûâ~qõuÆÝ>©×ÅßúÌgû§ãO¸°û%øSjæ<²øÙôYLçÖ¿ÿ{^Ò÷ÔPÀuøiU5jâ¾¸/îûâ¾¸/îF7nyí{è_y%XÆWÎüÃîypáòõ¿Ïôé\ëoÚê ¨l ÊqÖWÏ)%îïkLwÖ÷Å}q_Ü÷ËûÞÂ~ý/©§ íjkÛÜóôÀßÞñô3zÿdÉåW]{Ó¤ßübÆK`}2EeUo\p®OÉpÿÃ/a/¼ãXb«\~°e¥¸/îûâ¾¸_òÜ§>X÷4L]`îc©[=zÜ%
¹rÐ¾¢¢â¯ýÍïT¢²*=òß7Ízr'¸_,Çúç~ËÄÞx»éHÄ&Öö5L÷Åý¸pÿØc¹è¢îÅÕ}ö¸¤z]~ãE=zC?^(öYpÂ	Ñáþ	ÇQ·)®ö0ü¢î= /tû÷íùk~VÇsLD¸¬Ô<Zÿ'¡4vÇ©ZgøvõóÇÌÿtü	Ø±ç%}QÈè;ï7Ð{
f>¸Sc?âÜ§EûØd­ÿâ¾¸îCúÕõ«=¶tÄ=+°ðýÛùí¢ÅSjûë'~VÐþÐîhZ²|æä¢ë-wÏtOíé¿úÞ¸¶Zô³Z3{Z²ëV\î§îß®>ñÌöîÇÔØ¾owÐÏÏÊÀ¶Qg}¸ó¥½Çûâ~\¸½áÞ¦W·¿6dòú-­ø=ðÆëqüyâ~DôÍõË®¹ãÙkãËïlô	GûyRùà~Lýès÷*¾ãÖ¯ÏÚô¹¬~}â¾¸©>×ôÊíl ñ§/~ÓQÚÜþúÑUP¿ó¬øÙ÷¡ì×'îçûÐc»ìkFî¿³fVÞ®¥/îûâ~
¿ß­Ï]1a]Lýrà>ÌüÊñk¡Ñ7öÅ}q?\î+n¸/îçÃäÇ+¾Æ~9p&?nSô}q_Üû°îßkZDcßUöç÷Å}q?k½êçwµ´ûQÖW]þ½Û×FßØ÷Åý¹Ï6ý¶¬ôõmu¸/îû¹èÉëÿðúïÅý(ëï×}Ü¯/§*îû¡pãø8dO~~q_Ü÷Å}q_Ü/Ïñûâ¾¸/îûâ¾¸/îª?ÍùwÄ}q_Ü÷Å}q_Ü;÷÷.ÏÐ=jß÷Å}q_Ü÷Åýr×8ÔyÚþâ¾¸/îûâ¾¸»®yùÀ¿y
îÛ2ÒÅý¹¯ñûâ¾¸/îûâ~Dù]c~q_"îûâ¾¸/î§ßÕ8Fé ÷[&ö¶	w>Ø²2´Gq{Ä}q_Ü÷Åý¢ü1OÜûâ¾¸/îûYü1ÏãþäÉ»wïÞ©S'üÎ7)6mÂjuuµåimmE
Òåç÷Å}q_Ü÷Ë­??Mþû÷ýÊÊÊCayß¾}@?6ûX¶;:@EEE^¹ß:µ_j÷Å}q_Ü÷Åý"ü15ö=îïÀ½ûâÀ´ß»,3«ùã>°ÞnÇ'îûâ¾¸_æÜ¿}ê¬o\pQQô_ü´XN¡}/÷i×ï¹?}útºúAÿë®».¯Ü½/îûâ¾¸/î§ÖUþðÅ/wX°¤aé²URèO«ª{^Ò7DîÓíO'?òçûjß÷Å}q¿l¹¿·iYÓÓOAªúª	k¹ò¼çþÈ'ýèÞ?,¥~å«ç<²øÙ,üüîihh<y2¹ÕÊÊJ,ã®þüqýùS«úóûâ¾¸_ªÜß¯°Ö'þã)ÏÈÞ÷ým¯½)ÜSkç=¦±ïq¶üu×]ÇåC±K¿qË>½ýä>öÂ/Ãò°e%Ãõ+>¿¸/îû%ìç¿`ÇýÕÿñ¸/c?wc?8m÷Êc~~Úøt°wmÿøùm ¿79ï±]Ä}q_Ü÷KûÉqc¿ÀÜÏÝØ1²ªãi§C»^Ømîü%Y}ÝÕ¾ýú³@(Æô±·Ý®bãA§Ï],c?YÜëºdÇ}">Ê¸/îûâ~õësMþûæ~Æ>4syõÚâ­-m9r(Öm 2­é8¡îÚó.q8¤/]¶ª(Æ~.ñúý÷q¸¼r¿ebo¼ÝA>wÏ©÷Å}q_Ü/aîÉ}c¿ÜÏÝØÍg5Àls JR#k®y>bdÍùÔÜgQÌMM·yµ@¹Æò×8ye¯~Ã
§GÄù«Ç[Ò¡.~~·ÞkZÐ	 îûâ¾¸_JÜ7?úÆ~!¹JË>Ýòà²}VhãnyXèô	¸y°Wû(¨ØJsö¾ýÆ%C®ºããàéÇÊûÔvé5÷[§öc×>¾éìã§ñûâ¾¸/î÷aòÿäîå¿nü0·aÑ³@ÖéFmËu×io)Aî£øWîÏ¨ýmïËÏ]Ý6nöÖ¾·>úÏzr'VSë¿ô:÷F|W3Õç¶¼íu7MAÿÇïôìÏñÅ}q_Ü÷cª­+çLym/}á3ÎìÔñÔûÆÜøæÚâ~(Æ>pïºÜG¬¢iÏ*¬uûìàrßzýü@¿µ#Ø.÷çÎ_â¶d­ççÆ!Ö^ï(¸º««)ôâá³¯¿§ÕLõg¾ìqèÏ÷·GÜ÷Åý2áþopÅ·ÿõã¿ég?ß¸å5|Û_Ø°åÚa?<áøÏîéÙÓÊûaûæ®7LÃº·xLÁä¾åÙµçÝÔíûØÊaÆ}T*ì Ø=.ýÖ6þÐ©Íé»úCñó·ëêÏû;Ævy¯iâöûâ¾¸_ÚÜ7ÿâ½xæ£uÁüîýïþð?ãÑ4ÿÀýÇì[;üÈ®¯?«÷-³y\îú¬X/A{ñ ¡û_ùê9w?¶6#âÅýtºöåÒ¯/ø[VÒÏoª¸=â¾¸/î÷~j¦ùoîç#@_(=êuPûsW·e1-`.ÜO³3ÿÜÆïgÑ¦/îûâ¾¸qî·kà§Ö¨ÿùæ¾ôå8f?îg$áÆí÷Å}q_Ü/÷35ðcaþçûÆc¾q~þ5Å}q_Ü÷ãÎý
oþçû2öÃ5ö£Ï}ß÷Å}q?vÜOÑï"Ðç 1$2¬ÛÙËH1
ªñûâ¾¸/îçûþñÕeeà§oþß9þÎç®ý ßØû×<8{SP÷Åý|p_q{Ä}q_ÜÏ+÷·.{äüs¿zò¿|Ï½´¶÷¡Û^{sÜø;O8þøË1û)Pþ¯úîØÆïß¾vÒ«É}hÓÓOûâ~îÜu¯øüâ¾¸/îØÏÿÒðýïpüç
V:äæAJþ¸3ß}{±ßUä÷Å}q_Ü/
÷Ó7ÿÝNw¬ ÇtPÝ^.ÖÙÏ}Lv0?ãýÝ:@>(ÚÉ_\>s²¥\xÞYîWÜ7?¦Æ~ûÝÿ*×]w_QQÁe{¡úsá~B÷Å}q_ÜÈ<¼)Ì×Ónö>§ÍuÃó3sÕå>ÜvÜÇ!ì(YøAýå-ÃÁz.1dèo§ß5ùcjì{ÜÜ«««Ý:À¼yóÀwÔ:uêdéÈÕüq_ã÷Å}q_Ü÷SÿsÇú¤<tÓÄ¶ï³ÿòp+Yàè<îk¾dö¾×o0÷ü~½/ñ7>1Ã* eË}ùýÇ?Scßã¾w}ûä>ê Þ q_Ü÷Å}q?µùÿðìßÈ®?Ë@|²qýÈd{þ3ÞÎ¡|	[l/×ÞÏÎÀOæíô]¹Ï+¢!9áôÈËåW]ûà¸Ç}kÊåaøÓÕÌÕÕÕâ¾¸/îûâ~^Çþd/Ü.ú?R¦?OÜ?ã+g?³n"(¦£}¾sÙ¤9©¹ßÚÚûæ
ÒÀý`¼>_óòûâ¾¸SîhþÀÀN¼¾|ûaþ):a¦9íB¦ÑójìG6^ß{Møj9´ÇS$jü¾¸/îûñå~æÁüp?Æ¾'ã+;@¹ïûk^>ð`Ãëyåþ¡ÿþs(Üß1¶Ë¾iP¼Ý\p5}èûâ¾¸/îG_Ó4ÿ£oàçûù0ö;vúÖ67F=Ã ôí× $2Ä¢kòc+ê,3#[¼ÎÅÀQzU3¦L«É_MÀ}ÚâÊë¯¼ó<q¿éwo¼ãÒõ{
Ð¾¯~}â¾¸/î÷Û5ÿãbàçûù0öIs7µò[$JNhï#Ã"æXgh+)fï[:'JÎ±oÄç$ùà>?±nûÎ·Þ¾Ï°½¶ð^Ó¢Lkâ¾¸/îûñRÿwOóÿúQw|là÷èV3ibìþH(ÜÏ±oLgæyEE7RÜPÉÁé°Éòcu ÚûV`|Eré¨' @wÖýïVÞp×R#>õ²ñÏßùW\í1ðö;i¬[Ó>Øðú
â»ÆþÆ'fì]·Øò`Ù]-1îç;@
x<cÇmùQk¼ïÞÇçÞ³oúüñ>ÞÇûx?nÞWoFôòÈ½ùåÿ]ð-ÿØýðßýVsëz]º¡c{â":~¼xïãýâò~Ï¶b\/ïÛk ¼ï{?¿Q¼õ¾ù~~¼÷ñ>ÞÇûJùåý"MöÃï}cyI_só¨^Æõá}¼÷ñ>Þ/lÊ/ïi²_÷ñu·,ñí/ñqÞÇûxïãýÂ¦üò~&û<·ð>ÞÇûxï·q}x?ïÝP3dÁûxïã}¼÷ñ~$Çõ¥Ö¦Ù«ïã}¼÷ñ>ÞÇûÅïnßÎ¸>¼ï_8qâoùZý«¯l(Þã¯ø³k3{Ê/«ÿö¢.+»æñ]Å{ü:çôþÌ¯Ìú®ÈûÅxØ¦\þ¥)E÷ý¾.õ¹ï5æÆbæk«v¯úNSñSSSOÐ	Òi*Þã7ÿö3L&ô­ÉûþìÐûî3|ð>ÞÜXº¡ãäûýÄ!Ìèé4"ï¼y¿»e±ò}½â}¼xïÞ÷Só>Æï÷ñ>à}¼x?zÞïmköÛ÷ïã}ÀûQõ>ÏíÁûxïã}Àûññ~ºçöØrhÅ5xïÞÇû÷£á}ûÜûå¾sìÇûxð>Þ¼_,ÞÖÏvï·£÷»ÖUnß®%äûxð>Þ¼1ïn¨TjvîãÃû÷ñ>àýèy_é¼Ïs{ð>ÞÇûxð~¼oR{Ï{æbçôâ}Àûxð~ô¼ÿÞ-ÚëanÞ×¤Ïïòà}Àûxð~$½¯¢|ÿl÷~3_<·ïÞÇû÷#ì}Û÷ñ>ÞÇû÷ããýã0ù~o[óÑ
rÌ!ô>É>  Þ/
ï+2ßW¦/¿Û«éEZUNþpzd  ï÷Mg¾½ÿþû7nÜ¨¤Þ$ûÊñåMo0ºÇû$û  Ñóþ;?®¶÷åw9Ýôí¿wi=H¼^³Z¥KÍêªÀ|ã÷Iö ¢çýÿýÏã*§Û·w·,ês{¤u3`O¯v¤oúüííü2¾ì¯W;{æÌ¼ïc²¯<zç®×ìì=÷.k?phÈ-ßêêÑ«ÖjMh¯ªg=ôpÉ> À½oRþ?ü¹ xoÏÃ
endstream
endobj
167 0 obj
<<
/Type /XObject
/Subtype /Image
/Width 680
/Height 666
/BitsPerComponent 8
/ColorSpace /DeviceGray
/Length 462       
/Filter /FlateDecode
>>
stream
xÚíÁ1   Â þ©g
?                                                                                                                                                                                                                                                                                                                                                                                                                                                       [/
endstream
endobj
2 0 obj
<<
/Type /ObjStm
/N 100
/First 797
/Length 2274      
/Filter /FlateDecode
>>
stream
xÚµZkoÛÆý®_±]îûQû:1ôaù¢í
Ó 'B"F@¤l%F|I%ðJÒÖa-PµnUI±¨¥: )AZ¤EKò 6 @xh³û*@¥VÑP*í	@µ#¡øèüHJ-ãÄnZáTºÓ ­¡Uº4Pªt¶ÀL·\	Ã¤ËGJ4Ýr¥aOàa é¨drÏ
ú
V¶
ûH­ð`-AÉlÆwÞc!q$!BÆGºÕ°rPädÙØ-m©
âÈÍÉ7¼¥¯à+QÉÑÞËÆ,{[V,;d¯bÒÕË×ì§F¯gm]/ºg¯7NVËÉoòÉõe]-fç,Çë¼¸(gåöz¹òÝÝ¼¨ßM;Þ<Õ<ÊÛâ¦Y³`ñùëÕ9Æm^·E½cr:Ç)¶Ø13á>¨fm1k×O~0ä?Óâfíy^çu>¿ZÎ^Íÿ§ÍÛªÞ½ ÿmOË²è±"â×ºÂ&íÝîÉE3©ËùË>9y¶~gø§ØµZý¤¸(êb6é±be¸ür÷Ü¯¦»écµ:ôoªíÄ&éWùì²`òúz1ßáKiqA²Öz57	ßgM1½øay¿f¬¹kp6/sËe?ã 
º[J×ÆpDYæ´çÆÌ/>·½/g×ÙþÞ^·C¶ßé%gÿ=9¦×««¶ÿeeSÌ
>©n^Ï3!yÉÂt´Ü]wÙGà³·ÏDTÕÙÉ)ÂdvÜ=óýñçÿÅ&¹ÂãnFÌÓéÙ¦©n9U[®ÄL=Á¹ÉMÉ=(É>8Êý+Çqt¾¥A!!ûãÏ.HÂñ
Aih©ëzý´cOWÆ5ø4lF
78
E4Ý}¦ÚÈV~@OÅ±Ôïw½I¨Ë2r½.Þ]TUíñíü>ô®;ÎM'Ü@y¿}.ji¡©¿n6Õ¨zþ«Rô~ÁÚ5¸uú@¥«Ôæiùº±,ÝQÿ¤5ßØ
DÄÄh{0Sié	ËCõ°¼õXÞcsÞÝÂu	ð ¹1´¯¤"!Mª\}[êööm9ý¡º¸('e>mÊ¶keû«E{|zü>ûý*oËÞò¼y~ó9S"2yx·@îpý-ýñÖ>ùEß·U}Ýt]´ÛòºÌò¶¸¬ê»ÇEMWáÓ²'OÝïgCÇì~8C¨§~G£XûØ»ë]~'xá@ÀÀQ:Y0<çñÑ2g@ð¾Ýe'¨sÿ~4­n'WyÝ>l_Ò/m½óÈ¹[ç¦<dË½°½æâEØ±ÏT0?i{µPd¤-Ô{ÍÕ§-THfªSO%-Z6µ,mJR6µ2mJj6ÙÊTÑÞS·
å¾²Å$ýnì0; Ó4VZsvà%ðJ;»²Î\¨.MR[d¡<¬U;øïÈ;vB¢¥ðMÿ ¶kà&Áp%"äüEÓ|úÏïw}¤`mc@e+¡ªe°~P}Rü½(öÓÑbzQNéGJàájv¿W.Oñ/ä»Üó
endstream
endobj
173 0 obj
<<
/Length 2387      
/Filter /FlateDecode
>>
stream
xÚÕÉnÛHöî¯àiFâ
«ØAzIÚA7ÆcÓh$9ÈT1ÉR¸Ä£ùúy¯6.ÛiÀpí¯Þ¾å{;Ï÷Þý¸>{ù:Î¼dIxë­Ç>	¡&!YyëÂ{·ÖoÏ~Y}:£pÊ÷¨'$ÉBØäF^^½ûà{¬½õà|¶ònÕÎÊ²I`ïÞõÙ¿Îü;oN)IÂÔKQ¤¯¾¨çAì/²oto»¤þ-ñÿÉFt\¯@KãÅ:=âèd³üÅ=Á¶70ÅA¼¸ÕJÔ}Ç[»¹.Ì4«êq²I6|+s·èþ¾ãYÉeu(yÇvU·¥7fK)nú^´?(.[ö¼|M}Äß;|Ï_Þû4íð{!,¨Í¿³F_Özwï-,½sÆ¿*°WýÔpfåa¸³êÀÄÎX¦;-/KDÇÐoÎÔÈ(¹ÝÞ|9¿{P´dÈ$
ELéãÅÑúcßå¯î,ø@y)Ê3?XO'èéïûAÍg´_Úµ~Ê¦ÛÊRHÃ®a:-Ù¿wH°3rYkôn¬½±£<«Ï¹^+Ï>uû&Hí\¢ÎÃF+Æ9>¯u^ÔyÙÙ?óBòKM/6ÉÎ ÞÊ½	6NÎ?³ò òî¶=ºº_4íÿÎÕU"LFÃÊÒÉîä¦Jp±þª\S#×àIÈ6­Q¬5KºZì¬Böýó ØëØ4õdÑº¸õ«Cø
zF¸»µ8½0UÌ`tUªØ¡ý«QF¾@.Tk&}5
|³£;Þ¼ú¾þ´gõß;¯ø§[£|Ý¨Ïe9@0Ú½ìmþ*ä>ÂÑÊÖï*÷mN`²ñÇOÛ%g­Áào6tJª{¬Ni#PãÍ¿R0Q(×3¨i;TW6Ä´¬âÎ@mU}+u»mdõ2.¾G([÷Ö»BU÷aP½E7W,¤}Û°jc½DçaíËWéð
L¬ä1 ic.B!ËóÎ_ÌÂ+[|JÌb ]pË±qø
?ÃdÏÔê£ìu§Û³ÎötÛ­í@cæn*Þí¥Üç nñ/æìÀ6¥¨ôÚ	­]?e«ëdÉâ{ÝÒYÃy¹Äâ	wÐdQ4åá	CjÔ!èNá°²E\¨dÁK³²²Ð³
}ýÚút,*FQaÛ·|Ûzj%ÎIè:pµQ ØqÄ¨QBÒáÕ"ì×ÒÜ\±NUÑêèëonyH9
åc?á¾é
Ýoìob0¾T?¦$q±vêg6h'+û¡~mÒhúÂzð.Aÿÿ!÷WFÎ£XõÃ
uÑ¾ë?¼|9Maæ2o]ÿÑp
endstream
endobj
178 0 obj
<<
/Length 1984      
/Filter /FlateDecode
>>
stream
xÚXÝs£È÷_Á#ª¬IW©KÝù¼·¾$µ­ËÖwF0a°¢ýëÓ=ÝF¾K^Ä0ÓßýëîA¾³s|çç«7W~¯µ·NÂÄÙ<9qì{,Iä­Mæ<ºÉìËæ«ÍÕ×« ¸|'pâÄKÖù,´¼züâ;ýâ ÿzåeé,Ö+/ß)«^ù5//Î2½h± Õ½ÍÃØwSUµ²jé%¯èÙÚÓæk'4¯·Z¤Ï³ÀweÛÐN&+ÕÊfÄ#JÕYJÓ³êÊ­äµzbe­,Wõz3y%=ø4oÇdøo³ LP­]-E3Wî!o÷´ÝîóVM^Ö«³ï¾ÌØsU½$pV\**Zd²Iu¾eFWí+L\»1¤ÈèÕïæVY#k-ò¼v?û~¤faìRàio6¢dä`«½0Æ<XxkHâ &hßó0¸Æ8q´¹Q0-ÐùÃ(cOª(ÈðsA­ßàZÄÙ'À.8]g^1ì>iÈúl$M¥÷1úBÇwZ©'H/QYY4!Òk¥µL["Z+Ý íüó ñÑ
Ì Ö`I¬ïsÝ`6V÷@«ã{"C`¬#Ü©è¬îÍ1ykY´d¦6/M)Àn#¿v0QGÖ²Ï¦KÉlôª·ÄV#KÀ4È×X[Öif[¸R¤ûipæMÃuËýÐié­~`RµòÂ[Ø<	Ý;ø
z'éaBiìÁs~FÛÎÕ;ÍqþFÇD*¥©n~ÝÛzö¹¡fT%µJÝ
[SÍ 3M?!ÆûÞû9£Zh±Ó¢Þ÷ÔuoO7--.Õ[²8OÓ_2ÐyÂ µLÜ[4nIÐ|÷H»{ñ"iUËºG14ãHEÑÇVM-S5×ù·o÷EJl9X8«ÐÝÎBßícv¢FÑé,¦Xæ#¤®åuøßKh	hy
+oêàJpâä(¹è&Ù¢"SMQá2`? /yûÿo§òÁ·¹ã²¹¬òG¦MµÅÿ `ñ¸&ÄïXÄã+xÃL¿¨û:Ð'âu³Û5Sû,ìM&	ödw}$"ìÿî!ÿ	+zVh/°èLc
Ása½Ì IýÖô³iã"À¥ºO#RÚd£AÁXîp=6tdÀ[
>·Vþ^Á7D+º2XÆmãd¨%èq­ÊÒ|và	ÚÓÑ`,J,£y?D*WáyR°ýÚï@{²$2ôÂ¤ÒÙøzTë\Á¥ÛætÕÝ¦òÔ_FB®ámeªT6,ªõhTÝnèù õÖ¥yùØøØæËj3bWªÉÔzn&ý4}ûå	B²L²Ä(:ÿ&:`Qitöíþÿ4è
[¥û1ÑSoÌßsÍÿ£Ù~Zu6Öýògª<þ§ø¹Tø®z(¼Ãù=ÿ2à;yòýÓ8=Aã¸þ/©¡=¹qÏ´(|ÃÆOõq=8Sdíå{Øn öþÃðê¿Ö{UôåvºW}§
¼5MðüÜ^Ö®m2:÷äQ¿ï§¼(¦ãc³9àÈYßCyë³u½ÕNrÖ?À½	[¢]» #'s5þhÒøöÄý-³dQû	:Ï¹îÚúðþézºÏõ­Ç(GÀvýû)ßÿ&å+Ói¦ØxZ¨B;Ûév×Lås$g¯ÀòjÝl®þH=
endstream
endobj
182 0 obj
<<
/Length 1316      
/Filter /FlateDecode
>>
stream
xÚÅXMoã6½ûWèTØÀZ,KEÄÉ»´il´'F¢m62©%¥¸Þ_ß¡HêËT(z%gß¼Òö­ã9¿®V?sgîÎ£Iä¬6Nzn ÃY¸Î*qÖÃÙèqõep³|ø°Ês|'ÜhçzþÔ÷õ£ç$0÷ÅõóçPZîéüÂÀÄsRg9ø}àµ"ûÈ¾¸³"û\ÌUì;ÎR¼ÃI8¼EmñÓ\"rü@øÎØ÷Ýy*ûk¦LïËÕh
Õð¢ô(Poªg¾ÓÓY3Çã9NÔÑ¶-89±âµQ,8F¹ö´sÌ÷Jèå«`i
ëbñ½^¶rü­ V°eh¸¿Ø!ºÅêåæoÍîßÆ¤EÜ&%÷Åi#jY<íI^Ûµøù¨!vÔðSém<¹Þ,h#_bþBb½bÅ¤Þ°c!`#}r²Çë5¿Ç1&/]v¹¼yAijã'¦O*«mwt·Þ	qcà¶Ê_ã|}/v:½2þ¬F¿ñóÀ.³w)¢Ð­zûA«­ÈdMY!¯5õÚX&Fuá¸q ù®JcfÊD·ªD)©LJMÜ@Ð¬á-AÛp¦»ÀÇ?PJFrônWXäÝÙ0¬ï>ßR:ÇEE| |³÷U¯iWàf+fkNm9© up@®ÈæØÊ8©;C<'¦7°ÑøAç¢Y¤®Ã¤¨aI[£ý%ð¶j=2Ò! w¼¼Uç©óüJ+èð¦¡â+d1!´wý9eRÀ`£AØ|75Øÿ¶.icê=åû6º­íâ]dFæ@hß«<*ÁÛN]¶¯8XÁcÝÚ­^¯*=À~sÐÄþ9åñ¸¡I»}úñzÞS©ý'Rã}åùÔllëÿïë`½Ðj>ÏP¿A$ÿO»¡¢à¸e©^Ò]ÓªZ÷¯RX¬l"7wÅ/ô_oðôí½¶WPj§o4³ÅßfF¶öÞKSÿ¾ún©Èáò¹½\ì2:êî+i2I*zN:ÍõfCbÓ£åäAiZV³ªÂøQòÙîgÀXNK;pï4µ®nÈ¶àï;å"ÃÛ>K±Aöº[UQ(GWUI­.n¯¯N´FLÙv[õÃ ¢ó¸Ô¢h+Ôç3Ôh'¢¯Nþã´Æ§ØeLéü\õ#¯*ÀèëßË+i2óI°þùÓÑ8M	«äCÎ"*þeÒ·¬iùURñA£áaGÒ¦§ÕFeãË6#|Èæ©üK³8R{ð¼áLÕT®@©p#¿ü] _A+¡2Eòc¢£é .v~	#aÆ!ÑAÈ¦" ULÝùtÚNa\âyv¶-¦É ¦£ð	lÍàâäô.M`ÇM«yë ~«~«ÙEu¶)¤Ã=T0wjRjL~QÀ`}ê
{/AD"*ÿ'ûïMSõ¥¼eÖKúÍµg9ôL
endstream
endobj
187 0 obj
<<
/Length 1579      
/Filter /FlateDecode
>>
stream
xÚÍW[oÛ6~÷¯Ð£Ö.lÅ6MºíæÙ!
Æ©9°ê¸3rÕsÜÚäÆ¹?|[Æ:Æ>òÒL$bäëf¹yìúað/0~ø)A?þ?èy¾5V* Ô9g<ænL±ï»ó(2Û1ª^ÆAä
Ôºy"S<Wp|ÏV¦`^HÒò0»¨9#z
7l**;<jºU^Ú²OßÄT¦úÎXù#
1«ê4Þ*M¶D#c´qy2t_iÕ·ç×+»øìEÞòJýûæ}Gòé4Ô/±JºòbhÇèGÀm[Á33*e=©ä|¤,¬ÈU¡ÀµuÝZª }ð{#/#fð¼ 	ª¿¼2OíJýL©LJGö\Jºa`ÞPãêª.¸®ó}Ùø¯gìí¹Y²áåvKZ»"F ÐLÏQû&²WñU,h0²ÐÑ]=÷#aâÆHö¶ç¹Ä^Øú\BÊn@Gä6 ë 0£%¨Á®ë¼Jû#í÷_8
=F $
jßÔêãÛ^Õ/eBXU¯ÛG^¿¬þO$'w óíÇ~Öä¾2¹¢òË\¼¬9@jóÍ.¦<)õ}Ê³bÞ×P7q 0¦Ù3*;$Üt¥pSLVºÜ7û={ìOüNç,·hõ¶R©¢¬ÕÅ0íõÑÍQQy"`´¯.PþkTåeUñÏøìB@­V¹©Ø(¨mªc¤
p²Qi({Àò½î». 3£{K\49è?]Ñ*#Íp'3. ÑÉ°Ó ©­/xÊOo·jáâþ	¢5Y¢éRQR%KhÚaTÕ!ëL=¹øÿBRãçÔ¸fê¢^£ß·6E9NX(ãÜ:°Ë'qF2Ë)qÛT²Á«ç°Äq0¸ÑtzÌ×s«ÞMÏÕ¼¿nmeªè¦ÖÇAê­íz]5!ÙÐ;LÓêN$0ÖôI[qrx@¢Æ7Ôr.í¸«|³·ù/ñ**TP	
m9g=óGÆäâuõ-ñ,{Fò³J]¨~@º*üË§Cß
P>Ûö,&Ñùð»¶ßýæc!WÕæ%j!Hòxòûï°,lM9ÁJiÛYÚ/×¿73
endstream
endobj
196 0 obj
<<
/Length 2053      
/Filter /FlateDecode
>>
stream
xÚÍXIÛF¾ëWðâD¬jîç0°w§ØNºaÈÈ4ÉbªÈËüõyµQE¶íÁ`0©·Ô{õÕ[h[{Ë¶n¯6«ë ±nhmvVØÈaz(¶6õa¬>n~Z¼Ù,þ\8Àe[(L< ²íøVZ->|´­ö~²?­¤¬,?Q$¶UZ÷_öfg 9VäxÈ¥úÃ§«uàË_M	çj^ìkq*Ë	à µvÁéº¨qYüEÔ¬Íõ>ËRM	Ár¼£L
7üò¾Âì;ògG3¯»rWeEêvþ¦ÿ®9oë´ì2mÎËô¤XÔY?RdtuÎ!ÌmIªoâyãzO¾åsÍóúû4%=Vs'ôõ¤Ç~gI`ÉßÀeõ^Zïq\þRS=^¬û%Àì­¾ ¼óÝ|6¬4íÌa­£°µö\ä¸µvá\ÿ\9½¤Ýjíz®[·äðP[µØqi þØPÙIaÃ¥hyëÐ]þ¿ÎòßMÅuGçç	©!ò¼ÐÜJA÷Rè¦'öQ; pöxD#Åp?¡3@n7= Rë,ÊrpäªÊ+à ®ÆGå*oyXßp­}ÔRõÑ1eÅ¨Y¡Õ4¥ðx81:3µÙ0rZ#UhµölùæQJÝ«DxËî~¨6òÃðT[¸ü® ÁEKºSÿÀ35®.±ÒÆ¸^MiWfj¸ÕKi	«º Ä§jéw×
=ªè3¬kZ¯/dÓ"ßÏÓ+D(oÛB0öÕ*T0´%úý¶9nÍHsñn»¾5º~1R>o;Å[gót[XGÐ8û¼}ÞÕ©¼Ù(ýÿ¼~UÞÕT/!×ì»3a Ö6«ÊÔªJÐ0ÐAZQµV ¸Ê<,µ°ÓJåµ>-(	%d]ßF·Ñq2í@Î	þG7àþ7oàP <UmØ£-íÐ ­î²ÁHïbíÝ?h«j_Aq*9Äô«
XooO­Íh'ZøË©¹O`ZhIh«PbÅ¬è×ÿH¨	ìÙö`ö½ Ã§e'ÛiVÿ ©!;VÙul[ð\Å³¢"Å½âæ+¥
èXyCáª´°mÿy kÛ ÎßCsònÙ|¡p
endstream
endobj
202 0 obj
<<
/Length 1374      
/Filter /FlateDecode
>>
stream
xÚÍWKÛ6¾ûWè(±ÔËVoÝ4i´AÚøR$9Ðm+.IíÆÿ¾C)?¢EÒK­!9ïùf(èè×Åývq÷º¨¢*©Ê´¶û¨È$Ëóh]fÉ&Ú6ÑÇåçíÛÅ«íâ1Ñ¨(²Ê$æQÝ/>~&Qgo#dÕ&zr}W¤uÑÅre^Þl².¢5ÍlS¡í_âµrÐÖ`F+Jª(å½â-gf¹*Ò"|@ÊH|fiDÃs×N¹ÖôR5ÕJu´>*1öRõ¸>2oèIÏ2FÔ¸zänØ®ã<;Í[íwbð\µû÷
²F®a~fi¿xÐKÅÊzÔH¢|	¾ëÆá©s5,V@0pG_ÁÉq¥¹Cµ-}ê,_ÒØ.[QkdtñÀ³Kd	Zzö`£ç¸G©µpwiú%-âgâòØyATwJkyð§­gÓ¬÷:Å¬ª'×¤ö SsHxNyaw+Ð õdJvÚ+sýÆ­â/B+»ÎâÝ2%ñhÕøä ¶SÀ+óX jûÒa	èNH7 Y±ÚËì½³­+X%r0|06¦²ÞÛKÿÒÜ\ËeÙ:ÉË¥åÊïi9Ï$ôE6xãK |¶Â©o-lÏßj@Ôg<ÉÒüº¨Ò0_ÇZ:åzD<ìºQi	èF©öc,ºÃ7{â;v?a/Ô-S:GãÃ9°J ¬Â­Vç­uâÜKVloûk»ôìñ	©â­k8´¤Jòÿ­îôùºOÙéUÝñ¥Á§á¾Êá»%»ù~8>JÓLCjëZ6ör\ÜÍ¹Å5Î+ÕcpâF0¨R¯qÅôN<Lyé0É¹§í.ønàÇNò8	Å®µa£Q uJÁ<¿~ùã<.y¾Ïþ(õþ/7«}ëPËÄ>_8V/
endstream
endobj
238 0 obj
<<
/Length 3787      
/Filter /FlateDecode
>>
stream
xÚÕZ[oÛF~÷¯Ð[) 3¼f±(mÓºnã¶X4E@KckTI*ª÷×ï¹ÌP$-Ù,¶/ç~ÎsùÎÌ¸åÄ|{ñêæâòuL2ÜÜM?Ê÷'Q¨D<¹YL~s<oúûÍ÷ßÜ\üqáÁ0wâMP^®p=2__üö»;Y@Û÷W¨$ì¨çzâ'±¡;É'ï.þyávNüçÃz¡¤µÍ¤I Ååtæ¹®ë¼Jç÷ËjêÅN¹-Ó\'µýÞue5YY ­ÜÉLJ!Ã§ü.J×ùK»Înê¹NYÝãÆcÏÑS/pþltQgS8±¨ó3 kVÜ
BH«"ÓJ~ö¶ªÎL¢ú=zÔSôx®¡ ÖEÙVºâi@ú@tLf¾Dz8ó<,ï¦3$°µJ×ºhH}°fSs]×7_Å¡S7iÓ²¢nªíÁTAfFE*EÚ¤\µ.:·½¯¸î¾Ð¤f\jrÍLzÍsÔåZ7«²uV×PÓY¨"çªé(·ù¸uûl®Ø6HÝ¡»
[­þZV:mø³)ùÿq÷ÿD¹@²ÿìT ÜãÐK3ôy/ehfâ6.PÍli'©GeÅq:¥/Ã#ÿ¯ËÊ|ÍËb±wl¿å»+4£Uó2ÏÓÛ²"Ô¼Z.¬'Ûë²nPß³Ñå&×ü}_fg±Ól©ÿÈ·À6únâ¼ÚIÐ(þðA­N«½NS	· ÿû[5¨wh§Ük®L<#^;ÜLÚêúG9?_¿g»~¤r2ÞÈ¯ÿ3aÓ¬/aãLBáÉq¾KöÞFcdèè[ÂXxIÒó-Áé¾.TÎ×zÕ¤HDSi=àGõ½[8N@}~ÔMñê?èfäî¸"ñú':û·¡S´ìì?diÎÄ°ôô®ð£¨GO|,®3ò÷°ú:Ý\; ø"ãÞÚÉY²øm×·V÷"Zß¥HºçHã5G±NcK ¸¨oJ§¦`){¤U Á}MÑ¿:
NT 9=ò,rþQs½i¸0^wÀ#·¤:y§`Å·¯¦_¾ûîj¤ýÂº}ûþ9ëÞP«ï¹guSóç{7p)ø	w*e§4{fÖ»d×ÝÅ>lÿVY¹5ÈKB&~8@^&¦uæP¨ÀÝ_S¸ÆìíLÍÜV üñÒ¼Yµ¡z(fHUlßl§e³²W¯ÊªkµõTvQ × »\óré«îìÈG°j8Xó·íµ¦aÇ8Q¹ÀÂtÞõáLY@Í¹\h½0ãî'ÂÖ²%7-Ì'ÁAø¿5´Ì¸Ôìì!<´Ô®²9
Ë2_sØFG9+Ðg®ÒR1Ï] I55­³5c,[P½@|(ÈKbCvÇÿS®áFó_%©c9 °GhÈ÷´âP<ÛËHQI¥mºÀ¦×ÙS¬(14U
Ù)uýµÚòã~p^£Ð,^k"ÖlXFGGgÍp@×¥u~àl+#v°·§>Îa©Rü^'â­¯l²}4Ð¬o]rCç»ö< Iäzµ¤p#Xúþ²#éü¿ó

òä¾çdùr¨ýÅýöêë1vy1W_^ÓRBþÄn`cwà²º"VÿlS©!UCñä¬ø°f²1BÝ²´Ô!XcÎ*¡÷mÓôO+¡KÁv ](¾AÍ!,Á0"ÿ5rîà.³]ÙXDH±pýäøØ6Þ6|}ÿÔ!|æ^B²ÇÈJçë©³bÝÁç&S­ø¢<OÑÔû4)êWºÎä\}(ìÄ»ÚóX5L45$ ))áÿÏFW¯{¤ütZíë®cå Æ`8¨Û­èÚê*}§«j/BÓ556JA+JcªæØN"l3c
©'¼ÇôÕÁÉÍ&mXä0Jþ_öëØÚäsmÒqy®Û?ó¤'_lAd¹Ã~ï>}¢_Ê2Òõ²{·Ý»öFªÖ¨ï±Þ¨b»¾mÙ®\w®ë§c:GÐïÖLÛG­*ÏXµ1×é³Û´¶nC¨=`Èj+´ûlf	vá;{r7PäÁbdË½3Ó°)SÞ`¶¼qtÞÙ@øD§ÇÂ¼Â'7Qùo'á'(ý¡äº¸Íle>Ý.Wý£ÖZÄß·­=/ôÁùî¬AÁ(Ý·ð¨õv½ÙÛYÛlø»xx^"jLæ¬Sx(ôOsr·ÚÇ²L³yWmO¤çÕìúk¢©ú¼"9æ:ÚºìâÔÎõ"ÞN}<Zª¦±õïæ¨,¾ÀÛE3£½haÒØ=¶n2ÇÓ4A~®qÈ÷ÏWe6·b°È/µ¯Ú«d#£UZ-úÎÎJa0tðvàóÂc7Ü^åÆ*à¶hêÏ»é¨WÝûÄ´i ÅÅëmcÅ^oç6T&[B;ÔV}iYS&o]Õe»ÿõ4aÓJgUö²Ñ6=×é¦_Ñ¹TkU6Ý{ÕÎmkÞÀC[±Ð4»¬ÖVÃZnºà$!æeÝÊÜ;ÐÑT#D¦kÔÚEæ$ÿW<6$¤óþ{Ë+æÒ¦øEÞ ®ðÈçQÉÀêi·Pé¡ÜVÜ£b¯ºÍÓÊ\3­ÊÍÝ_gîTF÷íp3»/l5KÐ-4¬Ù4 hÐ9OÔh³¿Íg¾êÝZ(÷²u|æ/¦¤%æF÷½s¬imcàL¾Xå:íà¡¬| zÈê%ð}Õ>dµogP¦¶>ôE º/½ô$é>Ý|¤u>IÀc»ýÔy1Ú¹è6©ø­}O"¼Î¼3Pg
)Nú¯KU÷Uëù¢
ðÚ°µ|#%]LA6&%qaéòXë}<ûCA,"Z=Ô(¿=;Èö9»_÷GI@ÏfÈÇÓ¨{ØñrÇËªz~kcOøî@þ(Iü\ÐSë<®ñ-lçÞ¤År¹K?_¿ÁÐs¢x<\
FÉºËôâ¥äCKÄSðd(\o ßÁ(	<zÌø	J/£ØÄUõÃ(5ª¸ÏZ8µ¯{GÊ+Üqzm×úË<m¶!(CØç'Å}k	Ìü YQJH_âÖùPèfo»ÝNl°jkwååLªDD^Òg2Åä±7½àÍ©¾	çöGñý¶ZvÖü@Ë=Ée@ ì3bÒ¼5¯ýNäÈwEó&¸ÎDãOqáGB}ßÁ/>WÈöÍéÑ§îV,|97³ø»¼Ür$1D)wÀç8¸Ô}Êú)Ü+óýqòµ¦åF1qòÓcl¸yîì©ü%t16Ê_ÂÊã·.ÐçoÐyô°öÿbÈ,õ¬µ¡ûÇ.3ã°Êþîé®?ë_µÏº¬{ôCÇ.
°âSÝ9`4ä¨.!oXÖ{nnh5Î"\=ô,¾R}æÆaG÷¿àÉïÕûßò¥Y§ï¿SwOyläÛéÛ:3/ÙÆK)VÂð¥ÒU¹$õDqìÒ×ÿ(ÄR
endstream
endobj
258 0 obj
<<
/Length 1007      
/Filter /FlateDecode
>>
stream
xÚ½VËrÛ6Ýë+0ÙÀ7½'u&IKSOGõ"a#PÈ²þ¾ ÊLªí¦âÁû8÷ °|\Î&ï?%(`)=$N`Ç K#YæýûÙÉõlò×ëc`¤0-"BáëÉüJÿûì:äÄES
øAX«º¿èøÇU-øÚPÑÒèA©Ý±¶â;9*ýv»XPçXÃZÍÅCày|ow5¥ÍàMûNM)QF9£ç¡ÓóIðaßçC\reí0òðö5iY9îÿ7®Î9O«½&§¢Bö¼üNG:ÄsìRýåAB:ã4g.ÍmÖ*AZÉãcYoR¹²«Ie2î?ç¹óæ4+ëªûìâËQ®jZâw:º5=Cë­ÎiGÙïßÿv{1ýL]5	}¦¯+2èv½´iÈx >
*¥?pqb¾¢ë
qrÒT©­Mÿ(fÂ8Ê]1çýUéú,t9×Æj3+Ik']¢ÉÚÑrdfÌAJ®óyÁuVÚ>P`÷§í°c+ý 75÷SBD/ÓÞ´zçBÞFðRÁ+Ül6Ï F÷88À+n-0­æÅqO1,ô=}Ä)1{KZi#¼õÖO4Ñ¶c	Û-ls#rï§÷Î]ÜR=ùõÀsaÃ3Æ9ÌyDtZþð4ô~è/ö®»ùí@pt«CyÖù: 6QöNÐ´:;µ9:"¨#éÇ+¼éÎê1x²7þú°æQ´wØt÷½kåÔ×YöhvhsüÂ±oî&`ªcöõ`FÇÝà+="|ÉÝÍÒ÷»p&<¥D'ÝØ¡ä±úÁp$1L³ü
G8ÜÅ#û7ñp CÙJÔÖ{¼áRêd£/`*áàªßÀïÒÐ
endstream
endobj
262 0 obj
<<
/Length 2535      
/Filter /FlateDecode
>>
stream
xÚÝÉrÛFö®¯@ùEhì­ØÎ(åTìU³Ä9@DKDËúûy[c!Çsç"6ºßÞoë'×ºµ\ë»ov_½S+uÒHEÖîÆ
ÐñÀ#ßI¬]nýl{þæÝ÷/v¿]xæZFNú å:®XûãÅÏ¿¸Vgß[®ã§uGG+H'×*­·o.Ü)ë4°¼ øExQ¥0ñ¹¿Ùz®ëÚ¿?éæUÑv(#ºNê¦"&$:Êß2ØLµ­mUìqÀÏ6[ù>vÒØ%ª^ìxé2à¿6ÛHÙ¯á¯g¿ õOgxèn2à¼:C5r|?6 WDè-Ý
í;Îmä@IÃ57ÃÂÀWë¯ÔY¯IIR.	°K¿õ©+ê*+ù½ðm5nÐ	/q7xv·I\Rç·¿­á«w
U5iEgy^tÅý¨fÊhö¾DÇXC
ÉÛ¢ªêvIÕpÅ¾h#ÞÖ¸ý¨J62øälZ9Ë´+¡¾ÀþÔák»ºaG	ä¹(0÷uµÈ
Fg9Û<l
¼Ôaç|ÆÜa­û2gí®ÅggÓjÈB9[b´Í
¶2FîöBçÐGDÞhþ÷d,»+ÈÃ%G©E=¡VjÖ|OnáÁ)²LRªÈh5	Þb|ÞCK&-ùvßf{`{ó83á'u4¦d¨«í¡¦}S7GÞÁ¡ßÄ~ÅGÙ3ÑÖò[
¥î:ÙM$¦ð¸lk^xpd"Iù&6a3jÞ3Oä»©E66ìAFÇ}Ó¶å¤[*þªË¦áC¡B/\
[0Ø`è}»=eUËK3"§cB	Í}_"Xß
îb¦;ÿ> Ã(Åó@8Ék-Üªºc©°-±LcPþé5´¡îHJ"ñ¸{¤¯0jQ­WÝwVÁq
§í þÏä~eÀþ©Ñ(ÍGþ¡Ý,a%-KÀMq ï¡F4°Ñ·¯Þ¹!^´ÿÂw9zSÌ ¸dÂ½_s°+d0!ÏWTLIvFÔ!ÿÊ9KIé) æùÌ;Õ¨z4]UÎÆhËDàÄGå¯a(iMÆE,Ù¢!{Âç¹áØÙCû¦jùøè¡3~À]iðñ[Â¬¾Ø/=A²Ug
FsfÔ;8eé£Ý6u¤	fý`V5 ®ØÛhS×TE-bmheg»G®P?57É}v<ÑÇO'Ã¶(´/Ù'÷8V`B6¿å#¹b8á+vùNr>¨ìsëg³Þ¶È6ÉÃåVf Á¤_ÏRÓ¡K÷
:f'C¹]Ú0;c¼8ÉTGÃ³&ãªGPTõpU.ë()ügvÿõÜº£(Jç#ÊIFt\Ð½Ç&LAM5ÌðDªÍãCJÙ¤SËvß·­yZY§e"/ZóÏ:÷û»ÿ /Ö
endstream
endobj
269 0 obj
<<
/Length 3118      
/Filter /FlateDecode
>>
stream
xÚÕksÛFî»fîC©i´æûákî&MÆ7Nbeî:I¦³¦VTù¨ãþúX>$*Io:Éä¸Äb± À ìÙíÌýxòýòäôIâÍn8[®gA(B D¡'âÙr5{mùÂ/Û¶­å<¶­û¿]þtú$HËü8aà Q½Æñçä|yòû	íÓS¶íø³t{òú­=[ÁÜO3[xI<»ÓÛ 1@±gùìúäÅ=âÖ9HÀ²ëÂóýC#ÿÃöláÀ.QBk.ÖógÇVÖà3±²Þ²¡Ay3wë¬lkÂ(+XAË*kîÇ³uSeiS¨º~  ×³vzcÛî{=/µ¥wY³!Ø×õ®Ïà×gÖÖÑlÔxQÌÜ&4Ê&Kïê`JíïùÆìL(1_øq`ÕåV5¬¸E­i=¡ºCÒÓÝ&K?×K¬U©`[×·II¤`¨h,Ó&+ íÜ%²^Õ<-çm±pHBkQ/£GSÉ¢ÎÍ³z50+{èÜ±¶ô«,Áñiåª
?¿õ 9Ö}ÙÒú­¼§íQ2°¦¡±	Ç®gý·	órEïÀbÅ¬¨%WZ³|,]Vp@¸%²ºéOÿd±êgNd`w$õËpu¯bßo@ÃÁÙÎÖ> xMáøkÞr
£acÖ;ÔªÌéíºâ%´P/ðÃH7Y¾ªT1fQòvªjdVL1'­Àl»a«3<g#¬@?f¾3ÆÝIà¡ùy­§¶kÜéã®wYÍSõN¥º­Z	:ìqZ±ÝXN7=CË¢­G!^ñv{Ú!F"lH8°
uVä|þõcg<v BXWÉÞ°ýDØIgúcGÁßGsÏ#_ø>,?æ? âùöÜÁqE±eNÞôyE	Í=]z¦ÙhýÀ¨Ô+tlÅ7¦£OV²DtcëzÔÊ¬_0«ÆIx¥irhèy.9Ã ­[Äa·pä´ªd¹jÀQîVÝÎhðòÇ ^äê àû®!Ux¼é¥&iÛSj$âh !óºä{2°Á[üq"¢¥ôcÔ8Lº#©ÐTÝjYDGÿ>úùùåùYÑþá'ÃÉëéÙÇO¯®®¬¼zvNð«'\>=?{{\ÝäêÙòâÙb|qxyuõJ/J³È@£37ÏåØ³ãLìÕ=4ÚÊwsplm	 ³A& BmL	%e5ª¶ 8:¤`-¤Ée1k)Î2^}÷u£	ÙS¹Ëvä
Ð«z/1RÅª6)À8Ç(ó²ØCæf©:ºF!wðÍ©ùù³Ç/QÀ_//®kFUi­Ú]Æ¬ÛjÓÓ CÂKJÜ0¾*Òê~×¨M/Ñ!e,Iò¼Ä+ìÂÉËôsÆ,uôHüÅqù¡n9aõ9îøPá`Éï	ô ·­óé`àÙºS¹ëÚÂ	£ÿ#Ù>ìÉ{<Ùqþr¶~³Ç ðk#6*Ar9u%u¶¨åzO3#û¤qMÞÑE*Âî²<ït¯ÏÐ
I I3tl­ËÏcË¹£O±BF¢S:ÐÎA,ì0ø
eTÜ¼ßUP²5Õ{v²*oæðd5Üá'¦3í,^(ÇÎQÌä0 UyíÀSZbáá×¡EçCjÄ"ÐA¨ iu/DO¼ùòTW1t\âú (ZüT¿·\OÁÌupíÁLX¬Ëj+á^_qËQ½Æ	ÀòçK¾²Ü ÊâñÒ
ÚD
n}ÝÐi
4ý »6¡É£íÃbÂÁÍºÒßLF¨®ÛpÐDt+ÓòÓ/L× :DZ·VµbrªIõÈc}ÎP'DfK#­xÂE+ÝlõM
á¿íMKÎ¶à3¢JvtSæû`tTF-Ãýt	ò-Ç=÷nåªy]ªUÓa¤2X_ä×U¹ç|L¸Y=\ëü:¯Hè	°#ì/âçý'ýfc> ZlßêÜ÷O8%{ZL®xU¨k;ævÜ|7oFPïtU´ù2«wùõ¸N,"L£?sÐÙSÊ÷åÍ¸¼+±Vó-ydÕ¡Ø¥Íþ3æ$	TL^÷1ý_1PD C¤ú" MDð]gø©ò HòaÁÂqÂõÀe÷¾d*þEÀ\Õû¨ø[ÝÎúúfê7¡ëz®¦ÙªBÜeï²ZeRÕí)¾òÎ¿MÿPÿx&2Ë_sYÜ¶LµQö Óÿ+#öÄ
endstream
endobj
168 0 obj
<<
/Type /ObjStm
/N 100
/First 884
/Length 2544      
/Filter /FlateDecode
>>
stream
xÚÅZmoÜ6þ¾¿@ ù`¾'K§½ÞõC±e[çµäjå¸¹_ßgdÚq¼é­vW¸ 6(iGä333¤´KB	íÐ! µH£up­½Fñs%\ a=ß'áß+÷Áh¦I{ÜkÐóÐ§rÜ9n´¸À¯:ÐÃPàül¸Ó­Æã ñïéè0¦Lâd1ñNüÏ¯iÐ; ëðF
PøIÄEÀ)	
ÚÏtÆÂ¤´ Hx+Á¤ÐabK +ôÞR°DìÃÈÂDÜ&au3ÒVXå±¤1Â,¤µÜ±=¹pà~À&Å2Q8eyt%ÆT32V8ë0rÂ¹O.Ù1¬7ìè	#m·¬vÂÃú`¡)0ùähpyÐFÏüÉ¶!'
.Mg>
$VÇ; ÿÉàU¦I²l,SÈ3u]æ¼âO $z	ÐVK$LEJì{E+PkÅÓàT­3´SVÙîî¬xÿù²Å¦iûYñ´í«î7¨>/ÅnÀë³â]uÔß´I2bê8Bc±$ûÓJXêàêcWus^<ÙÝú/õuÛÅÏï^òÿg}ù·¢¨y]×Õq]Ê¶;-ø®xß·ózÑÿð¾\Wúi?ü `%Þâ×þ¼<ÁHÍÕ|þá¯d©ádÆ'áÞQ¢ÞK
,[ »sFFÞÇ@aÓJ v: 022 HÛì+6#KÖ¬Bâ&D\&Üá e¤óf,?a.cIZ¥;$@`x"C&8@
»õ´rñûPÿÌ«²kvÊíU¿óûU9¯ûÏES]ï\
Ù8®[Þ¬ñ!Ý«T»'Ô8¸Úsé¯ÇÉ:PÍÒ8YËÅ¢'k¬dÇÉJA=RV»!%«Ü°%2Fuéaþe¤1iÒHÿò§~Ìodä}ñßµlr\á+ßôðÅï|øâü¸£$þò6k|õµìØô
ó¦eóµÌ{ïlËç³ ï§ý "EÛ-*úJ¿ ä{¢aÓwM^!
endstream
endobj
278 0 obj
<<
/Length 2780      
/Filter /FlateDecode
>>
stream
xÚÕZ_sÛ8Ï§ð£<­úß»ÞN·éîv§½vßl;ÝÌ
°§K¢(ªÜê¦Í«kU_}¡/*©FÔYùBH]SKÓ*Ð:-ê8YNWS9ä-1È
­j;¶sÀ!YTE
CÔÝ~xÎ|¥FÑVÁôÑýqOeè|Âª Oö,µg±ýèàX=m±â>ü 2ÞÔçTû±2·å¢ÖE¡Æ´þá^£ûf³ñ¾çÓD8µe.T#d]±YÇ+ØÝÁÀ
ëC ü¾»§ç\z§¶çå	Ac¸¥Â
Û¡Ð<yì
ïûÄ¾j(P1
Ü7dºÓµS3©Tv¢qy³aX{^¤ë¹Í¼1¯!YC×}$!¹c§
endstream
endobj
283 0 obj
<<
/Length 3247      
/Filter /FlateDecode
>>
stream
xÚÍËrÛFò®¯ài*½I¶[NDÖÅeû0$F"` Ðþ>ý<HØR-×ê f=ýîú³Û?ûîäÛëóK=[zË8g×7³(öbHbí¥³ëlönzút¡|ß?¯ÊÖíéëÎ_FËÁWazq¤ '}¢b9¹¸>ùý'ýêû¯ÂÙz{òî?Ë`íïée:»#Èí,\2 ñgÅìÍÉ/'¾ëû'Êu2KÈÓaÈD¼÷UBd¸ïhÆv¿ý.ðU°ð£¯$§ òçJ{¾ÿC~ÿ ¨PÀvÛ3ÕvgMk3~³§A4ÿxª¢¹­ïyJgæ¾9 nÌÑÉ[¨À[`ÿ9GÁ>Y¹íÆ<ÒG3AÏ¬åeÏ}·yU~aÞxûE§YxÝÆ®«2ëøáÁMUó *-î­©ÏQðÏ9Xßõ?µ¿Mµ¯¿¨rxÛu~öÆ´zRX£'øÿâGÊYXç	
@kë(S =©DLñÛS¥@Û{þbmäSS4öuSvUÓä«ÂvìaÏ^Ú<ÍÛÖ¹Ar[	G5§äå­lkëÖ8vv¦nåêæÃ6ßÚ¦5ÛÐV6;»Îßû~`3ï³ªõëpùwµúþ@Vj¾xõjáëÕÖnò:³1a[H+/`=õ`/^<H}V&ha×v»²_(:({tLùµ34æãd>Bü_@×§a4ßÛ³Î¥ÝT}]U» i:Å-N~ÂÓ¿·µsYq/#ÞWmwàÍ°Ç<ñËÞìTµ£
ã¬ÈrÁÇdËß<
2$¥¡BÕ)¾ØÒ/H8Ï®.×ºw¹åÎ¸ÚjBO(Æ$þzBï{i Æ\"«JÐkl§pæûyâ-_Qe¯¼(Iî·§8ÿÿÕüÆWàiâ¾ùqkÀ%!zCH¯;àÐ[¦JÚSéLCu/ñfbÏÈb`t eæÊ0mU"oZÝÒÜé`¯fWW¿ÚõBìTª\T\ÌÈ.`Õðkß´÷<sFlîez³©0.ÝQG(´O!KÏ³`\§ñX{i Á+íPà®þËdÞätîÂd¯S,=>eA÷"gäp >wÌ(.»CªÆºQª0U¸8T·L&0±"½ÍËX£ÜK£æEîæ*Y*{öåzc×¿¡¼mæ¶b¹øÿc@à(¢À²9¯
/)±^ÅgHO²há)¡F>àÆçÊòÓ)UÍgã/ò2Ë×R¢ã÷hã ð]aÖvS­pX¦¤ÐcIãùÝ&/dsÃ#²ólÙ¼aY-¡hü±­U¶¸4ug$P#hÿ~[Õ¥«Àïá,>ÂÓWÚ:\_¢O)[5Î~J\\&ÕÒ<Åtpºæ*¾ä¸b(`â½ùb>¼4*k15ãäfãm·OQú ¯<i~<¿ýZP.)_\x#ÔNB
Èb`Ç2 ÚWì±
>õ÷jg+ Ëdð\	/hú95ûÝ®ÈmãÊkPðÖôg6¨Höbow]×!w3$í¦7?sÈ2_Ô9@{K%*8|àÑ=«ñ¼ã´èPöBE¨é®0}ÌH¢ Ü3o§*1@§Ç³³À3ff aÊ~%/m[çRx8´ÍæºsdwNnÇ©èRÄgË¬jº
¸èäïiYjv&ZæWÅ6ãDâ¸ÉÝüºÚWPAø4º«u§úÿxþ¦ÚZäTM¥ý=Ü@@¿«­-ÁÞ´µ-oùÓ!}e³|Ï.ÍÛ1}rY2Ú×U-ýtXM8ò3ÖDî^ö®/q;h8Efõ%Lñ	³wm'Öè®_pA÷Xµ·üÇ~(ÿbÊðS/Ò]Ýx1(ñ;ÿW¸Ì°¼t8¤¸J@
výf©åW.@¾åº¨Èh¶ä'È£ÀUm¤>¥Foìwe) ½$w×k_}3Õ;¼p[R·êP}XîtÇRÍÇî(¥ÙÊÒ9ÎOéÂP9	pÃåêtÇ!P±¥êo´âZÉ_o9$o9pÇAªºãºOñT^Êè±?Ø¢Á7T1ÓhØ.ä	**¤×L>Å]
ýæ!ÔB°p§8F«}/Õ§==ßvsÞVçüN6{;}É_%¹ªEÝiè¥ËÎMoøØNÄáx[p½e=ÄRç¯|t£^«BÖ£ÿ÷)â×!BøîJ£X¡Áø£ôÑSjóvRÉÑQ×½ä%2ÙC<QZ;¯`b¨1[6¹xÁî,´zl»ªÉ±ÂjÉ­¥S0ùé(ðï°6/÷t+#w"ßÎ½£MX·ö$y´>	§Äï{ñ£e?	x)cÍ¸KE
>·KSÝ´ÈfbÝ-c¹¦KC±HÝ0á×aHWÊìýêSò ª0IâWsàà¶6eãn£dD®ß0¨õÆÑ"
endstream
endobj
289 0 obj
<<
/Length 2061      
/Filter /FlateDecode
>>
stream
xÚÍ]Û6òÝ¿B@^d Ö(YAP wÙô¶
¸ïÞuò` ¬®ZÕvªÚy]íÌØÒ ¿-ïÊ%ã.Q< ¢nr3ûáýwoaFVy;ãõMºÕÿ*N¼4ñÄ 0çVà÷ËU¸oá¹·~wÁ.AàùëÄ®y}mìal	î4£{Ít3G^ºf!³Ðck'ë$fÁý=¹ÄÌY¨J¹¸û*H3Lí¸
ØKÖ³b}¼ýéå'
*l³bLG¦ÖPc¥Ä]sJ6P{fþ5DbâÔÅCÊÆ|k4ñ'BÃtKè®6ã±ïQÈëm
vôRÈV¶¨ô$rÛ>+Ì7Ññ£Ï}ã	<!L¡Dõ®ç%ñ(µ'	ÎyEêµ¥üî
« $bZ\nMQ¬qßßj¬>ÇA&yAµó|ÐÖÙC¢Ç¦>Ö-ð-vÒ"4´MßÚ
~ ¼Éj<"£ïèµ¾°TùO¹ýÑ ð@H×è¹þh³-jàBÈÍÎÇèÆéGßJI4{[âçlÛéþ3ö2Ç9Éxâ17ÚA@«Fpt	¥77W0>¨®00C_©ß{ZUA}Ëi­#äQÐ×Á6èA`Ìå]÷ûâ¥*âôê[j²AK{èhKÕM¥U®uãÏCvÜÕÿÂ¡¶jß×½õ×Çº§¨((ÿ &³ ÛÕeic­l)È:ÉYh3Ç~vÕÍ±â>7Ò Ð»Æß95BÚgpòà¼[/çK3Kb/
ù·_GQé(JMq·Uc)/ªËÄàH'½©4¹ÉÐ`Ü>Ån%e.sðæòXJÁ \{A^(ä8õÌîrÈ
Ó%©¯#¦äF	ët%yjpÒ?Î½mÖ¨#rJå·ÿ¨¡öÙ¤«uãÅ8\\@Ý`é¡Ú o>¿S
ðucn§\]6o7pÙ8Å¤üsDpÀv>ó*Àå(IçW]Hóùd£jûf;¼ÚgâH¶48}¡C°3ý5»ëãÀo8)Ì 0ÛÛp<]
Õ^zÛxòÊä 4ë{·¯qÇjO{üDWö(²³·<a4®t}pïb¼Ý,þ¡Vã³
endstream
endobj
293 0 obj
<<
/Length 2784      
/Filter /FlateDecode
>>
stream
xÚÕYYÛF~_!À/`ÑÝlÞÍ¾âØãk`aûCöH¤<ºÇyXl^Äf±ººë«³[jqµPgOÏÏýEê¥-Î/aäE@#ã%óbñixÁj­RËv5YW7«/ç¯ý¦£yAxQ¨A*MÒ	ò½8?ûãj¡ÑÊS:Xä»³O_Ô¢o¯Ê3i²¸!ÎÝ"HA°¨Åvññìýl7n7
{ùÔÕWTØ&`y&f9ÆJ]d?kCF¨#a-m²êJ$¿E{fq¬eÕ5uqÈ1eÓÃNFÜ9DV¾ÝËÂ´ÑìÂx¡Á ¥ba¥Í<xÀÞ UaäÆ£>0ÿ=ã/±}ü%r|Sf´Ì:~b£o¶/´_d®øMC	:^ÝT^»Í:'ðÎc<?ìcß ¥yÓ¥xÔ{A(^ ´È@£oèÐ°üÏýQs»CÈs(QS£	l
ôßnY;W.n'Ué½X¨r)m¾ººþáfSæ¡BØõ³¡Ñ8ú${YEáò´Çõ¶Iðú*1

&_6õÉöPB}4b}ìMK9Ñ*´¿Îõ<>»ÿMÏqÏc >+åÿÉR¸ãÀk¤çC»ãù*v'îÁ±-ÃÔKôqùc`A)U»ª¨ÑV¡y[ÞÖpK²Ê·ÂZ*¨»þ¤ÙE}èç®§qQWö!­wEkD×õFøJ§keÖ¾fUD^-»UVÝWÖÑz*¯¦ZSãìÎO½Î¯Ü6]æNÐd¶îøMSÅUI¾J*]¹³ÃéW÷éøçâ1øË(T ñ¢¤?CøÊ&ÐkË¯xá¯/$ëÁÌWKd«+%´ÀÉÜn©­(ñ1]FyÑpjúEW) Ú'CßÔF
Ðdß(Lx¶ãQpàùqìJO]MiFKIE	ï- ¾ß?ÃuSvRøçÆ/0åEÕÙf`&ïóÈí^i\ÔYS4-ö~JÑ©¤ê/C¢Æ[I¬Á³í~­¼½¡Þ_élê®,y×hSÚ¡«zÓ=.0­ Jª¶o±%´»2¯·uÕnôÞ:Þ^:IÒãn (GQ?2QôwcÕÝv8\ë@pÁ»¤ Å}4(BákÞØ¬³³ÍFÀçLidÜù}g;qim>kÎ`Qv2ïeg@úÔbâIj1q E»»áº
Hm¶³Lr¶¶mâzo¤"¢B [¢PB Uð(ièöhé=£DÓ?eÌÉ*òXê$|Ìë
S¹,ª°mÞ{Äk°qêèxêHÃ¯ä'FGn@D §"­:òatgL%c|
(Þò5¾)WX×8ÔèÄ Z[¶°cWi]ð	ÁTníñà£¢¶" ïgÂP <¼òãù«Dj¯		4tÚ-xÐCÌZ<)ì¡ù ¡	ùÙ7P¸PÀ)Ûï·¥mÝì®ßH>Úäàæ£ð1¸¦OV¼ñµ,î3ùÒöMkÔ²Ý~kÛ»Ýöp¼Ø æö1ýÿäþ8rO(tzz¤R(5¾öüþN¼ ¤\]é"_ØÆ}ìê¯S%%gX
endstream
endobj
297 0 obj
<<
/Length 1134      
/Filter /FlateDecode
>>
stream
xÚ­WKÛ6¾ûWè(²ÒC Ý´9M×@nö KôZ,&Uwÿ}/Kòc½»ÈÅ"gß¾ÍÐ8xpðqöa5»¹ÍX¡S¬6AÂAÊZ«2¸cÏ#1ïÄ·¼Ílç«O7·I6:/'PÍ!iÙo«Ù÷âÐaÅnvÿtX¶öÆrÄ	êànöyÇáNÜ¦q)McëûO9§I¸G4Áa!®*Ekwj+:aÙ;¡$ü?ß}«E÷Îíýù'8%#§¥qD¢9µ²ìUÉF$W%ADÊÄÜ©Üè£¢#ÍÞwØ­kaípÕÙåûè£9]§§àü
øïÑß/g¯ü.ú÷,­AÄbK
Oâ,}#¿8~®£ì'O	Rs
Ï^_¶?½²N}SiðöºÚºDÏë¨AF£-¡[2q-}µÕMâðÆ´ílHæMi¥®YZá¸9:mþdNU¨úÉÚ*Ûå;áEUó¸ÐR®ç ê5±¶`qpF'Ø*+çs'[-6º¹ë¸J4>rgV¹}ßù`Ä®*díRe0/&|kÆÓ0×>vFZ5yi7rcmú^ot*
fv¨$ñ[sÁ½Ìj3dù£#)¶c2>*W¸zé¡ð¨lA |Ìcf<;¬dL¥±3wÕNuV+7îÌ)ØçÙMçÁ­´°B÷¾  Pû.VGô~&¯Mïíug;
RWÎ ³J3~ú­NèæÌ7=Êcç³C¯ÓÂ#²AëÉfél°
Ö. ´ÈÌ!Çùò0Rgx¥)±'¼BGy2náé¿­ýá+8ë]sq1u»µ3]ÏüËt'Äð%¶¹ò­ÝÙôkå÷3P:è:7^ÐÙ; ü÷ü	oàû
endstream
endobj
302 0 obj
<<
/Length 2163      
/Filter /FlateDecode
>>
stream
xÚÕYKÛ6¾Ï¯à-TEàÛ9¤¼½ã$]R¶I¨¤ÌGýû4Ð
v¿»±ôñ/-½æ¥ÑwÀ/Ë@bp¾l"V­¥\8·ØÉË'ÏA &þySå>998¼dºë		]Â<àckD{YÉNØ#ÑLé(
Ð°,4Ò×fFÛ®Q«ûUNA\¡¶»9<s×
nB#[NñKv¯±èq´ha¼ *Û;Oò@Äãû4þÂC4l§®5öÙªµMÌêvg½ñqì_6Å,c¾8'§ug.+¥Ìe!:A8l»ð(9{QÄh$²ÐæeCÓxÍv\Øj@|¬ng^µ)e·«×µ®·GRDÚíI| ö-ÎÂ [j»¬ÊÏÒ@DùøNO¬l -:½:ïB'>è30ZMY7dOÃþÒDÕ}ç&PKlCg:a?é¦×ú8w/ÄI5Ò*¸w0enQÙIö$Í- °OD À0-Þ¨¦íèRvÒÝjG×Óªr¯iJ«ÖÝëMl ~I<1ýì_¢ÀÇ8ÑAÎ !ê»6·uI©k?á5 ,7Yþó¸Í;«È4xk]´éALÝµØýÄbf°é·òK/«ØkÌ_ ÐÆðyî»VØÛ-¯í+´YvqÕí¼Ú(·°¦öÇ^wj®ñVÈj­VEW±"[ZÀ±¹;ÈÜÉñÆàªå_w¢e¯êª³Î×mf¸ù³$nîÿk-Ëê¹ÛÆ¼\¯a³ßåb:.çÁ1Ê3Æ?Á}=Ã¿¿ô¶j¦ÿ?75tÇgãÓíd¾Nl>H°¬$m¸(¶Ô{Uæpu'ÏzµûcÑüÖï)á âìF%ñ`'SÂ½{³r[´²T+ð^ÕÄ8àÂ¸ 4ÈÄYI&}çS ~¾1±È¼N¤3(.'° ÏÃ'XN0aD¡ïäH	eñMå?lR>íòÑ}æßs¤LÃôWuµRf¯ÃH§g9adxF^2®ß}F2BÃoé1~xq
O÷vz=Ò6/ßÿü¡­È®¤v6¥Ï¦&¸MêaÇw¥ ¸M	H75L°7%¢ÅÀÉ5_WXÄ-ïÂbÊJÛê)ä1HþkSy×Á_#b¦©écª¾C¢d@	X_´J±o
ÅRÓbFhÛ"Uo£K2¤PÄô{ÌÛR«¾«Ë¢ñ!¨'H<W¤ó1vÙïÌÕî!±Û/^.¼ý0¤c9E}&sË	õrÌ+hÖ*,göZÚò4É0ÅoÁuµÒý4wQ%ª²Øª43Êç[ücS Ú$Êù´7(àÑ¬\Qu5
/[aºg¥»õHÄpWã[_Þû­~Õõ
Yh7úÊp¹ãbq?¶ó¥¯U{Âè²£3l#Nè­³2as(û@¬,ÑØXdAúUuðÚÐèbdlÞýÆ
¤0E¡fÐÇOµ@f]}¿öÛdDÑ.²ÑNSÖh"ûÜ[IÜ;¥þ(bà¢!|Lã NÎË±
endstream
endobj
306 0 obj
<<
/Length 1793      
/Filter /FlateDecode
>>
stream
xÚÍX[s8~÷¯`üÔNbØ8q¶Û4ÖæRÎnÇ²­
³{×I~À'6&æ×AÂ^¸ÚC¾ñÝ£ïAPcQ!ò¡çÆeáF<ì²)G*ÄÇ|zT
ÄL:X|+n
WÞ9õ¶jÇ¨ÂéF¾¿ÆÖñË?]Ä<uÅÈÄæ".í 'k×»jx¯O[¡ÙoÕÚl¸-U¡WåÎî²Ï2öÍÓóîkÅüÉßÝÁq°C¶9µNº»îrõ+!RcXXÉX»XP @xipñðåàúp± Å<.ò/]6ýSî	®×ÂÜ
È,J/MhþQBmUE¼8*qoêÅåBõ£ââîê¤¿®þ·söSuuªÕh¯DñEÙðâ÷¨Öap51-Ê}c´Ô¢cª´¦¬¥þD	\®fes D³
*=+5æºÑ¶ê0ÄåÕ-©0ÊX"LT1fNohRÆE²~í®aìlæ¥Æ"D~sÝm¬DÓ?.n>]OÏk²qw¢tdrKØnÊÎêÎÙêÓ»{G~4¦>S'ò[U­kGÜ@ºDa(*U8<Àí^´ÂÍ®àv(l÷Td<LÆ÷±ó5U	ê5«òvÌ{*òórÞz+Dd~õ"ìó^Ïi½ÆQNòr+¤;I*K¾I· âÝ¢&ñR`deý'hÙ/ïïñÝû/Óö`ÕÛ/T3uÆKpÑË&AH¹$rO4Ë,k}XK%ÄCáª'¿A)Å0´¯ëüö§â@½ó\¬ÁúþëÝÞöÓó®ªò²Íèj÷§`»4dUh¾Õ­w(Ê¡·kQÞ9ÚüµÌ1ü`¢]ß]N¾>8ãû;%Ñ~DZ>²¤AEÒçòEëÅ\Æ§h8mÌçÅ¹^CÖ_t+nOò­¡nÚ#ü«
.iÞ
endstream
endobj
310 0 obj
<<
/Length 1636      
/Filter /FlateDecode
>>
stream
xÚÍY[oÛ6~÷¯ò0¤°-Så$ë"Ó¬EÒ´µÈ¶¨¨$ªm×ûõ£$RÖÕâdh@7òð;ç|çB(
P®Zo§­Þ;óL9SÏú@ÚÙ7U£ßWNzªL-åþX×_=L?´.§­-O¦upfðQ@Z_»­û XüÛ¨ÆÙ©²FºJÿìTð!@q»ÖçÈ,­¥ÖÕ44åD!DOÈ«®©Çïrã;lGp¸tÕþi(P>|¹j)÷Ñ¸#¶@ñb'¾[À ¾â²¨øº¦üûéþr+ ¥«iêiVi§Ç]$$­ØA5!Ù¼ftÓKïÄ+Ki°)wPG1Ònék:Áêªj

ÚLúÝ§hÉ2x2öQ
U®b©"%!ÜcOíÅÊÐö3¾Ø9%yG4fÜ/V@ÇK¬úPD¢'­Il*J·¿65) Ü t>úZÇ®¡©Æ©^ÝÃøá°©lbnã°ía-ùÈUéÌ*ÖçgãLÜc<TtÔÑ%Ù<³¦V6¢¢4í÷bÐô6g0\n×±dvµ&aæÈqFÔ10t i)Ìz¦°±/&Sd¾46Ît:ï(ûH]`'ºMÂeÉPâRÃQ^Æï;Fñ\äx+äídø»Ô.AÙV¹¶ÇDíJÚßân~xjÌ¯V³" gßöp±Ï)Û9bïv¶ñÏwNVÁe'©,×2)zÇèèu£J$ñÒ$8dÞè[\lSY³È3àôøC]Ä©jå²-^²åévM9¾­=·ëdy86Ü;Ý
:q>é¨àÄÈ¼X ù÷¤ÿ!¶½­ÙÕÿ?½y8í^û=}ÇÅòt®%¹ªL¹û7e~È}¢ÄçûªMºÛ©ío¾Ë
endstream
endobj
314 0 obj
<<
/Length 1522      
/Filter /FlateDecode
>>
stream
xÚÅY[s8~÷¯`M§1Û8q7õL¶u[g6uèÌÎdû lh 9 âøß¯@@B4û17éï\¾stbhkÍÐ>öþ²{G¬6Ñ'ãÁX³W5²ôáh¤úf»ÚÍÁ`øê»}ÞÙ½»I©Yc}<¯Ý0Gön¾KÞk>hÛüËPMNô1ùÄÐíº÷µgTD%Ñ¦eè'DòjË¶=ÃW}k` ~·]ì60¡hEpEDyéLT (-ÎdÒËÅÇÙ÷Oöêb°·ô³ü2ÿ,ßòËâMåc¢'Ánj}ÓÔ'Eõ\@×¡}	ÁVþÇDÓb×
.§ÓºMî4ôÑ¸Õ­i:ûçìòêböF ßNwöVXÊ!('I1ÊÜË`ág³ÁÑ»
ÉÌ÷0Ía{&%`ØDóÈ	RÖYbDÎ3ÑuÙ-"¬Õ)*ö®ÿ_í=Ng³ÈM$iN\,<?/2SR£Â{(Pÿ'³Ïï
4ZL}x2¨npVXæð&n`ù
r'Ì D#Lm£	%ÊÉR7V88AÑ( ®VÁü8^IÁC^HnáÏÉß ìíÉå³CÛÁë£½E¾-.G-¨¤Nçq¯[¼j³CP ojöÖõWùk,ZÛÔopóaC6Ì)³rV1
¥/<M¨ó CÞÓÒÅ¥©W0ª*`¹YÙºÅ5´õ¢ªJÕµuX6)ÎoD§n¤;%¹©ztùÆGs¸Õ_ù0vé)ûÏÄÙ¢dY)lÚCÁ3Ià§ SùÁOÊtÊRd{°q§0å[Eþ]
[Ý§*´/ä¾3×%§Á{xô>ñÖÑY´Ë§®ëR¡PVH¬K6Ó
$/uë7A¶<¾;^Pw<ó0^Õ¯£4\%ÑUÕSqâ[zêÆ¡õÈÔÇ¥ØÌoèb]ó
Ø¦ê,±ÅV+i52©ÌeTÑMã	¹´¥¥Úz¤¬¨2Õä¡¼³tLý½¾¦Ã8;²¦¡$>Ô¨Í_ÖM9É³¼½$Ê¥1½$ÝÚfH¢Z+_4½"{	Ð9KgÿtOÅm@®ßÍÇõöãó%ª÷lÉ+{þåóuáâåo°Õ´ÖL;^m18É4jó£T¬?i\Ñ
E°ÖRñôüÕðé?[üHöÓHP¥?}.(:
endstream
endobj
329 0 obj
<<
/Length 3042      
/Filter /FlateDecode
>>
stream
xÚÕksã¶ñ»ç¾TêX0¾oÚdæÎq&w¹ÚJ:K¦CK°Ä¯Ô)î¯ï.vA:Úg:éÝ °À.ö½\gã¸ÎåÙ×Ë³×Aâ$"	Uè,ïÀçûNz"vkçýLùó_ß½Zýv&aëH'Ex å
WúÎª8{ÿë¬aî;Ç^;{Y8~@\'wnÎþ~æPËÔÒõDN$=áÅ	!¿ÑuÚ¤]ÕpKèj6í^_92 j¤³R$A@¸~ÉKß$Ð.²UW%C|5_*µ= ùÌZjw­^S¯«, ¡Wóè¿½¯uó}ÖvôyÕé·°[v[^Ó¦÷ò¬Ô°Åeoõ¾Í4ÿãG´¥kHË
Ð5-O¢?èÜ rÇT\k]vr}ËôQ4nÛN7Yû«®ÌÉ?PÂï
3«Ø7ú.+3s'Ø01º~PÕ,L®Û]FÇL¿DÆåù½=e
<=Iw^ ªòåÑ©È¸v	v¯?Ö÷_²w$bUviV¶'ò÷Ý®¬FN}Ñ;ùýì	§udøKË³Údm÷1ëÃ¬}ÖmÅS'~b`QeÝÜÝi¼tu G¼?á{ûÃòå£¬ý4dþq2Lë:Ïtk=Ì±8ÝSõVw{­ãq>~Måú£üc%B¹³P@ää0Ì*p?Øiô¢éG
¥GvÍ÷»ÂóBpe6º1.{`_$±ôLfã	8yPÄyÇÎ@@»8 Jo«¹fð>:þ}µ£Î>ËsêÝZY!]_^üò¢0ðnè2@µ/<éBìúÓ<xÂ ;ÄdS*qEâ^UùèòªÁå¾?oAwh8² ýìºjÅágI,Ø!x5Ò·qÍ¬ì÷µy#ö²1ÑçOWoè|
¼­0ÆÁ»9`KW¾i»KólÕòºZ]ÔÛ´Íþ£	¦ËÙûPh§º£6¥¹R!ôP@;±8:ð4QïkÉ-ØÝÎ81Zkô<q¹ÜäìÏQ´ pôFDÐ(	(Ôj\ö{ZÔ½= ÌCm+vºMÖéñ.TJbo=$K4q»Jkd+}äºWÎÖI.i!·ä­ÁÐßgOºeF'Y¦
00ÔÐHÍ¾ÞuA< ÒR³Éa8£)}×MUW
Á2ä­n;¤@AD?°c,Æ?#À¤´T"ùYfF|Oaì÷yÅ òðXÙè·ÌÒpXC¶`u£ï4óÉ²»ÙJå,ÝÍÃ«éóXÊß¡¨lxî]Ö¡_àìÀ V#Ì¢Ýqúqú¼'jVUyûH¾Ìì
'öØ1;XÕ`ÍO¯ÍÆ¡Î5Wÿ°B°¹ÆP<v[(ôÆÑ´%È|lõ:ÃËß5ÎØUu+ÒYÜäNï6Å&] ¶ S´xîóh7fHÃªÎ($eMQÂ}?óPÒg		Ì0¤Óm³Í6Çk°öáÓJÁ'$SÊÉø|!â£c£êOÉY»¥Ü¢¤©QÊAâÊrÆÜ¶"ìZ(¼p¾«ª¨AÝn³<ëîit8ùêÍWh<»9Í
 qzaO>fpf7òÆ¥ê®3[¢Zk¦Í 5rö;ÅÃï³_³­ÔÅÆÒ§¤ÏÑ·{ÛõWåzÁ]¡¼x,Á7ºÜFòò½MÞ£4¹BªhD¥ÏP}¶ÖR" TÈªly	=*³TÈa	|	¦Óà©,özâf%TÀ\aNs yZ·ø*
8Ó­¿b\uÚôCPè=Ì.WLÀ¿wEÍ¥;L¦;ryÀ²1aQsoÊÌµ¶Ýó!+xÜÂ)Ó¡E2íþBuHµÊ^NåÐKÎåùÝ
}±E£2\<=,Öíb:õ*éâëpøØ/¨dß÷ú_PÙm¢(2HC_PK@	¡á lúí>JÄwøèpÉc
EÎ$ø*ÖTO'±ñ M²;bã~¿²BTÍæcö
©´!ùXMá Oª10o¦æDåøá±úlìðÄõL¡;êH((¢ßJÃÎ-JÝ]P°m¹õ¶þºÿÊÖõ]7|T|RÆÂj,?ù<ù]¾ý:Cíñ¿RM°¤xR57åUó¢­îº=dÍºHWíÅãguAuUtVS¹üËùÑ­¡Á<H5<ÂÙû¡ØÅ5îôL.H?ô&ØPànXMf`çHµÖ¼hz2æwÜr
K¦óÑËþQ4DñÜ#ËDÈDväW¶z¹è:úñÒtþ¿ùA§ê
endstream
endobj
372 0 obj
<<
/Length 2214      
/Filter /FlateDecode
>>
stream
xÚ­ZaoHþ_tª^[×ìÂÂéÕ«¶o¦ë^ã¶:]Oµ×6
ºà¸¹_³°`³uÉÞÃzgÙgØÖÚ²­ë³W³³ñUàX
<âY³E=äÁ
·\¥gZð¼ÑÑCï0¹©kÜb¸Zu°x®\çÀcjD(­VÍ6|8"Ô|!ÄyóqqåEu«HÕg½&Kö\T_ÓUõy¿u«Ë<Z'ÑÛ& fû·QÁEXDr!¦u;U{­D¸(Â¸úÅNð¶|·ØTW1(#L7Â¹.ÑÀ$áV]		ó¤Pú|MM­j²ÞÅ¡&K1ÞZZvb?ÄRåec2OßµY?æßjmø%¦êr&«TlA;ÝQ~¼5:#å`LÅ6éY73åK.¢Â0ÍJ¥\+¢ønf7·Ê&¼Iß6§Á92*cÞreÎyyÎlDåÑ¿bm¾|¸óò 	;p\H}J7E]ÇûýEE#ê²«h
MÊjdÌÏtlªâú³$§QKÕ7ãB¡²ÉÏ Ódû¢l¹êD`d75DÃö	t>r}ÒÎ¨ëÕ!y]VzÏ » ÛU¾ÀÃòÑÈF¾ÈæYºäñT:»I@ñ,æ`¨SE*ø6W¶{w ÈÇf	ïúÅkçÅ+´zAü|µÔJ.öà`Ø§TôgC¸¬Z§¨HSmBÆËcãäôÅïJÓÕóm	ÛÓá×8]£,N¸(hñõ²$Xtp·ÝÅñc M±È{`GË ÔRðÎsßd¯ñM/Ì¿®y(5!Vø¾íÂ8*Ç	ßWÏ¶M¯dq$ÀÜ«§EÆùXÚê!âû±¨õ®Ö*½¶²À1Á¤ÛRÁ}b<I~ÉRAå6:@Ô\Iéäy0césYöDAJìÁh*àdààÙè CºÁû\È%PõÈ8¿/OÅ¾Z
ñ´wÔ×Láâ£jµUÈTÙ´·!´·ªØÔþ8¹Ü¹ Ø72(´ør^k2oxn å»0¹Ë2óøKa1I©N)?Eºï"h´{FØþÏQ.{*ñÎ{\9ØR-l.åt]Ê·È7Bô"ªà¼ã}é(Ô#9I3jJ¤yÂÃñ,>·án¢d»/1_É@NÅ³ÁzH¡zG¿'=_ïEmØWNÅúHæüé ¾^#¨æ&Ïh0¡ú3ß¬¦H9sÑÝ\:Èq5öMÌj«W®ûÿ_J$!BX¯îy§{£t QÕ`¦«*C&Ûð×È
HÉæ®cÇÓ :F_§ÉgÅóç9PY
Q¢<q²
L4Ñé+9C|y÷æ¦ð³ÄôÜÿ©ññôY95B0ºt°
endstream
endobj
273 0 obj
<<
/Type /ObjStm
/N 100
/First 875
/Length 2872      
/Filter /FlateDecode
>>
stream
xÚÅZkoÔJý>¿¢¥+¤Ë´ûý@Ù»
°H° »ì.FfÒI,fìÁö²¿~O9$±Ñ~HÚ«OWWUj·òL0-1L[ÓI­òIïr)qïÖÔf=·Ì	62ïÜDÁ¤{ÇÕLÅ¢Ã}0L
kÑhcdÆ3)qc%ÚàI *Ð´ªà@F¨v¤+0i"ÀDÁ¤Ytd¡Í7Òúø÷dÔ¿ ãÑPnB=`P£P¬ýàyÄFZ@ÆX °N] MC'Z@ÖK;Ñ"hah0°§ 8$#éM`_j©ñgð3ºÓJ;\ 2"þÁÐèJKüjh_\÷î£ÅsÙ­VE]HSR[[M0»^iê@eVX3ÑxÁ*ÈÌòÑ|tÊ1!V;Â¬¡Qi@aÃE¤GÐbáZÑ,ÂÄ6¶Î1ä
öeÿü×¿a.îÐ³D\¹ÏßNþøã²"ð ÜDÖ:Ã)7EäröÇ²^rôÇøèaU¶lex ¾~é¦CX^_SlÂ®o`ZÜ1²¦¸y$)¦º(Ï^ÖÕì8µì
¹¬;í.³#çºè×'Én6I× ïÚm6Iú{Q½ã8µP_S_«ßaú&Ãlàweà_lòÝ¹>ÝZ¸u3Í`·îïÎðí´´ëØ¤X[Øylq¤±í<³6©vÔÿçÑ¨µ¥ÊÌmFó¿S%MX¨îZ%úVõ­éÛ9ß·±ÿ]ö­îÛQë 	þïn³Üä7e¹q´­¸þgu@ün°5YNÌõ	Vd.QoDñ ºæT[+«¹G¯Aÿ
¬kV)N:
.ì}ÐµjwHYU^ó9_
²Z+pï·7ñ»yuÎóêcª;C/òö"{r:ß;^o]å%¿hóÝñÃ0ã§/û¾°*À÷´ämOÅóæCgëyÊër/§%zïÃ*íUV¦Ë½Åç\°·çeYç{mUÍFø±HYæÝJØìaâÎkPb5aî$¢§=ª»cµ7c%ì¤²öhw*E!GX:Eâ°Ø%w#!})R½¨ëÀÿFäå)57¥u:Þw.wyýBU×gB!°iÿÔ rVÔ¢Lµ+>]Æ÷gYétú¼BÃ¿¦Ïòò|¯âBXm¨tþáÐé : ¢(íHÀóò}ºÁÃÎ#ìN§<ïN]¡RT^öqT\O[×À
Ú	0T~þÉÎò z¬¬ÿ2µu1-S»îéÄiôO^gU6X®nSVNnºã:ES^ÔçyYü·Ëù|:ÏJÎ!ö[ÛDÀQ°òhüHåét/ð)ÁëNíÄ"£âÝÑK0BaGæÝg¨FD,9ÆnëGÊH5=ïßÑ7V$¦«ëêp±êÐVqÄI
endstream
endobj
386 0 obj
<<
/Length1 1416
/Length2 6052
/Length3 0
/Length 7019      
/Filter /FlateDecode
>>
stream
xÚwTÛÒ6Ò RE:QCHè½÷*¥ $$ ½IïU©*½H* H¥)*J/_PÏ½÷Üÿ_ëûVÖJÞyföÌÞÏ³×Îwøív05$Ë Iuu5Á  $, 	89áXWØß~ §)#RÿPFÃ X¼OÅu ÖW XK@@!Hòo -TxÀíº@-$p*#QÞh¸£¿Îß@n(,))~çW:PÑ
C`ð)ö04¿:ÐHS¨!~u~î ÿl, þW¹?Ùà_É(é ¼áG ÜÔWÓÀzaï !û ÄÄçC< pWð«uPMÑ ÁOøg>
ö+¾pãgðóA!Q@ü0?¸ÿðÁ@<`@,úÌÏç?ÿ´ `0ÐÅí`pàßÕñnÃoþh¸Ð§ºøüëÉ
Ï0{$ÂÕûßð_G,htOí®)ßÿTRBz}øüB¢  $"Ç?øý³Î]üOÿ«p@/]ôß¨¿{öøCî?
áþ³O]ûßL· ø/ðÿï¿Rþ4¿¨ò¿2ý¿;R{àêú+ÎýðÿÄ!npWï?<u`ñ2ÐEâÅøo¨ì·vuaöðnÿÕÄBðrPD8â)Í üöÃ1jp/ý]8êô6¿ý&s#`wøÅÏþ+WÔ`ðÜü`ðÃþ:ÈÕ?ûPE@öêBÐh7 øxKèÆËÔæõÝ@AOâgö: Ñ
:^ÜeømÀ~û@@A×&.ÿX
Èól£-28A 9âVÙôRWø[)a=A^ÞãÝ@ú·=ÈaGI`ôñ&ît0¨@ÕâHß½.m:Úæ(Öû´PnòÎù¹æTý -7EÐà©¡pýD/]O+ßSúæeIêÅøaÝ¤e}J'?~ÚiîÇWÑô­'ÄF·(.ì6åFñU1½ÒR"H& ùìsÖæ®°#3ÓNì5vVös»s¤ÍõïJ,¦óÇ=.×oÝbÿÊH¸\ùz²½¼¯Ñç	N*àÜ²ÚnòÖ{Y6¦!·§â·÷l:;¾û^òµ¯µU`çûåA%×HÛÀv­MYZÏ!¾¶­N1Åvy:<ïmA-¸@ÎIß«Í	Ä½´iNF
½{/¾áÐT/óÝYûçã1F×ý9N]7+ªtÉ%þ® ¼.L3GiÆÃwÁ>ïièyßç¨MùØ¿lq 
h³Ôï	júýg'z¹HÈËÖ*Eß`»ö×º6 pû{#Ö
muòd¨+paiê@¥î&EVØÉ	[ïîÞ¢[eÚÐõU `WîçÆÈÙ^ÚÆ7ÇÞ·Q´¤é&C,¢êlQ¡ûÂRÙ
Ñ½+oFKêÞ$¬â×¹gzÿ¹ÝóAÐAgz9ÕqêêæÝí:q­õOzãMR+÷3ºa®ÇÆ,}Ñ3ïÌ.IOÏùOL"ñLV$2D}È×Xa¾¼Êk
Õ+çJfJRoV¨$îÑ¼´1¬Kâ(j
QÝ¢T½^:*oÛÓ"ëvë±¾3$êD}ÍrèñZRáNy4È«ÈÏÄ<y¹Ú9ÙôéX =GVIÄ¶£jñ¨ô´áËÞµµ @Ü«Xt9	åÆÂ(G¡Òs
BÁÈ¸ÏRJô{À¹\êÌ9£Càb +m  a7Ù7£9»^$w¾{ý»Rõ)?µKËË¦ÂÅÝÚlånQ³
s6­~h¿ß<ÖNCvÃFî6®bATÓòø^þ=Ô|&QñTÂM7¹÷9Ø¾UOúÖrº?éHBI+j¾e?õz#£²zÑµD½w¹»æ}¥Ú¿Qµ+Î÷ÚÚ.·:K	RÞ ¸_p~fRÄÉ{,Ælùq§^iu1q*^¦cån4È¹, ½gÝ³Â/h=Ïiø9|eRØ=ð³v¯9Û9Äï)Àò5VCyãòVÿ[º @eqø²ÜëZºNT*ó¤¹ucøÔ÷µO*´2Ìõô8?»~ê¡2Yß··,,÷ÏP@®TbÊZÕç	j1n<ó7æ
IJ±ó+ðLW§ËÍSåt© ÉõÏ6Cü/ý\üuF>-}}u@]¶ËúÓÇ
Q7Ó
:ãT+C,ÅJ\[Å_L¼&Ò¡üª#L+!ÈÆvfÛD+Ú~¾Jj{ñEÛË]¸³pá
÷Úñ½­¥e[/Î=Ú¢÷Ï¨	bäÓrgYÇVEJ0R­V½ÌÒBå!¯ªå]Ûj«¡t4ËgwvoÂÈò§7ø±àÇ{ãídBgN]NW|æI×GCy´Á±o{¾J¨sRG ZÞlö4èþK>F¾æl2Þ|ÓJü4¥r3¥ÞY|ì¶ôO¶kÏw0Ä¬¹Ö²ÊßÆ×ÎÊ­m~À]±±JlAûãÿj$VDbRtî¬)?Ww|ÜvôYòHIVcïòÞMLÞ±ø½ã>'4åÞÍ rvX©ôÚÀµQ³n{ÿõ3jÚâ9AÁx¹¾0Æ^iúÜýJü`cÅ¤2ª	ÔgÇ½KÞVóY3!w·ogò9µë÷¥}ööDQ¶ç¾-Ö{º5Nµ@Úê²¹Ðe¿àÕ¡é¤*ÛT^h`'´û]mþ¦ùèäk¦Ð,cùí«aÄégÝä©÷	Ð§ÞM&.Dqø7ºþæoÛB}[Ìïç¾êæ^ÇÍl¸ùx¼zÜ©åÍü¥"PI¯dJ °ÆºÏñgfo°r×¨m¥3^9ýZÍtHQ?»<óÆ¡{æ5¤2­qK$I¡½å_a·´+|SöêÁzR*÷¦tseWÃñü¤æÊõiýüb­c¨zâ[=£ÞHhÐøÏæhÐÙ%ñ÷Ê­ò£Ö*édgÑq#¶)ÛtY®îeÜBV³méz0ælíµ$P
úàÉz?¶kÚëµMn¿`ZÎIF©JµzögçÐ«Bi(s;K;e5÷Ö#µzm¿¿I2ç1ôÚKX#êò"r*¹MÖ¬¢Á¸;	ê#Öùw4Ñk^Y
mÜ
,r'¦ïésòÖ­=S¹wû.ä§§ïöyòqjÚ]cAtÛi{ÅbÝFKo~íÉ²k)§+nñÇ|NT¹«¬'¢mY?»½*¯zû!bô ùÖÆ¢ËíÙÜÝ£¼c_-
ó]
îÇbG(¼(wöøéyÅë·4m
VQ¶qÕýT­~´?/6âdáÒmôÉ¿§\Dnw´ÔXÃG®èy];pð
ÈRE¯*¶Ìêj!9;Ôí·a²2O÷ÿ+Í£õDÞÀà¼ò.§`1éaE/%T8x·Ö:÷Î¿0ëYç)T|¼°Lï~û@®RtÕ|dÛl#/×` ±ø	ÿaq·ÓFzÚ\_K°_¯g¯î~Õè¤uÒPÔÇòÛ9æÜn^ÖÍ|:¢é¹6lUÖ¾ÅÈ6{öG°ó²Çª1m§òtN×Q?Ä!Eú
g^ÔØQ©>L<éçê¤{ô´§¸àð¡N<¨vÿýÒ­òGâî0ãúb»B

[Ý07Z56Ó·
ÞXôuI/á1r2Ìi½hU§h\HdëÝëÈaéî!o;¡F×9»¶W.ñæqËò|é
Úâ=¬×þü¯AA&À?|>»v¦ÌXÎHIò¤'Àµj«gÄÒÑï:G'2E¥0}Ê1tìÌ;ðh#o
k?_ÿé.PÕÈÚ6û®0ìF×Páf¯k©ðqöó+û:v8&R;#ÜX­R*î½Ñ+ð
Z$É"ÝqrÚç,ú8jLÄË­ò®ÅK;J´2prÝ·»©¸\s~­¥ØË©a~ÅÑ²$:©cNLJÃj³uxL>¦µ	Í³âyíÍÏ->j©èÅynþ¤À¤c>áyRìX PHiød{ëäG%Åºø¬ÍíQxz õqKÊ½ø®ý¥wûÇÖ;V>|³FàúÙz`G¤®ÿa¯¸¸\³èx®¨æÂmè®ñËI6.ðrûÂø vèõ	kzÃ7ÙãÝ(IÉùþÚ(^
endstream
endobj
388 0 obj
<<
/Length1 1444
/Length2 6262
/Length3 0
/Length 7245      
/Filter /FlateDecode
>>
stream
xÚx4Ü[×¾ ¨Ñû½½÷Þ[1ÃÁNôÞ{
½Î_ N0@PBB÷W8@Áâà Ê	â^`(åû¯ÒN(¤··7?ÈÉðpåâxCQN Câá±ül rüi
 ºÃ?ý!ÁP7	ýìQàgô6«Àí®®8
ÿ³>e¨Þw_?ëGxÃýÿ² p{mØ{º	À¡î
Fì P8þ?ÙÑ0Äá·>¨À
  øóõ÷5Zaö8Ì÷ú¯#P5PÑRÖæùÓòßNEEÀOHÀ'!

ÄÅEÿÎ£þ©ã?b5àÄïrÑûôWÉ^4Àùg@¸ ÿÎ¥@+àüGè÷¢@0úMðÿ,÷_!ÿ?ÿÌò¿
ý¿+RõÁ~ù9þ?È
óýÃ@+×zàÿM5ü]=ÔÓõ¿½(zàhEó	ðE~ãP¤*Ôb¯E~«æ7nòsÞ`P8Dþ¼aÐQ@àùÐCvAß"H´4¹ èú÷º*p0Âþç°	@ _|ôY£-Q¿ z*í!>¿Äà#Pè ºÇ@ÂÿçÁ
¢#`» a ¤ÓOßo(ööøEÛè½DÂß@ ¾'þþWi`OôþÒºî¿ì_âã/¾A¥ÂÂ».êè¼ù>¼ÂY]ëI¶E±Ï?öwÒÆÍUqW|`ÿz,K¡2rúM ÷ÁÅÏý¾üLõBÊàâ_ÑÈ×>G£=ÖqR<+fô0Åø¶GÙ«ñ~á­gK®{[» W@Ù	s&*A¡ g3Îu
Á³$Dd.ÏjÄÆË¶ÉdÜ>|;utCÙ`/¤~ã¶Aÿ×6ÉvGBx6Z=NÊu94Q"ÉÐÝä«mE#ñ7+ßMlÉ*Þ/tHøøeë´ù°Ð\¡1ÚÞ;´aûd¡Ûr(>ûùÔÞ@7GÆzóåöÝ¨ä0Kx)¬º%I´Ciy"ÆÄj¤ÝuÚçÑ?îÐrú@Ðê\Jd3ÄÍf»Y÷Ðí[»¢2à1ÇBðÆS`v	lhÓ eÂ/÷î¦CÞÀù1Zð7arZKÅ»V¬qm±¤jnGgôËdõôÃ~às¬ÒPÕ{ß¼ôß½0×{é«è­?x¸»emæN§ªÓm!²Z~ÙFZl47^l®¯r¤}-´a+Ô~ûi{%B=Ã_Êg|d£·Ë& Axqvi¦ËÄ`«~\¶Ó4yú=}#Æ¤úò~6)¦¡à3FÕ»ÏeO'y¢`JÖ²Ò·ýxáô^s0Iê|Ý}¦ÆÀs={%åà©MaÍGë*×ÈM×Ðòp­*½DfÛñ
VFÏÉ=ì:ÜTªºBEÿÓu©Fæ%Ó©ïJ£äa¦Æ¬·^{©rýéLRéùõ2cïdyÃ6Ê«{î³TmÉÈ¥6Ü¿ée¨±Po ìOC4+oË[0L9OÜír2ÁÎ¶¥ q¡oYÕã½KVf¯1¢îçÂ	>óùÌ;²g4j¢¯Ñèà¯5Qù
IApðÊ¢¶«h_`Ï«/iÒª¨ýÛc6^ünzXdÚé}DÍ'co¼RæxXXLÊuäNwåÖÒÜ¸ß{ÍSÉ¼ÕDn¨§Éè¦Ú	gÄh¼çÐ	 õ5(
k×ã
o"¬Ï~a#¸®FPrjè÷ìäÄáÔ
 íókº%¡jL6'ÃzA¹Ö§Ûrs¼ûÇv¨"XZ¶XÊ½h¯~ÛrÃOãÉF ,ý}f·ó[}Étçíbç]}R¥Û½C^.¾¤Íê©¾nR´Ê#ó4g}Áü)É#Ãpëå<;?5%9¶Ð Èr©7óv}æ+±±RCýmÖ­í?º_st'ªÜ]Ø.µç¨øÐKÇ×ÞBðRCnÀö910j±.~áëXD­åíbm¢{ÏOÀc'ÍòEÌØ<mõÒ×ZïNOZ
¸²¿àºðÌ¿[øf¾ê,-Ì»Of«3ýO¾xÇçã4²~ê¬eT1RBl/·\oNMÆfñâÜE×¬Ùâù¾êô¶b`cæ'Æ·¸«ûKs6Bl$@L«ë=×ðNø	âO° ×0ÄìË½JOÃ|¤%-y1Ý9äy\RÈø"]¥øºa+Ughw^àéå.j!ëJ¹¨¯ÔôÉK÷`EM, lð ·°ÀºY°H*ùy|:OÀVçf»éÜçÕXµx¨¹ßG¡í¾Ì75*±Hs@g/õ@F}ä!À»ÆE¿íËðöåC"|Ä_×*ûn-±´Fm'
ÃkQ5xÑ/×hÚ6ÓÛûºQ°ú	õë"+ãäN1C~wÓc¤2©Ì¡¬ÃÛe)ñB]K¯"	Ê05pÊ
dXøÒT=`*í½s'ÆïdëÞÐ`@o©¬ýg_ãÜfS×áYk4îåãJ£4)')Ï;roHøÝìü`­´$ðõ°#e0;òf9{?K"~ÈcrN#®á\k²¯uFæã\ÔÁçÕ`ÝÏy0eíCK,áó}>8â´ë¸CzÊ¢{Â·'(pA_(Ï­"z7Ë>ês	"1ÓßZ©Jõ;ê-?Gæ©hî'ÙÎ±¯ùt¿ì¿*}õq|/iPËÛÀq9Á-[Ð(ÿMlô£þÝzmÓ§/\]¸Ã@Ölä{ü,e;+m´Béh7Ý
,A¼N}ÅÞ: ½:1XuÞÃ8M»_wçÇÎbO:èiptÑC_×=¤tÉ§	7fÛÌr®¥/eºyjMk7³e0+^=w¶nº?6Õ,ò[TÞÑ½¸Ñm'dHðw§²³àeY¼Ç½×3òÊ¥ÂWø±{ñ|£¾ÑO¤ì½Þ~a]LÐML±kÿØ_%b´t Î;df-ÂtmËæçÂêâÂj-²[K}vh+º¬%éTÂ6Ë?;ù&üè,Ë	fPû8ÍàcN¶ÝZÛÉæÇôÆiî=ªÓ÷°m¿Ï)¦öÂwÉ^ãþ(vÕJôg÷ë-À	q=Þ°OR6íæ?ùÌÁMyínl|~¦w9À«r¥á*t8m¯ÝÏX[/¾ð½Ë¹QûmÉ¿¤¹Ë1_ È\õi?uØR¬æ©ó;TY=´BM/9êiÑ'<a½dm!§}:/·c//æ"±®¢Í$Ú£Ã`ãÖ	T§ ÍùTZ ¥dÿd-ûæ[7M ¹óu¡*)-Io48ÉÊØWã8_WºÙáÆýëç{¾-S.i1Wýgûe^iómüæÆpB÷!/öÚÑs¥ÕÂº-ÚÈFoc}OÿJdWÇdÝ~Aß£§E&qYõª_L.ôY:µ&"#yª»f,z âdrÀjÎ3<¨=]®v£®DßN
Eyæ©æ'¥å(²t2À(ÕêÉÅò©QêòQFf¿W÷ØÑÕ¥r½a©ª,b&üu@Ù-ÌSwZ³á@ÑÙêiÝÏÈO+ûa>Mëµù*æqï+1½eþÀ¸`ÔîX(éQ±éúXe#O
m´+üÄ§G·­z¨¦²ºÒÎw?â}çÝzÑ%ølè¹T ñQÄ} Gà7¤z¹³È
M·ÉFÏ¿Lc!î50ëx¦wýe:E[Ïï[?¸íÄ^mÁ~µúnaa,ioGfWüNºuNÓÙÅË£^Qø¨Æªjl@¾ÜÕxlÎ¡5Éß¤+ð4?#@|!¦{Yã¸°¡ª1sQí¡1¯ëû6o¬D«ÛùÓ®ëf±¿î}¬$íOã1D,µH]2Ý-¼6àð¢T9ôgÁ½m«v5/|÷ñ¥¶l»8õìówY_°´øHúh(0b|ïb	tÖLÂ¸¯{»w¾Ôâ¦Y-LÎÙ´ñD<a/Xv>]#ÇÏ­iß#±|¾^co+©©áªÖÞÈûË¡­34öy>?ï á©åeën¬Z~âjø7ÂÏn}7ñg±¼b`Q\÷[bË%MÆ
endstream
endobj
390 0 obj
<<
/Length1 2136
/Length2 9351
/Length3 0
/Length 10517     
/Filter /FlateDecode
>>
stream
xÚuwuXÔ[×6Ý
(Í -5tKwt0Ä1ttHIw 
C!R¦0 Lap$ÿ£¦7ÓVvq6µúmääpr ±8 °9`²C°ØXB¼Ë-\þÑ¹áI ð¤L xJ(ÄÎ`²û¹ØÙ©Ú ¿iý­©=ØÎãÿ¯×­¬a FeØÅþµò0S;°¹8ÄÊ þ-;ËÝAj`¹5 æäú[ü
br²C@jPgðï X9ÀÿÑiYÍm! gg ÏT*PØNMû?ÂëcÈª)ý/=¼sÿÄ3u6A` þ°èoç ÅÿvÞÛ¿zÀ®¬¬¤£¢Èü×ÿRICÌ¡``êädêpÀÀ SwÜáµ²³A 0¸ÀÁæ°:aý/]ü·èoÄ`x@| vÉÄ`z@ véÀ.ó8 ì²À.÷¸ ìòÀ®ðà\ÒsQ~@p.*ÎEõ_Äç¢öà\ÔÆsÑ|@p.ZÎåÕsÑ~@p.:ÎE÷Á¹èýà\^? ¸é¿îgjï ?8¦ðyÿ#å34uÀÎ¶pS³ü²:=¨á59Û`v KØë_¹Ó_·ä_¤ù¿Ýj?½ÿàþ-±· ûû.°[üA^är;ÿa'zoè¿òòþÖ;ºÚýá¯×òÁÎØìúGßj¨Óp«p½ÕïúÓNßú¡ø$­=¬A?,à2ðÎÔæ/ÎöïÏc^x#ì~¯=¼önð_c§¸Øý^VPâ÷ú@ú¼P5<©ò_óææøô¿§Í§ ?f­Myÿ¡<xcì\þ(.q|(ü7r9ÿµÿÍý[,ÌZÄ%ðáóààÿ1&x'²ñÀAöàÿ><¿m@®ÌÄìþ@^³©³õáÅ=¤åwfíúãPÁ»sþá áòp;à9]~¯|gs¨Ó#×? °Û7ÔýÏêñÏó3<'Èéoÿ½éÕLÁÃ¿ïÕïÕÿæøkÂ ¶ °ÌúOeSøw×²áøû÷Ï?ÃÿûHH@Ý½XyàO|òÀW7¯Ï»8ÁÏì¯wþý-ÁðrcÍÍ@ÍÞØÔ¼i½¨'scÝø¶²ú)<V¯'Fÿ5ÇËZ	=MvÂQÂÄ¢x(Ym¶4d|ÆìÅÁÅ»AgFÀr\6Aºg]â5wàò¤Ó
Di%µåK_ü3NÏDE!Agæ&¯k³òGÁí'çÍ×» {@Ñ>u,Z<ëÓ.R¤5í*lPÏ ?æ~ü«Ñ[¤7|4·ò;£!¼Á­PÖ_e,»['w«ù®'h§ß	´:ÜÎ
ûÔ¾hmØIoSâWi¼1tT!ÜIºèôón??¹¬Mú²ä´¸Su¡¯àØUrÑµ*¥±Ñ¦ý%Ó§:÷õ¬|ê­xÅñãCxZvÔ6f#>Ù²¨ÂX]Ó-ïÙÛMâ!ì£aq}"Ñdå2_:¾·9Æ±éóe}>Ö¬.´ÃªPýÅ?ü"°#p]fyßáeú=áÉÅ4~wã>A( Ç Í|(?ëî®­U:T½N-¨#Ë¥©;1}CzúÝ´ACh«VÍ_T¹åÎ
gu®ÚÈ²'%:>.Ð
^2qË±gÎ¼E¨ç¤~*+ÏÀ£Îòãú¼ç^ÜªØ¼¹$}i)}*õì¸Æ1÷õ´hO.ùR=pcq9gåÔ^£`2óLE¢D
ÿÊõÝ¹úÿ¤hô-+Èÿôö§ó½Çnôdã5}È¯ñô´s}§Üz>zªv¶eùéçÛv§è­ùþk­í:¯CÒñïJlLÝaÛoÚ¬~jEÃxõ¸!¦îö¬pEø]ævÜ;~Í²
hÿEpy0¥×i(íî:OmÀG8&Ë1zqr×Fó8[Øha2ô"|ÚEß.Gþnä$õ¡ .æ®Û[ê(¯wn¼õÇ|*ETÝ¢_HL¤S' ]z<j»¸§Éj~uÈ×Za¢³^ÄDïêÄÈ+÷W£ ØðÉÆÖ²$*¼cÉµÕÜã>ýí¤ üxVUÔ([áÃ0H5xP}jÔu²òú§§¡ÑÓ60n>d¹I¯²	x[ôSEë;Ú 3@="cùLXô.AÕXz\DûùÎ×½áx.
¼½¸À.m¾©Ý+`¦07Êüæ(½YdìeöX8ÉM9O¨}Î5B¹UóGAÂ«o¾.£N9ªM/åòÎ6H5ãRQhÝË>6~ªDÌH@èÑ2±Zîq3õ~T¿L6å¯Þ·tâÈ1÷¢ÿéê#V¹JÉzÔ­ïN¬½Æ|(õ÷®xV¾ìTÉ0TV%òVKÔøÔWÞµ^ôF9ÉiUî]\
à8MýÊrøðnÈÆÍ."úætîUO	:¸¨´KÔ`ËÌµ29/Nvbviõ*SÁ=è¦<n{rY³ö
EjtÓéñÐs
,r5Ç'Ø2Ï>ÊnPQMåÀjÝu/VÚÝº&ßgØ¤'&_:ý  ÅÍXOalªABÃ|C¿wÈr¾R"j2y?·~*âñ
ß6|IûÍ¨&)(ûþnQ%µ8Í*õsý4_ûð¶ùEz®4UàÏq
âõG]BI4PóÊ}2æzV¤o¯
hÈ3J yàÇAË¿ÂUVïÚßª_IKýÈ0Þ!g·1ôó}0@HÕJØWÐØî¡»|Ô|Þ}Ïm\¾I4°cáÔÎ{ú.r£ÅIN;×S²¿¥¼å§(,fÞ,w ª9¾ÜôyÙç:ÿNZz¤Þy û¾[ÄòNWbîSWÇÒ	¨=Ú³è÷þ41tÍ/ßz úï£æXQï?mÈkÐm¡$£QA
#qÊ ÃÉk=bóÀb´qII`¿@3zÔZL /hîíÈ²Qôãòxlnp°¡7°jùR»J®s­çÇgSsBÞW¦áx<ûgF¹ÙZÚúQ#K'uh-=®¡î
Þ}%µykò<¶Ú±uS?) ÃÀ;ÞD'éàgµb^©Rè~]Úf7U(xîm]]+yböOfjtT#Ëþ"©ÑlèlÔÎmRÉ>>}n/ü+êñ´Gbü¤XymxürÕIIS¹{nÑI_ë¶0.OÎ!'Lü jÅS,qï¤>ÓbÌ±ZÔêrÌSXV^ùF=[Ú*PùIcLfû4³Þ& ¿¯¿<ÀÄ_Y2VÕiã±GÐG)`Á)F|¤¨{æHîîÜ¨¢/Bð]Ä/ïóÖ|´Ñ@ÐÝXv²ÕPO}îÇïMxÆ«óßæ³½ìPâ[¶XµÈÜÖi·Ó(Sâr~Ì£Q¦Ø¢Tj9}íòO
¬ÊFzÒòµlÊ'GÀÂ1K¹³÷ÒG¿Ô3j×J6eTWñÎ}hù´@b¶sCT¸¿øxSÁ_A¤ë[$û´W÷õÜw»úAn`_ê8?É¡+g Q]ÉµÏåZìª
¨oNçeòâQÞùdC&Þßé¥·é)÷ÊÔ.PÞÕw]Ø&8ÒÈè2Ç¡seSãéÊ[0§-E??yÝpÇå;¿Àÿ¶CBÜ·ÁÊ¾Ú;uÊ÷²uw¡lüu\oË6ô¤EÎ­oSX6%ãý ¡\bS¨õh ÁoZ%ÿje
qj£qáJ¦æÝ¹d¡Î«?>W¾md6L}y½§S*\£¼å²g[H·«òÆÐî­(¹C[ K ÖÈ&X*8ë*Ôy¨½ÙÅYoorO¯ù/`_øNø¾ßzyTÞ)ñ9Uózc{³èFÀ·Ëkpèòoîðä§cH£ídvS¨¶]uÄaLLBsÈûóvýêw²O³ÒÓwo$°/ù ãH?ã#àÃé7uÚ¿ÛÄ­,2
a,ó²Ù´_EuªZ¸v.{qÆúmQ,±ç<E)í×Jrß~ì/OÎYã3xìÀ½¢ î¦^Ï Þ µÇUD©VñZîÉØ»^,ûÚz%¥¹#QQ¹|-×ôÕ
NéÄNÚ|FcÞ2hèPÓè¥y¼5 È¤¢À<Uà?.S¸"qô3©ø¬¸=eÂA!i±Wn&Q8¹#È]Q±N!|)G	ÚÙ¿£#	ÝÞ75l^É¦åqï¥Ñ¥X\½Ã»Í`+4<ºr®YÁUgà¡	@=IZ«)°}è!ü÷jö ¼²àcàT],ºÏË¦X|Îób©)/ÙÒ}òìlaéQ½¨ ªPº7¾ÆmG4ÔtC³í3!JozÁÝ<æ[¢ÌgÈjáQz%hjÚÃkìõ³ÑªÏ "ZúaÈÈ¸ÝôW^U ÂÐ"Â±È]CÒ¯tm}¨GéÊ³vòÚÔzSoÕyÑà%r6w3»ÁÏ=êÒ	ý*½ÊSÞf?Q¼Ù¬KæëcF¶ÂïÐã³¾Ç£óaÇq,£¢ÇÓå)nðþ
ZüÌ¾Ä^ª¡ÃWgÎ;ª>ôO+n}Úh>	¬ö¼¯J2jð1ºTÊà§WáH$¶þÂ±¼5b¨,ôNÛmu¹ºì+Uèq8ýE«¿©-G'AøØ$sÄYËÀ{0Õx%zTÙ³ÎÝÖec7ÌN×-èM§ä=µÇT§Z9ÌÝÇõ>2¼ø·(¼\ª¡æwüB<A;ý"ØÖß"Ä£éæf×c&mÿù¼?^ÙrAW2>òaåÉÍáªe°·_UTyì1W,Ð»?±Ã³â!;Tµ !ävpóÙXýJpÿi¿¬x)Pk5ü"ïO)³ìÞQÞ&O¬ã\býÐ@¼×AÂV¬Ë?Í´Pè$¨	ó¤4	÷;6.)d®@
)³r
¢%>r×³|¯ûr²9[GûÈÌÜ>ó2ßÛìQgaUMóÖ¤-ëÐ£$«´(6UûNóµ\ïF%#õÙ!dÝÚuÝ¨ù²¨-Þ/aX*¼>©Jæéð£Û,õïÝr¼)û.o?×]ò£ ìÍ*s½ýÙ/µ¶¥"þÓ÷}Ú¬ö.nÕ-d>ËH95Î° Õ)hjÿÊ¢þÚ8Å´Û@B°¡uâIm¢G¶¶f½Ý=ö]j¥#¡xÒK§,	Sò¾¤ü³B&sõH×©a© ©0ÞÅîr1N¢]O#MKÕ ¶ÎË¶HL9oÖJ¿ö0ÖNMÒÍú|¬V'øR1HËo¾4n6ª¸þt¼ï|êBF%¾(âMÆ31®'1&ßIÊ3~Xs­7iªÕ¨Mm9¤b}ÕzÂã"?qüçÊ7yie^£¶Óí?î¦m&(Ï¶t|xâq«'²}Ä¾^ÑÆ]Y1ÕIc¦,ñíy}~Ý^1<kÛ°­æ¼g'¿æxPóÀ¸Zü®Xx·¨½¼ò$õù"ÞùwL-[	Lêr>zE«FkýÖ¨ÐëgÊRk+±à­ûØGRgÉ"iëÙ·ôjlûLy%-#-¦M4#ÑãKôXI	*ìn	NÜãÃæ«S>Ç8|LN$ULÑbÀÓÉÛ°«hü,Õöö©ªºDÌ¿ø¥ûzùÞÖ5WÃ^ÌÇÜ9­S&_ÆÀ&U~ÏpÛéeÈS?$1ÏUÞçþeJñ¼ùòÍKê8ôßÈVbIBDÏT¢ä9<í½¤ò9'øÖÄ$Þm~ÑFÃ½©Ê;KÂ¢î+èÅºåx'A[o8£½u*aNm%èzøKó£Ax>ß0?ïåÀøÐ[¨àV¿þÀ±âç34<ìáÜHÞåÝí*B¨C%Ót3FXyá@ZI¼ÙvÏÊKÅ»Î8F6Ä{êXä-[Ý5OÐ"P´ÐhaÁî/DÎêy[1TaO¦påöTÙÑÝ0zØÂ!yJÂÄ ¶­ôûs}ãÐ_ö²
±n²ñÏ>¹í%ºQÅOKúûQ
À<ÌÆq[îdJ3«Ó³K B
%M¡{ªÁê°nx @ê5½^bòÃBS=Êóm¨I­Ç/g&Ë²J«5n¶K|hÎ¾ã,¥½õ|ðTþÔJ ­ìHé5U!ÐCir9´âÔ4a`frkãBfç<·öÝpIot0åSîÚÝ5HRü§7Û,ÈOÉVÖ¯yë--'e³UÖ¶½
î¹c×X+|©ÂÅq; <?JÍR"K/É#Çrµ×>Úá3:Þ
»{Á-@äL¨EýÄÛ½ì\ªú%@Ô¸;wDnM³ö»F³HÁ²ê(ÏqÙ:a*Ëò/t£t§z
)0*ònÝÅ+ÊGuðvEÿþwµ8¸~Î%ÅÀÛÉº #úc¼]lõOÍæûåËtÚNÔÔ¢Km]%xÐ{¼Øê¥RbTxwU¦UyáòÂ="q¼%GÌ@iVÁtDØôIoö¯ÛÜêncêîRN·}êï`Ù¸ó¥wO.Ü$ôÜòí.ñf|ð[_ØJô<ÿaò*÷3SíJÆÖp{±¤Ì(á~épKÌë}V4Î }þ¸¯Q*Iuâ­£-uÌ#3û_ JÓ¹ê¯W",\Õ(
á"Ô[cAX+YB¤Ç7·5K")¢¬Ól^¶Þ­yÙ$+±ÇªöÝYÍÎê&*ícg?6¯ÍVpKõuSØÍÛEÔ&0æ;TÓÂñ#kÍ±u(k3Â.ý8¥ÉçÚo¤jn¬¾[
O$Dk;kz+mÌR"/ÊeicNà¼q
F$ *4®}Å|©pgoäâ¦x®Eì/Å·
(ð¥ÝýFUCÂE¥Tél)eR  ~¬´°Ûlwd>F¢Zÿ;»læ[¨ñ¯eÍU 6ú*«:¿§æ:ÕóYÐ©TEª"a/¦0ö­0Ì,éÙ~ÁágìæÇwñaZ$åVÍ,c^KÇ=`Ë#m¯çQ\ØNo;¯È|BS©ZþÌnÃp)·íJ"»Ú?¬ÙkÉeé§ä¼¯Ô¦®á£	SÎ¯A).wâtäÍühâºlÝ_Qü¦A29Ù²}0}söã}
 ÷MÃ¾ª2§ÛCåT.ö%¢ÉÉMõ]<$Ìb[	Û55_|$ï°Ü=;k@ ó5|û§Å~õ%ý'lA^ñ«Í{<?¤*#~ZÍU¾BÎ
endstream
endobj
392 0 obj
<<
/Length1 1144
/Length2 4009
/Length3 0
/Length 4765      
/Filter /FlateDecode
>>
stream
xÚuSy<ÔÛÿ&Y[!ÛX&Y³ÍØg5K1Ùe+Ã1ÍBYD²¤-;!ûdÍ]¬S"ä;u¿÷Þßí~¯Ïsç}÷r#rÆÄ\ZwBéáq$ic<¼æ´
í¢Eý¦:Áãt$
oáê2F@r`«À!5XþÏ@<2!`<ð7A&(Åà(.ÞÙË#{yzb1(¤÷"8£0¥²géà=}	´+	$nif-!))õ7B¡ 'ß?.Aã@¢7
÷ü"¡Â¡¢?cM\ÒÏvAâ®$'LVÖÓ¢`2D$+A)ô©÷ø)@ü.r¦4å+ûûÜÜqxß¿`ù«%¤§¬%sÝe¨ûß`
øC£H E°
¡®P7]e¦´ðõDý"!?aàç÷¹ °DT ÆEùüoDðBøý_â; BbI 'r
Eª(ÿ»¢	óßÀ6Ä¹àAÐ?
§LìÏâ½Q"Å ñ_ ýS	'aQ ñ¿MbVSüAùAþ§yþÁÿOýCÏýÕ¿ø(AF ½c#<0Xßÿqà÷@kÔ>ÿtI,ÆYÆþ5&Qs4Á]ÿ0Æ¸%ùëÅ¡LðDÌÏ7(B~ã,\1Îî8Hqß/
CþòÎÄàÐ sÅò/à'íìE PÆóë(gÿÜ»`(¢P7PÎ±¼³j[YHÝnÐGúc¯|«å×#/A@4z^æXÛ=¨µ£®kÒíz¾ÈÆ:,x!ZÙÇª]/CÏÆÊvÌ wM¦\
éä¨«nÛKµñàtè^ôÖii¸ôaþ-U©½ )_ ¾8ñ¶·:þå¿¡ùµæ§ôc_)¸Aµ²ÕÈìÀ¢¸ôÁþ¥>sòÕÍ«¢´R&_ÛüFyç
 x£ìºiñ¬#ýQ8n¤â&b¼I[ZÐ8RÀ·ëô6Ã²d¾G®W.ûÚÀ}µãöjÍÝX·'ä«Ùuíå"%{ø¦´ÕêÀ¡f¬©X1kdDt6ÍÄcýåá¹ÈÝýóé»9ÃShPÐã¨»4LOÄàTÙÅÜ
K?Î·*a¬ïÄÞmc¼T_?Ù©QzúÒ7[¼ãÅí¹N)êð·p+±ÒÃ¯òoçÃ=¥¦ÚÌq9çÐ_Êéù]ó°¢_¹º¯U°ÒMõ=}È_ÃåVg¹7ºÊöZ¶%Þ×öjðÉâp-^·Ç¹ýþM%LçÔKZýsç·äz´¼´m`Úhåâ3v©WB«\#ªÝÕ*Lô¶	>2¯¸Áé§ËkJ§i|oVøÜn$¸±5UêK2áÉK!~À'Kë|¿s3 ÀjÎÕ®K¢ûb9
gó|wAHºçzójÉ|O-§­­¯¹L/¾+­ö$ÌÍ³Å6Y[Á"TëÕ[â@
+×ý»é2ú?Lä+ðÝ»_0HW[D/YþìæÂäÙùü-ücØ¹ QöQ[àsä¤º}Õ¥jZ4ë÷é@þûè§ûgÕ±C$µWy6ÒE¾øà:¥,)×^µ­uVÿz1õÁ¹q¢÷çØ+Ëm_Êø.DÊß¨:Ú2¦:0úôºõÆÂ*öÒúä'RÙÈ6Fn@l<Ø1pN­ üy
NÇª+³Y
'õø54ûlLEâeÙ,dsm48\1Þ+CÌÉ)s1AªõÓ<«IûÔ³´þþý}\È;F1<ø
CQi·í`¯(Øô{lÞHÐfÃþþð
ù
Za|µd/NkÈú~MF4M*z¬ekz tçùF¤¨ÊÍ×tW{çæù[B¹õç ¹£Ðí<§Ì¡ÓKnR9£°a -ÍÈOël³5Hê(à¶ÝÒ£RÖKO¤éV{7ªÀvõpæ5ºw&,5(l|+ÿîc5¯J¨ÑE~|^»TCî9Ú4.Ý/hã*4«Y¥Bü¨Wå6JøpD3\)kÓ¿RëÀ1²L#B%{«®Ýþ©èùÍö«·Þ6æÖ±þ*ó­AM÷àtK`}¢OÝzÂûó=A7Ûïg¼±~|Ðnqù¢ÃAEbÜë{_ä4°ÄÚ}rêôqÉÇ¶Òfg¼³lPÍ+»O5U¼
Z¥B¢Ât&r÷[»»ÔJGÒÈèB¾äñëÛÐªñÆD±[½â>ÄÝbf</[¸ß^Q9ÕF`OÔ15£OÔ¾^L
.ÐVRE/N ¤:6-õ\Jéþ ðAK¾ð5b¤a|6°JxD>HFwì²w¼O:¼¤lËdRºô6ëm%9x6âÂ7ï¼øógãn+i}ë×yÍX¤Ï0ðÔ<nïoÅûiÙ6X­¹6\jïNõÌÑ
endstream
endobj
394 0 obj
<<
/Length1 1626
/Length2 13330
/Length3 0
/Length 14176     
/Filter /FlateDecode
>>
stream
xÚ­teTÛ-w	®w·àîîîl`ãîî$ÁàîîîîîÁÝ^Î¹Ý}{Ü×ïO¿ûãã[%³fÕ¬µ(HTÍìMöv.,Ì< ­«³½­=·<Ðøcç§ u»ìíÄ]< M @h
`e°pssÃS Dí<@. juM::úZþ
xþ§çO¦3ÈÂ@ùçÇ
-ájc£`lûgþñÆ þ<2Æv?ï@ð×Cãjû¥Ûl<ÿ_Iÿ­	ü[{³õI»ÿ°ÅYÿa9K<fJ SK¹±ÍyýmW·3:Ùìtý{¤ fæñ©YL­íþã. Ù¿Òÿ#ÕßäTuäuäèþÇõï@¥?Kà¢æéðÛ´"ooö_¿`DDì= Þ,_ lì,îÞBÜÌ¾ÿCÉ¿Xþy7vqy tÿôÍÌòw÷ÿñýó¤ÿ/0âv¦öf­ª±ÙMû/Ã_nSW'§?ÿ}ùÿtýç¿wô Â¯.ÙòX¥þHs©ÁÎÓíëa
u(®W+È¨²ïöOØá.7z­elâyoõ\<uxÛ¡=éÁ²¡êNþÎ%ð%£éÍCÛ¤lç¢;b2(FJû¥ùÝûbAnRYãàç²AÑ+4áT;ìÅM [^ ù½²iJ]fjzMþé/Êã{ªÑá¡Áî+¨Þ}|º¬8
^cl¿¤SDO#§ÛzÓw¨g7.0õQWUQÆ8³Æ¶tyóÊMZÿLýtZ?««îolå4ô¿ØÞ)»VÏÕJ:B6,ÕÇ¦B=«Çö<D5º@ÞÃÏp1s0Õ@É°UÔ´PGZô|<c ,õ`õâgåH.¬5ñãPx0I?øì¼í=ç	ã>ÔN÷Z¹A1^+Ô*ã½"oh_vÅ¤òOÍâËá^ó¢¾Ü1NÈAºå§Õ®Ü1áÁ)¼'ÍÝÊæa¨9^³óÇ­-a¤l%kÝZT0l~ðã,ã2?,ÎÊÑ¿K ËYï_Äù	ËìÆi¹-Ö9 º_`Ñe¡g¸{±û7±²À(óSRsÎSRO{1%ëh]^äÙAKèI9GëjA®ü?:	¿ºà;ÎÌm5(:Áf|=;´fìàjñáô¢¸m¨°pýÜÛ©vÎH 5;%G'4§"ä
Ó;KIÊ§ÕXè£cy£4?o]ïBë1ÓlÐ:GdWO)Èi8Ú¼¹-1§&r%F-à¦MÕi]Üç²Ésy÷=¾(øÏ§MH¶S~âK®@òÐvçáò²z¼ÒîPï6;û1¬êX4®Üå³?`¼þãÂ8% Aç5Ó-
Ò¹É±3g÷»Âáu&X?Å[G¸H»Tãd <W04ï¹LwÅªivfV¨Û 3cDWÓ¸ÛûÎ:aâåº?>±Èãá: ç@¶°©LÑ)LíTÁÖ§£ôéâªµ}ÜøZ2mç5ÏEyt{;LáK	I
VÂBTÊMèË=Jð×§»GþyÔ
ïÌ{6WÔ55ñnÍp^Z}ûT­#Íç^¡­:ºË.#\°¼sðyå%rp«®ÅmbDÒ6ÿ±, ¾¿Eõ³aÆñfðºn¸èh²£[þËSÅRã¦)<tL%Ì<Tc¤LXEI¢;3Uñ¥½ñãÙlKOÇ
A$yÆ¦÷å´;Ýõ8¥KR×S­÷Òp_ËÔ¥¦TÒ£ýÏv,½â²ÇÿÒ©¿óÿ¨¹ÑÓ©´[Ü¦C>e*Tñ"C'ï±YÍé»¨Va£Q»¢(
0an($41xq§ç:[³´o|m't°ÒSÊùñèJ>Â;ÚK,óZxæpõcªü®ý¶Î³¨_7ÈºÈC³0·Ø*9Rb&
=D`«A¹ví<âñsáÌÒ+N%}ËH»ò¶G]R¦e´°¿Zø©t(öÍÛ¼~­ü:ÔC)¤G|óy»_àSð_xÐspÃ¼zþþV¤;bëÀ¦·àíù©<àjSZ¼03ÿÿ£ËÊ_CÑ*ÄDÑk¦oÓ`F:ñÖqúq|Ë¬bmÄa\mIáXÑÞYÃ8Åîe43$Yoæ âKÈç¡¯ºçPF©»A x¢.)ç4¤=$,q?D=}§ßÅW¯ÑôÈDÁTêÅDÔx'¾McÛyü/ã{|×ÁB»Þ27z6P)¶Ô¸¦­¤Sð+èý_nb:ì6Â¿ýjíÙICî(Wsc|ªÒyÃ]«
rEfFB©ÞÞ¨$et*ÀôeJ¡
5ÖúsaLhÍ]7Ö='C.ÅMùí³2Dþõ©ç`T
Ç7uX?n ¿ÇZ)LúèþÏo*ÐÑMês¸U{HÉn"ÝiME3Þpß:1æ¶ùYbÇçûòm¨Ý/äï{©RÀãB"ÉQ|,Oéà½99#KõÅä©Âäfgü*(øº¥5rdk§|f²XÑØp	L¸!éue	0çvEðåÞµÃátÕy*	ÂÒîâáîë¿Ëlw(ãä©\è6K0!gcÀ¶×ó60á1ãÔö
éÑØª©w8£ ÌàøWC´ñ
¼&ªNA\¥$¤ÌPÄõ×.¢P×êâ"m']YìK:cË¸ÃÐûÚr%é¾áÜç­ªÅ'7& »y´Ñ'.&@{ydÂ>%Àº×}ÿeKpkB&`ÖK÷ñ¦pTR
» ¡¶]óS¸8øÝÇÀþ~TI<8ôò-#¦dìblÎè¡äB'OÍ",e1)øEØQ¿ªM×x^¢êXÄì"+L½&®Ý´Ê©ý7týàg´- o¾fÏÆó«&ûàÓ=¼Ê"Sí{OØk÷¼éß©H«z³ËØ÷ºú­FJm=¸HäXÛG_çúW=	W¦ó>àãK£_Yr[ò÷KÁ©µ~ûJK>*áCvT~¦dîÈaùîr1¾òå°ì|ªækûÁ'QGyqwÜBI9æãøïë]ü_lÔ}tbÜ>(µ¾¡M_o+yûõÖ»¦qÛ6Cy<F'g¹*<Ë4hZø?»ÿ\ì(|§;ãíã-ÙíãÙï]úZØðsíýQ¼©ËÁO0ÅL­*øÇ]ÍÝ)ÖÃ~×þÝ÷HqþKð:Øq!oL·¸ÎÖÕÚì³Ï°R0>´?ÛÈ<	ÊÛjX]ûáF¥ Qø/#æþ! $h53O/»=¥ôfÿ!üãÂ.GâUI?BÛ{K6¹Ê4L&+"k"Â÷þF¨×Ü´ÍöE[½úUøãÔ*ÝåBõú«O`õú1§/íç¾êt°þz§o®
XVé=Iz`]}+~ôÈ«Ç%Êh5Á?½
¯Q<2y¥ÉW\Hä³ëGHk p1<·Põ
Q`dãï;à 4=¸»6-_	²}¢IöS\ Ø4Z¤l1O¨£>ÜVñ'åf«%n&Åüu¸\QJë×I%üñÔÉüyámçô ì~w¾à0ØOÃ%Oýb%uâÔµª§Õ¥íÞþúkÂ*à¹8'ØiötÞKÐaÝnúo¸dAh	®¹æ9mÏ÷Sä"äâT7­èÍ	ZáÕ%ährÉáL§¡ÏCÍôªÅ¼ª&á EpÆè}²	vLÂ¸T¯~|Ñ%eÜÈsQ¤² ¡ÕlËáÌ
,*uI(ÕÍ¹,enðSÞñôÊÝ`±ð\1+mJ°äaWôM[¿ Û$Ø¼Ó
IxÃ¼ÆÁó%ÍÎ]6r«Þ /ìï Ú_VÂy
3Òû¸ºQõ1©ÑráF®Üeý
üy¿5Öò{Ç<¨QÖ¾mÁÎÒÅæ
Q¬ØÍ£÷_A¶m^Ø÷ÿÆ)<Ä9ín-;ÝÚÌÆ5Gg¢î¬!_Vv°'±ûuyAcÄ­+àÌt3?ÜÐoeù«
½obu_¸=¡%Tx ~÷ªííjc£7<Ú7uïPç»Åán#½DK¹ÝW7,BÙAn÷Ì²Jw£IéïºLè
w5u>Í3åY1ÒAá°v5ånqÙçê¸¦c>'#¼¦¼Æùõ¢ÕTP3N1û§R$eã§UuÌ¬vLöfs[b­4uQQÒø`¢_ 0ÚÎ¦êBÎ#Ô#zX´$ð7Ï5¿1õ:=NýHÖQU±Få%S L)td}¤X­Çb¢ðó®T¹úÞ·ì¼®h1K ­¦np#d4¤dF(°EMã-×K!{ãüñQËÏi¬áV1CÀKÛ¢µÞE×èf »ü^gc8¦M]Éb~¬ÑSÖy<o2c9é`å¢ ®g2î6BMr5OwÂJK·óýÏ"­ºÐ¹¯¬ z<1k§Ñ&9)nuúí0Hé_t%ÛQ
^®D´Ê¬³ßnÙî7ÆbPÞ)3HÂÍ¹Cvø:Z[ëÂÌ]Á<iáò{vÕÍHxö2¥Î:©3*¹¦ÎÊîóî»ò§æÛmÅK¾pe!&õþhÄ;áÚSyBr8Û
ÿÒøGË ¾A}©ÕmÅº¥8\Ë¹0dÚý_±éðUÔÎrÉ6y;${BUìÙ¹)ÜÎÔãH`(½/¾¾Öµ	yGÃ©S!Ty¿UÙ²º½Ã³Úyx®SÊõ½õë(nÀ= £ô{LaÐPµ¡srÄm¶"k#FÔÔ$fËSHzr2?9¹ø u&¼ÇtY.å&ÅG|4	4æSeµOånêæ%Mâ!çãàBP:]SxÛ3Õ ¾d¦OÀ7Æ8ûò³/eÒ#Öñ¾ï­¿%Þ|>~ÉÜÌ=sù9;_?µíµk<³ÄqÛU!ZLZÞø¢âVLçMÇa¨u¶¬tÎ\ºj6ý:fìÀÎ)KzÙaÅì}ÊDÅ)=Àén÷ÅÆMnZN³­²Ç?ìåá&aøQ$gL'K}t8¯Ù¨
üfÙ8IÈÎ´¥
Íön~Ï4²I¥8o6ò¥TðûS²Fä¢:ÈÅ"zá£ ù-jªÁö³mÑ±XGg®Maêë ÍÀe±è1["(nVC4tóë·þÄÝbô7þëR¯Þ`e.pOÒô¤AEsaHþãz0¼±tj:ÂCÑ1ê4|ñnÐ+s@ÔÌÒVÒÆjý O8±ê]zí¢ÝTÆ'¦C¾ïßÈ¿½¶íEªìË[¸¯B(Ó&þÄüb'ØàÙÜ»Bàâ£7"J[ªî.·7
kc$&
oÔ&¿FÀfh¾VÚUMþY
¡Kzgà8Fi7$&1Qòó
RÇQ*6Wmùk>nåqpØô;ïnhlÔ5a¬ÉýÙ¸èw:m²éÍË,WîhAÓ;·êüb¤R#¿o>4ù÷·àè/ér?ý~ò,ÆxT(©XåHR´Tæ½®(jKºy2µû8¾êÀ-¶÷éÝ}/û?òi¥ãäñä
Íý*o¦>8Õ3v½~Z¨Dä×Yø4«ÂàG¢1a×8p_©ª0`ÏäÉÀ·°l²â65ØâÄæ×ÏºÐõîWÁx=çª¤S°åWÐüQñÆ¥ü)»?	t}(²¢Ú«ïºþå¼9vBL$nWuu·píiêtÏ
ï!h¬Ä04åN<$LP3ÄÅ@Ñæ]Ú\cG¥ùÈºrí?¢K±u]jKÞË¼"¾½±ZXøÅØ´-â;ô.ðõLåÜ÷}Ìqì»&ýðM	þddØð Ô@UDdh"·9ü:ìüNr;X8¬AxTì2£ÖvAWÅHÊTÑ?7Ã¥ï(,"«$. 6¬p§­Okµº²ÌT7­ô:ÞäØøLc½TVìIÏ*ìïîmlÕ §[ã$ç¢­
®?Kªe )±7#ìô¤C1µø×NÌãÚ®cô³º¤¤`ÒëkgÙÚûnçñ§Ki,³¯¨ËÒhX¨)PØ¤g@MHoP â9 Ô9µçz}MßS¬
@£r,hô¥ãÂ£RÞ¦¦ÂòãÌ©Ïd+õ^Tóµ¨C)Y$	fÍ©È}^w·È¶øW+ªùF$½~½{Ã­¡<WFõ¦ùø¶¸ÅkïV¢Aï¡ç-VÞGwÏp´eà`QDÒhD!g«ÈÍ}cæ±ô|À/´#Þz:tÉ;|ÕjÚy0gÚ_µH ,¿Çb3\SïJÃhòÑ{Y*®¯iúKÁ½DÁ¹VY±ÇAvshÛË§th[t«¯®«¶åômPz05yË" ù/j_?Äþ!XLTÖPÅõ.a>úøma0:Ê;Ìäü½¿àÌýåw³Ù`åL>ì`Ï/a³utäÜÚâiØì,ÙáLu!ßZ½ëÈÇ}éyÌÔë¤^Â@ÌQG¹mgû<u±eÆ[ñTõ¥k8S48oë#&h´±'ch¬¾ÖX:]MÈ|ÁyµÑöÄ,\ ¹÷n3ÑXäEYr<²Ñ~G^ÖL¢´ËÛ'Etl±ÌáÃkº¾Üù¸ÕQjÅVÍîÃ`Ó(?
æf¡·0^ÄkYjH3dìü$D$Êäjáúù¥ÃÔû¯³&øjç_J-§òÂ¢ºªWQ÷kÃªd
ÑÙn*Ïm¶KbjÒÒú®5Û¬Sx¿h'G1_2½F¸iöSOð<{Æ(
iÎoú·ÐRª4(M¸~ÍzÚs­¶¶-6Øç+8I² ¤¹D¬é±ô1Õ¼ö'DÑ(ñ ßÝ®»0ÉEÑkzëmz÷té%¯7GMï¨­T¡5¶¨Ýcðs8I&¿Ò×2íÄ­>Þww	¾!§c3ßqÙpÑtqy¶4rÒÅ0èÖ¨`|3ÂÒJ=g%é`Q.PF£ìPº.<¿D¯´D÷R8ã²i¬\©Í
ÏÛVÅ.É%ªCIRK).Q®GÖÐ¾6.$Sm#Ò¥ÙGeÚ°Lê'Ê²´ðùýóFgùáWÒn
ï#;H'KH&TV½2¼A]¶`²õQfbt±ÜþnßF*ûàCT"-¦»«c¡E¾ÃÆ«ßQÀ¾ÂAjæNa¤µ³Ú]1;a>þé%Va*8MÐËZ÷ï7ÛG2+ÔCúÈíãWNº¬1-~GS£Ý|¡ÖMH`¡úmåâó¸Hâj
úXeP¾!¸S4¥V²RÜ[Ö3Ûøí±D-ËJv¹.j7Z*pÑZÂïÊY¯lãd¹KoWÏRÞwMøuu0ÁVa+È««NtLt¥ç#`îO:Ó/ÈXàñÈB-_ÑmîêQ&¨÷gÕn0ØcD0¿¨Hçæ`¨~x	0M]mËs[\ÑL1|©ÏS,²f[8 º êÐÕ$o¿¡}û>r-
m&¨ÄvcÙ<q`YF*ad Ùêÿ^M\Ã£¨³(gJÛ Ï´Hñaj¬pì&RmÏÁN[Àáöã¬À_m¢°lß-½Dë½NRÎc0+í'òå4ºîüÞÄd³ç¦¬ÈÚ¶TÉ8õÍ%Øõ1y½Û[KìsÌ[G×õ"VÊ]öCOfÏ¥;j¨­lxY*å^KHyà
Q]/Éw¡à¥u³qwÜ¯±Â¼½ü\õu»%ÆyÌýeøÍJìæ/s§Ñ²û|·rÕÈì¡@8îå­ü^pôGGh#W*4îã/X¢móyîÕMKm¦³¢Ðg ~VòNn9ÒUOYlCaùn
@2ëë¹Î¹hÒ2ÅÄ»M@K°§õ]3O,CøópþÊX£ü>ßS W.SjzI¢¦éÂa²ÁÖàuokk£OèHß±CÙÄ-nàêTæúÄjRrç×ú Á¢ò¦uÓê	¦üêÆÐíÆökl©±&G¿o2uë¶ª`DYé:D¿¦^ã==îsÄEPCÂnAjîÍíÌ®ªhúY²«3w?g"ÎrÅ2´ÅâÆ9ÀìV¦='cF21Gèø~D§[öHçÏãh>rçÌ|ó4ÚCJýxÆÄ?? t¬Ê·U_ZÌNf|r	)jÄÛ­á³-}M°ÏÚãù,jR~)Á0µùR!¨äAÉ?#PF[Ëv½UHXÑêÕWÜ/SÈðRzAXfä|Ü
Þä³B´!¸hâ«E@0Ä)¢e÷5Bm{Q:'ÙPÝ[±EåêGuu¨{² ½ñÞQ®"Ä}e½'3âJ([jñçXôÌar`¾Òâó¸\ÜþR2&î×3¹Ë4`Ïã5©¶¾áC¸Æz»P9çãa]þÍØ+Ä4«8­ÃÂÛ½ ì°me1âKt¿96çÞ²d¿£í,¨GR²|Ñ ­Ó§4µF//FúÛÉ°üålªT~Y¶=|ÈÄÕ>ó;øð´ý{Kr«½ÓGq×ÔSúEúàxeíAüçýE©âA6éu&§\a)L¥¶Ì«½e°:Rý[ÝÂÝjQ¹6Ù5;bpjG¦ÛR6ÛTP½,\HÕH½ÜkÒ_y´'ÅvÒ)#6þµ«#5$jäj{Óp^iµTÐ;:ÉÃâg¢'1}T¶éAYí_I¶H0Öô²ØÐËÃx^?y+·ÈªnÅÇÀáûu7×`Q,¾ç2víçÁ^og»¦PyÌ¡ÞXvpYÇäB»@QaR!®bà5vûÊG2ÛpöØgã¨1J|1~:-QòQ7æw5ï²NuÌÝ=eQýÑ u&@C¸86úst&$_:ü|a&ÕVz·Ì$A$ýàÚCé1"z±ð¥ZO¤CK~PÔ¸gbò_ÁáJåL±31
ó9¨<Ò¢¹ØX^ùß	ÜµþX¡hGMëÖ§·¼l=ý¸#;µÛFTCÈÚB
í[¯Zj|á+ÝóýQÿ	Gú`ôädÛ×!p£~ÃÂQù'ÛÝþHrXîI©Irò¦ÃëÄûCÊv®ëó/gYÂÕà¡,DÐ-»\Ó×1OW®´­vã.OWc«¹6åge,ó-yß/;ùWîèq¹Ô¾2¢Qª3È	Þò½ê·~®¹LÚ»*u8GN·¸gë+ÁÑ S£±·<ÚxyµmÍ{{¢\ ^/¦<Ný?dèy7ÂPX&%_Ô³öx«2y\*Ñô qP«Û-T×´¾"Ù$Õ8±õ ~/Ç
endstream
endobj
396 0 obj
<<
/Length1 1630
/Length2 19223
/Length3 0
/Length 20056     
/Filter /FlateDecode
>>
stream
xÚ¬¹ctem·&Û¶mTlÛv;Nvl»bWlÛ6+NÅ®ØN*Æç}ûôéq¾î?ÝçÇcÝ×Ä5×\kMIª¬Æ(b4Hí]YXxI­ìL\Uv@yFU+ÉRÌ	`ìb´7vðhÌHÄ¦$ll$¬<<<p$b@O'+K
ô ñfdåä&adãfýºÿ¾âaûæû¿	ù/ Öÿ<+»8Yyè}ÕÍÂú¯êÿÇï?OÿFÂÞhöÏè¨¹Û}MÛÿü£6uurú"ù_à«êÿ8ÿkî )ÜêÐ/Ä:-3Ý¥;wdR\o |$Ô¡´Q½¨  Øë±ÍSùý­6©i÷£ÝsñÔá}_îàW-uo*à2À¶¿ uªþ Ù°1ýL+ÚûjAþ.'æÁÎ¤ªaÉát'»ÌÕ#m ¹[A ÅéÏ8Ì.&´ºÂÓ3ª¤ãÇê¡±ÑáÞÈþ}|ú8XJ>cl¿SÒdÏïN÷¦/n\ÎUY­Z5¨Iî^ø¯K®Äc·ÑYÓ/Ø,>E@÷XLâäÜ/ÃÃàcÙÇÅfÔe
«£°|î,ôçKØVCâ)äÈêßá·ßîç®é.(¶Ó!Ígô¥Êês3aU0Úòñ OÌX)6´ý·`çW,N®¶d7ÅßÙëäN§.æû²5uÍÐªXÞb{"HËÁqµ2Á¦?õc}ÈKýÿr3i×`o½J!ÐÇoS!Wü-÷rR¯K Ãñ¦­²þSåäªLªfÓ`åâä+¸Þèx~{q:Ël&¥ÅïsfÇd]ß8õmÏ ûaMÀ0·Å>[ÇAÏaæ·jÌE2C¿Wo6RTÈ	OÂ1Éd$éäs'Í1Ö
´.1pÜÂç«cã¡à0VÜ`ÂS©)ÙþuRÓä©þ[f
}ñkôqªm!y.CCâ('PC"tl6ê#ã§cdm~m5Âëí^é¦?
ºõX­× ±zª î0CfFÞhC¹ôÕê¢ K¯HK¬;¶" rO¯±>&X½lïoViR³Vot Bó3	|8ÁJsP5$Omæ÷X§Jî²r[æøÝ_Cü!­¿½ïÁ÷¯>niñúfþÁk¦!ÌÅ#¼ñÓ1W7ÞoÄTÄ=ÚìéÉVsó`A£Þoj·jüx+¤@¬oÍ2ÈAIc1,É)ãÑ©Á[]7fX#§ª4s»cÎTJù£àï
qâzkA3%õo®feS9ÑîÌ?G/Æ`e,QØ¿ü	¦>îYÆMLª àõøý7ó´&{Pìü§"v+óÇMáålüvIÂ½ÇMg÷Ò*qòàßÏZÙ¢°-¢5b£¬üaY§ñ¢@p|$l­;»-üæ|Ú1Dz×­r W23%NÊäúöpª÷­,U}Å¦Æ_`Ý?/¬WÄ|oµ=;d>ù®.§Ií
jhÝÐñ84(pÅ|çõ»5|¬v óøaYÊv6Ú»³ÐÅ
«ôÞ2lhãóRÀÑÞzkà³(Ç=Ôgð'l-7ÌXYã°ÞÃ®Qrñ.m
D?é§õ&èï(y?<ÃË°ìè!Üb]A¼ü±Ñc&"éüZO·Ó6Ü~ÈÿîÖ)¿w¢4/-F/é'Öl±çüaýÇ«ÃØ§	ñøoÁèéM³´«~xØÁµIÜ½ªî¼WFP]ÉòÀTaÉ
];¾I;½\>nIUÙ/h_<Îº$Ìæ"_ÉÅ¢5±A±¡=ktáúµãÒ4YÝþm8c}}ZzäÞ'WB8Éþõo«á¾f´pW¼tÝs5Oýºð`§¨¬ôùtw¢øL¯8lÑgæ[	U¯}ÒXÀ_îó;på§/ÞìëÌÆGè¾2>·µ¥>Øü¯\MÖÍ8ÈÐ"zÅFãDÌFÅ?îfÜ, T ø;ïr·xÐ+~l"øpY#öOÝ 4r©ÍFÃªRNßDËÔ¬ß|^,@uæ.+!w]CÓ3l;Ä³[7Z¾´PácÞ×À@ZÓHÉu+ç&tÉQf·åñÔl[&­e¶
knµ	"-\8õ9.¥qÓzjÏ!ëáG_;Fµ0éR¤¬r<É³õaNï'âý`Lò±5¡^Ô\`v0¹¦|Q~H¯q]8 íjíxì­àqüÚ°ÖÂû²ü?D§5µ ¡}}"níÙ!ãÕÝþ9Òó·S ÝÒsoæºuµ2L~Cúçß4K{Ê:<ðÉD¬?oJ/ê¬?UsxC+(¬tW¸XDBËjRß<ÅQ®R@:ÒÇÍÊ6bNýmÝ#:ÜäïÄ=êhÆñ/_µ|¤Õ#ïRîyY©­y$WÕÅgî9¯¸¼=$²æ×ÊGö4ñÿ<%pr¯Ä[é±C(ÎîrlzøüvÒÄÕpÈÊ8¿sù
ò	©oÎEYìjauufª5nÒðÇ&dÙ²2Ñ;e¹1úGÝ÷sf/Ðd7
[}1éæ#^18»A'µ«èÅçÒÏ¡Ë`¼è^?,8J4þÏê Üëç~÷ô¹TºY^>9KQÈ¼Û§=ØhMÓxÄ'¹bÀ¤uâuYÛf=£­¥	Ø÷£þ9npÏ#D:ÂíRØ¦>í:´l7¹ÐiW¹úBYDÙ4R çKdø~$¤Y]jÓ¦¿uÌ¸«æªAç öñôoÜ²<èéÀsÖ»)íÆ½Ç/ÉGvKË½¾«Í1GÊËk;#Zu½RÂ@F,¤\¼Fñîè!ó÷aß¯
4ò´fZóû±ïDæ/²ÖvÝíÌË¿¥µ´j:(ÑhËì+¬	fû!'M|09ý=¿g8 Atãá½¤5g&IÓb
'bMÂYÌÊÞtÎ(²JkqÌå©zþÐt¡,Îb±=8rÚªQ°ùÍ HÓ;æþÙºK¯Ý	ïâÐ­L¼8ùçOKÜ©"¤*ÒTjyÒ(æ ²ù²$:
ÄÆ-Mä%MÿÉ
zÂÛ £Ê­^ìbVUðÝ(w­ÚÞëoâ±5ÄÛ£®:ßV¨ÕjQÝ¨DtÕá+¯@á]
]Òw&¡Ï}9¤»Ø"ûm¶¡Ù\ÅtÑ<ïFw=Þ
#JHÐ]P5bÑ*Êk¨?²ñ¬DBÕ]\lï^!*ÛíFXÞ bF´UÑ´ËnÁ¤cé÷3UN.¦c@¡6Ø Rë¥»oÞÔ®ÖEräëÃ.¢)]êî³ø*òØ=C4tTu½WbÜ? ±	õù¥qP&©1wæ¹¥âG×ù!ù»è3ü¤<õKxÇ ý~¾¦\Úø°ýE
õª£=U!ObD"IE¾â
Æz@ÉT%é¨FTþÈ9}ìº!ø÷/£DPÜã@$+~×»¬¼ ö{æn(GYbð±Ï	óIÇ.¢­»ìÒq8Ë%ú7uË·×UÅj§L¼×ªY¸¬êE9¸x°ÌoÛ9spßrpOü¯
Gü¸=îl#­
¿8óñÉ
ÿ¯1@sÌÓ7óvV®0»´ïuÇÉíZ»"
Ù¢-ÇÃ|Fß½óé:gÑ¬Ñfraá°ÞmoQ0-Aü
oÈvb°ÏM¾kó©uhî~ö
Fr
o ^-Zÿ3F; ap²ôFTNb¢ÙÌ©Äý$!A¯ûÛ)­ÝÛÍè{^3
o~~A¾^ùºÝkS¿sÔU]´8Ø¥­°)¿yõew³&ß!4!tô¶Ì³V-,D@Çº>aerÍdr+ÏÙ²rÕ_í´
+%DðÜa{ÀJZÿf5£ëOQ¾Ág£´D#KR[éaÄÓP¿ú-k~ÿöÈÍòíi!UDÍ¾|þûMO&ßP¾­mË9Mñ®ê(wQ¸&~ÛËüúrzØ·ø »ðº§ìþ^yj¿ÁÎ>q/±aÞ² /ùIÝM«;ø=Âñ¿'Þdbfyú@Î}÷Ñ·exIùÅ<Þ}0ú'ø`äSÁÇ	¡¸QÜ<ìºF®*ÔÆ'Ûîª¹ë©ÿLí½¢îÏrÐÇßuÂÉ¯KÚääØ,iü/ì¿/¯ÛEÌw´aMaÞÃ'¿ù{·<«åQBèTÇýòÌÃ¾.¶B²·?MÛÈ3ÑçßÀwÇ3ûNNTÌºZÓ¹SúN(Aöc:ë¨T²ízE4xâwÓ-shc.Çc-)ß Ç<¦rïz¶÷4yêJÅá6Ñcò­%äõ¹ØÙ¼Ã+Z=$7f¨5Ns.X$DFW\ÑRÁógËB$øF}¦qk5ÚèÊ64ëÉ@V$PÌaoú ®ü Àåþ;5dÛ·:"4Û>D/ì,Þþàwmd­ô_Ýâ»²¡«ÄwÛZqªoQTó«Þ	æDhÀu;"¶ zTÀ2ïüìÓ6«¡P»Í÷²bÒO;,\ÇÀA#ÿÎmfZf85}m¶ÀÀ¨EªÉÃö ç¿Arû®¯'%NÌ?ìyÐÒ¹\ÉwÁîÈNu~töì×iÒ¼bñ11Æ=SÌ
S»2wö]º ,µç­7á¹÷ge®Syät¾2j½gU¬NæÁ5q÷Ùï-Ód^å´1ÙÌbgþª?õ¹´KQïO²º~ÖÙ:@Üâöî8ºx-Ä/Wxgù¥Ê)^5©>îÑèfÆI¼XWÅÁª
2²4Ç²²ð*aeÙSå7Z½[fhÿS¼éñüqv#¸îWpÑ%"e·4BF&Ûc3+ªë!u¬Ã/
z%@	ãº9`ÔÇr¦·Ý $*ÿ,4Þß-~êkàÊ'[Î]gÒGQÉ6Ç=|¤ÇôBÖXÍÅr~»Å¦­SrëËsð9íQÒxòEÃRËÀT×!ü"ðDü¼!E´$Y:+*Ö+	¢²¦3·h*;ÿÝ+ÁWà6bëçZêðÿ?¤7s{Us®×P5ªÎ&]]ì}*_pïAL2ïÆÐ86ó©ú·¦ýPLÅ/ëGc`u<ZFü¬s¤9ø?Yè%Q ðYÎ&¦¢PP¹²Þ	ø©ÃáF³±n Ñ.ömô@ú^¹íRºÚ#ë»¶=®ò%wìdlVá´%\mDUJËý-C·©= îÕÐXbé47J¿A\ÈæTVéDà	ÿQCøHªÐ?å±åè^'" µRP6ìÑ§pæÍ ÜcîjskÂPÉ`¢P÷ÜÌé¶P*ÕÔµ¿Z¯7Ò0Ûì¥f-NÎ´ºóÁðä.zÍN;´âçGã¥Ó¥,¹*ÙlGìÖ_þê8Yêl_ÛQßñíÚ1®Ò¤`¨Î»Ä+æÝêÐÁô|"G{¦ôsi¢Ù´y4úg»°Q¹Òás[Zp²ÁÛ ËVuäg÷Ö¸3ºûÛD.Þ!,7 ÄûÔc)í#¦lx¥ülÈ½Ùük¬ArÄý7÷rþµð»ÕU®ÐØNZ2qv©Ñq[Ã)ÌaÆÀÌL%h_X'<NÙðÀ7eVb~ùrÓµ`Â1W]cæ×YQü
J°nIÏsâx
  ¥FJ=ÐjUjÛ1÷G[oÚ-<Ê±ÐuF3Ã{ÇþÚäÎcó;±ý>«Ð M+­1¡VVLÆO*¿ÖÅÓWçº	/21ï9ì£(¼Ä{t0cúÀk#A_Íúo³Á·ëD&kâ^­xPð*é½éÄßØ,M"ÝUÁ$ÆTöY3BâÔÈ{òýÞ8f¦»Ýý-Prµ®»6;È L²Ü©æ¸v'­Ê8JBLMÃ×zø·XÓ|0	¾À2QrX Uç°nmÏ´à\± Î±ÍîÐÉ9/]ó§ßK~ i;ñc`Þéñ M6çÐ@¢x¼ã÷ºäæòQ¡bÅÛò¢1,ÑU2¯üYËÖn1W!æF³FB«ÙqÊ]Çå TrrÖ¥BÄÖÜ
w]»© ­Òû
Ç*Õ¹¬Ã©HXæï¯éã ­¨¸$ïHÚx§uk.ÔætóI½M¬öxEáEUåuBH
Þ/%úáÇl$§
Iâ2ávÂIûØÂöÊ5hû!É·¸Ú¬æX;¡-r*·~¢Q¡cºíj%*Qç[ö7H vódiþÉbO8@8.fB@6Aá6Íyj^±®ÖwÕ¥ê«Ö'ÔÞÞ÷X ³R ¾­6ÍõuH5¡þ¡K×U|Ób9Ç×(-E¾
¤ÂÐ¹Oì`þoô¤ßÛ+ö5Î½
}.ö0y^%¦¢åÙ~ZsÔìo
Y:øV$_7ùµBlrÕ1f¼O'³¸uÀlÐëlYR±ç¤ÊÒ6F¬Wfã,
äùÝÃÈ#¿p¾BVD1ÑdCybJu2VW®ÙÔxÛ*ÖH}^ PN@¾¶Ô¤ ®¿wÛ'(ú_:TrÑC¾cÅï¢ô¤t a¨> d37[Ù?L½873jÛ ¾Ò#ò¸.s»Ø]=OØ;"¨½¯á©}løwUèM´òm¤ß ±±Îæødr!ulJ-z,/P»y¨º>ö¥k@öÇ¿¥=Ëó.ü³Ü4`
u?W*`píÑuYSA4Zú bÙLÂFµ©T±EP­h,ICceð%ïAÏ>å"ÇÇ
ÍUqÊ¨2ÒùÈåã~ç¤gE<ò¿¨1Fÿ8pî­ÛeXföÐrb`ÛD-u<Q`«q  ph|ìÅ«.3âZß9E×¡*64

³msÛpL:bEÎÁ
OÉãnI7×w\÷¾jT¿Íâ_ÁMÂ?fTYGúÐâÁVDErÅLÚ?Æ)áºT¡/G¼i°>QÓÎ@ôýÚ  	nfÐéL¸ñÍýC¥øTâß¦Ìõþ·ü^qRâÐÉà»¶dÆ³¹Äö
êë­ØZ?ïÏ¥Ú2f>ÏãÎì¸­¤£ÐU5"²ÍÓÙqË«ïÒ¡ëìtÜ©úã« u3à×lÒ03iËò ]«Ò6³JÚ+!{V­XÎ~²{ní¡ÎT³ò²æ	r
Zz_P¹3úÈy`=sQ~@XÔUÂ"m6çNl1./ï6X6%ÝsQXýúØLÉ æ21¨Ï3ër¶§:OUè%Þ¥ t~ßÊËpsÝ*HöL:²<Hz±o#¥}wsZõRlÐOÅ¶¸/Æ
ÈýU  ù\²$7"ä?g°Ö"÷EÙ÷ä£ÁHÐÛí\Çñíã8=ig¬êAéðÌßëiê~>açÍßÙ_Âï@IB:5îk7eàÜQ#Ç%õ3¦j`gBì>@9A'ReÚpò[3eS;éËÉ´ûÈ0½Yhuù,reÈÔÑÈ+3KIÁ¢72­TÐÙsç8®Aõ×ï6ö-ào
y'~õypZHÞPs^DÐÂ¿ç,4*%ÎË$»ä'OÛh2£sËD¨üf¼6à£qzgµ^ÜK))ÝØé¦¨ñ;3HÍúÔÊÏzÁ%¿útõÏCÝ7áU1ÕÜ¸¶COágCÛ°5"ks8¼¶aâV§e"7ëïåü¡E®¨ÐébBHËbØ¬Ú¬Ò~ííFÕ¶RAF·5Yóäl3öÓïäx,ñx­üKÑú´üoßG£^v[ûJÒ?FlRô5-ZÏö½ÀûR¬úûbR2 ³{¬éuôè¨¶'`/ÐÌJUå½¹1ê\»¨wS <ÚtýLlÄÌü G-nN¸$·ÆræÕ©v`·õØQ¨ý¢
ÜhW¹åäaA1zG?DFü0+é§÷çØÛij:ºbÁÁtÈi£%ÓBÿ#m0={ÅÙ)üýuhÀ!Û/D¶Ø^zt_àtéeë´XH
¶ôÙ¼C0_¨{|Ïç	Ï3¼Õu"|ßÝ&áï`,³@6Z¤YQ[Nî	ÖÔ¤övÐIÖÊÙÆX"yP¤Z^ï×Ijå9»²éÆ|Á\Ñ°ëTs³ó¬i äß¿{ïÏ²óTXÜQ¡fJ![~?§¦\IW¸ç//q«ÌXûÓÛúÇº,V*ÑG®¥ùR?IÞ|æÌÁ¡[}núÞ±Ø,ñ®ç3ÂÂ/µþºèJNÚ©'V¶g¤L?È.uÕL	¨TuÍÇÔÝ4±¶X4¬^
ÅµØ¹;÷ZÞ«¼e¶Rc?±°0=×ì}v%¼Ymô ·t¢ÔU²(K:Ù eVôÃ99[o¹9úÎ&½0¾EÌÄç"ÆÔg!yÒ­]UÓ#·GuÐs?·b¹õÍºïÇß¼ð}ªê-²¦1T¢¿OttÙhDòõñöÕ
p!X{nÀ	½F E
ð+³r
KV 
ÏóS6|­ð¶ôÞ¦Ð$Æ'µ@ØÌ!¯íÛN$ÉÉ Ú7ßMè
ä	ò»Êa=®NlY¾Ç¤¶æ+Qhs@ÀÀ0V¨OCmådnù5
þS¹ý#³S
X#g:4¯.t;ë:æÈü+þ	ü§ßÒ/»¢».|ô/vÈùÀ\RXJ<lßlMjNÞG¼6tá!ÔùúÕGmpèµØI[¥y°®ýzâðj!&ÕiôT¬ëÓFÂ~%Æ\ >|MSêKHù:¬3xò°Hfªå*1dO,ÚYvj¡Ûþ³_\7+ùC¡NGÕ c
hPR°-N?°b¬7d½ÇfªÐë ýXÏ¸SâHÚ_	_q©¹ÉS3óûþ­23Zé8£f»%äñ|jÜ+¯8Yºò«^¼¦ønwü'¾Ù©UòÂ¸«ÙVW2lNÆOØîSµêÑìu¯(9³ñKâfÁÃ«±C´L²à võV¿>ØÆaf=ÑÍBQùó»¡à
ÈÀ7È¤s£	KõÍ'Û6J³É0#÷ØpW¥ü^ftä!ÛÅêªÔ¹K{¢èÙûhK')r®l¦Éëo ±úr"ÈÜñÖùjëxc§~S¸Åi¿©aÁ
âÄÜHiº;[´Yr¤Áb´o>¾¦L1Î5<²KEÀ¿#ÁÝW;Ðãs8´c3VXÊAù¼VC~þÿ¥ä%QVÍæ-)°9mö9êCõéÖò±/Ò»¾íýZu¦¼:}¼½6Å§<×sQ÷«Ýö®«ÆÔUK]¦·}p`»m»ÁfÚ/ÇU<þ|¾VÃåíGúnhµéHxÓÓT÷=ãz«²}·S¸^¨@Ùío=®MÌONáýTçyÜàòu-ºÌ*I¤¼JcM¨ÌÚÁ`ëºs}&
_¯"­'â+YÆª7¾¥&×Ã
,l 5bÙíµ¸nTb¨#ÒVæØ{ßjEp¿}â-"?K[Lîÿ¸@ìFr|2eg£(.M3PJA¿©}
¸ÇÑjXOÐÊ´!wþâAÆÔi÷âg{FéÄ4ùôÂt:ªÒ}>Qà÷v&ÍR<Q"÷<¾LþI\lÌqÍÚU¬{ø0'¹M-<Ìªfr0ªNß0Çsirð®¬8,»þóGWGêakÜJ3Y¥|ïLÂÑ+ÛÞã\MIÂ§7©Ïð{	cNZÊí ë ¿¯ï5{Æ§ÇÌo(<~^&á/Å5Cf¿
7ÏH´"_ÍX!\ÐØ[C^P7º
Ú(IÂ½8&à(p¾ö@+eòqÔhg¶KQo$|}ÅaiãjSuAPòàfÍì_«®=×Üº4U)nyÖ
Ôqa{Î	3¥)Mn×OÃ^®½ÊaÄ²NÛ­kiaÁæ9 \PY©	¯`IÃÃî0]ê+¿N=[¹ÿá¾;²>vX´ÿªqÄ:õ'ÚBOÖ¿E"üÐ@Áÿ<YÀ>h"ßMþ÷Y&
oï
¶­Ö|&
/*§>¦Iº2¨ígÖ×{«ËÒD/W»kl,n	;lJRæcÓ]*Ë.ÅY2Ø ÂiÔl3ÿàyPÅX¢ø¥ÈÙÍ~Ù³ÿÔk¤HXA!ÆÝ5`eyóÁ1tÉÛY#(¤7Í,6p¶í)uh;%	ñÄÓLÊ¢¡L§i-æÍ G_K.qÄLfN-¿ÝP¶)·£æÓÒñ*³+0¥×ì\@:$0Py2Ì¼F±þ#xv ^bó®¨²6×
Y#ÚÁ¡70VU Ú®F·ñcÆ*Ú¸­z×]!ÊÜÒÊù³¡Ý@Õ,Då,~=çF0ÿø/ÚuW±õ9$<ÆØ:¢s®^CæÞ#&Ê«2íNïÛzú'ÖÖ)³Ú"Ã¥@S>háµðÏ}ªÎHãfîñ¿k#f:¯#.Áxk[Ô2(ßîâÒÑ	08­#Y_1|ÂñâLüÐsÃÚÜ&ª¸N-/å×Vk«Äßûn
Q[b¤ b¦ÿ= ©'Ù£ÅÝë6;Ô(_l]\ºÈ,?eÿPcajà³`L°ÖUûÁWjêsÝP6óô×*ÄõrÉÅrÁ<NT&5¹ªö¥}iÞ+8ÀUb¤Á_ËãÅ´vè©uy
¥-7_YaÄ.`©ØsÛÚæYW05fWfPgÂÌp'¶GAðÈóµ¶Î:°ïÃ¢KùC«XëæðØfÁ=Í*ë`­pùÊÕ	¼Âç Siyc8Ø;½ÃMÔP¤åa© ³Ðÿ< -¯Û¹°Ys
ÇÝþÅø­A¿){,f,Ü¬¿³ã0<W4Ü/¦§L7×¾°n©ä@îJRé(Ç=o+¾ÃÜ3Cû»e}Ç~Ð­ê`dÌIzÕSMLæIúW^3§zz;±·aU
³.ÄÃbö+¸òËÉ-JxÒB·i´|ÄH`b¥é<ÎW3T¢³úÜÐ>øÄdbdÐíç0Wû3³& klJ«%IëS@WKEÁëj%xÈölJxCôH:A`ßï=Ö­MzÄÑÉÍÁiÀE1´BN[O5íoe)+Éïk,½®d ]ø¡ÆÛºÒÑàÝ$t¯Yd¢Y]¹ÉfÞùAºIGòsýk|#mê¿ *v:?»É=tW·èWPW×wîä&¸èY¸Ý]^³&M¾XêÃ¶ÚZUPb1ÂZºé9ÂqòÎ>{0
çTù¾3ÑÊ/°âIVÛÔ(cØTÃym
3È ,N³ÊÝ	Þ¼<©PnVÍ'5¿ôtù7v;ÿué_¾E5¨âûÉÄ¬«þçCp \?Úð¦D
Rêßí!´ég^§Ñg&@øéZHÐ3"¸Å£=¤2-ce,O¸Ä¢V®Øe¸+ç0.ÏdéÄ°sùqàE ¿.Ú1s¼wÎ¼ü-@!?s½cî/N ÝmùçPÇy
Ç\Ç¸Üò¨gº51ÁØÖ±U¦'#æs¥'$bµ[,N¯U>!%m°]O&}(ìà|2ç93eëÚjIíÓzëúþ9ÆÄ`%27`êZ §·@hd¾âr~ó_	¦¸*½ÈcwË\j
	åï3= ³?¦D7nÊF¿õ}Î[¾.`ËóÖxbñïèÎYÊ*Â+¨|hîÕ°Øjf=è\XXÐcÚ ¯JÁùÒéô{Î¨ßRZw¯¯° Â±qJ*ÜZr*s>àÉ&íB¢c[¦ÍJä ^*g¼IÛ²È¾Å¢lÅ>Ï|ëÂ-¿ÄwØÍw?ü_Wù{cZéP×åHF¹
3Qñ'ÈÉ0høë3¢¬¡[ÃõìÖ¤{¤³ÐñO5Ó;4 ³ñX»oTlV;¬¯Êü§!ðýìõW£÷ p\'MÏµÍËk²×Cân¼<êà)Ð,jú<j®%r+ËiúLGÞ¸BqÉ_]òºª}KÍ5µÿÅãÚ{¿lðí-Ôy `}ÄCÓïÆzI+7Tú¼Án|²/°^`saá8®m!Óy6   5Û*¼s ´ªÒâð¸"YÔf8x¿)¶­è£Ì½'×UBu<ry>bÀÑ]ò}©gÍf7¿Dp+v[ý¤I~º¦ÛW£G=±YÐ
âÖ×£<GR¥És­És½ìÃ>PÏaëýî#ò#|NÈª!_n%:µÐõ§Ü;ã:¯{ÌY´§ÊSâÊ.ëRµs-¡ééQR_ß¶AS8ÕQ¡ |6@ÝbJçE¾²h?CÇØßÓàÀgQ	&+¬úÁs~°æj_¯ÜK[×¶LÈìgxÓ²¹lß®ô|l*àJ
wMN¢?
sÿâvr]|_ëlÅÎp75I©}ÁªÖÒ@`.ÿè/^Jµ>ôÑ
©Ùb]8²ç hLY3ý®º«É×æEiÎþ4PbOàèIù}¸ñú£bjEÝ3Ã=AÀ;á~K}FpÞïÐA1#
Omï^6©Eso× t¬P²ü³&	¬Ù\c]´YÔ£è-»Ð¶ºIÙÙÔ¹B?BeÈ´Y;Mc¾üYv/mhy3_M(=¾²:¶â$#ÿ4BåPbAEL\qëóüLpWóuûO"ÕG<©;I­z>"?,ÞÌ[~^SËIcíÒÙÓBJMÎ%9DlÌñ¶ÄöwA'	qåÇ¬Ã;¼È4WFîöá×.í÷­Ìòp
3/v»TùsbÈªËEÝ¼z³é~ÒÁJöÍ*|ÙêV2'DÒ(RìÞÊªMó×nÆJ­¸+ø·Â
Õ
*JSN±.Õzõ!oYuÏËÐ¢:æÅÛ®l 8öÉLNËQuÈº3×ºBóhÿå:9AgùcÚ|ýQCè³"ä,-WZ-]ûI|ïEûQcíhYY2°AÕþè¯¦ð,Î`ÉÅE e®c.1Ç¿h*òPx6é±)ãIÆ7ýS³¢æÍÚô¼ÇP§ï´Déõþ
f¿]VN0¦Îî½¿%«ÀÚÞ~~×?mÇ2<ÜL£j|C:¿/é
´¦üòoö
àÕçOÿño}âòçv¹3jõ¬"RI«VN¯¸èÔÀÚ1³ !¿«Âj»ÄÂ@UÙ¦(=|2mõäDy¬E(°öt·ÍöåvÒÛÀOO JÇn°í¸º]Î«sZj	WðJÊJ·
endstream
endobj
398 0 obj
<<
/Length1 1644
/Length2 8638
/Length3 0
/Length 9488      
/Filter /FlateDecode
>>
stream
xÚ­veXÛ5$	Á¤	îÜÝ%¸[C7ÐX#{ xpw»»»[p
µQò*0©Í ÏvNt**q0ÚJ a`> >| °ñòò¢SÄ¡vnsVCUñ?W &nÿ<{:BÌmÔÏÎ`k¨
PmÁt 3¨ÀúïÀjü)ÍùKÔ 8ÚM!Ïn`WS°Ý`v°8:>  s -ì¹0( bkjíúÀ³ÝúWBvÐç6ÏØ32Ôæhê ±£*KHý'ÌûÛò fÏ7APS§?%ý=Ó<£0 ÄÖ »ÂþÄ2@G;k Ûsìg2;È_i89BlÍÿ#Àlt Yi¹ÿtçuþKõ@;;k·¿¼¡ÝúG#ØÚíÃsLSØsls-:ËYµ5ØXÿ¶ìþs;üÕ Ú?3C÷µµvÀfè,JPØsH íÿNeæÈÿÿ-ÿ[äý¿û¯ýGü}ÏÿJ-ådm­´y¿wàyÉ mÏ{  ø³h¬ÿÍh±vû¼þõ¶øïtÿ2Yð¹-¢¶æÏÒ0ñ2sð°òþ
úÇá¡ÔàÁÄÆÅ`úÀÃöüSãýÀáõÿ	þÛ?Ï@Ä ÇÊÌÊÊöLúçõOì ÿB#ik
ý$5Ðô<{ÿ0üM%ÿk<×ÿç¿^ì
6E_òX&¥&Ã*	2ûG%ôº;Ùû?ÛÔ¨ç~õ-vø$¯ó?T|f®ç{lrÝ·û½%G¿=ØoMÓ >Î&ñ¢ ëú³JÝÂÍ°ýÅ°àUòV¸ÇÉÂw$].VÍí£*ªù/HÇ[ØPO®é|)¿ú¾¡¼²Ãô6M¬ÄkÅ®{]³@ûóú¦wh ¿¯ã¹k!#Hà¿Os3v¸¨1}D¾sæv,MkÐ*ÇÕpq'¾szGy±Ë|ÄNfþ$
¿É*2g)ïrø2âCnã»añ	u9ÃªÖ9Ù®¥Ãj!¾$«ÔÞÈËÚ°9é$\ÎµGMZÞTÝÀh&+v²fà7GÕ[a*I!Ì0Jß¡â¸"y_[`^d¨ípeêI=UéÊLýD¦/l;.¡ö¬"":ôáW(wªEÂoVkñÅÇ,K¿õ/"£'ÕE´áT¸ÈoR±ßáÈ¬ÚÔ¾ãÍ¤:÷<7lèÐkkOäüôjZØxb·»V>ÿª[M¿Lû\¡<PR7G¼îÁoÌ¾ÚZF½°úë%ÄiÍb	©¡\qü¤©«ü
ée6Ø6~F]«5±¯]ýíÞ°]~UfSÔó^hcK`åjÝ½ÇEeÀT	26TD^ ²¼+®b>2eÝJlsØ²;ÙºBð9~ºE.uY2 	ªä±Y~ÌteKÚ
!Ã)dì)|Ö?'nÜØ	:Û(Ê\ÔQj¢ÇNéL2ÓçaÆ/f²íáçîØ(W´}ÖÐ¦Ì÷NÖd»ýW%~³WÊçîùÕìN_w¦kê^²>Døµ!*k¥"?õ#<ß¼/yµËñáÄóÖ
¤1ó¢Ö©±/ÜÔ+£é	ÝÇéJ-¿ç¦yA9ÇJbË>h°qsñýµÒü[ä.òÎEú µt¸Ómyeß«Z!a(ÄqèíBûd%'§ul÷"0Á°YêÏÍázyAù:}NÃBÆ< !êgåÎÏûòâ¼QÄ®®ú[äNïõnPÂ¾#m²*}Q|;¼&ÍáhþÅÒÌ°¹òL~j£.zeÆ4èáKátþÏòí-¼¥ü?¯;ÐÀà»zìöXââ±®9¡ U¥Xû	U÷è}ÏgãÑxjY1hÔ}%q?çDEÓ&fÍí{bÁ1,Ùè·è¸¿WI÷~ds¡LåÝ¾É4LO÷Bn[PDyi'Ô<&Gîéy©ÎVôîLg	Px²=ì^Ìæßl3_¯Ò¡z^Ç.:Øò(Léva$S®á1±Içó×4_³÷l'ÈKÙÈûÐ=g×.à>ÐÑk1(q
°Ë2 Í[éù÷E²Ð4¼ÈqÉiUïºôÅò1¾@êw@%;¾S×Ú©I¤^¢98æàCo¶¬ãÉO)7°¯¼aX¼]ò§Iw9¢ÿ2ÄNyáI5äÙ!h²îs)¸¦P/¶÷¸D)­BdçÈÛÒø
ÆààcWôçj*m ²ñUéwCÀ7È_C#8)FCÚ,M-eq¾[iÐÊXÉä.ì`Ú¥öLAU}Ë\06¹ô­.ÇDo¸f¢]ÅúÎbSÑû¸³åàM'Ü	ýõ»V\¦vÍÚó·?äIKÆrÃÕá¿Ô`¾¯<æ4uG¸(aÊS<Ñ76L\Ñ~WD¥»¨ÚÚAòSOA­WPf8ÖÞÃ³bõ°(àæWT«14B«1;©ô½Ñº¤Ý4ó}¦ðu'¤?åµüÌð·fQ43SoT6%cïõ`}£¿y©ãXA7¿ø]~^¼Ri½>¡rßï§"üp×¸Nå¦gl ¿·´¢4Ò¬¤vCÌ%Þ_tñ1º_©B,ê¤¡4À-Ú¡[Ý¿Û:ÑB§æ©òúLîªst+ïyT^M~OYnm(ô*¾!=
÷ØOîJÏ°ò+[Ä3ò¨Ò,tÌ8[E105}Miå®"¢²ÓíØW)LNpG4a½cªÕ%ïÖ4\ÁüºBæñF²¾ÝÉ[øXÂÍìíD1QQ2<lÖ,®^q3Y»Ï²íkÎùµt}Aã:y<Û{Û)³t¬Ç¸W³¸?ÒÅrî-~;Gf°2ìßDyã^N;Q3_õÕ¿\ ¥±3´jváTÛI·Øv
ÉåÎ¸~×àWÉINsÅ1¾é.ug~!Í=<òûÔ{¦îêô±£*qôÆ`«Ih$
Þát1aó*à'ÃãO}±Âðâ7ý£|bFÞM@CïQLùoA;eÉt,a¾Õ-yE²¶|s[O±1B\4.Ø¥J¿[¯¦õ¾¶Îzengoá¼¶ÀÄ§lbWdÿ¦Á)3Vï»À
õþ6cf-ðç·åGV¸¯KÔ´>lÔÊ
·áTUOÆ4'²ØUoÚ¡v¾âË¥N$à¢ßLÀ÷Ô|*É8ÌKñlÂ_¹5¾-×V+á°:^(ÚÄs²h÷ì9{	Ïx6òËµOå­=b&ngùDYÁ¥c²áùy'Ìry×2e°õãÂl-ETM³¤æi-áov")Ò»üø+}òühg_«ýd)Ú;á¶½õÚª){ßóÎÏ_9Õ?sÓéteD¡dô{Ö¯eµ¹6!{ù,_OeógJ4¢Æ^tU¹møØõEÃEßÒUåYô³{åxóý5cÀÁB½RÞéÔÆp¸~3¬îÐ.$×æsê<BVKÕÂòUsnÁAëáÕÔÎ¤1L¦Ê%Ý  uÓÌhEàEDÄ·pýÓnltõXk¥/¹Ã¸¨ëtÅÎ(¬<ö,ú{±äèüãXO¿´&_¬sæ~¬)hh*vÖ|zÚKÀÐ{Ï#K4ì"3ü~Q
[Zû[ÈÀDèÜçìÐYôr³W´ÃÒ"ü;fÖºç'ë\tÄêQÐ&&íøûÃÂ¬P¥ø<Ü.¸®Â
5úÀYLÌ¼fmï4¢OáD"¨­:u6×ôb¼ßTÙâ«ÙÜ¯>>¥6 J?À4o\ÙGµM<mæÚíû­¯å,&xúL¬çGÌYp_èpÔ&¯wµM§¼5(o¥89yÈMYÀ²ß­d&ýÎôÓãÁå­ÇàVR®h
ä|×Z´QÍxÖafë^eNË
²hß©tñ?ª9*ûÛ~²BÅû.ôÛÕ»!ÅÊ¨·?TQÀ{+çdÃ§kíÐðx¥
`enTÁ!ªçÍÎ]ºç÷sÅì·r ±,.æä1ÁÍ4·o±øð=Z?Ã,~{\_h }÷Ðk×Ç;$évzyN«-æ§ùò¶fCêøÝ[dD^3Ø³§É¶©õæy¾øJýx¾ÀQêY*Î8J»ï~å\ÝsÍ^ÙÔ	¥¼ÉQJt8$r^0G¬8±E¾mï¥µ3þíèZ¦W M]=ÓÇ®R
0
C-.Þ/º«HoDLZc2õ5¥õÐÄ.çòRÈiÔ8½òôúàÉË*o["Ó%_Ú=º=ïwCë´Óá²ðØ+.nýúÛ/¢ÝòCkYý;`¬D¾ìqï®»6¥í\ë\añ_)ÐÚ{!h(CÀ0kì¾ÉmT«W7k¬Gd¯Jërm2yXøù|É{-Óù5:ìÔ(jà7Xve(ºÖ¡ðòzgÖ`×Øvcïæ=J3ÚVÛ þÇj§W>³eÝ?=ñ|INiUe7õéåz5\©:].OÊeBDÃDúZ¥hû÷ØjH¡Õôz¨C*Ýê%ÇCï}(¢dxæ9Þ)ë
.«ùMºãPäe8æ¬ýRïÛË+¹£Ç©ÐVËN7öTñ@Içá*[È$Q¹
AWqGtÜÝ'K¥}¡Y1M½6u!$z28RÇ;4øð«ÌØ·)
¼
Q¹±xÁ®¶ïA´'_Ù«@~8üµOT
[[Ñ§J4tj9÷¥DËà6Ùê¤e§ævJ¸Þ÷UÚDû},b)ÏXR|?Ex0GLöÒ'6L«_êûbán,V5pÇÒó û¼aóÖ+;5¥NåR®òÚáëk!íÛ;j¨óèÇ*èmÇ¥q\8ù=XoTA<n`¡NøG-7bTÓtµIíµä
RNK°Uõ}®=ôBdy| ï¾¸µMyÄ±eúë|;ú­v²BÎü¥[Yá«øqÇäéÝÈmÊeîÛoþðhDMÍ?³Lµ=yòÉ¼ÔòÞ±t±~ÏÄ®Vh3»\Eh¬w¨À%ìNsx@è-aeû
]3^$éñYÚ§HPRDâ@¶æù'º9«RIAå´_-ÞcïÞ.Ï&qjSgøe¢\ºx
Ky®Q-ÊJRj+u°.ª!Daü"éÝßBïçvýÔ3ð
®ç´\Ý	cwÓk]ãn¤yÉKÖF0å ÍðÀGü9Ñë{óÍÄÇ·Z@ù¬½Ï>|0¯NÒfw0ú¿r	ZÞÙ^Èæ¥Ã·ú¼u,YN$q¯è½ OAûÑÀÉïó	'(>¡«§f^CÐSðå;ò¹7&Raû{i@ÎúÝÅôµý)ðg"by°ëºrÏa·gd$Ìe¢õ»áô\ônï1#cKÿ¼?©*¨´ßz¾¶&SEÈ{ª»ñJòÑº?// @û´Ð8ÿð".Á32%y¾ox=é¾{/|vJ"q¡Ú£¯¹³á®éýÆßÝ)UÊö1mRDûè».Ü¼%ù;bðFy¯Aù;PÝ¯|-	Ä]%¥4½q?ÊÕH÷ØÎ«¾ÎÔH-wæ®>/Êº|g·RãðÓ¸çU2âgø¨Á|âoU¿Ó¼6ð£¶7ÃW`
vÄD
ýåe
endstream
endobj
400 0 obj
<<
/Length1 1647
/Length2 13165
/Length3 0
/Length 14024     
/Filter /FlateDecode
>>
stream
xÚ­weT]Ý-®;@p÷àî®AÎÁ»»www·ànÁÝßwûöíqßë?ýúÇ9c¯«fU­Y«ÆÞTdJªÂ@;c- `acìì¤bg£`Ç#Ç 2sYÞ1$**QGØÂÎVÌâh 1	ÀÂÃÃDµ³ww´03hÕU4?ÑÓþå¯- c÷"ïNf¶ ê÷µ½
và÷ ÚÿÊÿ{"ÿ/Hü¿"ðÿ¼ÿâþ»FÿåÿÿÞç§p¶¶V0²yoÌÀû 1²¼Ïà¯acmäøkàXü_®F6Öîÿó¿ïÖý#ëÿàüwø!mÍÞb`á`äøÙÂIÂÂ
­Ê*q:²ê­³rãV\næ"x|0wº+´ªV¶§î­8MìÁS\ÞÈ/×©B/ù!µ	6të@*ØìÇCòÛGJUS&Á£Õ<æÂ2ËåKçZs.)ïI¬NÌ\ÌÙoýÒå^CLwM,ybÆW]û¢x%Y+ÓAPâ³øé¾<%*_ïÂhFEWn!~ü	Ðõ¯¾+M,|fÄ=m4.«ÃÅ­ZUF+%ÒÉ'ãÇ*£x·"KµÌCÏYBcÿðÁÑmÂÃfÿ¤í9Aü½ ö"ÈGX×eâm*­pÈ¯©»æ iµ" UYBþ'y©õ­I·÷J&/ý?§A0DÈ¡î,ÄýÏëÈ0µ¢ðI!±þÊno×öD¾î?0Üå]Qx æiGKû'Ï¦0TµµÂã¨@ey=îµ?¨ä¸Ã[d¼.¬Qsh"rIéwm*ê«E»ÜH°	ä)c»òæy#îrôÚyxK«H,.,  _µñCmê²XîÎ»*Ur8\PßVRLHÏëûZ3V{ã!Ål¾ä"Â~f»×¿ÍªkYQÕñã£ä¸/st>¢O]ï]©¶·ú:PáÑ =@v}µ²è£p$óÞ¸f	"5lA=ê¬A 8YJÏ<ÖQ6@÷|ZÄé¯oÞJs%È·åÅPÂ!ý^´>ôC«6gÀ4TcOïK8g,:'ÔõîsN 9µE5N=ï3±^	âíËk+Ô©eÂ®ÝZyt½Fv¡%	Yób 8Q d±Ù#á·?cð5Uö³1¨+¢Vj8¹¤Ì£÷Ýb°ÁÚYà¾9ýÒRÇVÁó2MÙxI
ÍÁâJsI^]P^Ýæ¦Âr ÿ²ÎÝ¾´Gìô¹ðïc?´6þPÂ -kýÅßèÁAk>póÝ
ËÝ~&s¬°â2²±N?ãôÄ´u3ÑVb­WJ&i­
Ý|¤u°Ê3=ÃidÛTìÌXK,Ñûè¶ªvP&}SMÐ¶XE}¢F/>;$ÂÓø	Ö#nÙ
6¦fÅw£5ÌNÊ8ü.³º¸ÍûÙÔ]¦?VÓXCXÀtÕÌ§ßtÖréÌwä!¼ <¾¿eþ8´· B$é2YØ¥%((x\¥ª2øÑæQ)fÃ­o£b2Éz_ÑÖã/#ûF³ïè§¶b°!f§ã8Éjã#¸dwvVÝ¡Å@Þ=ÿ0x1êPö{6]ÛøÔÜÓÉû&ì¶Íò#Ò<qÅ«yçuY@]ÆðQn+*{×ôvbmÞ*í4Kµµ/ñÚ©â¾Ã<õö$å²DÚnÑ\ÔÑ×Éä'wÿñ9fDùý§ùåÄÍææ.ÆEÔoÿpKØf.ì¯3£@ã5ÒÜ6^9Ú¹õäz"ãOÜOðÙ¯=G¦`ß¦YØ"Þé&ÄÛ"LðÇ	Ù¥Î@tÑÕT,´éYÇ_*¸Õï°É½éiD«Ô¤²µ¾OktjZ¿y+Áë~fGlÆÆ;\ÛììÐfÄ,_ÐMá2Ê@è¡ÖbPUó¢¶ÿÒé`%¥ö}uO?Eæ¾Õð®ôû}`/4¤"2ÆÈ¯c}Bo+:Õàw~h¯þ^±0ûÑ¦6àPºHò²úx§¤<«~Mèw
É¢Êð7éñÔ®-åìz8BOÖåmSÑäB@h¢6}Ym`0O¤ãZ^,µ*xIpú°.M 9Mg¿tÚÍXD]$ÈI«Þÿy4O`_u¨ZÅ¼¼~I%cBâÐ(§çx\=Ýã|ú´ëSÏÞ¯¹\úòTêy¿?-
¦Û
üâ~kØ¿Nò!ÝÜRí£/H·wÝªj¿@­åÔOÅHð 'ÐGN3Òp­Û[­s}8ÛÄ}ç5GÞ½ ÎÒqÞ+`ÌRÝfÑN]É2Ì¤Z3~IöàH¿×Nd%FfCÆ
§ÿ
¾õùhKí	sU5ÎíÅÃ]c>veí<22óMíâã¯Oøã8^½{j}$w×Ïb%ð-Ý/´§ðð<KÚéÜ¿_-éºc°©JÍDárÌ{¡z;Ó^p Â,ðÓÏ<»êEQ3K²Cj­¦¿oaFR>òLÜgÅò
?
%4wËÐ­®u.T
 jºNà±W %(áZheY¾äÑó%*ìÐK	RF1^WsÚâO#R%ÎAo=bãéc·®È´dÓ¥ÐÝõÉµ½]ÔO><;'V*^>Ûê¸É[ÉQÊ'ü,ï¿UkFK,`²!C]ßDÛ	&×XZ½e¸Ís¼MÙJàvi^Ã¿¨ÌFëugÓÌZójc,=ÃDQúa;°ñaÙl.;Tôc¦2¬÷Ñ¡ }ü·ûì æØ]IâíAHËÈ¡ý
QØhµÍ<}<XÛ³LbÈIõþ&ÑDÙ6J?««ÈMtâ8¬çáÆuÇ?"ò°îY.î¤GâQåÐºÙ]ð kæÚvS×ÉðRÍ{â¿e!®ÉT5ì9»%W>PÃ7¶ÆÇñJªmw7ôèþN_óè¿ãÿ%4hJýÑ¡VWÂL×u!lÌìhO`*þ:z"¿æî­Eërl§®?äñµ¿g~K¾¸Ô}QRîqÀÍãGq#}ÑÓ'Írß=t\ª£þ
õO°vÚåÑµÌ¾Ü8ð<geÚÚÒ®T'bX#îq1Òè=¹î¿»Ë®DÊyÜ
cµ K¹¶»sÑ5©ð¡øìy¬lÒITÔ Jt >çÅaÀQPþáB¶S~Ø(2\jvòR^à*NL|î~(S¼[©%(¬Ä28¶¼ºJ²¥¡Ôu¢#ºíw¥ßaTòý80ëP-0«FÓ;øE6/n´eøÊf¸e@Ïh¸§ü=ÂY·º¡4	·s¨¶­D¡jZºòTcúö µ"¦ç,°!)'KÚbYGÚ]~:å~:dÀW0bv²ÌçøXÇü$ÝóòÆ50IaXÊ¡3]V75M´WÑì$è¢¢<wöóüÉ"íw,õÐ^
t½A«Yãxícª^éê¦ìyvãë÷9[Plñ¢[ÎñzµÌÚ7ýgêmôÍ±4Lø['Ö*Ô¶º<½ ìC×;ã s%²ØÏ­1¯l?^U:
fxIííWI¯ªÈ GüDnÞ9à$âÒáca£aA3Äs!üëdê³ÚßjÙC2±}mb	{mÈâbMÝÏ(É¨×üw´æT§^(R(<&æÃèÂ\VOí]§ê²ÇÚ^ô³yÑ¢Ô³CÕ'1À°+w)ör»Ø@qªê.tyXEªÃâáLQ½ºy
YIÚõ$_âCõ¢ì¬8b¿g'l÷p½­Â"Îº×ÊhA°A·Ñh·Ñ¹dÓ¯³ÆT­@ÝÏüZ¦x¦eH$LgMªËâ8
\·Þ{»ïþ°Áîò}òÖ¾xX¯^ÑéKÄ,Ê$VöÞÃg+1ä$WIU ÖtQüVzã£û¯¾­_¹R5[aâúg¥´}ØÖôFè"?b$·û/ëØT?*<µÂªæÎª5~Ì­©&>Öq[z¸Ý¡+ºÒiLµªR?k_J6·ºÍ%¥mr6ÅËçS!Ûµ´Ò¹ß_~øX,>ËÅ0IZz1ÕÎp
~ñ*ÂÀ¤á%äÂ6Xâù|Ø
ç®E!-]jæ½yü­«¾ò;©"ÌÊéÀC@ø»/
hî[ýlÆÝ.{|þaGÆÄ¯¶aÒUûv·ÞµÚ«U27-dü6¢wíylÛ@
B1s´½ýL\<eô6ºìíùáëäWìÁSUrrKxu¯Åö£¾ÌþÂÍØÜéÈu¹S¹ó¾üO·kXkÝ?ýZNªÖRèÉªË
Tg¿gí2ã×ù§%sÜ=¨¾^ÝPÐþ±=ò5Û¶o@xFöÂò>Ùú,d=ÁÆ'?ÏåJËs¦ÃË¶ÊWaÞ­{h!8ªËïçÎ})(ð&:í3p{Îä5ÀÙ8]5´Æ÷l==;¯\ÀÀ6¯>l>×YXÖ~Ð¯ÛÄÅÔei(80ö83ÅÚÃ¹ãRh$Hü«ã÷À³ï	@¤=Cù¡­:	}û§ch:£%ár§#l¼³ê©négþÜùtNÔz<TæAã¾9îæJ"@¯±ØýcÀ5ÜKyÓõ¦­²gé×«ñ¶·Áå½D
ä~v)>v¾¥à¢h<kÍç«´©Ö¯8 ¦SHøÏ35t4µ¾SV°>«w¯FQð\dRqìé\³uRëJ·=ê_Û#
Î@L9¤Á*×EÒbëf$aÑ¤SAàôÁkÓÊÂØµ7N-a°PÛe(rOräh¦øþÚÛ¸tGì@±\÷þ¨¼VÑ4CGYV+Ô§pÑ¦Å(¿íÄ»?8$¦e¾EÜÀ¸5(i° Ð'}ëØæRÅ
­CY¦[ÐX;´,1¡³¶¡OQ¨t1q-7yÃôsr¨"T!¯C+²ÇWá1Ú<w©å>\ÄÐßYÀÚSCc®êI;Næ|ÐTëÕ«TæâÑ;|l³¥Pý¥Ä×·& Ï3AâS LpÜ[äà¤ó¤9ÿ5kIøÛ87ÜuÝo!R§ÖÕ¾Ôõ5êÆ8½m?)QßTæõ*L!?2úJûuïKÄÒ<û`£ÝúZuúl3¶¶X2ÞÆ<{sã<¬³ÿ<S$ß=oºaÕObò¡L1Q/ttç¯B(XæýªB*#{hø;ó+hä!°
 ³>d%mq}&¥ÉÆF)ºÑÊH¾n~Çí°äÂlåÓY¾
Qõ²Äë	 Y¨I=ìã[ÉI
PÉ#çë½ÿ>ìn+­¥ÛÑ*S÷Â¡ì~ù¨÷Kõrç`kç}ý|Ëá*u©y¹|¦Í9íÁî2UÝ:vE(ºgh¯â8¾¿<}6Ìac÷d¶¸×TÁ·désnÀiðlÈÉ©¢)N>ñc¢à§@t²ÙKrhÍö}þ³0u	yÌ¸åô«R`aêùÝ«Õ÷zPõXqþ²B¨ç2ä
FÙe>R*/ÂóhíSÖ8æ(o=ñ±¿v!³s]ýáÓlä/\yfáÍÒ÷&¬²üÊ2zñóa1ú	Í ©µ@ÇuÕxº´n¨ù$/Toé E«$!¸OêR´ý©´ì*ú½s7BÓX½Rf)¤8Þ¦<h 0c.45RñÚax.ãDóRFrÿ©Îp*è¬#
xónÂH¢yôYÞ+áÏaÒãó&Ððhppçû]¹!t
äwÒÎÈ¢æ=É=5÷>w~/ÐbS@#Ïk¸ÔÍo&%]ÙäF;e/í*é>Ï¦ëÿ¬êøLó¦Øã_ÚÉK\àÈ\ð GÎAAs¯õ:Ô1|ccP¼LÁß®ìghÒ/ûéÏÙÊãÃöcQ".ëð1dPPá\¦:YÚ\öW¯Ââ¤@$§9ÃûCàõÈ¾©¾¨Ìá%;ê Ï¸MM~3hüe]å½°@§ÒaÚ¡JÄì¤µf$ Ä9Ò¯¾«6ßhÒÅêèsüDóuÁ1Û=É-`©p+>Ú![ÝÆ¤|I«ê=DëoüqBÂBeü´íÌ72=ÞöCUf£ßG3=i
ká©´<#qÒþ¢È>XGB¸ûÅaäKk@D¶rº]3Y¹P®µVH¹ÉCwô¯ê|ÿÈ¾q(]­9ò`gÀØ#mþi=ÝFQT
!ý
ÁÏ»üCÙ
â¡¨¿u¢Çê^88&X.+O){~¯8Ä50æDÆæÖec±¤÷ö£­ðn¡þ2íd_hðøQï¬ëÏ(m¶8äHH'TÉníYøU²qÃÜä>
#LçÅ±/Óq­*ÍÈÛØ]Ù6x£G-ý3:öö HÍ16ÅK5.Aq¢f.Ãò?b&özvboÀÕW?7äj¿{9H®B4ýíù¥TÎR¡ ÄÚÂæØ
ÓlaÒý4#PóÂbkÏm?WÙI7Í #;ç»ùÝâWIÛ&ÂÜj8Î¿ð×PÁ{³óÚB4<yÐºóYJ%Q|Å~ª HÀ{>{ep'p~õBø üÐÛê´èÝÅÍôom4ûfqM2âÞdL'é}ÎºÛCsÎ8Ý
/Í	JaOf¤^x{°{Ø µarØDÉ=öVRù5uÉíOjq×.6ä-r¤lÍ0uâ 5ºafw\= >4ÖÝ
1*Í@(+¯o&0L@SpÑ7FeÀqÓñÎ¦¥ÂÏøÍè«ç ¨Û[17Wùi[¬?	|&OiÁ£$A×óäÌ+ls}Ä!ÍwuÄfÙÕýu<Í;µðtvÆJ«¦§¾ÎÜÊyaÙÆËÍóW/NÎ·©¾IV¾®l"h;Íð·hÂ8Çöõ.éá­X
±^?·ÕoÑiOcp%d¦ÔZßâl­Ê§µµ?$`?0GÊV{¬ÔCø0á(}4>zØ|R,»Ô$S½Ê÷¦ØcÊ/Ã[0G
Ì¯=ü¬µ®:Ìç!±J@ô[>(+ÖÜÀÿçÍEàî*»¾þÏMó<ÙU	?&¸ßñxðw©nøá.LHUf^ø³`r²	»]3Ø¯ÝX¹KÑÁ+Ö®ÒZe&´Ð"ª¶Rê?×D0Kr¿Rú2 n²iùerh¹² ¤ÀõÑ.¢agbÔ
~nÌèLf'SSóD!//}* OµIï;7u¯o>Ñ5pE?
C;Ö8¦ àíÄÉ+@P´ó\[5ÂH«ÕaªEAeS]ÄÅZKá|[¹*Þ=að?Oi3Bö\R»»ÐGþêzÀ³¢gd§tfë 
endstream
endobj
425 0 obj
<<
/Author()/Title()/Subject()/Creator(LaTeX with hyperref package)/Producer(pdfTeX-1.40.19)/Keywords()
/CreationDate (D:20191005205708+02'00')
/ModDate (D:20191005205708+02'00')
/Trapped /False
/PTEX.Fullbanner (This is pdfTeX, Version 3.14159265-2.6-1.40.19 (TeX Live 2019/dev/Debian) kpathsea version 6.3.1/dev)
>>
endobj
376 0 obj
<<
/Type /ObjStm
/N 82
/First 719
/Length 3516      
/Filter /FlateDecode
>>
stream
xÚíZ[sÛ6~×¯Àc¼Äèd»c'qí¦vÚÜÆÓQlÚÖF]JÒþú= aP¤ØÍîËî$$ÀÃsùÎ¤,´&%Úæ°µD(­#" ¦k#ÚrC¬ÕÐZâJI-	ReèÎKpgáz%°pÊÐ1DZXG$WpË1"% R°pH+ÄH8CT)ÀÊylLQR1@­á]60¢ tB-Xk-A ÖÚ8=b:Ni@r£dÍ¥%ôpùcÌ0-1N)±V,¬%Ðð;b3$RCW'C i&\ ÎXrbpzä Ä*®Gô8ðVûA"Öp ô0.=èz06
ÈÐÄ1 Æãx§F@Ðè
XBVÐ³fôðá¾üã¦"to>¯Ý¯Õâ]	E^Ñ§ô}àìlDOªó¼cÎ\+m
ÄaY¡apq¤j§«÷
­bh¹Âñâ @K[Üâ¬º?M>L<PìÐ#½Þ_ÀYªÂqÕWX¬i
¬a&xaýVH|nªù,¾¹¨ª½ùÅQ5_e¨wV²úúÍ[¢T¡..¢`°0ÏWÓéÙF]t¥(8,ÝzÞ	=p8Ñê NXÕBß'+ÚÌ¯xèE}~ZM¾x|@èËêsC¼ówÆÂÂò+öÎFï°®¿Áá4,mãÝJ2åÛkÍXÁâyPãÔ÷Z&­µgäCáÄsÐð©bU·çdj¡ñ¢¸¾1¬ÀUÞk2^Ä8RÂ]åÏ:øÑäÚºÂ×fJP¢àÂéÂï^ ö
%f¥.  W³³!(`ûÑ¶ðû\Jsã9#
¨VBú4®¹DàÎ-­ûÂ×A²ñÄðÔ)7ükïs­aìTÎÛÃß­¶è@eå´íH~Ly{Ü	_8¶mÀàOÖßs ×5öV®¤ÜO¨ÔÌiµbYæAâRÛ6'Ø·±ßÞO6 Td÷<¨@ ã])óãúðàÑÅÁöhé"
ôÑ~­à~aGVøy·Åb®&K4AP/N¢×Î</ü<·4òQN¶ì»Ná·x±mé})ß*É²hÛ¸*¶ÈÒÎXù¦´T*¤þÿøoCûy\4Öös#÷¾v?ÇWÎ4EKûÅ)î;EÿÇ÷¦0UoìÛ¡)íÛ9rÌ;Ã4ýUöæ'³-Ó: P9´yZ)½ÛxgÙ{¾Ï<®Ât½ï7ÇãÜ9}sðbÿ×ï=c%Ü¯Dýýú3y·+8ÙÅa¥¾¬toy^Áv ùh|ó´\]Ã¥ðU{»o>kÆÓÉùÞüjZ§M5ûÑ×ÑJ
ÂL@IXüÊvÒ}-Ýÿàç'ÏüÓ7àsGv.ñÓ
Q·ð!ûÁåføö.ð_?ÿ®ùÜ4Ãàµ0Ì*_êym;Ð9Ï¡kÓ^¶À­ÊëpWÞøÉÞ£ßOfïWËÓñüp÷¤ºZ
¼O./«E5?¯ä§z9ÍÎW³÷Õb9¹ÃÚGÇ³¸Ï/èï«º©ÞÁnZ]ÆÞ".ôfºZÒóz6Óë?n®«9ãI}AÓñòþY-jZÏ+Ú|ªis½¨*zY¯úcEÏtY}O@ñ¼ÖsÏ&¾Ï	´ú}5- OµôÇ
é½¦ú/úNéÎiMoèïtA´¡+ú~¢éôOû&Ðtñ~êéi/W¦JZÍ/
xX´ôbô/'Ë³~Å¥­ÄaT÷ÇËÊÃìíïõ¿+á ÓÉbÙ<º/­Ãq{ëñ«ÉEs½ô?d
oï~ã.µÃuRç88»ÅaÃ¦ÿMíÎÈ¶m<ëàÔ:8¾[ù-°mÛIÖ±­ØpYJØÔ·Àö¥e´÷ÜOeõeÅ7Á÷U{×:îåÇ¾Ìîsç:i¢3+¹Éà<£¼_UKØêîT#¸^à¾?ÿz¿Ï'°(àÍVêÐê(7<¶¾ÄÎîÙèËFßa*ÁKRsaB«îG¼\<¸>Ã:mÓûÅÏODDÜ¢T±
endstream
endobj
426 0 obj
<<
/Type /XRef
/Index [0 427]
/Size 427
/W [1 3 1]
/Root 424 0 R
/Info 425 0 R
/ID [<1AF7E5628F18238F7AC10E6F8AA0FA56> <1AF7E5628F18238F7AC10E6F8AA0FA56>]
/Length 1022      
/Filter /FlateDecode
>>
stream
xÚ%KlVUFï>÷R
þÜ>(åÕ'¯¥´PJ)RÊ«@)(ôEtÀÈ$Û0aâÌ±ÄF0Ã3B¢	SÔh4G$Dÿõ9Y9û;·÷¿={s²,ËþMY2K}¿g®WÇ>ÂÈ@ª"N¢ÌAA6K6L¹ÔÝ$;H¹ÔÝ"¢\VÝ&;@¹
ÔUËoðAÊÕ ÌÈöSVÀ²D¶²
1pà8
K½wª»çówÅû÷5G4ü!ùëA¥±4íÊQ±4ñ·29>Ñ,M}¨	ôµ`Àâ`b=`é¢ÙÒÌ/zwc#ÀØÐûÚ,-i:'º
:ÄVkÅ %*/Áî	¤	ìÌ	Äô	öeàP°kNG§¥Þèñ*P*P*P*P*P*P*&À94a1	Ð"p(0'&°)p#¦-ÝÍõ3`\·ôÉ²ô£Ä"{-bÞÒýOõÈè@©ñ¾Ó¬\jÁ*PáÁ¬&V@GUUo?ÓÄj #­è}Õ>úVg[·lµôô7e:¯tÈ´[ú¡EYßÒÅH§J¥¯4¡gØféåe:dvK¯ÿP¶ì»-ýü²^À	R ý``ûÁ!0¸?Ê>Ko~Õ«FÀQpã`§Àip%'Cy\ à"Àep\Ó`\Üo%
endstream
endobj
startxref
291055
%%EOF
doc/HyperListTutorialAndTestSuite.hl	[[[1
150
HyperList Test Suite (V0.99); Press '\f' to uncollapse this whole HyperList
	This HyperList serves two purposes
		A tutorial for all hyperlist.vim features 
			Do each item and you will learn all the features of this VIM plugin
		A fully fledged test suite
			Doing each item will confirm the plugin version is working correctly
	Requires the files <HyperListTestSuite.hl> and <~/.vim/syntax/hyperlist.vim>
		Set the cursor on a file link and press 'gf' to open the file
	Tests are broken into 3 major categories, "SYNTAX HIGHLIGHTING", "FUNCTIONALITY TEST" And "MENU TEST"
	SYNTAX HIGHLIGHTING
		Ensure that all HyperList elements are correctly highlighted in the <~/.vim/doc/HyperList.hl>
		Check: The Property should be in red
		CHECK: The Operator should be in blue
		[? OK] Qualifier in green
		A #hashtag should be in yellow; And the preceding semicolon in green
		1. The numbering is an identifier and should appear in magenta
		+ The multi-line indicator should appear in red
		 and indicates the item runs across more than one line
		This link should be in magenta <link to nowhere>
		This comment should be in teal with the link inside in magenta (the <link to nowhere>)
		Quotes are also in "teal" and with "links inside in magenta, <link to nowhere>"
		Check (comment): Comment within a Property should be in teal
		Keywords END and SKIP should be in magenta
		Keywords FIXME and TODO should be in black on yellow
		Markup like *bold* /italics/ and _underline_ should appear correctly
		Fold this item and child by pressing 'SPACE' and see that it appears in bold
			This is a child item
		Press '\h' and move the cursor one line down
			This line should appear as normal while all other lines are dimmed
			Press '\h' again to remove the highlighting
		Collapse and uncollapse the next line to hide/show the literal block of lines
		\
			Check: This "literal" block should not contain any colors
			[? OK] *bold* /italics/ _underline_ FIXME TODO #hashtag
		\
		Check that State items and Transition items are underlined correctly
			By pressing '\u' State items should be underlined
			Pressing it again, Transition items should be underlined
			Pressing it a third time should toggle off underling of such items
			Now press '\u' three times
				S: This is a state item (indicates an item that is describing something)
				| This is a state item (indicates an item that is describing something)
				T: This is a transition item (indicates an item to be done/processed)
				/ This is a transition item (indicates an item to be done/processed)
	FUNCTIONALITY TEST
		Toggle folds; Press 'SPACE' twice to see the child of this line collapse and uncollapse
			This is a child item
		Do all these: '\3' '\4' '\5' '\6' '\7' '\8' '\9' '\a' '\b' '\c' '\d' '\e' '\f'
			Observe that the children appear at the correct fold level
			'\3'
				'\4'
					'\5' 
						'\6' 
							'\7'
								'\8'
									'\9'
										'\a'
											'\b'
												'\c'
													'\d'
														'\e'
															'\f'
		By placing the cursor in the reference and press 'gr' you jump to the next item (<42>)
		42. This is an item that you will jump to
		By placing the cursor in the file reference and press 'gf' you open the file (<~/.vim/doc/HyperList.hl>)
			Close that file to come back to this file
		Toggle autonumbering of items
			Press '\an' or '\#' to toggle autonumbering on/off; Press '\an' now and go to next line
				You should see the message "Autonumber ON"
			1.1. Go to the end of this line and enter insert mode and press enter
			1.3. You should now have a line "1.2." above this line
				Place the cursor on that "1.2." line in normal mode and press 'CTRL-T'
					Observe that it numbers the line as a child of "1.1." (1.1.1.)
				On that line, press 'CTRL-D' to observe it goes back to "1.2."
			Press '\#' to toggle off autonumbering; You should see the message "Autonumber OFF"
		Sort lines correctly
			The following lines are incorrectly sorted
				2 Item2
				3 Item3
					3.1 Child of Item3
				1 Item1
					1.1 Child of Item1
			Mark the numbered lines visually ('V') and press '\s'
				Observe that the lines are now sorted correctly with their children in the right places
		Create and use checkboxes for items
			With the cursor on this line, press '\v' to see a checkbox appear
				With the cursor on the above line, press '\v' again to see an "x" appear in the checkbox
			[_] With the cursor on this line, press '\V' to mark the checkbox with a time stamp
		Show/hide items with specific words
			This is an item with the word "simple"
			This is an item with the word "amazing"
			This is an item with the word "simple"
			Now go to the word "simple" and press 'zs'
			Observe that all items that does not contain "simple are folded"; Press 'zh'
				Observe that items containing the word are hidden/folded
				Go here and press 'z0' to remove all hide/show behaviour; Press '\f' to again uncollapse the whole HyperList
		Check "presentation mode"
			With the cursor on this item, press 'gDOWN' to go to the next item and collapse all other items
				Now again press 'gDOWN' to go to the next item in presentation mode (see this line collapsed)
			With the above line collapsed, again press 'gDOWN' to go to the next item in presentation mode
				Now again press 'gDOWN' to go to the next item in presentation mode
			Now press 'gUP' three times and 'gDOWN' three times and observe the current line "presented"
		Check that filling put forms work correctly
			Press '\SPACE' to jump to the next line in insert mode to fill out the item
				Fill out the rest = 
		Encryption and decryption
			Note: Encryption requires OpenSSL to be installed
			With the cursor on this line, press '\z' and enter the required password twice to encrypt the line
			Mark the above encrypted lines visually and press '\x' to decrypt it with the password you used
			You can now create a HyperList password file and save it as ".pass.hl" (not the dot preceding the file name)
				When opening the encrypted file, VIM will automatically ask you for a password to decrypt that hyperlist
		Export to HTML
			You can convert this whole HyperList to HTML and save the output to "test.html"
			Pressing 'u' will undo the conversion, but you need to do ':set ft=hyperlist' to set the right filetype again
			Press '\H' to convert this whole HyperList to HTML format
		Export to LaTeX
			You can convert this whole HyperList to LaTeX and save the output to "test.tex"
			Pressing 'u' will undo the conversion, but you need to do ':set ft=hyperlist' to set the right filetype again
			Press '\L' to convert this whole HyperList to HTML format
		Export to TPP
			tpp: <https://github.com/cbbrowne/tpp>
			You can convert this whole HyperList to the TPP presentation format and save the output to "test.tpp"
			Pressing 'u' will undo the conversion, but you need to do ':set ft=hyperlist' to set the right filetype again
			Press '\T' to convert this whole HyperList to HTML format
		Export lines to your Google calendar
			To use this feature, you need to have the program 'gcalcli' installed and properly set up
				gcalcli: <https://github.com/insanum/gcalcli>
				Now press '\G' to see that the below item appears in your Google calendar at the correct time
				2020-01-01 08:00: Item from the HyperList Test Suite
		Show the complexity level of this HyperList
			Using ':call Complexity()' you should see the number "157" displayed
	MENU TEST
		When opening <HyperListTestSuite.hl>
				The "HyperList" menu item should appear in the menu line
			During insert operations('i,'o','O','a','A', etc)
				The menu should be greyed out
			Using 'ESC' at the end of insert operations should un-grey the menu
		Selecting the menu
			A TearOff dashed line appear at the top
				Clicking the TearOff dashed line
					The Hyperlist menu should detach and be moveable
					Menu items ending with '>>', when selected, also show a TearOff line and a submenu
					Each submenu should detach when their TearOff line is clicked
		Closing TearOff Menus
			Each Torn off menu should have an 'x' in the upper right corner
			Each Torn off menu should close when the 'x' is clicked
			All torn off menus should close when Gvim closes
		Go through all parts of the <FUNCTIONALITY TEST> using the gVIM menus to see that they work correctly


ftdetect/hyperlist.vim	[[[1
50
" WOIM files are included for backward compatability (HyperList was earlier WOIM)
au BufRead,BufNewFile *.hl		set filetype=hyperlist
au BufRead,BufNewFile *.woim            set filetype=hyperlist

" Using code from openssl.vim by Noah Spurrier <noah@noah.org>
" dot-files (files starting with ".") gets auto en-/decryption
augroup hl_autoencryption
    autocmd!
    autocmd BufReadPre,FileReadPre			.*.hl set viminfo=
    autocmd BufReadPre,FileReadPre			.*.hl set noswapfile
    autocmd BufReadPre,FileReadPre			.*.hl set bin
    autocmd BufReadPre,FileReadPre     	.*.hl set cmdheight=2
    autocmd BufReadPre,FileReadPre     	.*.hl	set shell=/bin/sh
    autocmd BufReadPost,FileReadPost    .*.hl %!openssl bf -d -a 2>/dev/null
    autocmd BufReadPost,FileReadPost		.*.hl set nobin
    autocmd BufReadPost,FileReadPost    .*.hl set cmdheight&
    autocmd BufReadPost,FileReadPost		.*.hl set shell&
    autocmd BufReadPost,FileReadPost		.*.hl execute ":doautocmd BufReadPost ".expand("%:r")
    autocmd BufWritePre,FileWritePre		.*.hl set bin
    autocmd BufWritePre,FileWritePre		.*.hl set cmdheight=2
    autocmd BufWritePre,FileWritePre		.*.hl set shell=/bin/sh
    autocmd BufWritePre,FileWritePre    .*.hl %!openssl bf -e -a -salt 2>/dev/null
    autocmd BufWritePost,FileWritePost	.*.hl silent u
    autocmd BufWritePost,FileWritePost	.*.hl set nobin
    autocmd BufWritePost,FileWritePost	.*.hl set cmdheight&
    autocmd BufWritePost,FileWritePost	.*.hl set shell&
augroup END

augroup woim_autoencryption
    autocmd!
    autocmd BufReadPre,FileReadPre			.*.woim set viminfo=
    autocmd BufReadPre,FileReadPre			.*.woim set noswapfile
    autocmd BufReadPre,FileReadPre			.*.woim set bin
    autocmd BufReadPre,FileReadPre     	.*.woim set cmdheight=2
    autocmd BufReadPre,FileReadPre     	.*.woim	set shell=/bin/sh
    autocmd BufReadPost,FileReadPost    .*.woim %!openssl bf -d -a 2>/dev/null
    autocmd BufReadPost,FileReadPost		.*.woim set nobin
    autocmd BufReadPost,FileReadPost    .*.woim set cmdheight&
    autocmd BufReadPost,FileReadPost		.*.woim set shell&
    autocmd BufReadPost,FileReadPost		.*.woim execute ":doautocmd BufReadPost ".expand("%:r")
    autocmd BufWritePre,FileWritePre		.*.woim set bin
    autocmd BufWritePre,FileWritePre		.*.woim set cmdheight=2
    autocmd BufWritePre,FileWritePre		.*.woim set shell=/bin/sh
    autocmd BufWritePre,FileWritePre    .*.woim %!openssl bf -e -a -salt 2>/dev/null
    autocmd BufWritePost,FileWritePost	.*.woim silent u
    autocmd BufWritePost,FileWritePost	.*.woim set nobin
    autocmd BufWritePost,FileWritePost	.*.woim set cmdheight&
    autocmd BufWritePost,FileWritePost	.*.woim set shell&
augroup END

README.md	[[[1
264
# hyperlist.vim
This VIM plugin makes it easy to create and manage HyperLists using VIM

---------------------------------------------------------------------------

## GENERAL INFORMATION ABOUT THE VIM PLUGIN FOR HYPERLISTS (version 2.4.1)

HyperLists are used to describe anything - any state, item(s), pattern,
action, process, transition, program, instruction set etc. So, you can use it
as an outliner, a ToDo list handler, a process design tool, a data modeler, or
any other way you want to describe something.

This plugin does both highlighting and various automatic handling of
HyperLists, like collapsing lists or parts of lists in a sophisticated way.

This VIM plugin makes it easy to work with HyperLists. It has a vast range of
features:

* Automatically recognize files with the extension ".hl"
* Syntax highlighting of every HyperList element
* Syntax highlighting of bold, italics and underline (using \*word\*, /word/ and \_word\_)
* Automatic underlining of State or Transition items in a list
* Collapse and uncollapse parts of a HyperList
* Syntax highlighting of folded parts of a list
* Set a specific fold level to unfold items down to that level
* Linking/referencing between elements (items) in a list
* Easy navigation in lists, including jumping to references
* Easy navigation to elements that needs filling out (when you use a list as a template)
* Open referenced file under cursor using (g)VIM or external program (user definable)
* Autonumbering of items and sub-items (children) and renumbering of visually selected items
* Sorting a visually selected set of items (while letting the children stay with their parents
* Create and toggle checkboxes, even with a time stamp for completion
* Show/hide of words or regex patterns
* "Presentation mode" that folds everything but the current item
* Highlighting of the current item and its children
* Encrypt and decrypt whole lists or parts of a list
* Autoencrypt/decrypt files that has a file name starting with a doti
* Export a HyperList to HTML, LaTeX or TPP formats
* Transfer all items tagged with future dates/times to a Google calendar
* Show the complexity level of a HyperList
* Description on how to include HyperLists within other filetypes, taking full advantage of the above features when including a HyperList in e.g. a normal .txt document
* Menus with submenus for gVIM users
* ... and there are many more features. Check out the comprehensive documentation (type ":help HyperList" in VIM after install)

For a complete tutorial, go through the file HyperListTutorialAndTestSuite.hl in the documentation folder (~/.vim/doc/HyperListTutorialAndTestSuite.hl). This file also serves as a complete test suite for releases of this plugin. 

For a compact primer on HyperList, read this OnePageBook:

![HyperList OnePageBook cover](https://isene.org/assets/onepagebooks/7-hyperlist/cover.jpg)
**[Downloadable PDF](/assets/onepagebooks/7-hyperlist/1PB_HyperList.pdf)**

And for an introduction to the VIM plugin's most sexy features, watch the
screencast:

[![HyperList screencast](https://isene.org/assets/videos/screencast.jpg)](https://isene.org/assets/videos/HyperListVIM.mp4)

GVIM users can enjoy the commands organized in a menu with submenus.

### Installation

As you most certainly have already done, to install the HyperList plugin for
VIM, dowmload woim.vba and do:

```
vim hyperlist.vba
:so %
:q
```

You will then discover that this file (README_HyperList will appear in the VIM
directory, while the documentation will be placed in the "doc" subdirectory,
the HyperList plugin will be placed in the "syntax" subdirectory. A HyperList
filetype detection file is placed in the "ftdetect" subdirectory.

From now on all files with the ".hl" file extension will be treated as a
HyperList file, syntax highlighted corrrectly and you can use all the neat
HyperList functionality for VIM.

### Include Hyperlists in other document types

To use HyperLists within other file types (other than ".hl"), add the
following to those syntax files:

```
syn include @HL ~/.vim/syntax/hyperlist.vim
syn region HLSnip matchgroup=Snip start="HLstart" end="HLend" contains=@HL
hi link Snip SpecialComment
```

The documentation file contains all of the HyperList definition and is part of
the full specification for HyperList as found here:

  http://isene.me/hyperlist/


## INSTRUCTIONS

Use tabs for indentation.

Use SPACE to toggle one fold.
Use \0 to \9, \a, \b, \c, \d, \e, \f to show up to 15 levels expanded.

### Autonumbering and renumbering

Use \\# or \an toggles autonumbering of new items (the previous item must be
numbered for the next item to be autonumbered). An item is indented to the
right with c-t, adding one level of numbering. An item is indented to the left
with c-d, removing one level of numbering and increasing the number by one.

To number or renumber a set of items, select them visually (using V in VIM)
and press \R. If the items are not previously numbered, they will now be
numbered from 1 and onward. Only items with the same indentation as the first
selected line will be numbered. If the first item is already numbered (such as
1.2.6), the remaining items within the selection (with the same indentation)
will be numbered accordingly (such as 1.2.7, 1.2.8, etc.).

### Presentation mode

As a sort of presentation mode, you can traverse a HyperList by using "g DOWN"
or "g UP" to view only the current line and its ancestors. An alternative is
\DOWN and \UP to open more levels down.

### Highlighting

To highlight the current part of a HyperList (the current item and all its
children), press \h. This will uncollapse the whole HyperList and dim the
whole HyperList except the current item and its children. To remove the
highlighting, simply press \h again (the fold level is restored).

### Jumping to references

Use "gr" (without the quotation marks, signifies "Goto Ref") or simply press
the "Enter" ("CR") key while the cursor is on a HyperList reference to jump to
that destination in a HyperList. Use "n" after a "gr" to verify that the
reference destination is unique. A reference can be in the list or to a file
by the use of <file:/pathto/filename> or an relative reference such as <-4> to
reference four items/lines up the list.

Whenever you jump to a reference in this way, the mark "'" is set at the point
you jumped from so that you may easily jump back by hitting "''" (single
quoutes twice). 

### Opening referenced files

Use "gf" to open the file under the cursor. Graphic files are opened in "feh",
pdf files in "zathura" and MS/OOO docs in "LibreOffice". Other filetypes are
opened in VIM for editing. All this can be changed by editing the file
handlers at the top of the hyperlist.vim script in your VIM syntax folder.

### Simple tricks
```
Use \u to toggle underlining of Transitions, States or no underlining.

Use \v to add a checkbox at start of item or to toggle a checkbox.
Use \V to add/toggle a checkbox with a date stamp for completion.

Use \SPACE to go to the next open template element
(A template element is a HyperList item ending in an equal sign).

Use \L to convert the entire document to LaTaX.
Use \H to convert the entire document to HTML.
Use \T to convert the entire document to a basic TPP presentation.
```

For information on the Text Presentation Program (TPP), see: 
https://github.com/cbbrowne/tpp

### Encryption
```
Using \z encrypts the current line (including all sublevels if folded).
Using \Z encrypts the current file (all lines).
Using \x decrypts the current line.
Using \X decrypts the current file (all lines).
Using \z and \x can be used with visual ranges.
```

A dot file (file name starts with a "." such as .test.woim) is automatically
encrypted on save and decrypted on opening.

When running gVIM under Windows, encryption will spawn a DOS window where you
enter the password for encryption/decryption. This window may be hidden under
other windows.

### Syntax refresh

Syntax updated at start and every time you leave Insert mode, or you can press
"zx" to update the syntax. 

### Speeding up hyperlist.vim

You may speed up larger HyperLists by setting the the global variable
"disable_collapse" - add the following to your .vimrc:

  `let "g:disable_collapse" = 1`

If you want to disable or override these keymaps with your own, simply add to
your .vimrc file:

  `let "g:HLDisableMapping" = 1`

### Show/hide

You can show/hide words or regex patterns by using these keys and commands:
```
  zs    Show all lines containing word under cursor
  zh    Hide all lines containing word under cursor
  z0    Go back to normal HyperList folding
  :SHOW word/pattern
        Show lines containing either word or pattern
  :HIDE word/pattern
        Hide lines containing either word or pattern
        Pattern can be any regular expression
```

This functionality is useful for easily showing e.g. a specific tag or hash.
The functionality is taken from VIM script #1594 (thanks to Amit Sethi).

### Sort items

To sort a set of items at a specific indentation, visually select (V) the
items you want to sort (including all the children of those items) and press
\s and the items in the range will be alphabetically sorted - but only the
items on the same level/indentation as the first item selected. The sorted
items will keep their children. This is useful if parts of a HyperList is
numbered and you get the numbering out of sequence and wants to resort them.
One caveat, the last line in the selection cannot be the very last line in the
document (there must be an item or an empty line below it).

### Add items as reminders to your Google Calendar

By doing :call CalendarAdd() all items containing a future date will be added
as reminders to your Google Calendar. If an item includes a time, the event is
added from that time with duration of 30 minutes.

This function requires gcalcli (https://github.com/insanum/gcalcli)

The function is mapped to \G to add events to the default calendar. The
default calendar is defined as b:calendar at the start of the HyperList.vim
script. To add the events to another calendar, do :call
CalendarAdd("yourcalendar")

The title of the calendar is the item in the HyperList without the date/time
tag. If there is no time tag for the item, an event is created at the start of
the date. If there is a time tag for the item, the event is created at that
time with the default duration (30 minutes). The description for the event is
the item and all its child items.

### More help

For this help and more, including the full HyperList definition/description, type 

  `:help hyperlist`

If you use tab completion after the "HyperList", you will find all the help
tags in the documentation.


Enjoy.

## Contact

Geir Isene <g@isene.com>
...explorer of free will
   http://isene.org