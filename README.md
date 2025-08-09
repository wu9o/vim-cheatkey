[中文版](README.zh.md)

# vim-cheatkey

A Vim plugin that provides two modes for viewing your keybindings: a clean, curated cheatsheet and a powerful fuzzy-search explorer.

## The Problem

Vim's power lies in its customizability. However, it's easy to forget your own custom mappings or the mappings provided by plugins. `vim-cheatkey` solves this by providing two distinct ways to view your keybindings.

## Core Features

1.  **Cheatsheet Mode**: A static panel that displays only the keybindings you have explicitly documented using the `:CheatKey` command. This is your personal, noise-free cheatsheet.
2.  **Explore Mode**: An interactive fuzzy-search window, powered by `fzf.vim`, that allows you to explore and discover **all** mappings currently active in your Vim session, complete with information about their source.
3.  **Simple & Reliable**: By separating the curated cheatsheet from the comprehensive explorer, this plugin provides a robust and predictable experience.

## User Interface & Commands

### 1. Define a Keybinding (for the Cheatsheet)

`CheatKey <mode> <keys> <command> "description"`
- **Description**: Manually define a keybinding and its description. This is the **only** way to add entries to the Cheatsheet Panel.
- **Example**: `CheatKey n <leader>s :w<CR> "Save current file"`

### 2. View the Cheatsheet Panel

`:CheatKeyPanel`
- **Description**: Opens a clean panel displaying only the keybindings you have defined with `:CheatKey`.
- **Recommended mapping**: `nmap <silent> <leader>? :CheatKeyPanel<CR>`

### 3. Explore All Mappings

`:CheatKeyExplore`
- **Description**: Opens an FZF window to fuzzy-search through **all** available mappings from all sources (Vim, plugins, your vimrc).
- **Requires**: `fzf.vim` plugin to be installed.
- **Recommended mapping**: `nmap <silent> <leader>h :CheatKeyExplore<CR>`

## Configuration

### 1. Installation (Example with `vim-plug`)
```vim
" fzf.vim is required for the Explore mode
Plug 'junegunn/fzf.vim'

Plug 'wu9o/vim-cheatkey'
```

### 2. General Configuration
```vim
" (Optional) Set the display language for the UI (currently no effect, for future use).
let g:cheatkey_language = 'en'
```

## Technical Implementation Outline

- **`:CheatKeyPanel`**: Reads from a simple internal registry populated only by the `:CheatKey` command.
- **`:CheatKeyExplore`**:
  - Calls Vim's `maplist()` function to get all mappings.
  - Formats the list with source information (derived from the mapping's script ID).
  - Pipes the formatted list into `fzf#run()` for interactive searching.
