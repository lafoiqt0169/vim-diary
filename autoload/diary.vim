if !exists("g:diary_action")
  let g:diary_action = "diary#diary"
endif
if !exists("g:diary_sign")
  let g:diary_sign = "diary#sign"
endif
if !exists("g:diary_mark")
 \|| (g:diary_mark != 'left'
 \&& g:diary_mark != 'left-fit'
 \&& g:diary_mark != 'right')
  let g:diary_mark = 'left'
endif
if !exists("g:diary_navi")
 \|| (g:diary_navi != 'top'
 \&& g:diary_navi != 'bottom'
 \&& g:diary_navi != 'both'
 \&& g:diary_navi != '')
  let g:diary_navi = 'top'
endif
if !exists("g:diary_navi_label")
  let g:diary_navi_label = "Prev,Today,Next"
endif
if !exists("g:diary_dir")
  let g:diary_dir = "~/diary"
endif
if !exists("g:diary_focus_today")
  let g:diary_focus_today = 0
endif
if !exists("g:diary_datetime")
 \|| (g:diary_datetime != ''
 \&& g:diary_datetime != 'title'
 \&& g:diary_datetime != 'statusline')
  let g:diary_datetime = 'title'
endif
if !exists("g:diary_options")
  let g:diary_options = "fdc=0 nonu"
  if has("+relativenumber")
    let g:diary_options .= " nornu"
  endif
endif
if !exists("g:diary_filetype")
  let g:diary_filetype = "markdown"
endif
if !exists("g:diary_dir_extension")
    let g:diary_dir_extension = ".md"
endif

"*****************************************************************
"* Default Diary key bindings
"*****************************************************************
let s:diary_keys = {
\ 'close'           : 'q',
\ 'do_action'       : '<CR>',
\ 'goto_today'      : 't',
\ 'show_help'       : '?',
\ 'redisplay'       : 'r',
\ 'goto_next_month' : '<RIGHT>',
\ 'goto_prev_month' : '<LEFT>',
\ 'goto_next_year'  : '<UP>',
\ 'goto_prev_year'  : '<DOWN>',
\}

if exists("g:diary_keys") && type(g:diary_keys) == 4
  let s:diary_keys = extend(s:diary_keys, g:diary_keys)
end

"*****************************************************************
"* DiaryClose : close the diary
"*----------------------------------------------------------------
"*****************************************************************
function! diary#close(...)
  bw!
endfunction

"*****************************************************************
"* DiaryDoAction : call the action handler function
"*----------------------------------------------------------------
"*****************************************************************
function! diary#action(...)
  " for navi
  if exists('g:diary_navi')
    let navi = (a:0 > 0)? a:1 : expand("<cWORD>")
    let curl = line(".")
    let curp = getpos(".")
    if navi == '<' . get(split(g:diary_navi_label, ','), 0, '')
      if b:DiaryMonth > 1
        call diary#show(b:DiaryDir, b:DiaryYear, b:DiaryMonth-1)
      else
        call diary#show(b:DiaryDir, b:DiaryYear-1, 12)
      endif
    elseif navi == get(split(g:diary_navi_label, ','), 2, '') . '>'
      if b:DiaryMonth < 12
        call diary#show(b:DiaryDir, b:DiaryYear, b:DiaryMonth+1)
      else
        call diary#show(b:DiaryDir, b:DiaryYear+1, 1)
      endif
    elseif navi == get(split(g:diary_navi_label, ','), 1, '')
      call diary#show(b:DiaryDir)
      if exists('g:diary_today')
        exe "call " . g:diary_today . "()"
      endif
    elseif navi == 'NextYear'
      call diary#show(b:DiaryDir, b:DiaryYear + 1, b:DiaryMonth)
      call setpos('.', curp)
      return
    elseif navi == 'PrevYear'
      call diary#show(b:DiaryDir, b:DiaryYear - 1, b:DiaryMonth)
      call setpos('.', curp)
      return
    else
      let navi = ''
    endif
    if navi != ''
      if g:diary_focus_today == 1 && search("\*","w") > 0
        silent execute "normal! gg/\*\<cr>"
        return
      else
        if curl < line('$')/2
          silent execute "normal! gg0/".navi."\<cr>"
        else
          silent execute "normal! G$?".navi."\<cr>"
        endif
        return
      endif
    endif
  endif

  " if no action defined return
  if !exists("g:diary_action") || g:diary_action == ""
    return
  endif

  if b:DiaryDir == 0 || b:DiaryDir == 3
    let dir = 'V'
    let cnr = 1
    let week = ((col(".")+1) / 3) - 1
  elseif b:DiaryDir == 1
    let dir = 'H'
    if exists('g:diary_weeknm')
      let cnr = col('.') - (col('.')%(24+5)) + 1
    else
      let cnr = col('.') - (col('.')%(24)) + 1
    endif
    let week = ((col(".") - cnr - 1 + cnr/49) / 3)
  elseif b:DiaryDir == 2
    let dir = 'T'
    let cnr = 1
    let week = ((col(".")+1) / 3) - 1
  endif
  let lnr = 1
  let hdr = 1
  while 1
    if lnr > line('.')
      break
    endif
    let sline = getline(lnr)
    if sline =~ '^\s*$'
      let hdr = lnr + 1
    endif
    let lnr = lnr + 1
  endwhile
  let lnr = line('.')
  if(exists('g:diary_monday'))
      let week = week + 1
  elseif(week == 0)
      let week = 7
  endif
  if lnr-hdr < 2
    return
  endif
  let sline = substitute(strpart(getline(hdr),cnr,21),'\s*\(.*\)\s*','\1','')
  if b:DiaryDir != 2
    if (col(".")-cnr) > 21
      return
    endif

    " extract day
    if g:diary_mark == 'right' && col('.') > 1
      normal! h
      let day = matchstr(expand("<cword>"), '[^0].*')
      normal! l
    else
      let day = matchstr(expand("<cword>"), '[^0].*')
    endif
  else
    let c = col('.')
    let day = ''
    let lnum = line('.')
    let cursorchar = getline(lnum)[col('.') - 1]
    while day == '' && lnum > 2 && cursorchar != '-' && cursorchar != '+'
      let day = matchstr(getline(lnum), '^.*|\zs[^|]\{-}\%'.c.'c[^|]\{-}\ze|.*$')
      let day = matchstr(day, '\d\+')
      let lnum = lnum - 1
      let cursorchar = getline(lnum)[col('.') - 1]
    endwhile
  endif
  if day == 0
    return
  endif
  " extract year and month
  if exists('g:diary_erafmt') && g:diary_erafmt !~ "^\s*$"
    let year = matchstr(substitute(sline, '/.*', '', ''), '\d\+')
    let month = matchstr(substitute(sline, '.*/\(\d\d\=\).*', '\1', ""), '[^0].*')
    if g:diary_erafmt =~ '.*,[+-]*\d\+'
      let veranum = substitute(g:diary_erafmt,'.*,\([+-]*\d\+\)','\1','')
      if year-veranum > 0
        let year = year-veranum
      endif
    endif
  else
    let year  = matchstr(substitute(sline, '/.*', '', ''), '[^0].*')
    let month = matchstr(substitute(sline, '\d*/\(\d\d\=\).*', '\1', ""), '[^0].*')
  endif
  " call the action function
  exe "call " . g:diary_action . "(day, month, year, week, dir)"
