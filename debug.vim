execute $"set runtimepath+={expand('<script>:p:h')}"

call kawarimiline#start({
      \ 'size': 22,
      \ 'left_offset': {->strcharlen(bufname()) + 20},
      \ 'right_offset': 21,
      \ 'animation': v:true,
      \ 'enable': {->winnr() == winnr('1h') && winnr() == winnr('1l')},
      \ 'wave': v:true,
      \ })
