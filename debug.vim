execute $"set runtimepath+={expand('<script>:p:h')}"

let type = 2

if type == 1
  call kawarimiline#start({
        \ 'size': 22,
        \ 'left_margin': {->max([stridx(kawarimiline#get_statusline(), '   ') + 2, 20])},
        \ 'right_margin': 20,
        \ 'enable': {->winnr() == winnr('1h') && winnr() == winnr('1l')},
        \ 'wave': v:true,
        \ })
elseif type == 2
  set laststatus=0
  let width = 30
  call kawarimiline#start({
        \ 'size': 22,
        \ 'lnum': 1,
        \ 'left_margin': &columns-width,
        \ 'right_margin': 0,
        \ 'wave': v:true,
        \ 'interval': 0,
        \ })
  if has('nvim')
    call nvim_open_win(nvim_create_buf(v:false, v:true), 0, {
          \ 'relative': 'editor',
          \ 'anchor': 'NE',
          \ 'row': 0,
          \ 'col': &columns,
          \ 'width': width,
          \ 'height': 1,
          \ 'focusable': v:false,
          \ 'style': 'minimal',
          \ 'border': 'none',
          \ 'noautocmd': v:true,
          \ })
  else
    call popup_create('', {
          \ 'line': 1,
          \ 'col': &columns,
          \ 'pos': 'topright',
          \ 'maxheight': 1,
          \ 'minheight': 1,
          \ 'maxwidth': width+1,
          \ 'minwidth': width+1,
          \ 'posinvert': v:false,
          \ })
  endif
endif

edit autoload/kawarimiline.vim
