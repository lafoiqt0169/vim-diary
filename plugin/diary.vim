"=============================================================================
" What Is This: Diary
" File: diary.vim
" Author: Yasuhiro Matsumoto <mattn.jp@gmail.com>
" Last Change: 2013 Okt 27
" Version: 2.9
" Thanks:
"     Tobias Columbus               : customizable key bindings
"     Daniel P. Wright              : doc/diary.txt
"     SethMilliken                  : gave a hint for 2.4
"     bw1                           : bug fix, new weeknm format
"     Ingo Karkat                   : bug fix
"     Thinca                        : bug report, bug fix
"     Yu Pei                        : bug report
"     Per Winkvist                  : bug fix
"     Serge (gentoosiast) Koksharov : bug fix
"     Vitor Antunes                 : bug fix
"     Olivier Mengue                : bug fix
"     Noel Henson                   : today action
"     Per Winkvist                  : bug report
"     Peter Findeisen               : bug fix
"     Chip Campbell                 : gave a hint for 1.3z
"     PAN Shizhu                    : gave a hint for 1.3y
"     Eric Wald                     : bug fix
"     Sascha Wuestemann             : advise
"     Linas Vasiliauskas            : bug report
"     Per Winkvist                  : bug report
"     Ronald Hoelwarth              : gave a hint for 1.3s
"     Vikas Agnihotri               : bug report
"     Steve Hall                    : gave a hint for 1.3q
"     James Devenish                : bug fix
"     Carl Mueller                  : gave a hint for 1.3o
"     Klaus Fabritius               : bug fix
"     Stucki                        : gave a hint for 1.3m
"     Rosta                         : bug report
"     Richard Bair                  : bug report
"     Yin Hao Liew                  : bug report
"     Bill McCarthy                 : bug fix and gave a hint
"     Srinath Avadhanula            : bug fix
"     Ronald Hoellwarth             : few advices
"     Juan Orlandini                : added higlighting of days with data
"     Ray                           : bug fix
"     Ralf.Schandl                  : gave a hint for 1.3
"     Bhaskar Karambelkar           : bug fix
"     Suresh Govindachar            : gave a hint for 1.2, bug fix
"     Michael Geddes                : bug fix
"     Leif Wickland                 : bug fix
" GetLatestVimScripts: 52 1 :AutoInstall: diary.vim

if &compatible
  finish
endif
"*****************************************************************
"* Diary commands
"*****************************************************************
command! -nargs=* Diary  call diary#show(0,<f-args>)
command! -nargs=* DiaryVR  call diary#show(3,<f-args>)
command! -nargs=* DiaryH call diary#show(1,<f-args>)
command! -nargs=* DiaryT call diary#show(2,<f-args>)

nnoremap <silent> <Plug>DiaryV :cal diary#show(0)<CR>
nnoremap <silent> <Plug>DiaryH :cal diary#show(1)<CR>
nnoremap <silent> <Plug>DiaryT :cal diary#show(2)<CR>

" vi: et sw=2 ts=2
