[中文版](README.zh.md)

# vim-cheatkey

An intelligent keybinding cheatsheet plugin for Vim. It not only allows you to manually add descriptions to your keybindings but also automatically discovers all keymaps in your environment and uses AI to generate accurate descriptions for them in your preferred language.

## The Problem

Vim's power lies in its customizability. However, as configurations grow and plugins are added, we often forget the keybindings we've set up. Constantly checking `.vimrc` files is inefficient and breaks focus. `vim-cheatkey` aims to solve this by combining manual documentation with intelligent discovery.

## Core Features

1.  **Manual Keymap Documentation**: Provides a `:CheatKey` command to attach a description to a keybinding, which always takes the highest priority.
2.  **Auto-Discovery & Sync**: Provides a `:CheatKeySync` command that scans your entire Vim environment to find all keybindings.
3.  **Two-Tier Description Generation**:
    *   **Local Fallback Analyzer (Default)**: An offline, rule-based engine that provides good-enough descriptions for common Vim commands and `<Plug>` mappings. Works out-of-the-box with zero configuration.
    *   **AI-Powered Descriptions (Optional)**: If you provide an API key, the plugin can asynchronously call a Large Language Model (LLM) to generate superior, context-aware descriptions in your preferred language.
4.  **Cheatsheet Panel**: A `:CheatKeyPanel` command to open an elegant panel displaying all keybindings.
5.  **Lightweight & Asynchronous**: The AI sync feature runs entirely asynchronously, ensuring no freezing of your Vim editor.

## User Interface & Commands

### 1. Define a Keybinding (Manual)
`CheatKey <mode> <keys> <command> "description"`

### 2. Sync Keybindings (Automatic)
`:CheatKeySync`

### 3. View the Cheatsheet Panel
`:CheatKeyPanel`

## Configuration

Configure the plugin in your `.vimrc` file:

### 1. Installation (Example with `vim-plug`)
```vim
Plug 'wu9o/vim-cheatkey'
```

### 2. General Configuration
```vim
" (Optional) Set the display language for descriptions. Defaults to 'en'.
" This affects both the AI-generated descriptions and potentially future
" localizations of the plugin's UI and local analyzer.
" Examples: 'en', 'zh', 'ja', 'es'.
let g:cheatkey_language = 'en'
```

### 3. AI Service Configuration (Optional)

If you wish to use the AI-powered description feature, configure the following.

```vim
" (Optional) Set the AI provider. Defaults to 'gemini'.
let g:cheatkey_ai_provider = 'gemini'

" (Optional) Set the specific model name to use.
let g:cheatkey_model_name = 'gemini-1.5-flash'

" (Required for AI) Set a shell command that can retrieve your API key.
let g:cheatkey_api_key_command = 'echo $GEMINI_API_KEY'

" (Optional) Customize the prompt template. Must include {rhs} and {language}.
let g:cheatkey_prompt_template = 'You are a Vim expert. A keybinding in Vim executes the following command: "{rhs}". Please provide a concise, functional description for this command in {language}, under 15 characters. Return only the description text, without any extra formatting or explanation.'
```

## Technical Implementation Outline

- **`plugin/cheatkey.vim`**: Defines user commands.
- **`autoload/cheatkey.vim`**:
  - `cheatkey#sync()`: Checks if `g:cheatkey_api_key_command` is set.
    - If YES: Calls the asynchronous AI analyzer.
    - If NO: Calls the local, rule-based analyzer.
  - The AI analyzer uses `g:cheatkey_language` to format its prompt.