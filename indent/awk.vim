" Vim indent file
" Language:        AWK Script
" Maintainer:      Clavelito <maromomo@hotmail.com>
" Id:              $Date: 2013-01-03 20:30:29+09 $
"                  $Revision: 1.14 $


if exists("b:did_indent")
  finish
endif
let b:did_indent = 1

setlocal indentexpr=GetAwkIndent()
setlocal indentkeys+=0=while
setlocal indentkeys-=:,0#

if exists("*GetAwkIndent")
  finish
endif

let s:cpo_save = &cpo
set cpo&vim

function GetAwkIndent()
  let lnum = prevnonblank(v:lnum - 1)
  if lnum == 0
    return 0
  endif

  let ind = indent(lnum)
  let line = getline(lnum)
  let pnum = prevnonblank(lnum - 1)
  let pline = getline(pnum)
  let cline = getline(v:lnum)

  let ind = s:BackSlashLineIndent(pline, line, ind)
  if line =~ '\\$'
    return ind
  endif

  let [line, lnum] = s:JoinBackSlashLine(line, lnum, 0)
  let [pline, pnum] = s:JoinBackSlashLine(line, lnum, 1)
  let ind = s:MorePrevLineIndent(pline, pnum, line, lnum, ind)
  let ind = s:PrevLineIndent(line, lnum, ind)
  let ind = s:CurrentLineIndent(cline, line, lnum, pline, pnum, ind)

  return ind
endfunction

function s:BackSlashLineIndent(pline, line, ind)
  let ind = a:ind
  if a:pline !~ '\\$' && a:line =~ '\\$'
    let ind = ind + &sw
  elseif a:pline =~ '\\$' && a:line !~ '\\$'
    let ind = ind - &sw
  endif
  if a:line =~ '^\s*\%(if\|else\s\+if\|for\|while\|function\)\>'
        \ && a:line =~ '\\$'
    let ind = ind + &sw
  endif

  return ind
endfunction

function s:MorePrevLineIndent(pline, pnum, line, lnum, ind)
  let ind = a:ind
  let [pline, pnum] = s:PreMorePrevLine(a:pline, a:pnum, a:line, a:lnum)
  while pline =~ '^\s*\%(if\|else\s\+if\|for\|while\)\s*(.*)\s*\%(#.*\)\=$'
        \ || pline =~ '^\s*}\=\s*else\>\s*\%(#.*\)\=$'
        \ || pline =~ '^\s*do\>\s*\%(#.*\)\=$'
        \ || pline =~ '^\s*}\s*\%(else\s\+if\|while\)\s*(.*)\s*\%(#.*\)\=$'
    let ind = indent(pnum)
    if pline =~ '^\s*}\=\s*else\>'
      let [pline, pnum] = s:GetIfLine(pline, pnum)
    elseif pline =~ '^\s*}\=\s*while\>'
      let [pline, pnum] = s:GetDoLine(pline, pnum, pnum)
    endif
    let [pline, pnum] = s:JoinBackSlashLine(pline, pnum, 1)
  endwhile

  return ind
endfunction

function s:PrevLineIndent(line, lnum, ind)
  let ind = a:ind
  if a:line =~ '^\s*\%(if\|else\s\+if\|for\)\s*(.*)\s*\%(#.*\)\=$'
        \ || a:line =~ '^\s*\%(else\|do\)\s*\%(#.*\)\=$'
        \ || a:line =~ '^\s*}\s*else\>'
        \ || a:line =~ '{\s*\%(.*\)\=\%(#.*\)\=$'
        \ && s:NoClosedBracePair(a:lnum)
        \ || a:line =~ '^\s*while\s*(.*)\s*\%(#.*\)\=$'
        \ && get(s:GetDoLine(a:line, a:lnum, a:lnum), 1) == a:lnum
    let ind = indent(a:lnum) + &sw
  elseif a:line =~ '^\s*function\s\+\S\+\s*(.*\\.*)\s*\%(#.*\)\=$'
    let ind = indent(a:lnum)
  elseif a:line =~ '\S\+\s*}\s*\%(#.*\)\=$' && indent(a:lnum) == ind
    let snum = get(s:GetBracePairLine(a:line, a:lnum), 1)
    if snum > 0 && snum != a:lnum
      let ind = indent(snum)
    endif
  endif

  return ind
