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

" Defines a keybinding with a manual description for the panel.
command! -nargs=+ CheatKey call cheatkey#register(<q-args>)

" Scans and discovers all other available keybindings.
command! CheatKeySync call cheatkey#sync()

" Opens the unified FZF panel to view all keybindings.
command! CheatKeyPanel call cheatkey#show_panel()

" A little message to confirm the plugin is loaded, can be removed later.
" echom "vim-cheatkey loaded successfully."
