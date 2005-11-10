" Vim script file                                           vim600:fdm=marker:
" FileType:     XML
" Author:       Rene de Zwart <renez (at) lightcon.xs4all.nl> 
" Maintainer:   Rene de Zwart <renez (at) lightcon.xs4all.nl>
" Last Change:  $Date: 2005/11/10 18:55:30 $
" Version:      $Revision: 1.2 $
" Location:     
" Licence:      This program is free software; you can redistribute it
"               and/or modify it under the terms of the GNU General Public
"               License.  See http://www.gnu.org/copyleft/gpl.txt
" Credits:      Devin Weaver <vim (at) tritarget.com>  et all
"               for the original code.  Guo-Peng Wen for the self
"               install documentation code.
"               This script only retained the
"               documentation function. But this was my inspiration.
"               Unlike Devin's script there is no provision (at the
"               moment?) for attributes and html editing nor for
"               globally changing the <localleader>. The attributes
"               should come from a dtd thingy 'a la mode de' PSGML. A
"               bit of inspiration came from psgml (Lennart Staflin) to.
"               

" Only do this when not done yet for this buffer
if exists("b:did_ftplugin")
  finish
endif
let b:did_ftplugin = 1

" Buffer variables                                                  {{{1
let b:mapgt   = "inoremap <buffer> > ><Esc>:call <SID>CloseTag()<Cr>"
let b:unmapgt = 'iunmap <buffer> >'
let b:emptytag = 0
let b:endtag = 0
let b:haveTag = 0

" SavePos() saves position  in bufferwide variable                        {{{1
if !exists('*s:SavePos')
fun! s:SavePos()	
	let l:restore = 'normal ' . line('.') . 'G0' 
	if col('.') > 1
		let l:restore =  l:restore . (col('.')-1) . 'l'
	en
	return l:restore
endf
en

" getTagUnderCursor()  Is there a tag under the cursor?               {{{1
" Set bufer wide variable
"  - b:emptytag
"  - b:endtag
"  - b:haveTag
"  - b:tagName
"  - b:endcol & b:endline only used by getMatch()
"  - b:gotoCloseTag (if the tag under the cursor is one)
"  - b:gotoOpenTag  (if the tag under the cursor is one)
if !exists('*s:getTagUnderCursor')
fun! s:getTagUnderCursor()
	let b:emptytag = 0
	let b:endtag = 0
	let b:haveTag = 0
	
	"Lets find forward a < or a >.  If we first find a > we might be in a tag.
	"If we find a < first or nothing we are definitly not in a tag

	if getline('.')[col('.') - 1] == '>'
		let b:endcol  = col('.')
		let b:endline = line('.')
		if getline('.')[col('.')-2] == '/'
			let b:emptytag = 1
		en
	elseif search('[<>]','W') >0
		if getline('.')[col('.')-1] == '>'
			let b:endcol  = col('.')
			let b:endline = line('.')
			if getline('.')[col('.')-2] == '/'
				let b:emptytag = 1
			en
		el
			retu b:haveTag
		en
	el
		retu b:haveTag
	en
	
	"So we got a '>'! As a result we are now on >
	"| Now let find a < or a > backwards.
	
	if search('[<>]','bW' ) >=0
		if getline('.')[col('.')-1] == '<'
			if getline('.')[col('.')] == '/'
				let b:endtag = 1
				let b:gotoCloseTag = s:SavePos()
			elseif getline('.')[col('.')] == '?' ||  getline('.')[col('.')] == '!'
				"we don't deal with processing instructions or dtd
				"related definitions
				retu b:haveTag
			el
				let b:gotoOpenTag = s:SavePos()
			en
		el
			retu b:haveTag
		en
	el
		retu b:haveTag
	en

	let b:haveTag = 1
	"we have established that we are between something like
	"'</\?[^>]*/\?>'
	"Now lets go for the name part. The namepart are xmlnamechars which
	"is quite a big range. We assume that everything after '<' or '</' 
	"until the first 'space', 'forward slash' or '>' ends de name part.
	
	let l:fendname = match(getline('.'), '$\| \|\t\|>',col('.') + b:endtag)
	let b:tagName = strpart(getline('.'),col('.') + b:endtag, l:fendname - col('.') - b:endtag)
	"echo "Tag " . b:tagName 
	retu b:haveTag
