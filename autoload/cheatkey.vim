" autoload/cheatkey.vim
" Author: Gemini & wu9o
" License: MIT
"
" This is the core logic file for the vim-cheatkey plugin.

"==============================================================================
" INITIALIZATION & CONFIGURATION
"==============================================================================

let s:registry = { 'manual': {}, 'generated': {} }

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
  let s:registry.manual[key_id] = {'description': description}
  echom "CheatKey: Registered annotation for '" . keys . "'"
endfunction

function! cheatkey#sync() abort
  " Scans ALL mappings from maplist() without any filtering.
  let s:registry.generated = {} " Clear old results
  let all_maps = maplist()
  for map in all_maps
    let key_id = map.mode . '#' . map.lhs
    let s:registry.generated[key_id] = map
  endfor
  echom "CheatKey: Synced " . len(all_maps) . " total keybindings."
endfunction

function! cheatkey#show_panel() abort
  " Shows the unified 'Library' panel with FZF.
  if !exists('*fzf#run')
    echom "CheatKey Error: fzf.vim is not installed."
    return
  endif

  if empty(s:registry.generated)
    echom "CheatKey: No keybindings synced yet. Run :CheatKeySync first."
    return
  endif

  let formatted_maps = []
  for [key_id, map_info] in items(s:registry.generated)
    let source = s:get_map_source(map_info)
    let manual_desc = get(s:registry.manual, key_id, {}).description

    let line = printf("%-20s (%s) %-30s -> %s", source, map_info.mode, map_info.lhs, map_info.rhs)
    if !empty(manual_desc)
      let line .= '  -- "' . manual_desc . '"'
    endif
    call add(formatted_maps, line)
  endfor

  call fzf#run({
        \ 'source': formatted_maps,
        \ 'sink': 'echom',
        \ 'options': '--header="CheatKey Library" --layout=reverse'
        \ })
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
    let script_path = scriptnames(a:map.sid)
    return '[' . fnamemodify(script_path, ':t') . ']'
  catch
    return '[Unknown Source]'
  endtry
endfunction