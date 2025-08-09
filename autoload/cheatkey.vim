"autoload/cheatkey.vim"
" Author: Gemini & wu9o
" License: MIT
"
" This is the core logic file for the vim-cheatkey plugin.

"==============================================================================
" INITIALIZATION & CONFIGURATION
"==============================================================================

let s:cache_dir = expand('~/.cache/vim-cheatkey')
let s:manual_cache_file = s:cache_dir . '/manual_cache.txt'
let s:generated_cache_file = s:cache_dir . '/generated_cache.txt'
let s:registry = { 'manual': {}, 'generated': {} } " Still used for current session state

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

  " Add to in-memory registry for current session
  let key_id = mode . '#' . keys
  let s:registry.manual[key_id] = {'description': description}

  " Format and append to the persistent manual cache
  let formatted_line = printf("[Manual] (%s) %-30s -> %s  -- \"%s\"", mode, keys, command, description)
  try
    if !isdirectory(s:cache_dir)
      call mkdir(s:cache_dir, 'p')
    endif
    call writefile([formatted_line], s:manual_cache_file, "a")
    echom "CheatKey: Registered and cached annotation for '" . keys . "'"
  catch
    echom "CheatKey Error: Could not write to manual cache file: " . s:manual_cache_file
  endtry
endfunction

function! cheatkey#sync() abort
  " Scans ALL mappings and writes them to the generated cache.
  let s:registry.generated = {} " Clear old in-memory results
  let all_maps = maplist()
  let formatted_lines = []

  for map in all_maps
    let key_id = map.mode . '#' . map.lhs
    let s:registry.generated[key_id] = map " Keep for in-session logic

    let source = s:get_map_source(map)
    let line = printf("%-" . 20 . "s (%s) %-" . 30 . "s -> %s", source, map.mode, map.lhs, map.rhs)
    call add(formatted_lines, line)
  endfor

  " Save the new formatted list to the cache file.
  try
    if !isdirectory(s:cache_dir)
      call mkdir(s:cache_dir, 'p')
    endif
    call writefile(formatted_lines, s:generated_cache_file)
    echom "CheatKey: Synced " . len(all_maps) . " total keybindings and saved to cache."
  catch
    echom "CheatKey Error: Could not write to generated cache file: " . s:generated_cache_file
  endtry
endfunction

function! cheatkey#show_panel() abort
  " Shows the unified 'Library' panel with FZF.
  if !exists('g:fzf_loaded') && !executable('fzf')
    echom "CheatKey Error: fzf.vim is not installed or fzf executable not in PATH."
    return
  endif

  let all_lines = []
  if filereadable(s:generated_cache_file)
    let all_lines += readfile(s:generated_cache_file)
  endif
  if filereadable(s:manual_cache_file)
    let all_lines += readfile(s:manual_cache_file)
  endif

  if empty(all_lines)
    echom "CheatKey: No keybindings found. Run :CheatKeySync first to build the cache."
    return
  endif

  call fzf#run({
        \ 'source': all_lines,
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
