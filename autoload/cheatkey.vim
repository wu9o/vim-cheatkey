" autoload/cheatkey.vim
" Author: Gemini
" License: MIT
"
" This is the core logic file for the vim-cheatkey plugin.

"==============================================================================
" INITIALIZATION & CONFIGURATION
"==============================================================================

let s:registry = { 'manual': {}, 'generated': {} }
let s:ai_jobs = {} " To track running AI jobs

" Load user configuration with sane defaults
let g:cheatkey_language = get(g:, 'cheatkey_language', 'en')
let g:cheatkey_ai_provider = get(g:, 'cheatkey_ai_provider', 'gemini')
let g:cheatkey_model_name = get(g:, 'cheatkey_model_name', 'gemini-1.5-flash')
let g:cheatkey_api_key_command = get(g:, 'cheatkey_api_key_command', '')
let g:cheatkey_prompt_template = get(g:, 'cheatkey_prompt_template', 'You are a Vim expert. A keybinding in Vim executes the following command: "{rhs}". Please provide a concise, functional description for this command in {language}, under 15 characters. Return only the description text, without any extra formatting or explanation.')

"==============================================================================
" PUBLIC FUNCTIONS (Called from commands)
"==============================================================================

function! cheatkey#register(args) abort
  let desc_match = matchlist(a:args, '\v"(.*)"\s*$')
  if empty(desc_match) | echom "CheatKey Error: Description must be in quotes." | return | endif
  let description = desc_match[1]
  let command_part = substitute(a:args, '\v\s*".*"\s*$', '', '')
  let parts = split(command_part, '\s\+')
  if len(parts) < 3 | echom "CheatKey Error: Invalid format." | return | endif
  let [mode, keys; command_list] = parts
  let command = join(command_list, ' ')
  try | execute mode . 'map <silent> ' . keys . ' ' . command
  catch | echom "CheatKey Error: Failed to map key. Error: " . v:exception | return | endtry
  let key_id = mode . '#' . keys
  let s:registry.manual[key_id] = {'mode': mode, 'keys': keys, 'command': command, 'description': description, 'source': 'manual'}
  echom "CheatKey: Registered '" . keys . "' -> '" . description . "'"
endfunction

function! cheatkey#show_panel() abort
  " --- Cheat Sheet Mode ---
  " This panel ONLY shows keybindings manually registered with :CheatKey.
  botright new [CheatKey Panel]
  setlocal buftype=nofile bufhidden=wipe noswapfile nonumber norelativenumber signcolumn=no cursorline
  if has('nvim') | setlocal winhighlight=Normal:CheatKeyPanel,CursorLine:CheatKeyCursorLine | endif

  let manual_maps = values(s:registry.manual)
  let lines = ["--- Vim CheatKey Panel (Press 'q' to close) ---", ""]

  if empty(manual_maps)
    call add(lines, "")
    call add(lines, "No keybindings registered with :CheatKey yet.")
    call add(lines, "")
    call add(lines, "Define them in your .vimrc, e.g.:")
    call add(lines, "  CheatKey n <leader>s :w<CR> \"Save file\"")
  else
    let header = printf("%-25s %-10s %s", "Keybinding", "(Mode)", "Description")
    call add(lines, header)
    call add(lines, repeat('=', strwidth(header)))
    for map_info in manual_maps
      call add(lines, printf("%-25s %-10s %s", map_info.keys, '(' . map_info.mode . ')', map_info.description))
    endfor
  endif

  call setline(1, lines)
  setlocal nomodifiable
  nnoremap <silent> <buffer> q :q<CR>
  highlight default link CheatKeyPanel Normal
  highlight default link CheatKeyCursorLine CursorLine
endfunction

function! cheatkey#explore() abort
  " --- Explore Mode ---
  " This uses FZF to search through ALL mappings.
  if !exists('*fzf#run')
    echom "CheatKey Error: fzf.vim is not installed. :CheatKeyExplore requires it."
    return
  endif

  let all_maps = maplist()
  let formatted_maps = []

  for map in all_maps
    let source = s:get_map_source(map)
    let line = printf("%-20s (%s) %-30s -> %s", source, map.mode, map.lhs, map.rhs)
    call add(formatted_maps, line)
  endfor

  call fzf#run({
        \ 'source': formatted_maps,
        \ 'sink': 'echom', " For now, just echo the selected line.
        \ 'options': '--header="Explore All Mappings" --layout=reverse'
        \ })
endfunction

function! cheatkey#sync() abort
  " This command is now for reloading .vimrc settings without restarting.
  " For now, we just clear the registry. A more sophisticated implementation
  " could re-source the vimrc.
  let s:registry = { 'manual': {}, 'generated': {} }
  echom "CheatKey registry cleared. Please restart or re-source your vimrc."
endfunction

"==============================================================================
" PRIVATE FUNCTIONS (Internal logic)
"==============================================================================

function! s:get_map_source(map) abort
  " Tries to find the source file of a mapping.
  if !has_key(a:map, 'sid') || a:map.sid <= 0
    return '[Vim Internal]'
  endif

  try
    " scriptnames() is not available in all Vim versions, so we wrap it.
    let script_path = scriptnames(a:map.sid)
    " Return the filename, which is more readable than the full path.
    return '[' . fnamemodify(script_path, ':t') . ']'
  catch
    return '[Unknown Source]'
  endtry
endfunction
