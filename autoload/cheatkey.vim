"autoload/cheatkey.vim"
" Author: Gemini & wu9o
" License: MIT
"
" This is the core logic file for the vim-cheatkey plugin.

"==============================================================================
" SCRIPT-LEVEL VARIABLES
"==============================================================================

" Cache the absolute path to this script's directory when the script is sourced.
" This is the most robust way to avoid context issues with <sfile>.
let s:script_dir = expand('<sfile>:p:h')

"==============================================================================
" CONFIGURATION & DOCUMENTATION
"==============================================================================
"
" To set the display language for built-in Vim commands, add one of the
" following lines to your .vimrc:
"
" let g:cheatkey_lang = 'en'  " For English (default)
" let g:cheatkey_lang = 'zh'  " For Chinese
"
"==============================================================================
" INITIALIZATION
"==============================================================================

let s:cache_dir = expand('~/.cache/vim-cheatkey')
let s:manual_cache_file = s:cache_dir . '/manual_cache.txt'
let s:generated_cache_file = s:cache_dir . '/generated_cache.txt'

" Semantic descriptions for known commands and mappings to improve readability.
let s:cmd_desc_map = {
      \ 'NERDTreeToggle': 'Toggle file explorer tree',
      \ 'Gdiffsplit': 'Show git diff in a split',
      \ 'FZF': 'Launch fzf file search',
      \ 'Ag': 'Search for pattern in files with Ag'
      \ }

let s:map_desc_map = {
      \ 'i <Plug>(fzf-complete-file)': 'FZF file path completion',
      \ 'n <2-LeftMouse>': 'Handle mouse click in NERDTree',
      \ 'i <C-W>': 'Delete previous word in insert mode',
      \ 'v <BS>': 'Delete selection in visual mode'
      \ }

"==============================================================================
" PUBLIC FUNCTIONS (Called from commands)
"==============================================================================

function! cheatkey#register(args) abort
  let desc_match = matchlist(a:args, '\v"(.*)"\s*
)
  if empty(desc_match) | echom "CheatKey Error: Description must be in quotes." | return | endif
  let description = desc_match[1]
  let command_part = substitute(a:args, '\v\s*".*"\s*
, '', '')
  let parts = split(command_part, '\s\+')
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
  let built_in_keys = s:load_built_in_keys()

  " === Part 1: Scan Mappings ===
  let all_maps = maplist()
  for map in all_maps
    if has_key(built_in_keys, map.lhs)
      continue
    endif
    let source = s:get_map_source(map)
    let lhs_key = map.mode . ' ' . map.lhs
    " Use semantic description if available, otherwise use the original rhs.
    let rhs_desc = get(s:map_desc_map, lhs_key, map.rhs)
    " Clean up escaped characters for better readability.
    let simplified_rhs = substitute(rhs_desc, '<lt>', '<', 'g')
    let line = printf("% -20s (map)  %-25s -> %s", source, lhs_key, simplified_rhs)
    call add(formatted_lines, line)
  endfor

  " === Part 2: Scan Commands using a fixed state machine parser ===
  redir => commands_output
  silent verbose command
  redir END

  " Split output into lines, filter out empty lines to avoid confusion
  let command_lines = filter(split(commands_output, "\n"), '!empty(v:val)')
  let current_command = {}  " {name, def, source}

  for line in command_lines
    " Trim leading/trailing whitespace for consistent matching
    let trimmed_line = trim(line)

    " Case 1: Start of a new command (matches lines with command definition)
    let match = matchlist(trimmed_line, '^\s*[!|]\?\s\+\(\S\+\)\s*\(.*\)')
    if !empty(match)
      " Process previous command if exists
      if !empty(current_command)
        let formatted = s:format_command(current_command)
        if !empty(formatted) && !has_key(built_in_keys, current_command.name)
          call add(formatted_lines, formatted)
        endif
      endif

      " Start a new command object
      let current_command = {
            \ 	'name': match[1],
            \ 	'def': [match[2]],
            \ 	'source': '[Unknown Command]'
            \ }
    " Case 2: Source line (Last set from ...)
    elseif trimmed_line =~# '^Last set from'
      if !empty(current_command)
        let current_command.source = s:parse_source_line(trimmed_line)
      endif

    " Case 3: Continuation of command definition (multi-line)
    elseif !empty(current_command)
      call add(current_command.def, trimmed_line)
    endif
  endfor

  " Process the last command in the buffer
  if !empty(current_command)
    let formatted = s:format_command(current_command)
    if !empty(formatted) && !has_key(built_in_keys, current_command.name)
      call add(formatted_lines, formatted)
    endif
  endif

  " === Part 3: Save to Cache ===
  try
    if !isdirectory(s:cache_dir)
      call mkdir(s:cache_dir, 'p')
    endif
    call writefile(sort(formatted_lines), s:generated_cache_file)
    echom "CheatKey: Synced " . len(formatted_lines) . " non-default mappings and commands to cache."
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
  let file_sources = [
        \ s:get_built_in_cache_path(),
        \ s:manual_cache_file,
        \ s:generated_cache_file
        \ ]

  for file_path in file_sources
    if filereadable(file_path)
      call extend(all_lines, readfile(file_path))
    endif
  endfor

  if empty(all_lines)
    echom "CheatKey: No keybindings found. Run :CheatKeySync first to build the cache."
    return
  endif

  call fzf#run({
        \ 	'source': all_lines,
        \ 	'sink': function('s:safe_echo'),
        \ 	'options': '--header="CheatKey Library" --layout=reverse'
        \ })
