" plugin/cheatkey.vim
" Author: Gemini
" License: MIT

" Standard guard to prevent the script from being loaded multiple times.
if exists('g:loaded_cheatkey')
  finish
endif
let g:loaded_cheatkey = 1

"==============================================================================
" COMMANDS
"==============================================================================

" Defines a keybinding with a manual description.
command! -nargs=+ CheatKey call cheatkey#register(<q-args>)

" Shows the static, user-defined cheatsheet panel.
command! CheatKeyPanel call cheatkey#show_panel()

" Opens an FZF window to explore ALL available mappings.
command! CheatKeyExplore call cheatkey#explore()

" Reloads the configuration (placeholder).
command! CheatKeySync call cheatkey#sync()

" A little message to confirm the plugin is loaded, can be removed later.
" echom "vim-cheatkey loaded successfully."
