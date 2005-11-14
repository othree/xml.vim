" Vim script file                                           vim600:fdm=marker:
" FileType:     XML
" Author:       Rene de Zwart <renez (at) lightcon.xs4all.nl> 
" Maintainer:   Rene de Zwart <renez (at) lightcon.xs4all.nl>
" Last Change:  $Date: 2005/11/14 08:36:41 $
" Version:      $Revision: 1.6 $
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
let b:html_mode =(&filetype =~ 'x\+html')&&(!exists ("g:xml_no_html"))
let b:haveAtt = 0
let b:lastTag = ""
let b:lastAtt = ""


							 


" NewFileXML -> Inserts <?xml?> at top of new file.                  {{{1
if !exists("*s:NewFileXML")
function! s:NewFileXML( )
    " Where is g:did_xhtmlcf_inits defined?
    if &filetype == 'xml' || 
			\ (!exists ("g:did_xhtmlcf_inits") &&
			\ exists ("g:xml_use_xhtml") &&
			\ (&filetype =~ 'x\+html')
        if append (0, '<?xml version="1.0"?>')
            normal! G
        endif
    endif
endfunction
endif



" Callback -> Checks for tag callbacks and executes them.            {{{1
if !exists("*s:Callback")
function! s:Callback( xml_tag, isHtml )
    let text = 0
    if a:isHtml == 1 && exists ("*HtmlAttribCallback")
        let text = HtmlAttribCallback (a:xml_tag)
    elseif exists ("*XmlAttribCallback")
        let text = XmlAttribCallback (a:xml_tag)
    endif       
		echo "Callback() ret ". text
    if text != '0'
        execute "normal! i " . text ."\<Esc>l"
    endif
endfunction
endif

" SavePos() saves position  in bufferwide variable                        {{{1
if !exists('*s:SavePos')
fun! s:SavePos()	
	retu 'normal '.line('.').'G0'. (col('.') > 1 ? (col('.')-1).'l' : '')
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
	let b:haveAtt = 0
	
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
	let b:tagName = strpart(getline('.'),col('.') + b:endtag, 
			\ l:fendname - col('.') - b:endtag)
	"Check if this tag has attributes
	let l:line = line('.') | let l:col = col('.') 
	if search(b:tagName . '\(\(\s\|\n\)\+\)*\([^>=]\+=[^>=]\+\)','W') > 0
    if l:line == line('.') && l:col == (col('.')-1)
			let b:haveAtt = 1
		en
	en
	"echo 'line '.line('.').','.l:line.' col '.l:col.','.col('.')
	exe b:gotoOpenTag
	"echo 'Tag ' . b:tagName . ' attri ' . b:haveAtt
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
    normal h
		if s:getTagUnderCursor()
			if b:emptytag == 0 && b:endtag == 0
				exe "normal />>/e\<Cr>s\<Cr>\<Esc>Ox\<Esc>>>$x"
				startinsert!
				retu
			en
		en
	elseif s:getTagUnderCursor()
		if b:emptytag == 0 && b:endtag == 0
			if b:html_mode && b:tagName =~?
				\ '^\(img\|input\|param\|frame\|br\|hr\|meta\|link\|base\|area\)$'
				if b:haveAtt == 0
					call s:Callback (b:tagName, b:html_mode)
				endif
				if exists ("g:xml_use_xhtml")
					exe "normal />\<Cr>i/\<Esc>"
				en
				if (col('.')+1) == col('$') 
					startinsert! 
					retu
				el
					normal l
					startinsert
					retu
				en
			el
				exe "normal />/\<Cr>"
				if b:haveAtt == 0
					call s:Callback (b:tagName, b:html_mode)
				end
				exe "normal a</" . b:tagName . ">\<Esc>F<"
				startinsert
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
	let l:newname = inputdialog('Surround block  with : ',b:lastTag)
	if strlen( l:newname) == 0
		retu
	en
	let b:lastTag =  l:newname
	let l:newatt = inputdialog('Attributes for '.l:newname.' : ',b:lastAtt)
	if strlen(l:newatt)
		let b:lastAtt = l:newatt
	en
	'<
	if  col("'<") > 1
		exe 'normal 0'.(col("'<")-1).'l'
	en
	exe "normal! a\<Cr><".l:newname.' '.l:newatt.">\<Esc>'>"
	if  col("'>") > 1
		exe 'normal 0'.(col("'>")-1).'l'
	en
	exe "normal! a\<Cr></".l:newname.">\<Esc>"
	let l:rep=&report
	let &report=999999
	'<+1,'>>
	let &report= l:rep
endf
en
" Change() Only renames the tag                                         {{{1
if !exists('*s:Change')
fun! s:Change()
	let l:restore = s:SavePos()
	if s:getTagUnderCursor()
		let l:newname = inputdialog('Change tag '.b:tagName.' to : ',b:lastTag) 
		if strlen( l:newname) == 0
			retu
		en
		let b:lastTag =  l:newname
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
		let l:newname = inputdialog('Change whole tag '.b:tagName.' to : ',b:lastTag)
		if strlen(l:newname) == 0
			retu
		en
		let b:lastTag =  l:newname
		let l:newatt = inputdialog('Attributes for '.l:newname.' : ',b:lastAtt)
		if strlen(l:newatt)
			let b:lastAtt = l:newatt
		en
		if s:getMatch(b:tagName) == 0
			exe b:gotoCloseTag
			exe "normal 2lc/>\<Cr>".l:newname."\<Esc>"
			exe b:gotoOpenTag
			exe "normal lc/>/\<Cr>".l:newname.' '.l:newatt."\<Esc>"
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
		let l:tname = inputdialog('Surround block  with : ',b:lastTag)
		if strlen(l:tname) == 0
			exe l:restore
			retu
		en
		let b:lastTag =  l:tname
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

" BeforeTag() surrounds the current tag with a new one                   {{{1
if !exists('*s:BeforeTag')
fun! s:BeforeTag()
	let l:restore = s:SavePos()
	if s:getTagUnderCursor()
		let l:newname =
			\ inputdialog('Surround Before Tag '.b:tagName.' with : ',b:lastTag)
		if strlen(l:newname) == 0
			retu
			exe  l:restore
		en
		let b:lastTag = l:newname
		let l:newatt = inputdialog('Attributes for '.l:newname.' : ',b:lastAtt)
		if strlen(l:newatt)
			let b:lastAtt = l:newatt
		en
		if s:getMatch(b:tagName) == 0
			exe b:gotoCloseTag
			exe "normal! />\<Cr>a\<Cr></" . l:newname . ">\<Esc>"
			let l:To = line('.')
			exe b:gotoOpenTag
			exe 'normal! i<' . l:newname . ' '.l:newatt.">\<Cr>\<Esc>"
			let l:rep=&report
			let &report=999999
			exe line('.').','.l:To.'>'
			let &report= l:rep
		en
	en
endf
en
" AfterTag() surrounds the tags after the current one with new      {{{1
if !exists('*s:AfterTag')
fun! s:AfterTag()
	let l:restore = s:SavePos()
	if s:getTagUnderCursor()
		let l:newname =
			\ inputdialog('Add Tag After '.b:tagName.' with : ',b:lastTag)
		if strlen(l:newname) == 0
			retu
			exe  l:restore
		en
		let b:lastTag = l:newname
		let l:newatt = inputdialog('Attributes for '.l:newname.' : ',b:lastAtt)
		if strlen(l:newatt)
			let b:lastAtt = l:newatt
		en
		if s:getMatch(b:tagName) == 0
			exe b:gotoCloseTag
			exe 'normal! i</' . l:newname . ">\<Cr>\<Esc>"
			let l:To = line('.')
			exe b:gotoOpenTag
			exe "normal! />\<Cr>a\<Cr><".l:newname.' '.l:newatt.">\<Esc>"
			let l:rep=&report
			let &report=999999
			exe line('.').','.l:To.'>'
			let &report= l:rep
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



" Section: Doc installation                                                {{{1
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
    "% s/{\{3}[1-9]/    /

    " Add modeline for help doc: the modeline string is mangled intentionally
    " to avoid it be recognized by VIM:
    call append(line('$'), '')
    call append(line('$'), ' v' . 'im:tw=78:ts=8:fen:fdm=marker:ft=help:norl:')

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
      \ substitute("$Revision: 1.6 $",'\$\S*: \([.0-9]\+\) \$','\1','')
silent! let s:install_status =
    \ s:XmlInstallDocumentation(expand('<sfile>:p'), s:revision)
if (s:install_status == 1)
    echom expand("<sfile>:t:r") . '-plugin v' . s:revision .
        \ ': Help-documentation installed.'
endif


" Mappings of keys to functions                                      {{{1
nnoremap <buffer> <LocalLeader>5 :call <SID>Match()<Cr>
nnoremap <buffer> <LocalLeader>% :call <SID>Match()<Cr>
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

if !exists("g:xml_tag_completion_map")
    inoremap <buffer> > ><Esc>:call <SID>CloseTag()<Cr>
else
    execute "inoremap <buffer> " . g:xml_tag_completion_map . " ><Esc>:call <SID>CloseTag()<Cr>"
endif

augroup xml
    au!
    au BufNewFile * call <SID>NewFileXML()
augroup END


finish

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Section: Documentation content                                          {{{1
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
=== START_DOC
*xml-plugin.txt*  Help edit XML and SGML documents.                  #version#

				   XML Edit  ~

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

Known Bugs {{{1 ~

- < & > marks inside of a CDATA section are interpreted as actual XML tags
  even if unmatched.
- The script can not handle leading spaces such as < tag></ tag> it is
  illegal XML syntax and considered very bad form.
- Placing a literal `>' in an attribute value will auto complete despite that
  the start tag isn't finished. This is poor XML anyway you should use
  &gt; instead.


------------------------------------------------------------------------------
                                                         *xml-plugin-settings*
Options {{{1

(All options must be placed in your |.vimrc| prior to the |ftplugin|
command.)

xml_tag_completion_map
	Use this setting to change the default mapping to auto complete a
	tag. By default typing a literal `>' will cause the tag your editing
	to auto complete; pressing twice will auto nest the tag. By using
	this setting the `>' will be a literal `>' and you must use the new
	mapping to perform auto completion and auto nesting. For example if
	you wanted Control-L to perform auto completion inmstead of typing a
	`>' place the following into your .vimrc: >
            let xml_tag_completion_map = "<C-l>"
<
xml_no_auto_nesting (Not Working!!!!!)
	This turns off the auto nesting feature. After a completion is made
	and another `>' is typed xml-edit automatically will break the tag
	accross multiple lines and indent the curser to make creating nested
	tqags easier. This feature turns it off. Enter the following in your
	.vimrc: >
            let xml_no_auto_nesting = 1
<
xml_use_xhtml
	When editing HTML this will auto close the short tags to make valid
	XML like <hr /> and <br />. Enter the following in your vimrc to
	turn this option on: >
            let xml_use_xhtml = 1
<
xml_no_html
	This turns of the support for HTML specific tags. Place this in your
        .vimrc: >
            let xml_no_html = 1
<
------------------------------------------------------------------------------
                                                        *xml-plugin-mappings*

Mapings and their functions {{{1

Typing '>' will start the tag closing routine.
Typing (Where | means cursor position)
           <para>|
results in
           <para>|</para>

Typing
           <para>>|</para>
results in
           <para>
                |
           </para>
typing a lone '>' and no '<' in front of it accepts the '>' (But having
lone '>' or '<' in a XML file is frown upon except in <!CDATA> sections,
and that will throw of the plugin!!).

Typing </tag> or <tag/> also results in na expanding. So when editing
html type <input .... />

The closing routing also ignores DTD tags '<!,,>' and processing
instructions '<?....?>'. Thus typing these result in no expansion.


<LocalLeader> is a setting in VIM that depicts a prefix for scripts and
plugins to use. By default this is the backslash key `\'. See |mapleader|
for details.

<LocalLeader>5  Jump to the matching tag.                           {{{2
<LocalLeader>%  Jump to the matching tag.   

<LocalLeader>c  Rename tag                                          {{{2

<LocalLeader>C  Rename tag and remove attributes                    {{{2
		Will ask for attributes

<LocalLeader>d  Deletes the surrounding tags from the cursor.       {{{2
            <tag1>outter <tag2>inner text</tag2> text</tag1>
               |
       Turns to: 
            outter <tag2>inner text</tag2> text
            |

<LocalLeader>D  Deletes the tag and it contents                     {{{2
        - and put it in register x.
            <tag1>outter <tag2>inner text</tag2> text</tag1>
                           |
       Turns to: 
            <tag1>outter text</tag1>

<LocalLeader>e  provide endtag for open tags.                       {{{2
        - provide endtag for open tags. Watch where de cursor is
            <para><listitem>list item content
                                            |
        pressing \e twice produces
            <para><listitem>list item content</para></listitem>

<LocalLeader>f  fold the tag under the cursor                       {{{2
          <para>
            line 1
            line 2
            line 3
          </para>
        \f produces
        +--  5 lines: <para>--------------------------


<LocalLeader>F  all tags of name 'tag' will be fold.                {{{2
      - If there isn't a tag under
        the cursor you will be asked for one.
                  
<LocalLeader>g  Format (Vim's gq function)                          {{{2
			- will make a visual block of tag under cursor and then format using gq

                  
<LocalLeader>j  Joins two the SAME sections together.               {{{2
      -  The sections must be next to each other. 
			<para> This is line 1
			 of a paragraph. </para>
			<para> This is line 2
			|
			 of a paragraph. </para>
		\j produces
			<para> This is line 1
			 of a paragraph. 
			 This is line 2
			 of a paragraph. </para>

<LocalLeader>o  Insert a tag under the current one (like vim o)     {{{2
				You are asked for tag and attributes.

        <tag1><tag2><tag3>blaah</tag3></tag2></tag1>
          |
        \o produces
        <tag1>
            <aftertag><tag2><tag3>blaah</tag3></tag2></aftertag>
        </tag1>
    
<LocalLeader>O  Insert a tag Above the current one (like vim O)     {{{2
				You are asked for tag and attributes.
        <tag1><tag2><tag3>blaah</tag3></tag2></tag1>
          |
    \O produces
        <beforetag>
          <tag1><tag2><tag3>blaah</tag3></tag2></tag1>
        </beforetag>

<LocalLeader>s  Insert an opening tag for an closing tag.           {{{2
            list item content</para></listitem>
            |
        pressing \s twice produces
            <para><listitem>list item content</para></listitem>

<LocalLeader>v  Visual) Place a tag around the selected text.       {{{2
        - You are asked for tag and attributes. You
        need to have selected text in visual mode before you can use this
        mapping. See |visual-mode| for details.
        Be careful where you place the marks.
        The top uses append
        The bottom uses append
        Useful when marking up a text file


=== END_DOC
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Vim settingѕ                                                            {{{1
" vim:tw=78:ts=2:ft=help:norl:
" vim: set foldmethod=marker  tabstop=2 shiftwidth=2 softtabstop=2 smartindent smarttab  :
"fileencoding=utf-8

