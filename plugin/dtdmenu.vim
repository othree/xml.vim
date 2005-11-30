" Vim script file                                                       {{{1
"                                                         vim600:fdm=marker:
" FileType:     Vim script For DTD
" Dependency:   ~/.vim/ftplugin/xml.vim for expansion of tags.
"               OR DO NOT USE SKELETONS!!!!
" Author:       Rene de Zwart <renez (at) lightcon.xs4all.nl> 
" Maintainer:   Rene de Zwart <renez (at) lightcon.xs4all.nl>
" Last Change:  $Date: 2005/11/21 07:36:53 $
" Version:      $Revision: 1.1 $
" 
" Licence:      This program is free software; you can redistribute it
"               and/or modify it under the terms of the GNU General Public
"               License.  See http://www.gnu.org/copyleft/gpl.txt
" Credits:      Christian J. Robinson && Doug Renze (script 453)
"               for the InsertDtd Function {HTMLtemplate() in their code} 

" dtd data {{{1
" dtd implementation details {{{2
" number of dtds s:dtd_count
" a dtd has a dtd(dtdid,title,decl,#roots,filetype)
" a rootelement(dtdid,elemid,root,skel)
" dtd(1,
" 	"docbk xml 4.4",
" 	'<!DOCTYPE book PUBLIC "-//OASIS//DTD DocBook XML V4.4//EN"
" 	     "http://www.oasis-open.org/docbook/xml/4.4/docbookx.dtd">,
" 	3,
" 	"xml"
")
"rootelem(1,1,"book",skel)
"rootelem(1,2,"article",skel)
"rootelem(1,3,"manpage",skel)
" 
" Since vim doesn't have structures I solved it by curly braces
" variables.
" {table}_{tableid}_{column}
" {table}_{tableid}_{childid}_{column}
"
" Conditions
"         1) contents dtd_{dtdid}_1_root must be the same as root in decl,
"            in the above case it is book, 
"         2) user is responsible for setting 
"            - s:dtd_count to the number of dtd there are. failure
"              results in script error messages
"            - s:dtd_{dtdid}_root to the number of elements and
"              subsequently filling dtd_{dtdid}_{sequence}_root
"            - no hole inthe numering 1,2, 4,5 (3 missing results in
"              errors) either in dtd or rootelements|
"         3) contents dtd_{dtdid}_filetype must be linked to xml.vim.
"            Otherwise no expansion of tags!!
"dtd tables    {{{2
let s:dtd_1_title = "docbk xml 4.4"
let s:dtd_1_decl = 
	\ '<!DOCTYPE book PUBLIC "-//OASIS//DTD DocBook XML V4.4//EN"'."\n\t".
	\ '"http://www.oasis-open.org/docbook/xml/4.4/docbookx.dtd">'
let s:dtd_1_root =3
let s:dtd_1_1_root ="book"
let s:dtd_1_1_skel = "<book>><bookinfo>><title>\emao<author>>".
	\ "<firstname>\eo<surname>\ejo<address>><email>\ejo<copyright>>".
	\"<year>\eo<holder>\ejo<revhistory>>\e"
let s:dtd_1_2_root ="article"
let s:dtd_1_3_root ="manpage"
let s:dtd_1_filetype = "xml"
let s:dtd_2_title = "docbk xml 4.3"
let s:dtd_2_decl = 
	\ '<!DOCTYPE book PUBLIC "-//OASIS//DTD DocBook XML V4.3//EN"'."\n\t".
	\ '"http://www.oasis-open.org/docbook/xml/4.3/docbookx.dtd">'
let s:dtd_2_root =3
let s:dtd_2_1_root = "book"
let s:dtd_2_1_skel = s:dtd_1_1_skel
let s:dtd_2_2_root = "article"
let s:dtd_2_3_root = "manpage"
let s:dtd_2_filetype = "xml"

let s:dtd_3_title = "HTML strict 4.01"
let s:dtd_3_decl = 
	\ '<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN"'."\n\t".
	\ '"http://www.w3.org/TR/html4/strict.dtd">'
