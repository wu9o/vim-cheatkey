" autoload/cheatkey.vim
" Author: Gemini
" License: MIT
"
" This is the core logic file for the vim-cheatkey plugin.

"==============================================================================
" INITIALIZATION & CONFIGURATION
"==============================================================================

" This dictionary will hold all our keymap information.
" We use a dictionary for fast lookups. The key is a unique identifier for the map.
" 'manual' stores user-defined maps via :CheatKey (highest priority).
" 'generated' stores maps from the local analyzer or AI.
let s:registry = {
\ 'manual': {},
\ 'generated': {}
\ }

" Load user configuration with sane defaults.
" The get() function is used to avoid errors if the user hasn't set the variable.
let g:cheatkey_language = get(g:, 'cheatkey_language', 'en')
let g:cheatkey_ai_provider = get(g:, 'cheatkey_ai_provider', 'gemini')
let g:cheatkey_model_name = get(g:, 'cheatkey_model_name', 'gemini-1.5-flash')
let g:cheatkey_api_key_command = get(g:, 'cheatkey_api_key_command', '') " Default to empty, indicating AI is off.
let g:cheatkey_prompt_template = get(g:, 'cheatkey_prompt_template', 'You are a Vim expert. A keybinding in Vim executes the following command: "{rhs}". Please provide a concise, functional description for this command in {language}, under 15 characters. Return only the description text, without any extra formatting or explanation.')

"==============================================================================
" PUBLIC FUNCTIONS (Called from commands)
"==============================================================================

" Registers a keybinding defined with the :CheatKey command.
function! cheatkey#register(args) abort
  " 1. Extract the description from the end of the string using a regex.
  let desc_match = matchlist(a:args, '\v"(.*)"\s*$')
  if empty(desc_match)
    echom "CheatKey Error: Description must be the last argument, enclosed in double quotes."
    return
  endif
  let description = desc_match[1]

  " 2. Get the part before the description.
  let command_part = substitute(a:args, '\v\s*".*"\s*$', '', '')

  " 3. Split the remaining part by whitespace.
  let parts = split(command_part, '\s\+')
  if len(parts) < 3
    echom "CheatKey Error: Invalid format. Use: CheatKey <mode> <keys> <command> \"description\""
    return
  endif

  let mode = parts[0]
  let keys = parts[1]
  let command = join(parts[2:], ' ') " Re-join the rest to form the complete command.

  " 4. Execute the actual mapping command.
  try
    execute mode . 'map <silent> ' . keys . ' ' . command
  catch
    echom "CheatKey Error: Failed to map key '" . keys . "'. Error: " . v:exception
    return
  endtry

  " 5. Store the information in our manual registry.
  let key_id = mode . '#' . keys
  let s:registry.manual[key_id] = {
        \ 'mode': mode,
        \ 'keys': keys,
        \ 'command': command,
        \ 'description': description,
        \ 'source': 'manual'
        \ }

  echom "CheatKey: Registered '" . keys . "' -> '" . description . "'"
endfunction

" Shows the final cheatsheet panel to the user.
function! cheatkey#show_panel() abort
  " 1. Combine manual and generated registries. Manual entries take precedence.
  let all_maps = values(extend(copy(s:registry.generated), s:registry.manual))

  " 2. Check if there's anything to show.
  if empty(all_maps)
    echom "CheatKey: No keybindings registered or synced yet. Use :CheatKey or :CheatKeySync."
    return
  endif

  " 3. Open a new scratch buffer for the panel.
  botright new [CheatKey Panel]

  " 4. Set buffer-local options to make it a proper panel.
  setlocal buftype=nofile
  setlocal bufhidden=wipe
  setlocal noswapfile
  setlocal nonumber
  setlocal norelativenumber
  setlocal signcolumn=no
  setlocal cursorline
  setlocal winhighlight=Normal:CheatKeyPanel,CursorLine:CheatKeyCursorLine

  " 5. Prepare the lines to be displayed.
  let lines = ["--- Vim CheatKey Panel (Press 'q' to close) ---", ""]
  let header = printf("% -25s % -10s %s", "Keybinding", "(Mode)", "Description")
  call add(lines, header)
  call add(lines, repeat('=', strwidth(header)))

  for map_info in all_maps
    let line = printf("% -25s % -10s %s", map_info.keys, '(' . map_info.mode . ')', map_info.description)
    call add(lines, line)
  endfor

  " 6. Write the lines to the buffer and make it read-only.
  call setline(1, lines)
  setlocal nomodifiable

  " 7. Map 'q' to close this specific window.
  nnoremap <silent> <buffer> q :q<CR>

  " 8. (Optional) Define some basic highlighting for the panel.
  highlight default link CheatKeyPanel Normal
  highlight default link CheatKeyCursorLine CursorLine
endfunction

" Starts the process of discovering and describing keymaps.
function! cheatkey#sync() abort
  if !empty(g:cheatkey_api_key_command)
    echom "CheatKey: Syncing with AI..."
    " TODO: Call the AI-based analyzer
  else
    echom "CheatKey: Syncing with local analyzer..."
    call s:analyze_local()
  endif
endfunction

"==============================================================================
" PRIVATE FUNCTIONS (Internal logic)
"==============================================================================

" Analyzes keymaps using the local, rule-based engine.
function! s:analyze_local() abort
  let all_maps = maplist()
  let new_maps_found = 0

  for map in all_maps
    " Create a unique ID for the map to check against our registries.
    let key_id = map.mode . '#' . map.lhs

    " Skip if it's a recursive mapping, already documented manually, or generated before.
    if map.recursive || has_key(s:registry.manual, key_id) || has_key(s:registry.generated, key_id)
      continue
    endif

    " Generate a description for the new keymap.
    let description = s:get_local_description(map.rhs)
    if !empty(description)
      let s:registry.generated[key_id] = {
            \ 'mode': map.mode,
            \ 'keys': map.lhs,
            \ 'command': map.rhs,
            \ 'description': description,
            \ 'source': 'local'
            \ }
      let new_maps_found += 1
    endif
  endfor

  if new_maps_found > 0
    echom "CheatKey: Discovered and described " . new_maps_found . " new keybindings."
  else
    echom "CheatKey: No new keybindings discovered."
  endif
  
  " Refresh the panel if it's already open
  if bufwinnr('\[CheatKey Panel\]') != -1
      call cheatkey#show_panel()
  endif
endfunction

" Generates a description for a command (rhs) based on a set of rules.
function! s:get_local_description(rhs) abort
  " Rule 1: Handle <Plug> mappings, which are very common for plugins.
  let plug_match = matchstr(a:rhs, '<Plug>(\([^)]\+\))')
  if !empty(plug_match)
    " Clean up the plug name, e.g., (vim-sneak-s) -> vim-sneak-s
    let plug_name = substitute(plug_match, '[<>()Plug]', '', 'g')
    return 'Plugin: ' . plug_name
  endif

  " Rule 2: Handle common commands (case-insensitive)
  if a:rhs =~? '^\s*:w\b'
    return 'Write file'
  elseif a:rhs =~? '^\s*:q\b'
    return 'Quit'
  elseif a:rhs =~? '^\s*:NERDTreeToggle\b'
    return 'Toggle NERDTree'
  elseif a:rhs =~? '^\s*:Telescope\b'
    return 'Open Telescope'
  elseif a:rhs =~? '^\s*:FZF\b'
    return 'Open FZF'
  endif

  " Fallback: if no specific rule matches, we don't return a description.
  " This avoids polluting the panel with unhelpful entries.
  return ''
endfunction