endfunction

"==============================================================================
" PRIVATE FUNCTIONS (Internal logic)
"==============================================================================

function! s:safe_echo(line) abort
  execute 'echom string(a:line)'
endfunction

function! s:get_built_in_cache_path() abort
  let lang = get(g:, 'cheatkey_lang', 'en')
  let lang_file = s:script_dir . '/built_in_cache_' . lang . '.txt'
  
  if filereadable(lang_file)
    return lang_file
  else
    " Fallback to English if the specified language file doesn't exist
    return s:script_dir . '/built_in_cache_en.txt'
  endif
endfunction

function! s:load_built_in_keys()
  let keys = {}
  let built_in_cache_path = s:get_built_in_cache_path()
  if !filereadable(built_in_cache_path)
    return keys
  endif
  for line in readfile(built_in_cache_path)
    let match = matchlist(line, '^\s*\[.*\]\s*(\(map\|cmd\))\s*\(\S\+\)')
    if !empty(match)
      let keys[match[2]] = 1
    endif
  endfor
  return keys
endfunction

function! s:parse_source_line(line)
    let source_path = substitute(a:line, '.*Last set from ', '', '')
    let plug_patterns = [
          \ '/plugged/\zs[^/]*',
          \ '/lazy/\zs[^/]*',
          \ '/pack/[^/]*\/start\/\zs[^/]*'
          \ ]
    for pattern in plug_patterns
      let plug_match = matchlist(source_path, pattern)
      if !empty(plug_match)
        return '[' . plug_match[0] . ']'
      endif
    endfor
    return '[' . fnamemodify(source_path, ':t') . ']'
endfunction

function! s:format_command(command_obj)
    if !has_key(a:command_obj, 'name') || empty(a:command_obj.name)
        return ''
    endif
    " Use semantic description if available, otherwise use the original definition.
    let desc = get(s:cmd_desc_map, a:command_obj.name, join(a:command_obj.def, ' '))
    return printf("% -20s (cmd)  %-25s -> %s", a:command_obj.source, a:command_obj.name, desc)
endfunction

