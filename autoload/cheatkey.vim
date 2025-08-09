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
  " Always open the panel window first.
  botright new [CheatKey Panel]
  setlocal buftype=nofile bufhidden=wipe noswapfile nonumber norelativenumber signcolumn=no cursorline
  
  " Set window-specific highlighting only if in Neovim, as Vim doesn't support it.
  if has('nvim')
    setlocal winhighlight=Normal:CheatKeyPanel,CursorLine:CheatKeyCursorLine
  endif

  let all_maps = values(extend(copy(s:registry.generated), s:registry.manual))
  let lines = ["--- Vim CheatKey Panel (Press 'q' to close) ---", ""]

  if empty(all_maps)
    " If no keybindings are found, show a helpful message inside the panel.
    call add(lines, "")
    call add(lines, "No keybindings found yet.")
    call add(lines, "")
    call add(lines, "How to add keybindings:")
    call add(lines, "  1. Run `:CheatKeySync` to auto-discover existing mappings.")
    call add(lines, "  2. Define them manually in your .vimrc with `:CheatKey`.")
    call add(lines, "")
  else
    " If keybindings exist, display them in a formatted table.
    let header = printf("%-25s %-10s %s", "Keybinding", "(Mode)", "Description")
    call add(lines, header)
    call add(lines, repeat('=', strwidth(header)))
    for map_info in all_maps
      call add(lines, printf("%-25s %-10s %s", map_info.keys, '(' . map_info.mode . ')', map_info.description))
    endfor
  endif

  call setline(1, lines)
  setlocal nomodifiable
  nnoremap <silent> <buffer> q :q<CR>
  highlight default link CheatKeyPanel Normal
  highlight default link CheatKeyCursorLine CursorLine
endfunction

function! cheatkey#sync() abort
  if !empty(g:cheatkey_api_key_command)
    call s:analyze_ai()
  else
    echom "CheatKey: Syncing with local analyzer..."
    call s:analyze_local()
  endif
endfunction

"==============================================================================
" PRIVATE FUNCTIONS (Internal logic)
"==============================================================================

function! s:analyze_local() abort
  let all_maps = maplist()
  let new_maps_found = 0
  for map in all_maps
    let key_id = map.mode . '#' . map.lhs
    if map.recursive || has_key(s:registry.manual, key_id) || has_key(s:registry.generated, key_id) | continue | endif
    let description = s:get_local_description(map.rhs)
    if !empty(description)
      let s:registry.generated[key_id] = {'mode': map.mode, 'keys': map.lhs, 'command': map.rhs, 'description': description, 'source': 'local'}
      let new_maps_found += 1
    endif
  endfor
  echom "CheatKey: Discovered " . new_maps_found . " new keybindings."
  if bufwinnr('\[CheatKey Panel\]') != -1 | call cheatkey#show_panel() | endif
endfunction

function! s:get_local_description(rhs) abort
  let plug_match = matchstr(a:rhs, '<Plug>(\([^)]\+\))')
  if !empty(plug_match) | return 'Plugin: ' . substitute(plug_match, '[<>()Plug]', '', 'g') | endif
  if a:rhs =~? '^\s*:w\b' | return 'Write file' | endif
  if a:rhs =~? '^\s*:q\b' | return 'Quit' | endif
  if a:rhs =~? '^\s*:NERDTreeToggle\b' | return 'Toggle NERDTree' | endif
  return ''
endfunction

function! s:analyze_ai() abort
  let api_key = trim(system(g:cheatkey_api_key_command))
  if v:shell_error || empty(api_key)
    echom "CheatKey Error: Could not get API key from command: " . g:cheatkey_api_key_command
    return
  endif

  let all_maps = maplist()
  let s:ai_jobs = {} " Reset job tracker
  let jobs_started = 0

  for map in all_maps
    let key_id = map.mode . '#' . map.lhs
    if map.recursive || has_key(s:registry.manual, key_id) || has_key(s:registry.generated, key_id) | continue | endif
    
    let prompt = substitute(g:cheatkey_prompt_template, '{rhs}', escape(map.rhs, '"'), 'g')
    let prompt = substitute(prompt, '{language}', g:cheatkey_language, 'g')
    let json_payload = printf('{"contents":[{"parts":[{"text": "%s"}]}]}', escape(prompt, '"'))
    let url = printf('https://generativelanguage.googleapis.com/v1beta/models/%s:generateContent?key=%s', g:cheatkey_model_name, api_key)
    
    let command = [
          \ 'curl', '-s', '-X', 'POST',
          \ '-H', 'Content-Type: application/json',
          \ '-d', json_payload, url
          \ ]
    
    let s:ai_jobs[jobs_started] = { 'status': 'running', 'map_info': map }
    let job_options = {
          \ 'on_exit': function('s:on_ai_response', [jobs_started]),
          \ 'on_stdout': function('s:on_ai_response', [jobs_started]),
          \ 'exit_cb': function('s:on_ai_response', [jobs_started])
          \ }

    if has('nvim')
        call jobstart(command, job_options)
    else
        call job_start(command, job_options)
    endif
    let jobs_started += 1
  endfor

  if jobs_started > 0
    echom "CheatKey: AI sync started for " . jobs_started . " keybindings."
  else
    echom "CheatKey: No new keybindings to sync with AI."
  endif
endfunction

function! s:on_ai_response(job_id, data, event) dict
    if !has_key(s:ai_jobs, a:job_id) || s:ai_jobs[a:job_id].status == 'finished'
        return
    endif

    if a:event == 'exit'
        let s:ai_jobs[a:job_id].status = 'finished'
        let response_body = type(a:data) == v:t_list ? join(a:data, '') : a:data
        
        try
            let response = json_decode(response_body)
            let description = response.candidates[0].content.parts[0].text
            let map_info = s:ai_jobs[a:job_id].map_info
            let key_id = map_info.mode . '#' . map_info.lhs
            let s:registry.generated[key_id] = {
                  \ 'mode': map_info.mode,
                  \ 'keys': map_info.lhs,
                  \ 'command': map_info.rhs,
                  \ 'description': trim(description),
                  \ 'source': 'ai:' . g:cheatkey_ai_provider
                  \ }
        catch
            " Ignore JSON parsing errors, as the job might fail for various reasons.
        endtry

        " Check if all jobs are finished
        let all_finished = 1
        for job in values(s:ai_jobs)
            if job.status != 'finished'
                let all_finished = 0
                break
            endif
        endfor

        if all_finished
            echom "CheatKey: AI sync complete."
            if bufwinnr('\[CheatKey Panel\]') != -1 | call cheatkey#show_panel() | endif
        endif
    endif
endfunction