endf
en

" getMatch(tagname) Looks for open or close tag of tagname               {{{1
" Set bufer wide variable
"  - b:gotoCloseTag (if the Match tag is one)
"  - b:gotoOpenTag  (if the Match tag is one)
if !exists('*s:getMatch')
fun! s:getMatch(name)
	let l:pat = '</\=' . a:name . '\($\| \|\t\|>\)'
	if  b:endtag
		exe b:gotoCloseTag
		let l:flags='bW'
		let l:level = -1
	el
		exe  'normal '.b:endline.'G0'.(b:endcol-1).'l'
		let l:flags='W'
		let l:level = 1
	en
	while search(l:pat,l:flags) > 0
		if  getline('.')[col('.')] == '/'
			let l:level = l:level - 1
		el
			let l:level = l:level + 1
		en
		if l:level == 0
			break
		en
	endwhile
	if l:level
		echo "no matching tag!!!!!"
		retu l:level
	en
	if b:endtag
		let b:gotoOpenTag = s:SavePos()
	el
		let b:gotoCloseTag = s:SavePos()
	en
	retu l:level
endf
en

" Match()  Match de tagname under de cursor                       {{{1
if !exists('*s:Match')
fun! s:Match()	
	let l:restore =  s:SavePos()
	if s:getTagUnderCursor()
		if s:getMatch(b:tagName)
			exe l:restore
		en
	el
		exe l:restore
	en
endf
en

" CloseTag() closing the tag which is being typed                  {{{1
if !exists('*s:CloseTag')
fun! s:CloseTag()	
	let l:restore =  s:SavePos()
	let l:multi = 0
	if col('.') > 1 && getline('.')[col('.')-2] == '>'
	  let l:multi = 1
      normal h
	en
	
	if s:getTagUnderCursor()
		if b:emptytag == 0 && b:endtag == 0
			if l:multi == 0
				exe "normal />/\<Cr>a</" . b:tagName . ">\<Esc>F<"
				startinsert
				retu
			el
				exe "normal />>/e\<Cr>s\<Cr>\<Esc>Ox\<Esc>>>$x"
				startinsert!
				retu
			en
		en
	en
	exe l:restore
	if (col('.')+1) == col("$")
		startinsert!
	else
		normal l
		startinsert
	en
endf
en

" BlockTag() Surround a visual block with a tag                       {{{1
" Be carefull where You place the block 
" the top    is done with insert!
" the bottem is done with append!
if !exists('*s:BlockTag')
fun! s:BlockTag()
	let l:newname = inputdialog('Surround block  with : ')
	if strlen( l:newname) == 0
		retu
	en
	exe b:unmapgt
	'<
	if  col("'<") > 1
		exe 'normal 0'.(col("'<")-1).'l'
	en
	exe "normal i\<Cr><".l:newname.">\<Esc>'>"
	if  col("'>") > 1
		exe 'normal 0'.(col("'>")-1).'l'
	en
	exe "normal a\<Cr></".l:newname.">\<Esc>"
	let l:rep=&report
	let &report=999999
	'<+1,'>>
	let &report= l:rep
	exe b:mapgt
endf
en
" Change() Only renames the tag                              {{{1
if !exists('*s:Change')
fun! s:Change()
	let l:restore = s:SavePos()
	if s:getTagUnderCursor()
		let l:newname = inputdialog('Change tag '.b:tagName.' to : ') 
		if strlen( l:newname) == 0
			retu
		en
		if s:getMatch(b:tagName) == 0
			exe b:gotoCloseTag
			exe 'normal 2lcw' . l:newname . "\<Esc>"
			exe b:gotoOpenTag
			exe 'normal lcw' . l:newname . "\<Esc>"
		en
	en