let s:dtd_3_root =1
let s:dtd_3_1_root = "HTML"
let s:dtd_3_1_skel = 
	\"<html>><head>><title>\eo".
	\"<META NAME=\"Generator\" CONTENT=\"vim (Vi IMproved editor)\"/>".
	\"\n<META NAME=\"Author\" CONTENT=\"YourNameHere\"/>".
	\"\e/<\/head>\ro<body>><H1 align=\"center\">\e"
let s:dtd_3_filetype = "html"

let s:dtd_4_title = "HTML transitional 4.01"
let s:dtd_4_decl = 
	\'<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN"'."\n\t".
    \'"http://www.w3.org/TR/html4/loose.dtd">'
let s:dtd_4_root =1
let s:dtd_4_1_root = "HTML"
let s:dtd_4_1_skel = s:dtd_3_1_skel
let s:dtd_4_filetype = "html"

let s:dtd_5_title = "HTML frameset 4.01"
let s:dtd_5_decl = 
	\ '<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Frameset//EN"'."\n\t".
	\ '"http://www.w3.org/TR/html4/frameset.dtd">'
let s:dtd_5_root =1
let s:dtd_5_1_root = "HTML"
let s:dtd_5_1_skel = s:dtd_3_1_skel
let s:dtd_5_filetype = "html"

let s:dtd_6_title = "XHTML 1.1"
let s:dtd_6_decl = 
	\ '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN"'."\n\t".
	\ '"http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">'
let s:dtd_6_root =1
let s:dtd_6_1_root = "html"
let s:dtd_6_1_skel = s:dtd_3_1_skel
let s:dtd_6_filetype = "xhtml"

"dtd count {{{2
let s:dtd_count = 6


"dtd functions   {{{2

"dtdMenu   Create the Dtd menu  {{{3
if !exists('*s:dtdMenu')
fun! s:dtdMenu()
	let l:i = 0
	while l:i < s:dtd_count
		let l:i = l:i + 1
		exe '1010 amenu Dtd.insert\ dtd.'.
		\substitute(s:dtd_{l:i}_title,'[ .]','\\&','g').
		\' :call <SID>insertDtd('.l:i.")<Cr>"
	endw
endf
en

"insertDtd   DTD Driver function {{{3
if !exists('*s:insertDtd')
fun! s:insertDtd(i)
  if (line('$') == 1 && getline(1) == "")
    return s:doInsertDtd(a:i)
  else
    let YesNoOverwrite = confirm("Non-empty file.\nInsert dtd anyway?", "&Yes\n&No\n&Overwrite", 2, "W")
    if (YesNoOverwrite == 1)
      return s:doInsertDtd(a:i)
    elseif (YesNoOverwrite == 3)
      execute "1,$delete"
      return s:doInsertDtd(a:i)
    endif
  endif
endf
en

"doInsertDtd   workhorse  function {{{3
if !exists('*s:doInsertDtd')
fun! s:doInsertDtd(i)
	let l:str = s:dtd_{a:i}_{1}_root
	let l:i = 1
	while l:i < s:dtd_{a:i}_root
		let l:i = l:i + 1
		let l:str = l:str."\n".s:dtd_{a:i}_{l:i}_root
	endw
	if l:i > 1
		let l:i = confirm('What root element do you want to use',l:str)
	end
	set fileencoding=utf-8
	exe  "setlocal filetype=".s:dtd_{a:i}_filetype
	syntax enable 
	exe 'normal 1GI<?xml version="1.0" encoding="UTF-8" ?>'."\r".
		\ substitute(s:dtd_{a:i}_decl,
		\ s:dtd_{a:i}_{1}_root,s:dtd_{a:i}_{l:i}_root,"")
	if exists("s:dtd_{a:i}_{l:i}_skel")
		if confirm('would you like to add a skeleton',"Yes\nNo") == 1
			exe "normal o\eI".s:dtd_{a:i}_{l:i}_skel
		en
	en
endf
en

" Build menu {{{1
call  s:dtdMenu()