endfunction

function s:CurrentLineIndent(cline, line, lnum, pline, pnum, ind)
  let ind = a:ind
  if a:cline =~ '^\s*}'
    let ind = indent(get(s:GetBracePairLine(a:cline, v:lnum), 1))
  elseif a:cline =~ '^\s*{\s*\%(#.*\)\=$'
        \ && (a:line
        \ =~ '^\s*\%(if\|else\s\+if\|while\|for\)\s*(.*)\s*\%(#.*\)\=$'
        \ || a:line =~ '^\s*\%(else\|do\)\s*\%(#.*\)\=$')
    let ind = ind - &sw
  elseif a:cline =~ '^\s*while\>'
    let snum = get(s:GetDoLine(a:line, a:lnum, v:lnum), 1)
    if snum != a:lnum
      let ind = indent(snum)
    endif
  elseif a:cline =~ '^\s*else\>'
    let ind = s:CurrentElseIndent(a:line, a:lnum, a:pline, a:pnum)
  elseif a:cline =~ '^\s*#'
    let cind = indent(v:lnum)
    if cind < ind
      let ind = cind
    endif
  endif

  return ind
endfunction

function s:JoinBackSlashLine(line, lnum, prev)
  if a:prev
    let lnum = prevnonblank(a:lnum - 1)
    let line = getline(lnum)
  else
    let line = a:line
    let lnum = a:lnum
  endif
  let [line, lnum] = s:SkipCommentLine(line, lnum)
  while getline(prevnonblank(lnum - 1)) =~ '\\$'
    let lnum = prevnonblank(lnum - 1)
    let line = getline(lnum) . line
  endwhile

  return [line, lnum]
endfunction

function s:SkipCommentLine(line, lnum)
  let line = a:line
  let lnum = a:lnum
  while line =~ '^\s*#'
    let lnum = prevnonblank(lnum - 1)
    let line = getline(lnum)
  endwhile

  return [line, lnum]
endfunction

function s:PreMorePrevLine(pline, pnum, line, lnum)
  let lnum = a:lnum
  if a:line =~ '^\s*}\=\s*while\>'
    let [line, lnum] = s:GetDoLine(a:line, a:lnum, a:lnum)
  elseif a:line =~ '\s*}\=\s*else\>'
    let [line, lnum] = s:GetIfLine(a:line, a:lnum)
  elseif a:line =~ '^\s*}' || a:line =~ '\S\+\s*}\s*\%(#.*\)\=$'
    let [line, lnum] = s:GetStartBraceLine(a:line, a:lnum)
  endif
  if lnum != a:lnum
    let [pline, pnum] = s:JoinBackSlashLine(line, lnum, 1)
  else
    let pline = a:pline
    let pnum = a:pnum
  endif

  return [pline, pnum]
endfunction

function s:GetStartBraceLine(line, lnum)
  let line = a:line
  let lnum = a:lnum
  let [line, lnum] = s:GetBracePairLine(line, lnum)
  if line =~ '^\s*}\=\s*else\>'
    let [line, lnum] = s:GetIfLine(line, lnum)
  endif

  return [line, lnum]
endfunction

function s:GetBracePairLine(line, lnum)
  let save_cursor = getpos(".")
  call search('}', 'bW', a:lnum)
  while s:InsideAwkItemOrCommentStr()
    call search('}', 'bW', a:lnum)
  endwhile
  let lnum = searchpair('{', '', '}', 'bW', 's:InsideAwkItemOrCommentStr()')
  call setpos('.', save_cursor)
  if lnum > 0
    let line = getline(lnum)
    let pnum = prevnonblank(lnum - 1)
    if line =~ '^\s*{\s*\%(#.*\)\=$' && indent(lnum)
      let lnum = pnum
      let line = getline(lnum)
      let pnum = prevnonblank(lnum - 1)
    endif
    while pnum > 0 && getline(pnum) =~ '\\$'
      let lnum = pnum
      let line = getline(lnum) . line
      let pnum = prevnonblank(pnum - 1)
    endwhile
  else
    let line = a:line
    let lnum = a:lnum
  endif

  return [line, lnum]
endfunction