endf
en

" Join() Joins two the same tag adjacent sections                    {{{1
if !exists('*s:Join')
fun! s:Join()
	let l:restore = s:SavePos()
	if s:getTagUnderCursor()
		let l:pat = '<[^?!]\S\+\($\| \|\t\|>\)'
		let l:flags='W'
		if  b:endtag == 0
			let l:flags='Wb'
		en
		if search(l:pat,l:flags) > 0

			let l:secondChar = getline('.')[col('.')]
			if l:secondChar == '/' && b:endtag ||l:secondChar != '/' && !b:endtag
				exe l:restore
				retu
			en
			let l:end = 0
			if l:secondChar == '/'
				let l:end = 1
			en
			let l:offset = match(getline('.'),
							\ '$\| \|\t\|>',col('.')+l:end )
			let l:name = strpart(getline('.'),col('.')+l:end ,
						\ l:offset - col('.') - l:end)
			echo 'name = '.l:name. ' Tag '.b:tagName
			if l:name == b:tagName
				if b:endtag
					let b:gotoOpenTag = s:SavePos()
				el
					let b:gotoCloseTag = s:SavePos()
				en
				let l:DeleteTag  = "normal d/>/e\<Cr>"
				exe b:gotoCloseTag
				exe l:DeleteTag
				exe b:gotoOpenTag
				exe l:DeleteTag
			en
		en
	en
	exe l:restore
endf
en

" ChangeWholeTag() removes attributes and rename tag                     {{{1
if !exists('*s:ChangeWholeTag')
fun! s:ChangeWholeTag()
	if s:getTagUnderCursor()
		let l:newname = inputdialog('Change whole tag '.b:tagName.' to : ')
		if strlen(l:newname) == 0
			retu
		en
		if s:getMatch(b:tagName) == 0
			exe b:gotoCloseTag
			exe "normal 2lc/>\<Cr>" . l:newname . "\<Esc>"
			exe b:gotoOpenTag
			exe "normal lc/>/\<Cr>" . l:newname . "\<Esc>"
		en
	en
endf
en

" Delete() Removes a tag '<a id="a">blah</a>' --> 'blah'            {{{1
if !exists('*s:Delete')
fun! s:Delete()
	let l:restore = s:SavePos()
	if s:getTagUnderCursor()
		if s:getMatch(b:tagName) == 0
			let l:DeleteTag  = "normal d/>/e\<Cr>"
			exe b:gotoCloseTag
			exe l:DeleteTag
			exe b:gotoOpenTag
			exe l:DeleteTag
		en
	en
endf
en

" DeleteAll() Deletes everything between start of open tag and end of  {{{1
" closing tag
if !exists('*s:DeleteAll')
fun! s:DeleteAll()
	let l:restore = s:SavePos()
	if s:getTagUnderCursor()
		if s:getMatch(b:tagName) == 0
			let l:sentinel = 'XmLSeNtInElXmL'
			let l:len = strlen(l:sentinel)
			let l:rep=&report
			let &report=999999
			exe b:gotoCloseTag
			exe "normal />\<Cr>a".l:sentinel."\<Esc>"
			exe b:gotoOpenTag
			exe "normal \"xd/".l:sentinel."/e-".l:len."\<Cr>"
			exe "normal ".l:len."x"
			let &report= l:rep
		en
	en
endf
en

" FoldTag() Fold the tag under the cursor                           {{{1
if !exists('*s:FoldTag')
fun! s:FoldTag()
	let l:restore = s:SavePos()
	if s:getTagUnderCursor()
	let l:sline = line('.')
		if s:getMatch(b:tagName) == 0
			exe l:sline.','.line('.').'fold'
		en
	el
		exe l:restore
	en
endf
en