function! s:get_map_source(map) abort
  " Step 1: Try to get source from sid (most reliable)
  if has_key(a:map, 'sid') && a:map.sid > 0
    try
      let script_path = scriptnames(a:map.sid)
      if script_path =~# '\v/(init\.vim|\.vimrc)

        return '[User Config]'
      endif
      let plug_patterns = [
            \ '/plugged/\zs[^/]*',
            \ '/lazy/\zs[^/]*',
            \ '/pack/[^/]*\/start\/\zs[^/]*'
            \ ]
      for pattern in plug_patterns
        let plug_match = matchlist(script_path, pattern)
        if !empty(plug_match)
          return '[' . plug_match[0] . ']'
        endif
      endfor
      return '[' . fnamemodify(script_path, ':t') . ']'
    catch
      " Fall through if sid is invalid
    endtry
  endif

  " Step 2: Infer from lhs/rhs content with enhanced pattern matching

  " Enhanced: Identify built-in <C-W> for insert mode
  if a:map.mode ==# 'i' && a:map.lhs ==# '<C-W>' && a:map.rhs ==# '<C-G>u<C-W>'
    return '[Vim Internal]'
  endif

  " Enhanced: Identify built-in <BS> for visual mode (delete to black hole register)
  if a:map.mode ==# 'v' && a:map.lhs ==# '<BS>' && a:map.rhs ==# '"-d'
    return '[Vim Internal]'
  endif

  " Enhanced: Identify matchit's text object `a%`
  if a:map.mode ==# 'x' && a:map.lhs ==# 'a%' && a:map.rhs =~# 'Matchit'
    return '[matchit.vim]'
  endif

  " Enhanced: Handle <Plug>(...) with parentheses for fzf, matchit, etc.
  let plug_with_paren_match = matchlist(a:map.lhs, '<Plug>\(\(.*\)\)')
  if !empty(plug_with_paren_match)
    let plug_id = plug_with_paren_match[1]
    let plug_keywords = {
          \ 	'fzf-': 'fzf.vim',
          \ 	'Matchit': 'matchit.vim'
          \ }
    for [keyword, plugin] in items(plug_keywords)
      if stridx(plug_id, keyword) != -1
        return '[' . plugin . ']'
      endif
    endfor
  endif

  " Enhanced: Handle specific <Plug> keys like for fugitive
  if a:map.lhs ==# '<Plug>fugitive:'
    return '[vim-fugitive]'
  endif

  " Original logic for rhs namespace checking
  let rhs = a:map.rhs
  let namespace_patterns = {
        \ 	'nerdtree#': 'nerdtree',
        \ 	'fzf#': 'fzf.vim',
        \ 	'fugitive#': 'vim-fugitive',
        \ 	'plug#': 'vim-plug',
        \ 	'matchit#': 'matchit.vim',
        \ 	'netrw#': 'netrwPlugin.vim',
        \ 	'dist#man#': 'man.vim'
        \ }
  for [ns, plugin] in items(namespace_patterns)
    if stridx(tolower(rhs), tolower(ns)) != -1
      return '[' . plugin . ']'
    endif
  endfor

  " Original logic for <Plug> keywords in rhs
  let plug_match = matchlist(rhs, '<Plug>\(\k\+\)')
  if !empty(plug_match)
      let plug_id = plug_match[1]
      let plug_keywords = {
            \ 	'fzf': 'fzf.vim',
            \ 	'Matchit': 'matchit.vim',
            \ 	'Netrw': 'netrwPlugin.vim',
            \ 	'fugitive': 'vim-fugitive'
            \ }
      for [keyword, plugin] in items(plug_keywords)
          if stridx(plug_id, keyword) == 0
              return '[' . plugin . ']'
          endif
      endfor
  endif

  " Original logic for command names in rhs
  let cmd_match = matchlist(rhs, ':\s*\(\k\+\)')
  if !empty(cmd_match)
      let cmd_name = cmd_match[1]
      let cmd_plugin_map = {
            \ 	'NERDTreeToggle': 'nerdtree',
            \ 	'NERDTree': 'nerdtree',
            \ 	'FZF': 'fzf.vim'
            \ }
      if has_key(cmd_plugin_map, cmd_name)
          return '[' . cmd_plugin_map[cmd_name] . ']'
      endif
  endif

  " Original logic for other built-in patterns
  if a:map.lhs =~# '<D-[vcx]>'
    return '[Vim Internal]'
  endif
  if a:map.lhs ==# 'gx'
      return '[netrwPlugin.vim]'
  endif
  if a:map.lhs ==# '%' || a:map.lhs ==# '[%' || a:map.lhs ==# ']%' || a:map.lhs ==# 'g%'
      return '[matchit.vim]'
  endif
  let builtin_patterns = [
        \ '<C-R>\*',
        \ '<C-G>u<C-U>',
        \ ':nohlsearch',
        \ '"\*P', '"\*y', '"\*d'
        \ ]
  for pattern in builtin_patterns
    if stridx(tolower(rhs), tolower(pattern)) != -1
      return '[Vim Internal]'
    endif
  endfor

  " Final fallback
  return '[Unknown Source]'
endfunction