endfunc

"*****************************************************************
"* Diary : build diary
"*----------------------------------------------------------------
"*   a1 : direction
"*   a2 : month(if given a3, it's year)
"*   a3 : if given, it's month
"*****************************************************************
function! diary#show(...)

  "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  "+++ ready for build
  "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  " remember today
  " divide strftime('%d') by 1 so as to get "1,2,3 .. 9" instead of "01, 02, 03 .. 09"
  let vtoday = strftime('%Y').strftime('%m').strftime('%d')

  " get arguments
  if a:0 == 0
    let dir = 0
    let vyear = strftime('%Y')
    let vmnth = matchstr(strftime('%m'), '[^0].*')
  elseif a:0 == 1
    let dir = a:1
    let vyear = strftime('%Y')
    let vmnth = matchstr(strftime('%m'), '[^0].*')
  elseif a:0 == 2
    let dir = a:1
    let vyear = strftime('%Y')
    let vmnth = matchstr(a:2, '^[^0].*')
  else
    let dir = a:1
    let vyear = a:2
    let vmnth = matchstr(a:3, '^[^0].*')
  endif

  " remember constant
  let vmnth_org = vmnth
  let vyear_org = vyear

  if dir != 2
    " start with last month
    let vmnth = vmnth - 1
    if vmnth < 1
      let vmnth = 12
      let vyear = vyear - 1
    endif
  endif

  " reset display variables
  let vdisplay1 = ''
  let vheight = 1
  let vmcnt = 0

  "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  "+++ build display
  "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  if exists("g:diary_begin")
    exe "call " . g:diary_begin . "()"
  endif
  if dir == 2
    let vmcntmax = 1
    let whitehrz = ''
    if !exists('b:DiaryDir') && !(bufname('%') == '' && &l:modified == 0)
      let width = &columns
      let height = &lines - 2
    else
      let width = winwidth(0)
      let height = winheight(0)
    endif
    let hrz = width / 8 - 5
    if hrz < 0
      let hrz = 0
    endif
    let h = 0
    while h < hrz
      let whitehrz = whitehrz.' '
      let h = h + 1
    endwhile
    let whitehrz = whitehrz.'|'
    let navifix = (exists('g:diary_navi') && g:diary_navi == 'both') * 2
    let vrt = (height - &cmdheight - 3 - navifix) / 6 - 2
    if vrt < 0
      let vrt = 0
    endif
    if whitehrz == '|'
      let whitevrta = whitehrz
    else
      let whitevrta = whitehrz[1:]
    endif
    let h = 0
    let leftmargin = (width - (strlen(whitehrz) + 3) * 7 - 1) / 2
    let whiteleft = ''
    while h < leftmargin
      let whiteleft = whiteleft.' '
      let h = h + 1
    endwhile
    let h = 0
    let whitevrt = ''
    while h < vrt
      let whitevrt = whitevrt."\n".whiteleft.'|'
      let i = 0
      while i < 7
        let whitevrt = whitevrt.'   '.whitehrz
        let i = i + 1
      endwhile
      let h = h + 1
    endwhile
    let whitevrt = whitevrt."\n"
    let whitevrt2 = whiteleft.'+'
    let h = 0
    let borderhrz = '---'.substitute(substitute(whitehrz, ' ', '-', 'g'), '|', '+', '')
    while h < 7
      let whitevrt2 = whitevrt2.borderhrz
      let h = h + 1
    endwhile
    let whitevrtweeknm = whitevrt.whitevrt2."\n"
    let whitevrt = whitevrta.whitevrt.whitevrt2."\n"
    let fridaycol = (strlen(whitehrz) + 3) * 5 + strlen(whiteleft) + 1
    let saturdaycol = (strlen(whitehrz) + 3) * 6 + strlen(whiteleft) + 1
  else
    let vmcntmax = 3
  endif
  while vmcnt < vmcntmax
    let vcolumn = 22
    let vnweek = -1
    "--------------------------------------------------------------
    "--- calculating
    "--------------------------------------------------------------
    " set boundary of the month
    if vmnth == 1
      let vmdays = 31
      let vparam = 1
      let vsmnth = 'Jan'
    elseif vmnth == 2
      let vmdays = 28
      let vparam = 32
      let vsmnth = 'Feb'
    elseif vmnth == 3
      let vmdays = 31
      let vparam = 60
      let vsmnth = 'Mar'
    elseif vmnth == 4
      let vmdays = 30
      let vparam = 91
      let vsmnth = 'Apr'
    elseif vmnth == 5
      let vmdays = 31
      let vparam = 121
      let vsmnth = 'May'
    elseif vmnth == 6
      let vmdays = 30
      let vparam = 152
      let vsmnth = 'Jun'
    elseif vmnth == 7
      let vmdays = 31
      let vparam = 182
      let vsmnth = 'Jul'
    elseif vmnth == 8
      let vmdays = 31
      let vparam = 213
      let vsmnth = 'Aug'
    elseif vmnth == 9
      let vmdays = 30
      let vparam = 244
      let vsmnth = 'Sep'
    elseif vmnth == 10
      let vmdays = 31
      let vparam = 274
      let vsmnth = 'Oct'
    elseif vmnth == 11
      let vmdays = 30
      let vparam = 305
      let vsmnth = 'Nov'
    elseif vmnth == 12
      let vmdays = 31
      let vparam = 335
      let vsmnth = 'Dec'
    else
      echo 'Invalid Year or Month'
      return
    endif
    if vyear % 400 == 0
      if vmnth == 2
        let vmdays = 29
      elseif vmnth >= 3
        let vparam = vparam + 1
      endif
    elseif vyear % 100 == 0
      if vmnth == 2
        let vmdays = 28
      endif
    elseif vyear % 4 == 0
      if vmnth == 2
        let vmdays = 29
      elseif vmnth >= 3
        let vparam = vparam + 1
      endif
    endif

    " calc vnweek of the day
    if vnweek == -1
      let vnweek = ( vyear * 365 ) + vparam
      let vnweek = vnweek + ( vyear/4 ) - ( vyear/100 ) + ( vyear/400 )
      if vyear % 4 == 0
        if vyear % 100 != 0 || vyear % 400 == 0
          let vnweek = vnweek - 1
        endif
      endif
      let vnweek = vnweek - 1
    endif

    " fix Gregorian
    if vyear <= 1752
      let vnweek = vnweek - 3
    endif

    let vnweek = vnweek % 7

    if exists('g:diary_monday')
      " if given g:diary_monday, the week start with monday
      if vnweek == 0
        let vnweek = 7
      endif
      let vnweek = vnweek - 1
    endif

    if exists('g:diary_weeknm')
      " if given g:diary_weeknm, show week number(ref:ISO8601)

      "vparam <= 1. day of month
      "vnweek <= 1. weekday of month (0-6)
      "viweek <= number of week
      "vfweek <= 1. day of year

      " mo di mi do fr sa so
      " 6  5  4  3  2  1  0  vfweek
      " 0  1  2  3  4  5  6  vnweek

      let vfweek =((vparam % 7)  -vnweek+ 14-2) % 7
      let viweek = (vparam - vfweek-2+7 ) / 7 +1

      if vfweek < 3
         let viweek = viweek - 1
      endif

      "vfweekl  <=year length
      let vfweekl = 52
      if (vfweek == 3)
        let vfweekl = 53
      endif

      if viweek == 0
        let viweek = 52
        if ((vfweek == 2) && (((vyear-1) % 4) != 0))
              \ || ((vfweek == 1) && (((vyear-1) % 4) == 0))
          let viweek = 53
        endif
      endif

      let vcolumn = vcolumn + 5
      if g:diary_weeknm == 5
        let vcolumn = vcolumn - 2
      endif
    endif

    "--------------------------------------------------------------
    "--- displaying
    "--------------------------------------------------------------
    " build header
    if exists('g:diary_erafmt') && g:diary_erafmt !~ "^\s*$"
      if g:diary_erafmt =~ '.*,[+-]*\d\+'
        let veranum = substitute(g:diary_erafmt,'.*,\([+-]*\d\+\)','\1','')
        if vyear+veranum > 0
          let vdisplay2 = substitute(g:diary_erafmt,'\(.*\),.*','\1','')
          let vdisplay2 = vdisplay2.(vyear+veranum).'/'.vmnth.'('
        else
          let vdisplay2 = vyear.'/'.vmnth.'('
        endif
      else
        let vdisplay2 = vyear.'/'.vmnth.'('
      endif
      let vdisplay2 = strpart("                           ",
        \ 1,(vcolumn-strlen(vdisplay2))/2-2).vdisplay2
    else
      let vdisplay2 = vyear.'/'.vmnth.'('
      let vdisplay2 = strpart("                           ",
        \ 1,(vcolumn-strlen(vdisplay2))/2-2).vdisplay2
    endif
    if exists('g:diary_mruler') && g:diary_mruler !~ "^\s*$"
      let vdisplay2 = vdisplay2 . get(split(g:diary_mruler, ','), vmnth-1, '').')'."\n"
    else
      let vdisplay2 = vdisplay2 . vsmnth.')'."\n"
    endif
    let vwruler = "Su Mo Tu We Th Fr Sa"
    if exists('g:diary_wruler') && g:diary_wruler !~ "^\s*$"
      let vwruler = g:diary_wruler
    endif
    if exists('g:diary_monday')
      let vwruler = strpart(vwruler,stridx(vwruler, ' ') + 1).' '.strpart(vwruler,0,stridx(vwruler, ' '))
    endif
    if dir == 2
      let whiteruler = substitute(substitute(whitehrz, ' ', '_', 'g'), '__', '  ', '')
      let vwruler = '| '.substitute(vwruler, ' ', whiteruler.' ', 'g').whiteruler
      let vdisplay2 = vdisplay2.whiteleft.vwruler."\n"
    else
      let vdisplay2 = vdisplay2.' '.vwruler."\n"
    endif
    if g:diary_mark == 'right' && dir != 2
      let vdisplay2 = vdisplay2.' '
    endif

    " build diary
    let vinpcur = 0
    while (vinpcur < vnweek)
      if dir == 2
        if vinpcur % 7
          let vdisplay2 = vdisplay2.whitehrz
        else
          let vdisplay2 = vdisplay2.whiteleft.'|'
        endif
      endif
      let vdisplay2 = vdisplay2.'   '
      let vinpcur = vinpcur + 1
    endwhile
    let vdaycur = 1
    while (vdaycur <= vmdays)
      if dir == 2
        if vinpcur % 7
          let vdisplay2 = vdisplay2.whitehrz
        else
          let vdisplay2 = vdisplay2.whiteleft.'|'
        endif
      endif
      if vmnth < 10
         let vtarget = vyear."0".vmnth
      else
         let vtarget = vyear.vmnth
      endif
      if vdaycur < 10
         let vtarget = vtarget."0".vdaycur
      else
         let vtarget = vtarget.vdaycur
      endif
      if exists("g:diary_sign") && g:diary_sign != ""
        exe "let vsign = " . g:diary_sign . "(vdaycur, vmnth, vyear)"
        if vsign != ""
          let vsign = vsign[0]
          if vsign !~ "[+!#$%&@?]"
            let vsign = "+"
          endif
        endif
      else
        let vsign = ''
      endif

      " show mark
      if g:diary_mark == 'right'
        if vdaycur < 10
          let vdisplay2 = vdisplay2.' '
        endif
        let vdisplay2 = vdisplay2.vdaycur
      elseif g:diary_mark == 'left-fit'
        if vdaycur < 10
          let vdisplay2 = vdisplay2.' '
        endif
      endif
      if vtarget == vtoday
        let vdisplay2 = vdisplay2.'*'
      elseif vsign != ''
        let vdisplay2 = vdisplay2.vsign
      else
        let vdisplay2 = vdisplay2.' '
      endif
      if g:diary_mark == 'left'
        if vdaycur < 10
          let vdisplay2 = vdisplay2.' '
        endif
        let vdisplay2 = vdisplay2.vdaycur
      endif
      if g:diary_mark == 'left-fit'
        let vdisplay2 = vdisplay2.vdaycur
      endif
      let vdaycur = vdaycur + 1

      " fix Gregorian
      if vyear == 1752 && vmnth == 9 && vdaycur == 3
        let vdaycur = 14
      endif

      let vinpcur = vinpcur + 1
      if vinpcur % 7 == 0
        if exists('g:diary_weeknm')
          if dir == 2
            let vdisplay2 = vdisplay2.whitehrz
          endif
          if g:diary_mark != 'right'
            let vdisplay2 = vdisplay2.' '
          endif
          " if given g:diary_weeknm, show week number
          if viweek < 10
            if g:diary_weeknm == 1
              let vdisplay2 = vdisplay2.'WK0'.viweek
            elseif g:diary_weeknm == 2
              let vdisplay2 = vdisplay2.'WK '.viweek
            elseif g:diary_weeknm == 3
              let vdisplay2 = vdisplay2.'KW0'.viweek
            elseif g:diary_weeknm == 4
              let vdisplay2 = vdisplay2.'KW '.viweek
            elseif g:diary_weeknm == 5
              let vdisplay2 = vdisplay2.' '.viweek
            endif
          else
            if g:diary_weeknm <= 2
              let vdisplay2 = vdisplay2.'WK'.viweek
            elseif g:diary_weeknm == 3 || g:diary_weeknm == 4
              let vdisplay2 = vdisplay2.'KW'.viweek
            elseif g:diary_weeknm == 5
              let vdisplay2 = vdisplay2.viweek
            endif
          endif
          let viweek = viweek + 1

          if viweek > vfweekl
            let viweek = 1
          endif

        endif
        let vdisplay2 = vdisplay2."\n"
        if g:diary_mark == 'right' && dir != 2
          let vdisplay2 = vdisplay2.' '
        endif
      endif
    endwhile

    " if it is needed, fill with space
    if vinpcur % 7
      while (vinpcur % 7 != 0)
        if dir == 2
          let vdisplay2 = vdisplay2.whitehrz
        endif
        let vdisplay2 = vdisplay2.'   '
        let vinpcur = vinpcur + 1
      endwhile
      if exists('g:diary_weeknm')
        if dir == 2
          let vdisplay2 = vdisplay2.whitehrz
        endif
        if g:diary_mark != 'right'
          let vdisplay2 = vdisplay2.' '
        endif
        if viweek < 10
          if g:diary_weeknm == 1
            let vdisplay2 = vdisplay2.'WK0'.viweek
          elseif g:diary_weeknm == 2
            let vdisplay2 = vdisplay2.'WK '.viweek
          elseif g:diary_weeknm == 3
            let vdisplay2 = vdisplay2.'KW0'.viweek
          elseif g:diary_weeknm == 4
            let vdisplay2 = vdisplay2.'KW '.viweek
          elseif g:diary_weeknm == 5
            let vdisplay2 = vdisplay2.' '.viweek
          endif
        else
          if g:diary_weeknm <= 2
            let vdisplay2 = vdisplay2.'WK'.viweek
          elseif g:diary_weeknm == 3 || g:diary_weeknm == 4
            let vdisplay2 = vdisplay2.'KW'.viweek
          elseif g:diary_weeknm == 5
            let vdisplay2 = vdisplay2.viweek
          endif
        endif
      endif
    endif

    " build display
    let vstrline = ''
    if dir == 1
      " for horizontal
      "--------------------------------------------------------------
      " +---+   +---+   +------+
      " |   |   |   |   |      |
      " | 1 | + | 2 | = |  1'  |
      " |   |   |   |   |      |
      " +---+   +---+   +------+
      "--------------------------------------------------------------
      let vtokline = 1
      while 1
        let vtoken1 = get(split(vdisplay1, "\n"), vtokline-1, '')
        let vtoken2 = get(split(vdisplay2, "\n"), vtokline-1, '')
        if vtoken1 == '' && vtoken2 == ''
          break
        endif
        while strlen(vtoken1) < (vcolumn+1)*vmcnt
          if strlen(vtoken1) % (vcolumn+1) == 0
            let vtoken1 = vtoken1.'|'
          else
            let vtoken1 = vtoken1.' '
          endif
        endwhile
        let vstrline = vstrline.vtoken1.'|'.vtoken2.' '."\n"
        let vtokline = vtokline + 1
      endwhile
      let vdisplay1 = vstrline
      let vheight = vtokline-1
    elseif (dir == 0 || dir == 3)
      " for vertical
      "--------------------------------------------------------------
      " +---+   +---+   +---+
      " | 1 | + | 2 | = |   |
      " +---+   +---+   | 1'|
      "                 |   |
      "                 +---+
      "--------------------------------------------------------------
      let vtokline = 1
      while 1
        let vtoken1 = get(split(vdisplay1, "\n"), vtokline-1, '')
        if vtoken1 == ''
          break
        endif
        let vstrline = vstrline.vtoken1."\n"
        let vtokline = vtokline + 1
        let vheight = vheight + 1
      endwhile
      if vstrline != ''
        let vstrline = vstrline.' '."\n"
        let vheight = vheight + 1
      endif
      let vtokline = 1
      while 1
        let vtoken2 = get(split(vdisplay2, "\n"), vtokline-1, '')
        if vtoken2 == ''
          break
        endif
        while strlen(vtoken2) < vcolumn
          let vtoken2 = vtoken2.' '
        endwhile
        let vstrline = vstrline.vtoken2."\n"
        let vtokline = vtokline + 1
        let vheight = vtokline + 1
      endwhile
      let vdisplay1 = vstrline
    else
      let vtokline = 1
      while 1
        let vtoken1 = get(split(vdisplay1, "\n"), vtokline-1, '')
        let vtoken2 = get(split(vdisplay2, "\n"), vtokline-1, '')
        if vtoken1 == '' && vtoken2 == ''
          break
        endif
        while strlen(vtoken1) < (vcolumn+1)*vmcnt
          if strlen(vtoken1) % (vcolumn+1) == 0
            let vtoken1 = vtoken1.'|'
          else
            let vtoken1 = vtoken1.' '
          endif
        endwhile
        if vtokline > 2
          if exists('g:diary_weeknm')
            let vright = whitevrtweeknm
          elseif whitehrz == '|'
            let vright = whitevrt
          else
            let vright = ' '.whitevrt
          endif
        else
          let vright = "\n"
        endif
        let vstrline = vstrline.vtoken1.vtoken2.vright
        let vtokline = vtokline + 1
      endwhile
      let vdisplay1 = vstrline
      let vheight = vtokline-1
    endif
    let vmnth = vmnth + 1
    let vmcnt = vmcnt + 1
    if vmnth > 12
      let vmnth = 1
      let vyear = vyear + 1
    endif
  endwhile
  if exists("g:diary_end")
    exe "call " . g:diary_end . "()"
  endif
  if a:0 == 0
    return vdisplay1
  endif

  "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  "+++ build window
  "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  " make window
  let vwinnum = bufnr('__Diary')
  if getbufvar(vwinnum, 'Diary') == 'Diary'
    let vwinnum = bufwinnr(vwinnum)
  else
    let vwinnum = -1
  endif

  if vwinnum >= 0
    " if already exist
    if vwinnum != bufwinnr('%')
      exe vwinnum . 'wincmd w'
    endif
    setlocal modifiable
    silent %d _
  else
    " make title
    if g:diary_datetime == "title" && (!exists('s:bufautocommandsset'))
      auto BufEnter *Diary let b:sav_titlestring = &titlestring | let &titlestring = '%{strftime("%c")}'
      auto BufLeave *Diary if exists('b:sav_titlestring') | let &titlestring = b:sav_titlestring | endif
      let s:bufautocommandsset = 1
    endif

    if exists('g:diary_navi') && dir
      if g:diary_navi == 'both'
        let vheight = vheight + 4
      else
        let vheight = vheight + 2
      endif
    endif

    " or not
    if dir == 1
      silent execute 'bo '.vheight.'split __Diary'
      setlocal winfixheight
    elseif dir == 0
      silent execute 'to '.vcolumn.'vsplit __Diary'
      setlocal winfixwidth
    elseif dir == 3
      silent execute 'bo '.vcolumn.'vsplit __Diary'
      setlocal winfixwidth
    elseif bufname('%') == '' && &l:modified == 0
      silent execute 'edit __Diary'
    else
      silent execute 'tabnew __Diary'
    endif
    call s:DiaryBuildKeymap(dir, vyear, vmnth)
    setlocal noswapfile
    setlocal buftype=nofile
    setlocal bufhidden=delete
    silent! exe "setlocal " . g:diary_options
    let nontext_columns = &foldcolumn + &nu * &numberwidth
    if has("+relativenumber")
      let nontext_columns += &rnu * &numberwidth
    endif
    " Without this, the 'sidescrolloff' setting may cause the left side of the
    " diary to disappear if the last inserted element is near the right
    " window border.
    setlocal nowrap
    setlocal norightleft
    setlocal modifiable
    setlocal nolist
    let b:Diary = 'Diary'
    setlocal filetype=diary
    " is this a vertical (0) or a horizontal (1) split?
    if dir != 2
      exe vcolumn + nontext_columns . "wincmd |"
    endif
  endif
  if g:diary_datetime == "statusline"
    setlocal statusline=%{strftime('%c')}
  endif
  let b:DiaryDir = dir
  let b:DiaryYear = vyear_org
  let b:DiaryMonth = vmnth_org

  " navi
  if exists('g:diary_navi')
    let navi_label = '<'
        \.get(split(g:diary_navi_label, ','), 0, '').' '
        \.get(split(g:diary_navi_label, ','), 1, '').' '
        \.get(split(g:diary_navi_label, ','), 2, '').'>'
    if dir == 1
      let navcol = vcolumn + (vcolumn-strlen(navi_label)+2)/2
    elseif (dir == 0 ||dir == 3)
      let navcol = (vcolumn-strlen(navi_label)+2)/2
    else
      let navcol = (width - strlen(navi_label)) / 2
    endif
    if navcol < 3
      let navcol = 3
    endif

    if g:diary_navi == 'top'
      execute "normal gg".navcol."i "
      silent exec "normal! a".navi_label."\<cr>\<cr>"
      silent put! =vdisplay1
    endif
    if g:diary_navi == 'bottom'
      silent put! =vdisplay1
      silent exec "normal! Gi\<cr>"
      execute "normal ".navcol."i "
      silent exec "normal! a".navi_label
    endif
    if g:diary_navi == 'both'
      execute "normal gg".navcol."i "
      silent exec "normal! a".navi_label."\<cr>\<cr>"
      silent put! =vdisplay1
      silent exec "normal! Gi\<cr>"
      execute "normal ".navcol."i "
      silent exec "normal! a".navi_label
    endif
  else
    silent put! =vdisplay1
  endif

  setlocal nomodifiable
  " In case we've gotten here from insert mode (via <C-O>:Diary<CR>)...
  stopinsert

  let vyear = vyear_org
  let vmnth = vmnth_org

  "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  "+++ build highlight
  "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  " today
  syn clear
  if g:diary_mark =~ 'left-fit'
    syn match CalToday display "\s*\*\d*"
    syn match CalMemo display "\s*[+!#$%&@?]\d*"
  elseif g:diary_mark =~ 'right'
    syn match CalToday display "\d*\*\s*"
    syn match CalMemo display "\d*[+!#$%&@?]\s*"
  else
    syn match CalToday display "\*\s*\d*"
    syn match CalMemo display "[+!#$%&@?]\s*\d*"
  endif
  " header
  syn match CalHeader display "[^ ]*\d\+\/\d\+([^)]*)"

  " navi
  if exists('g:diary_navi')
    exec "silent! syn match CalNavi display \"\\(<"
        \.get(split(g:diary_navi_label, ','), 0, '')."\\|"
        \.get(split(g:diary_navi_label, ','), 2, '').">\\)\""
    exec "silent! syn match CalNavi display \"\\s"
        \.get(split(g:diary_navi_label, ','), 1, '')."\\s\"hs=s+1,he=e-1"
  endif

  " saturday, sunday

  if exists('g:diary_monday')
    if dir == 1
      syn match CalSaturday display /|.\{15}\s\([0-9\ ]\d\)/hs=e-1 contains=ALL
      syn match CalSunday display /|.\{18}\s\([0-9\ ]\d\)/hs=e-1 contains=ALL
    elseif (dir == 0|| dir == 3)
      syn match CalSaturday display /^.\{15}\s\([0-9\ ]\d\)/hs=e-1 contains=ALL
      syn match CalSunday display /^.\{18}\s\([0-9\ ]\d\)/hs=e-1 contains=ALL
    else
      exec printf('syn match CalSaturday display /^.\{%d}\s\?\([0-9\ ]\d\)/hs=e-1 contains=ALL', fridaycol)
      exec printf('syn match CalSunday display /^.\{%d}\s\?\([0-9\ ]\d\)/hs=e-1 contains=ALL', saturdaycol)
    endif
  else
    if dir == 1
      syn match CalSaturday display /|.\{18}\s\([0-9\ ]\d\)/hs=e-1 contains=ALL
      syn match CalSunday display /|\s\([0-9\ ]\d\)/hs=e-1 contains=ALL
    elseif (dir == 0 || dir == 3)
      syn match CalSaturday display /^.\{18}\s\([0-9\ ]\d\)/hs=e-1 contains=ALL
      syn match CalSunday display /^\s\([0-9\ ]\d\)/hs=e-1 contains=ALL
    else
      exec printf('syn match CalSaturday display /^.\{%d}\s\?\([0-9\ ]\d\)/hs=e-1 contains=ALL', saturdaycol)
      syn match CalSunday display /^\s*|\s*\([0-9\ ]\d\)/hs=e-1 contains=ALL
    endif
  endif

  " week number
  if !exists('g:diary_weeknm') || g:diary_weeknm <= 2
    syn match CalWeeknm display "WK[0-9\ ]\d"
  else
    syn match CalWeeknm display "KW[0-9\ ]\d"
  endif

  " ruler
  execute 'syn match CalRuler "'.vwruler.'"'

  if search("\*","w") > 0
    silent execute "normal! gg/\*\<cr>"
  endif

  " --+--
  if dir == 2
    exec "syn match CalNormal display " string(borderhrz)
    exec "syn match CalNormal display " string('^'.whiteleft.'+')
  endif

  return ''
endfunction

"*****************************************************************
"* make_dir : make directory
"*----------------------------------------------------------------
"*   dir : directory
"*****************************************************************
function! s:make_dir(dir)
  if(has("unix"))
    call system("mkdir " . a:dir)
    let rc = v:shell_error
  elseif(has("win16") || has("win32") || has("win95") ||
              \has("dos16") || has("dos32") || has("os2"))
    call system("mkdir \"" . a:dir . "\"")
    let rc = v:shell_error
  else
    let rc = 1
  endif
  if rc != 0
    call confirm("can't create directory : " . a:dir, "&OK")
  endif
  return rc
endfunc

"*****************************************************************
"* diary : diary hook function
"*----------------------------------------------------------------
"*   day   : day you actioned
"*   month : month you actioned
"*   year  : year you actioned
"*****************************************************************
function! diary#diary(day, month, year, week, dir)
  " build the file name and create directories as needed
  if !isdirectory(expand(g:diary_dir))
    call confirm("please create diary directory : ".g:diary_dir, 'OK')
    return
  endif
  let sfile = expand(g:diary_dir) . "/" . printf("%04d", a:year)
  if isdirectory(sfile) == 0
    if s:make_dir(sfile) != 0
      return
    endif
  endif
  let sfile = sfile . "/" . printf("%02d", a:month)
  if isdirectory(sfile) == 0
    if s:make_dir(sfile) != 0
      return
    endif
  endif
  let sfile = expand(sfile) . "/" . printf("%02d", a:day) . g:diary_dir_extension
  let sfile = substitute(sfile, ' ', '\\ ', 'g')
  let vbufnr = bufnr('__Diary')

  " load the file
  exe "wincmd w"
  exe "edit  " . sfile
  exe "setfiletype " . g:diary_filetype
  let dir = getbufvar(vbufnr, "DiaryDir")
  let vyear = getbufvar(vbufnr, "DiaryYear")
  let vmnth = getbufvar(vbufnr, "DiaryMonth")
  exe "auto BufDelete ".escape(sfile, ' \\')." call diary#show(" . dir . "," . vyear . "," . vmnth . ")"
endfunc

"*****************************************************************
"* sign : diary sign function
"*----------------------------------------------------------------
"*   day   : day of sign
"*   month : month of sign
"*   year  : year of sign
"*****************************************************************
function! diary#sign(day, month, year)
  let sfile = g:diary_dir."/".printf("%04d", a:year)."/".printf("%02d", a:month)."/".printf("%02d", a:day).".md"
  return filereadable(expand(sfile))
endfunction

"*****************************************************************
"* DiaryVar : get variable
"*----------------------------------------------------------------
"*****************************************************************
function! s:DiaryVar(var)
  if !exists(a:var)
    return ''
  endif
  exec 'return ' . a:var
endfunction

"*****************************************************************
"* DiaryBuildKeymap : build keymap
"*----------------------------------------------------------------
"*****************************************************************
function! s:DiaryBuildKeymap(dir, vyear, vmnth)
  " make keymap
  nnoremap <silent> <buffer> <Plug>DiaryClose  :call diary#close()<cr>
  nnoremap <silent> <buffer> <Plug>DiaryDoAction  :call diary#action()<cr>
  nnoremap <silent> <buffer> <Plug>DiaryDoAction  :call diary#action()<cr>
  nnoremap <silent> <buffer> <Plug>DiaryGotoToday :call diary#show(b:DiaryDir)<cr>
  nnoremap <silent> <buffer> <Plug>DiaryShowHelp  :call <SID>DiaryHelp()<cr>
  execute 'nnoremap <silent> <buffer> <Plug>DiaryReDisplay :call diary#show(' . a:dir . ',' . a:vyear . ',' . a:vmnth . ')<cr>'
  let pnav = get(split(g:diary_navi_label, ','), 0, '')
  let nnav = get(split(g:diary_navi_label, ','), 2, '')
  execute 'nnoremap <silent> <buffer> <Plug>DiaryGotoPrevMonth :call diary#action("<' . pnav . '")<cr>'
  execute 'nnoremap <silent> <buffer> <Plug>DiaryGotoNextMonth :call diary#action("' . nnav . '>")<cr>'
  execute 'nnoremap <silent> <buffer> <Plug>DiaryGotoPrevYear  :call diary#action("PrevYear")<cr>'
  execute 'nnoremap <silent> <buffer> <Plug>DiaryGotoNextYear  :call diary#action("NextYear")<cr>'

  nmap <buffer> <2-LeftMouse> <Plug>DiaryDoAction

  execute 'nmap <buffer> ' . s:diary_keys['close'] . ' <Plug>DiaryClose'
  execute 'nmap <buffer> ' . s:diary_keys['do_action'] . ' <Plug>DiaryDoAction'
  execute 'nmap <buffer> ' . s:diary_keys['goto_today'] . ' <Plug>DiaryGotoToday'
  execute 'nmap <buffer> ' . s:diary_keys['show_help'] . ' <Plug>DiaryShowHelp'
  execute 'nmap <buffer> ' . s:diary_keys['redisplay'] . ' <Plug>DiaryRedisplay'

  execute 'nmap <buffer> ' . s:diary_keys['goto_next_month'] . ' <Plug>DiaryGotoNextMonth'
  execute 'nmap <buffer> ' . s:diary_keys['goto_prev_month'] . ' <Plug>DiaryGotoPrevMonth'
  execute 'nmap <buffer> ' . s:diary_keys['goto_next_year'] . ' <Plug>DiaryGotoNextYear'
  execute 'nmap <buffer> ' . s:diary_keys['goto_prev_year'] . ' <Plug>DiaryGotoPrevYear'