function s:GetIfLine(line, lnum)
  let save_cursor = getpos(".")
  call cursor(a:lnum, 1)
  let lnum = searchpair('\<if\>', '', '\<else\>', 'bW',
        \ 'getline(".") =~ "else\\s\\+if" ' .
        \ '|| indent(line(".")) > indent(a:lnum) ' .
        \ '|| s:InsideAwkItemOrCommentStr()')
  call setpos('.', save_cursor)
  if lnum > 0
    let line = getline(lnum)
    let nnum = lnum
    while line =~ '\\$'
      let nnum = nextnonblank(nnum - 1)
      let line = line . getline(nnum)
    endwhile
  else
    let line = a:line
    let lnum = a:lnum
  endif

  return [line, lnum]
endfunction

function s:GetDoLine(line, lnum, snum)
  let save_cursor = getpos(".")
  call cursor(a:lnum, 1)
  let lnum = s:SearchDoLoop(a:snum)
  call setpos('.', save_cursor)
  if lnum > 0
    let line = getline(lnum)
  else
    let line = a:line
    let lnum = a:lnum
  endif

  return [line, lnum]
endfunction

function s:SearchDoLoop(snum)
  let lnum = 0
  let onum = 0
  while search('^\s*do\>', 'ebW')
    let save_cursor = getpos(".")
    let lnum = searchpair('\s*\<do\>', '', '\s*}\=\s*while\>', 'W',
          \ 'indent(line(".")) > indent(get(save_cursor, 1)) ' .
          \ '|| s:InsideAwkItemOrCommentStr()', a:snum)
    if lnum < onum || lnum < 1
      let lnum = 0
      break
    elseif lnum == a:snum
      let lnum = get(save_cursor, 1)
      break
    else
      let onum = lnum
      let lnum = 0
    endif
    call setpos('.', save_cursor)
  endwhile

  return lnum
endfunction

function s:NoClosedBracePair(lnum)
  let snum = 0
  let enum = 0
  let save_cursor = getpos(".")
  call cursor(a:lnum, 1)
  let snum = search('{\s*\%(.*\)\=\%(#.*\)\=$', 'cW', a:lnum)
  while s:InsideAwkItemOrCommentStr() && snum
    let snum = search('{', 'W', snum)
  endwhile
  if snum
    let enum = searchpair('{', '', '}', 'W', 's:InsideAwkItemOrCommentStr()')
  endif
  call setpos('.', save_cursor)

  if snum == enum
    return 0
  else
    return 1
  endif
endfunction

function s:CurrentElseIndent(line, lnum, pline, pnum)
  if a:line =~ '^\s*\%(if\|else\s\+if\)\s*(.*)\s*\%([^#].*\)'
        \ && a:line !~ '{\s*\%(#.*\)\=$'
    let ind = indent(a:lnum)
  elseif a:line =~ '^\s*else\>\s\+\%([^#].*\)' && a:line !~ '{\s*\%(#.*\)\=$'
    let ind = indent(a:lnum) - &sw
  elseif a:pline =~ '^\s*\%(if\|}\=\s*else\s\+if\)\s*(.*)\s*\%(#.*\)\=$'
    let ind = indent(a:pnum)
  elseif a:pline =~ '^\s*\%(}\s*\)\=else\>\s*\%(#.*\)\=$'
    let ind = indent(a:pnum) - &sw
  else
    let ind = indent(get(s:GetIfLine(a:line, a:lnum), 1))
  endif

  return ind
endfunction

function s:InsideAwkItemOrCommentStr()
  let line = getline(line("."))
  let cnum = col(".")
  let sum = 0
  let slash = 0
  let dquote = 0
  while sum < cnum
    let str = strpart(line, sum, 1)
    if str =~ '#' && !slash && !dquote
      return 1
    elseif str =~ '/' && !slash && !dquote
      let slash = 1
    elseif str =~ '/' && slash && laststr !~ '\\'
      let slash = 0
    elseif str =~ '"' && !dquote && !slash
      let dquote = 1
    elseif str =~ '"' && dquote && laststr !~ '\\'
      let dquote = 0
    endif
    let laststr = str
    let sum += 1
  endwhile

  if slash || dquote
    return 1
  else
    return 0
  endif
endfunction

let &cpo = s:cpo_save
unlet s:cpo_save

" vim: set sts=2 sw=2 expandtab:
