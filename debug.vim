execute $"set runtimepath+={expand('<script>:p:h')}"

call kawarimiline#start({
      \ 'size': 22,
      \ 'left_margin': {->max([stridx(kawarimiline#get_statusline(), '   ') + 2, 20])},
      \ 'right_margin': 20,
      \ 'enable': {->winnr() == winnr('1h') && winnr() == winnr('1l')},
      \ 'wave': v:true,
      \ })

edit autoload/kawarimiline.vim
