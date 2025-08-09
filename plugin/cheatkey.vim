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
" -nargs=+ means the command takes one or more arguments.
" <q-args> passes all arguments as a single string, preserving quotes.
command! -nargs=+ CheatKey call cheatkey#register(<q-args>)

" Shows the keybinding cheatsheet panel.
command! CheatKeyPanel call cheatkey#show_panel()

" Asynchronously scans all keymaps and generates descriptions.
command! CheatKeySync call cheatkey#sync()

" A little message to confirm the plugin is loaded, can be removed later.
" echom "vim-cheatkey loaded successfully."
