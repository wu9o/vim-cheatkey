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
  let desc_match = matchlist(a:args, '\v"(.*)"\s*

" Shows the final cheatsheet panel to the user.
function! cheatkey#show_panel() abort
  echom "Showing panel..."
  " TODO: Open a new window and populate it with data from s:registry
endfunction

" Starts the process of discovering and describing keymaps.
function! cheatkey#sync() abort
  if !empty(g:cheatkey_api_key_command)
    echom "Syncing with AI..."
    " TODO: Call the AI-based analyzer
  else
    echom "Syncing with local analyzer..."
    " TODO: Call the local rule-based analyzer
  endif
endfunction

"==============================================================================
" PRIVATE FUNCTIONS (Internal logic)
"==============================================================================

" TODO: Add internal helper functions for parsing, analysis, etc.
)
  if empty(desc_match)
    echom "CheatKey Error: Description must be the last argument, enclosed in double quotes."
    return
  endif
  let description = desc_match[1]

  " 2. Get the part before the description by substituting the matched part with an empty string.
  let command_part = substitute(a:args, '\v\s*".*"\s*

" Shows the final cheatsheet panel to the user.
function! cheatkey#show_panel() abort
  echom "Showing panel..."
  " TODO: Open a new window and populate it with data from s:registry
endfunction

" Starts the process of discovering and describing keymaps.
function! cheatkey#sync() abort
  if !empty(g:cheatkey_api_key_command)
    echom "Syncing with AI..."
    " TODO: Call the AI-based analyzer
  else
    echom "Syncing with local analyzer..."
    " TODO: Call the local rule-based analyzer
  endif
endfunction

"==============================================================================
" PRIVATE FUNCTIONS (Internal logic)
"==============================================================================

" TODO: Add internal helper functions for parsing, analysis, etc.
, '', '')

  " 3. Split the remaining part by whitespace to get mode, keys, and command.
  let parts = split(command_part, '\s\+')
  if len(parts) < 3
    echom "CheatKey Error: Invalid format. Use: CheatKey <mode> <keys> <command> \"description\""
    return
  endif

  let mode = parts[0]
  let keys = parts[1]
  let command = join(parts[2:], ' ') " Re-join the rest of the parts to form the complete command.

  " 4. Execute the actual mapping command. We add <silent> by default for a better user experience.
  try
    execute mode . 'map <silent> ' . keys . ' ' . command
  catch
    echom "CheatKey Error: Failed to map key '" . keys . "'. Error: " . v:exception
    return
  endtry

  " 5. Store the information in our manual registry.
  " We create a unique ID for the keymap using its mode and keys.
  let key_id = mode . '#' . keys
  let s:registry.manual[key_id] = {
        \ 'mode': mode,
        \ 'keys': keys,
        \ 'command': command,
        \ 'description': description,
        \ 'source': 'manual'
        \ }

  " Provide feedback to the user that the key was registered.
  echom "CheatKey: Registered '" . keys . "' -> '" . description . "'"
endfunction


" Shows the final cheatsheet panel to the user.
function! cheatkey#show_panel() abort
  echom "Showing panel..."
  " TODO: Open a new window and populate it with data from s:registry
endfunction

" Starts the process of discovering and describing keymaps.
function! cheatkey#sync() abort
  if !empty(g:cheatkey_api_key_command)
    echom "Syncing with AI..."
    " TODO: Call the AI-based analyzer
  else
    echom "Syncing with local analyzer..."
    " TODO: Call the local rule-based analyzer
  endif
endfunction

"==============================================================================
" PRIVATE FUNCTIONS (Internal logic)
"==============================================================================

" TODO: Add internal helper functions for parsing, analysis, etc.
