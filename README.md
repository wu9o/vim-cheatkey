
[中文版](README.zh.md)

# vim-cheatkey

An intelligent keybinding cheatsheet plugin for Vim. It not only allows you to manually add descriptions to your keybindings but also automatically discovers all keymaps in your environment and uses AI to generate accurate descriptions for them in your preferred language.

## The Problem

Vim's power lies in its customizability. However, as configurations grow and plugins are added, we often forget the keybindings we've set up. Constantly checking `.vimrc` files is inefficient and breaks focus. `vim-cheatkey` aims to solve this by combining manual documentation with intelligent discovery.

## Core Features

1.  **Manual Keymap Documentation**: Provides a `:CheatKey` command to attach a description to a keybinding, which always takes the highest priority.
2.  **Auto-Discovery & Sync**: Provides a `:CheatKeySync` command that scans your entire Vim environment (built-in, plugins, custom maps) to find undocumented keybindings.
3.  **AI-Powered Descriptions**:
    *   For discovered "orphan" keymaps, the plugin **asynchronously** calls a Large Language Model (LLM) API to generate high-quality descriptions based on the executed command.
    *   **Multi-language Support**: Generates descriptions in the language of your choice (defaults to English).
    *   **Customizable Prompts**: Allows you to define your own prompt template to guide the AI's output style.
    *   Supports various AI providers (e.g., Google Gemini, OpenAI).
4.  **Cheatsheet Panel**: Provides a `:CheatKeyPanel` command to open an elegant panel displaying all registered and discovered keybindings with their descriptions.
5.  **Lightweight & Asynchronous**: The core sync feature runs entirely asynchronously, ensuring no freezing of your Vim editor during scanning or AI requests.

## User Interface & Commands

### 1. Define a Keybinding (Manual)

`CheatKey <mode> <keys> <command> "description"`
- **Description**: Manually define a keybinding and its description. This description has the highest priority and will not be overwritten by the AI.
- **Example**: `CheatKey n <leader>s :w<CR> "Save current file"`

### 2. Sync Keybindings (Automatic)

`:CheatKeySync`
- **Description**: Asynchronously scans all keymaps and requests AI-generated descriptions for those without one.

### 3. View the Cheatsheet Panel

`:CheatKeyPanel`
- **Description**: Opens the keybinding cheatsheet panel.
- **Recommended mapping**: `nmap <silent> <leader>? :CheatKeyPanel<CR>`

## Configuration

Configure the plugin in your `.vimrc` file:

### 1. Installation (Example with `vim-plug`)
```vim
Plug 'wu9o/vim-cheatkey'
```

### 2. AI Service Configuration
```vim
" (Optional) Set your desired language. Defaults to 'en' (English).
" Supported languages depend on the AI model. Examples: 'en', 'zh', 'ja', 'es'.
let g:cheatkey_language = 'en'

" (Optional) Set the AI provider. Defaults to 'gemini'.
let g:cheatkey_ai_provider = 'gemini'

" (Optional) Set the specific model name to use.
let g:cheatkey_model_name = 'gemini-1.5-flash'

" (Required) Set a shell command that can retrieve your API key.
let g:cheatkey_api_key_command = 'echo $GEMINI_API_KEY'

" (Optional) Customize the prompt template. Must include {rhs} and {language}.
let g:cheatkey_prompt_template = 'You are a Vim expert. A keybinding in Vim executes the following command: "{rhs}". Please provide a concise, functional description for this command in {language}, under 15 characters. Return only the description text, without any extra formatting or explanation.'
```

## Technical Implementation Outline

- **`plugin/cheatkey.vim`**:
  - Defines the user commands: `:CheatKey`, `:CheatKeyPanel`, `:CheatKeySync`.
- **`autoload/cheatkey.vim`**:
  - Manages a keymap registry, distinguishing between "manual" and "ai-generated" sources.
  - `cheatkey#register()`: Implements the logic for manual registration via `:CheatKey`.
  - `cheatkey#sync()`:
    - Uses `maplist()` to get all mappings.
    - Filters for "orphan" keymaps to process.
    - Asynchronously builds and executes `curl` commands for each keymap via `job_start()` or `vim.fn.jobstart()`, calling the AI API. The prompt will be populated with the target language from `g:cheatkey_language`.
    - Provides a callback function to parse the returned JSON and update the registry with the generated description.
  - `cheatkey#show_panel()`: Creates and manages the panel window, merging and displaying all keymaps.

## Future Enhancements

- [ ] **Grouping**: Allow users to group keybindings (e.g., `[Git]`, `[File Ops]`) for categorized display.
- [ ] **Local LLM Support**: Integrate support for locally-run LLMs like Ollama.
- [ ] **Caching**: Cache AI-generated results to a local file to avoid redundant requests and speed up display.
- [ ] **Interactive Editing**: Allow direct editing or refinement of AI-generated descriptions within the panel.
