<div align="center">
<h1 align="center">kawarimiline</h1>
<p align="center">A fancy tiny scroll indicator in Vim 🌈</p>
<img src="https://github.com/kawarimidoll/kawarimiline.vim/assets/8146876/bed68e4d-ebca-4f44-95dc-200b9d814ea7" alt="kawarimiline_demo">
</div>

## REQUIREMENTS

Please make sure that `img2sixel` can be executed and your terminal supports
sixel.

For more information: https://github.com/saitoha/libsixel

## EXAMPLE

```vim
call kawarimiline#start({
      \ 'size': 22,
      \ 'left_margin': {->max([
      \   stridx(kawarimiline#get_statusline(), '   ') + 2,
      \   20
      \ ])},
      \ 'right_margin': 20,
      \ 'enable': {->winnr() == winnr('1h') && winnr() == winnr('1l')},
      \ 'wave': v:true,
      \ })
```

`'size'`, `'left_margin'` and `'right_margin'` are required.

## KNOWN ISSUES

- This may works wrong when `set cmdheight=0` in Neovim.

## INSPIRED BY

- https://github.com/TeMPOraL/nyan-mode
- https://github.com/mattn/vim-nyancat
