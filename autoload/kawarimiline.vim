function s:echoerr(...) abort
  echohl ErrorMsg
  for str in a:000
    echomsg '[kawarimiline]' str
  endfor
  echohl NONE
endfunction

if !executable('img2sixel')
  call s:echoerr('img2sixel (in libsixel) is required')
  finish
endif

let s:resources_dir = expand('<sfile>:h:h') .. '/resources'
let s:is_number = {item->type(item)==v:t_number}
let s:is_func = {item->type(item)==v:t_func}

let s:statusline_lnum = {->&lines-&cmdheight}
let s:statusline_hidden = {->&laststatus == 0 || (&laststatus == 1 && winnr('$') == 1)}

let s:timer_id = 0

" {{{ ring list
function s:make_ring_list(items) abort
  let obj = {'index': 0, 'items': a:items}
  let obj.tick = funcref('s:tick')
  let obj.current = funcref('s:current')
  let obj.push = funcref('s:push')
  return obj
endfunction
function s:tick() abort dict
  let self.index = (self.index >= len(self.items)-1) ? 0 : (self.index + 1)
endfunction
function s:current() abort dict
  return self.items[self.index]
endfunction
function s:push(item) abort dict
  call add(self.items, a:item)
endfunction
" }}}

if !exists('s:img_cache')
  let s:img_cache = {}
endif
let s:MAIN_IMG_WIDTH = 3
let s:MAIN_IMG_BASE = 'kawarimi'
let s:TRAIL_IMG_BASE = 'rainbow'
let s:LEAD_IMG_NAME = 'space'

let s:echoraw = has('nvim') ? {str->chansend(v:stderr, str)} : {str->echoraw(str)}

function s:display_sixel(sixel, lnum, cnum) abort
  let [sixel, lnum, cnum] = [a:sixel, a:lnum, a:cnum]
  call s:echoraw($"\x1b[{lnum};{cnum}H" .. sixel)
endfunction

function s:show_animation() abort
  if screenrow() > s:statusline_lnum()
    return
  endif
  call s:main_images.tick()
  call s:trail_images.tick()
  call s:show_img()
endfunction

let s:last_margin = []
function s:show_img() abort
  if !s:enable() || (s:check_hidden && s:statusline_hidden())
    return
  endif

  let lead = s:img_cache[s:LEAD_IMG_NAME]
  let main = s:img_cache[s:main_images.current()]
  let trail = s:img_cache[s:trail_images.current()]

  let lnum = s:lnum()

  let left = s:left_margin()
  let right = s:right_margin()
  let length = &columns - left - right
  if left < 0 || right < 0 || length < s:MAIN_IMG_WIDTH
    return
  endif

  let margin = [left, right]
  if s:last_margin != margin
    if !empty(s:last_margin)
      execute "normal! \<c-l>"
    endif
    let s:last_margin = margin
  endif

  " subtract image width from length so as not to jump out of the area
  let img_pos = (length - s:MAIN_IMG_WIDTH) * line('.') / line('$')

  " save cursor pos
  call s:echoraw("\x1b[s")

  " display sixels
  if img_pos > 0
    for i in range(0, img_pos - 1, 2)
      call s:display_sixel(trail, lnum, left + i)
    endfor
  endif
  for i in range(img_pos, length - 1)
    call s:display_sixel(lead, lnum, left + i)
  endfor
  call s:display_sixel(main, lnum, left + img_pos)

  " restore cursor pos
  call s:echoraw("\x1b[u")
endfunction

function kawarimiline#stop() abort
  silent! call timer_stop(s:timer_id)
  execute "normal! \<c-l>"
  let s:last_margin = []
  augroup kawarimiline_internal
    autocmd!
  augroup END
endfunction

function kawarimiline#start(opts) abort
  call kawarimiline#stop()

  if !has_key(a:opts, 'size')
        \ || !has_key(a:opts, 'left_margin')
        \ || !has_key(a:opts, 'right_margin')
    return s:echoerr('lack of option: size, left_margin and right_margin are required')
  endif

  let size = a:opts.size
  let s:left_margin = a:opts.left_margin
  let s:right_margin = a:opts.right_margin

  if !s:is_number(size)
    return s:echoerr('invalid type: size should be number')
  elseif !s:is_number(s:left_margin) && !s:is_func(s:left_margin)
    return s:echoerr('invalid type: left_margin should be number or funcref')
  elseif !s:is_number(s:right_margin) && !s:is_func(s:right_margin)
    return s:echoerr('invalid type: right_margin should be number or funcref')
  endif

  if s:is_number(s:left_margin)
    let s:left_margin = {->a:opts.left_margin}
  endif
  if s:is_number(s:right_margin)
    let s:right_margin = {->a:opts.right_margin}
  endif

  let s:enable = !has_key(a:opts, 'enable') ? {->v:true}
        \ : s:is_func(a:opts.enable) ? a:opts.enable
        \ : {->a:opts.enable}

  let s:lnum = s:statusline_lnum
  let s:check_hidden = v:true
  if has_key(a:opts, 'lnum')
    let s:lnum = s:is_func(a:opts.lnum) ? a:opts.lnum : {->a:opts.lnum}
    let s:check_hidden = v:false
  endif

  let interval = get(a:opts, 'interval', 400)
  let use_animation = interval > 0
  let wave = get(a:opts, 'wave', v:false)

  let img_names = [s:LEAD_IMG_NAME]

  let s:main_images = s:make_ring_list([])
  let s:trail_images = s:make_ring_list([])

  if use_animation
    for i in [1,2,3,4]
      call s:main_images.push($'{s:MAIN_IMG_BASE}{i}')
      if wave
        call s:trail_images.push($'{s:TRAIL_IMG_BASE}{i}')
      endif
    endfor
    if !wave
      call s:trail_images.push($'{s:TRAIL_IMG_BASE}0')
    endif
  else
    call s:main_images.push($'{s:MAIN_IMG_BASE}1')

    call s:trail_images.push($'{s:TRAIL_IMG_BASE}{wave ? 1 : 0}')
  endif

  call extend(img_names, s:main_images.items)
  call extend(img_names, s:trail_images.items)
  for name in img_names
    let s:img_cache[name] = system($"img2sixel -h {size}px {s:resources_dir}/{name}.png")
  endfor

  augroup kawarimiline_internal
    autocmd VimResized,WinResized,WinEnter,BufEnter * call timer_start(0, {->s:show_img()})
  augroup END

  if use_animation
    let s:timer_id = timer_start(interval, {->s:show_animation()}, {'repeat': -1})
  else
    call timer_start(0, {->s:show_img()})
    augroup kawarimiline_internal
      autocmd CursorMoved * call timer_start(0, {->s:show_img()})
    augroup END
  endif
endfunction

" https://github.com/vim/vim/blob/71d0ba07a33a750e9834cd42b7acc619043dedb1/src/testdir/test_statusline.vim#L18-L20
" https://github.com/vim/vim/blob/71d0ba07a33a750e9834cd42b7acc619043dedb1/src/testdir/view_util.vim#L19-L36
function kawarimiline#get_statusline() abort
  if s:statusline_hidden()
    return ''
  endif
  let lnum = s:statusline_lnum()
  " redrawstatus!
  return range(1, &columns)->map($'screenstring({lnum}, v:val)')->join('')
endfunction