" FoldTagAll() Fold all tags of name under the cursor             {{{1
" If no tag under the cursor it asks for a tag
if !exists('*s:FoldTagAll')
fun! s:FoldTagAll()
	let l:restore = s:SavePos()
	if s:getTagUnderCursor()
		let l:tname = b:tagName
	el
		let l:tname = inputdialog('Surround block  with : ')
		if strlen(l:tname) == 0
			exe l:restore
			retu
		en
	en
	normal 1G
	let l:sea = '<'.l:tname.'[^>]*\(\n[^>]*\)*[^/?]*>'
	while search(l:sea ,'W') > 0
		call s:FoldTag()
	endwhile
endf
en


" StartTag() provide the opening tag given the endtag under the cursor  {{{1
if !exists('*s:StartTag')
fun! s:StartTag()
	let l:restore = s:SavePos()
	let l:level = 1
	if col('.') == 1 && getline('.')[col('.')-1] == '<'
	  if s:getTagUnderCursor()
	    if b:endtag == 0
	      let l:level = l:level + 1
	    en
	  en
	  exe l:restore
	en
	while search('<[^?!][^>]\+\(\n[^>]*\)*[^/?]>','W') > 0
		if getline('.')[col('.')] == '/' 
			let l:level = l:level - 1
		el
			let l:level = l:level + 1
		en
		if l:level == 0
			break
		en
	endwhile
	if l:level == 0
	  let l:start = col('.')+1
	  let l:fname = match(getline('.'), '$\| \|\t\|/\|>',l:start)
	  let l:Name = strpart(getline('.'),l:start, l:fname - l:start )
	  exe l:restore
	  exe b:unmapgt
	  exe 'normal i<'. l:Name.">\e"
	  exe b:mapgt
	en
	exe l:restore
endf
en


"
" EndTag() search for open tag and produce endtaf                 {{{1
if !exists('*s:EndTag')
fun! s:EndTag()
	let l:restore = s:SavePos()
	let l:level = -1
	while search('<[^?!][^>]\+\(\n[^>]*\)*[^/?]>','bW') > 0
		if getline('.')[col('.')] == '/' 
			let l:level = l:level - 1
		el
			let l:level = l:level + 1
		en
		if l:level == 0
			break
		en
	endwhile
	if l:level == 0
	  let l:start = col('.')
	  let l:fname = match(getline('.'), '$\| \|\t\|/\|>',l:start)
	  let l:Name = strpart(getline('.'),l:start, l:fname - l:start )
	  exe  l:restore
	  exe 'normal a</'. l:Name.">\e"
	el
	  exe  l:restore
	en
endf
en

" BeforeTag() surrounds the current tag with a new one           {{{1
if !exists('*s:BeforeTag')
fun! s:BeforeTag()
	let l:restore = s:SavePos()
	if s:getTagUnderCursor()
		let l:newname = ('Surround Before Tag '.b:tagName.' with : ')
		if strlen(l:newname == 0
			retu
			exe  l:restore
		en
		if s:getMatch(b:tagName) == 0
			exe b:unmapgt
			exe b:gotoCloseTag
			exe "normal />\<Cr>a\<Cr></" . l:newname . ">\<Esc>"
			let l:To = line('.')
			exe b:gotoOpenTag
			exe 'normal i<' . l:newname . ">\<Cr>\<Esc>"
			let l:rep=&report
			let &report=999999
			exe line('.').','.l:To.'>'
			let &report= l:rep
			exe b:mapgt
		en
	en
endf
en
" AfterTag() surrounds the tags after the current one with new      {{{1
if !exists('*s:AfterTag')
fun! s:AfterTag()
	let l:restore = s:SavePos()
	if s:getTagUnderCursor()
		let l:newname = inputdialog('Surround After Tag '.b:tagName.' with : ')
		if strlen(l:newname) == 0
			retu
			exe  l:restore
		en
		if s:getMatch(b:tagName) == 0
			exe b:unmapgt
			exe b:gotoCloseTag
			exe 'normal i</' . l:newname . ">\<Cr>\<Esc>"
			let l:To = line('.')
			exe b:gotoOpenTag
			exe "normal />\<Cr>a\<Cr><".l:newname.">\<Esc>"
			let l:rep=&report
			let &report=999999
			exe line('.').','.l:To.'>'
			let &report= l:rep
			exe b:mapgt
		en
	en
endf
en

" FormatTag() visual select the block and use gq                    {{{1
if !exists('*s:FormatTag')
fun! s:FormatTag()
	if s:getTagUnderCursor()
		if s:getMatch(b:tagName) == 0
			exe b:gotoCloseTag
			normal hhmh
			exe b:gotoOpenTag
			exe "normal />/e+1\<Cr>v'hgq"
		en
	en
endf
en



" Section: Doc installation {{{1
" Function: s:XmlInstallDocumentation(full_name, revision)              {{{2
"   Install help documentation.
" Arguments:
"   full_name: Full name of this vim plugin script, including path name.
"   revision:  Revision of the vim script. #version# mark in the document file
"              will be replaced with this string with 'v' prefix.
" Return:
"   1 if new document installed, 0 otherwise.
" Note: Cleaned and generalized by guo-peng Wen
"'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''

function! s:XmlInstallDocumentation(full_name, revision)
    " Name of the document path based on the system we use:
    if (has("unix"))
        " On UNIX like system, using forward slash:
        let l:slash_char = '/'
        let l:mkdir_cmd  = ':silent !mkdir -p '
    else
        " On M$ system, use backslash. Also mkdir syntax is different.
        " This should only work on W2K and up.
        let l:slash_char = '\'
        let l:mkdir_cmd  = ':silent !mkdir '
    endif

    let l:doc_path = l:slash_char . 'doc'
    "let l:doc_home = l:slash_char . '.vim' . l:slash_char . 'doc'

    " Figure out document path based on full name of this script:
    let l:vim_plugin_path = fnamemodify(a:full_name, ':h')
    "let l:vim_doc_path   = fnamemodify(a:full_name, ':h:h') . l:doc_path
    let l:vim_doc_path    = matchstr(l:vim_plugin_path, 
            \ '.\{-}\ze\%(\%(ft\)\=plugin\|macros\)') . l:doc_path
    if (!(filewritable(l:vim_doc_path) == 2))
        echomsg "Doc path: " . l:vim_doc_path
        execute l:mkdir_cmd . l:vim_doc_path
        if (!(filewritable(l:vim_doc_path) == 2))
            " Try a default configuration in user home:
            "let l:vim_doc_path = expand("~") . l:doc_home
            let l:vim_doc_path = matchstr(&rtp,
                  \ escape($HOME, '\') .'[/\\]\%(\.vim\|vimfiles\)')
            if (!(filewritable(l:vim_doc_path) == 2))
                execute l:mkdir_cmd . l:vim_doc_path
                if (!(filewritable(l:vim_doc_path) == 2))
                    " Put a warning:
                    echomsg "Unable to open documentation directory"
                    echomsg " type :help add-local-help for more informations."
                    return 0
                endif
            endif
        endif
    endif

    " Exit if we have problem to access the document directory:
    if (!isdirectory(l:vim_plugin_path)
        \ || !isdirectory(l:vim_doc_path)
        \ || filewritable(l:vim_doc_path) != 2)
        return 0
    endif

    " Full name of script and documentation file:
    let l:script_name = 'xml.vim'
    let l:doc_name    = 'xml-plugin.txt'
    let l:plugin_file = l:vim_plugin_path . l:slash_char . l:script_name
    let l:doc_file    = l:vim_doc_path    . l:slash_char . l:doc_name

    " Bail out if document file is still up to date:
    if (filereadable(l:doc_file)  &&
        \ getftime(l:plugin_file) < getftime(l:doc_file))
        return 0
    endif

    " Prepare window position restoring command:
    if (strlen(@%))
        let l:go_back = 'b ' . bufnr("%")
    else
        let l:go_back = 'enew!'
    endif

    " Create a new buffer & read in the plugin file (me):
    setl nomodeline
    exe 'enew!'
    exe 'r ' . l:plugin_file

    setl modeline
    let l:buf = bufnr("%")
    setl noswapfile modifiable

    norm zR
    norm gg

    " Delete from first line to a line starts with
    " === START_DOC
    1,/^=\{3,}\s\+START_DOC\C/ d

    " Delete from a line starts with
    " === END_DOC
    " to the end of the documents:
    /^=\{3,}\s\+END_DOC\C/,$ d

    " Remove fold marks:
    % s/{\{3}[1-9]/    /

    " Add modeline for help doc: the modeline string is mangled intentionally
    " to avoid it be recognized by VIM:
    call append(line('$'), '')
    call append(line('$'), ' v' . 'im:tw=78:ts=8:ft=help:norl:')

    " Replace revision:
    exe "normal :1,5s/#version#/ v" . a:revision . "/\<CR>"

    " Save the help document:
    exe 'w! ' . l:doc_file
    exe l:go_back
    exe 'bw ' . l:buf

    " Build help tags:
    exe 'helptags ' . l:vim_doc_path

    return 1
endfunction
" }}}2

let s:revision=
      \ substitute("$Revision: 1.2 $",'\$\S*: \([.0-9]\+\) \$','\1','')
silent! let s:install_status =
    \ s:XmlInstallDocumentation(expand('<sfile>:p'), s:revision)
if (s:install_status == 1)
    echom expand("<sfile>:t:r") . '-plugin v' . s:revision .
        \ ': Help-documentation installed.'
endif


" Mappings of keys to functions                                      {{{1
nnoremap <buffer> <LocalLeader>5 :call <SID>Match()<Cr>
nnoremap <buffer> <LocalLeader>c :call <SID>Change()<Cr>
nnoremap <buffer> <LocalLeader>C :call <SID>ChangeWholeTag()<Cr>
nnoremap <buffer> <LocalLeader>d :call <SID>Delete()<Cr>
nnoremap <buffer> <LocalLeader>D :call <SID>DeleteAll()<Cr>
nnoremap <buffer> <LocalLeader>e :call <SID>EndTag()<Cr>
nnoremap <buffer> <LocalLeader>f :call <SID>FoldTag()<Cr>
nnoremap <buffer> <LocalLeader>F :call <SID>FoldTagAll()<Cr>
nnoremap <buffer> <LocalLeader>g :call <SID>FormatTag()<Cr>
nnoremap <buffer> <LocalLeader>j :call <SID>Join()<Cr>
nnoremap <buffer> <LocalLeader>O :call <SID>BeforeTag()<Cr>
nnoremap <buffer> <LocalLeader>o :call <SID>AfterTag()<Cr>
nnoremap <buffer> <LocalLeader>s :call <SID>StartTag()<Cr>
vnoremap <buffer> <LocalLeader>v <Esc>:call <SID>BlockTag()<Cr>

setlocal matchpairs+=<:>
inoremap <buffer> > ><Esc>:call <SID>CloseTag()<Cr>
" Vim settings                              {{{1
" vim:tw=78:ts=2:norl:
" vim: set foldmethod=marker  tabstop=2 shiftwidth=2 softtabstop=2 smartindent smarttab  :
"fileencoding=iso-8859-15 
finish

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Section: Documentation content                                          {{{1
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
=== START_DOC
*xml-plugin.txt*  Help edit XML and SGML documents.                  #version#

				   XML Edit {{{2 ~

A filetype plugin to help edit XML and SGML documents.

This script provides some convenience when editing XML (and some SGML
including HTML) formated documents. It allows you to jump to the beginning
or end of the tag block your cursor is in. '%' will jump between '<' and '>'
within the tag your cursor is in. When in insert mode and you finish a tag
(pressing '>') the tag will be completed. If you press '>' twice it will
complete the tag and place the cursor in the middle of the tags on it's own
line (helps with nested tags).

Usage: Place this file into your ftplugin directory. To add html support
Sym-link or copy this file to html.vim in your ftplugin directory. To activte
the script place 'filetype plugin on' in your |.vimrc| file. See |ftplugins|
for more information on this topic.

Known Bugs {{{2 ~

- < & > marks inside of a CDATA section are interpreted as actual XML tags
  even if unmatched.
- The script can not handle leading spaces such as < tag></ tag> it is
  illegal XML syntax and considered very bad form.
- Placing a literal `>' in an attribute value will auto complete despite that
  the start tag isn't finished. This is poor XML anyway you should use
  &gt; instead.

------------------------------------------------------------------------------
							 *xml-plugin-mappings*
Mappings and their functions {{{2 ~

<LocalLeader> is a setting in VIM that depicts a prefix for scripts and
plugins to use. By default this is the backslash key `\'. See |mapleader|
for details.

<LocalLeader>5
        - Jump to the matching tag.

<LocalLeader>c 
        - Rename tag

<LocalLeader>C 
        - Rename tag and remove attributes

<LocalLeader>d
        - Deletes the surrounding tags from the cursor.
            <tag1>outter <tag2>inner text</tag2> text</tag1>
               ^
       Turns to: 
            outter <tag2>inner text</tag2> text
            ^
<LocalLeader>D
        - Deletes the tag and it contents and put it in register x.
            <tag1>outter <tag2>inner text</tag2> text</tag1>
                           ^
       Turns to: 
            <tag1>outter text</tag1>

<LocalLeader>e
        - provide endtag for open tags. Watch where de cursor is
            <para><listitem>list item content
                                            ^
        pressing \e twice produces
            <para><listitem>list item content</para></listitem>

<LocalLeader>f 
        - fold the tag under the cursor
          <para>
            line 1
            line 2
            line 3
          </para>
        \f produces
        +--  5 lines: <para>--------------------------


<LocalLeader>F 
      - all tags of name 'tag' will be fold if there isn't a tag under
        the cursor you will be asked for one.
                  
<LocalLeader>g
      - Format (Vim's gq function) will make a visual block of tag under
	cursor and then format using gq

                  
<LocalLeader>j
      - Joins two the SAME sections together. The sections must
	    be next to each other. 
			<para> This is line 1
			 of a paragraph. </para>
			<para> This is line 2
			^
			 of a paragraph. </para>
		\j produces
			<para> This is line 1
			 of a paragraph. 
			 This is line 2
			 of a paragraph. </para>

<LocalLeader>o 
      - Insert a tag under the current one (like vim o)

        <tag1><tag2><tag3>blaah</tag3></tag2></tag1>
          ^
        \o produces
        <tag1>
            <aftertag><tag2><tag3>blaah</tag3></tag2></aftertag>
        </tag1>
    
<LocalLeader>O 
     - Insert a tag Above the current one

        <tag1><tag2><tag3>blaah</tag3></tag2></tag1>
          ^
    \O produces
        <beforetag>
          <tag1><tag2><tag3>blaah</tag3></tag2></tag1>
        </beforetag>

<LocalLeader>s 
    - Insert an opening tag for an closing tag. 
            list item content</para></listitem>
            ^
        pressing \s twice produces
            <para><listitem>list item content</para></listitem>

<LocalLeader>v   (Visual)
        - Place a custom XML tag to suround the selected text. You
        need to have selected text in visual mode before you can use this
        mapping. See |visual-mode| for details.
        Be careful where you place the marks.
        The top uses insert
        The bottom uses append
        Useful when marking up a text file


=== END_DOC
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" vim:tw=78:ts=2:ft=help:norl:
" vim: set foldmethod=marker  tabstop=2 shiftwidth=2 softtabstop=2 smartindent smarttab  :
"fileencoding=iso-8859-15 

