" AUTHOR:     fuyg
" Maintainer: fuyg<FuDesign2008@163.com>
" VERSION:    1.0.0



let s:translator_engines = {
    \ 'youdao': 'http://fanyi.youdao.com/openapi.do?keyfrom=FuDesign2008&key=1676087853&type=data&doctype=json&version=1.1&q=<QUERY>',
    \ 'baidu': 'http://openapi.baidu.com/public/2.0/bmt/translate?client_id=K4GwmBaiSfbCd0a6OfOCpHcd&q=<QUERY>&from=auto&to=auto'
    \}

let s:engine = ''


if exists('g:translator_engine')
    if stridx(g:translator_engine, '<QUERY>') > -1
        let s:engine = g:translator_engine
    elseif has_key(s:translator_engines, g:translator_engine)
        let s:engine = s:translator_engines[g:translator_engine]
    endif
endif

if strlen(s:engine) == 0
    let s:engine = s:translator_engines['youdao']
endif


let s:result_cache = {}

let s:root_path = expand('<sfile>:p:h')

"
function! s:joinPath(...)
  let paths = join(a:000,'/')
  let root = s:root_path
  return root.'/'.paths
endfunction



function! s:TranslateComplete(A,L,C) abort
    let line = getline('.')
    return line . ''
endfunction

function s:ShowTranslation(query, result)
    let querylen = len(a:query)
    let winWidth = winwidth(0) - 4
    if querylen > winWidth
       let querylen = winWidth
    endif
    let splitter = repeat('=', querylen) . ';'
    let lines = split(a:query . ';'.splitter . a:result, ';')
    if &wrap
        let lineCounter = 0
        for lineItem in lines
            let lineCounter = lineCounter + (strlen(lineItem) / winWidth) + 1
        endfor
    else
        let lineCounter = len(lines)
    endif
    " let result window heigher 1 than contents
    let lineCounter = lineCounter + 1

    let win_number = bufwinnr('^__Translation_Result__$')
    "reuse buffer window/view
    "@see http://stackoverflow.com/questions/5303417/how-can-i-reuse-the-same-vim-window-buffer-for-command-output-like-the-help-wi
    if win_number >= 0
        execute win_number . 'wincmd w'
        execute 'resize '. lineCounter
    else
        " Open a new split and set it up.
        execute 'belowright '. lineCounter .'split ++bad=drop __Translation_Result__'
        setlocal buftype=nofile bufhidden=wipe nobuflisted noswapfile nowrap
    endif

    "append translation result
    normal! ggdG
    call append(0, lines)
    "goto first line
    execute ':1'
endfunction

"global translator function
"@return String
function! s:Translate(query)
    "invalid query
    if !strlen(a:query)
        return
    endif
    "if result is in cache
    if has_key(s:result_cache, a:query)
        let output = s:result_cache[a:query]
        call s:ShowTranslation(a:query, output)
        return output
    endif
    "use nodejs to request for translation
    let output = s:NodeJSTranslate(a:query)
    "remove ^@
    let output = substitute(output, '[\r\n]', '', 'g')
    "caching translation if
    "1. the result is not error
    "and 2. the output has more than 6 characters
    if stridx(output, 'ERROR') != 0 && strlen(output) > 6
        let s:result_cache[a:query] = output
    endif
    call s:ShowTranslation(a:query, output)
    return output
endfunction




"sub translator is implemented on nodejs
"@return String
function! s:NodeJSTranslate(query)
    let output = ''
    let filePath = s:joinPath('js', 'translator.js')
    "
    if !filereadable(filePath)
        return
    endif
    if strlen(a:query)
        let cmd = 'node "'. filePath . '" "' . s:engine . '" "' . a:query . '"'
        let output = system(cmd)
    endif
    return output
endfunction


"@visual mode
"translate block text
function s:TranslateBlock() abort
  let start_v = col("'<") - 1
  let end_v = col("'>")
  let lines = getline("'<","'>")

  if len(lines) > 1
    let lines[0] = strpart(lines[0],start_v)
    let lines[-1] = strpart(lines[-1],0,end_v)
    let str = join(lines)
  else
    let str = strpart(lines[0], start_v, end_v-start_v)
  endif
  call s:Translate(str)
endfunction

function s:TranslateWordUnderCursor()
    let word = expand('<cword>')
    if strlen(word)
        call s:Translate(word)
    endif
endfunction


if !exists(":Tran")
    command! -nargs=* -complet=custom,s:TranslateComplete Tran call s:Translate('<args>')
    command! TranCursor call s:TranslateWordUnderCursor()
    command! TranBlock call s:TranslateBlock()
endif

