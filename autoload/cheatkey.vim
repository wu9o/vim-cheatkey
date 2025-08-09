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

"==============================================================================
" PUBLIC FUNCTIONS (Called from commands)
"==============================================================================

function! cheatkey#register(args) abort
  let desc_match = matchlist(a:args, '\v"(.*)"\s*$')
  if empty(desc_match) | echom "CheatKey Error: Description must be in quotes." | return | endif
  let description = desc_match[1]
  let command_part = substitute(a:args, '\v\s*".*"\s*$', '', '')
  let parts = split(command_part, '\s+')
  if len(parts) < 3 | echom "CheatKey Error: Invalid format." | return | endif
  let [mode, keys; command_list] = parts
  let command = join(command_list, ' ')
  try | execute mode . 'map <silent> ' . keys . ' ' . command
  catch | echom "CheatKey Error: Failed to map key. Error: " . v:exception | return | endtry

  " Format and append to the persistent manual cache
  let formatted_line = printf("[Manual] (map)  %-25s -> %s  -- \"%s\"", mode . ' ' . keys, command, description)
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
  let formatted_lines = []
  let plugin_list = s:get_plugin_list()

  " === Part 1: Scan Mappings ===
  let all_maps = maplist()
  for map in all_maps
    let source = s:get_map_source(map)
    let line = printf("% -20s (map)  %-25s -> %s", source, map.mode . ' ' . map.lhs, map.rhs)
    call add(formatted_lines, line)
  endfor

  " === Part 2: Scan Commands ===
  redir => commands_output
  silent command
  redir END

  let command_list = split(commands_output, "\n")
  for cmd_line in command_list
    if cmd_line =~# '^\s*Name' || cmd_line !~# '^\s*!'
      continue
    endif

    let parts = split(cmd_line)
    if len(parts) < 2
      continue
    endif
    
    let source = s:get_command_source(parts, plugin_list)
    let cmd_name = parts[1]
    let cmd_def = join(parts[2:], ' ')

    let line = printf("% -20s (cmd)  %-25s -> %s", source, cmd_name, cmd_def)
    call add(formatted_lines, line)
  endfor

  " === Part 3: Save to Cache ===
  try
    if !isdirectory(s:cache_dir)
      call mkdir(s:cache_dir, 'p')
    endif
    call writefile(sort(formatted_lines), s:generated_cache_file)
    echom "CheatKey: Synced " . len(formatted_lines) . " total mappings and commands to cache."
  catch
    echom "CheatKey Error: Could not write to generated cache file: " . s:generated_cache_file
  endtry
endfunction

function! cheatkey#show_panel() abort
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

function! s:get_plugin_list()
  let plug_dir = expand('~/.dotfiles/vim/plugged')
  if !isdirectory(plug_dir)
    return []
  endif
  let plugin_dirs = split(globpath(plug_dir, '*'), '\n')
  return map(plugin_dirs, 'fnamemodify(v:val, ":t")')
endfunction

function! s:get_command_source(parts, plugin_list)
  let cmd_name = a:parts[1]
  let cmd_def = join(a:parts[2:], ' ')

  " Heuristic 1: Check definition for autoload functions (e.g., "call plug#...")
  let autoload_match = matchlist(cmd_def, '\c\vcall\s+\([a-z0-9_]+\)#')
  if !empty(autoload_match)
    return '[' . autoload_match[1] . '.vim]'
  endif

  " Heuristic 2: Check command name prefix against plugin names
  for plugin_name in a:plugin_list
    let clean_plugin_name = substitute(plugin_name, '^vim-', '', '')
    if stridx(tolower(cmd_name), tolower(clean_plugin_name)) == 0
      return '[' . plugin_name . ']'
    endif
  endfor

  return '[Command]'
endfunction

function! s:get_map_source(map) abort
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