endfunction

"*****************************************************************
"* DiaryHelp : show help for Diary
"*----------------------------------------------------------------
"*****************************************************************
function! s:DiaryHelp()
  let ck = s:diary_keys
  let max_width = max(map(values(ck), 'len(v:val)'))
  let offsets = map(copy(ck), '1 + max_width - len(v:val)')

  echohl SpecialKey
  echo ck['goto_prev_month']  . repeat(' ', offsets['goto_prev_month']) . ': goto prev month'
  echo ck['goto_next_month']  . repeat(' ', offsets['goto_next_month']) . ': goto next month'
  echo ck['goto_prev_year']   . repeat(' ', offsets['goto_prev_year'])  . ': goto prev year'
  echo ck['goto_next_year']   . repeat(' ', offsets['goto_next_year'])  . ': goto next year'
  echo ck['goto_today']       . repeat(' ', offsets['goto_today'])      . ': goto today'
  echo ck['close']            . repeat(' ', offsets['close'])           . ': close window'
  echo ck['redisplay']        . repeat(' ', offsets['redisplay'])       . ': re-display window'
  echo ck['show_help']        . repeat(' ', offsets['show_help'])       . ': show this help'
  if g:diary_action == "diary#diary"
    echo ck['do_action']      . repeat(' ', offsets['do_action'])       . ': show diary'
  endif
  echo ''
  echohl Question

  let vk = [
  \ 'diary_erafmt',
  \ 'diary_mruler',
  \ 'diary_wruler',
  \ 'diary_weeknm',
  \ 'diary_navi_label',
  \ 'diary_dir',
  \ 'diary_mark',
  \ 'diary_navi',
  \]
  let max_width = max(map(copy(vk), 'len(v:val)'))

  for _ in vk
    let v = get(g:, _, '')
    echo _ . repeat(' ', max_width - len(_)) . ' = ' .  v
  endfor
  echohl MoreMsg
  echo "[Hit any key]"
  echohl None
  call getchar()
  redraw!
endfunction

hi def link CalNavi     Search
hi def link CalSaturday Statement
hi def link CalSunday   Type
hi def link CalRuler    StatusLine
hi def link CalWeeknm   Comment
hi def link CalToday    Directory
hi def link CalHeader   Special
hi def link CalMemo     Identifier
hi def link CalNormal   Normal
