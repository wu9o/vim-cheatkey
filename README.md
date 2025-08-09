# vim-cheatkey

[中文文档](README.zh.md)

A Vim plugin to discover and display available keybindings and commands in a searchable fzf panel, helping you master your Vim environment.

## Features

- **Discover Mappings**: Automatically scans and parses all active key mappings.
- **Discover Commands**: Scans and lists all available user-defined and plugin commands.
- **Manual Annotations**: Register your own keybindings with custom descriptions using the `:CheatKey` command.
- **Multi-Language Support**: Displays built-in Vim command documentation in your preferred language (supports English and Chinese).
- **fzf Integration**: Provides a fast and intuitive fuzzy-search panel to find any keybinding instantly.

## Requirements

- [fzf](https://github.com/junegunn/fzf): A command-line fuzzy finder.
- [fzf.vim](https://github.com/junegunn/fzf.vim): Vim plugin for fzf.

## Installation

Install using your favorite plugin manager.

**vim-plug**:
```vim
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
Plug 'wujiuli/vim-cheatkey'
```

## Usage

1.  **`:CheatKeyPanel`**
    - Opens the main fzf panel, displaying all discovered and registered keybindings.

2.  **`:CheatKeySync`**
    - Scans your current Vim environment for all non-default mappings and commands and updates the cache. Run this command whenever you install a new plugin or change your keybindings.

3.  **`:CheatKey "<mode> <keys>" "<description>"`**
    - Manually registers a keybinding with a custom description.
    - Example: `CheatKey "n <leader>f" "Find files"`

## Configuration

### Language Setting

To display the descriptions for Vim's built-in commands in your preferred language, add the following line to your `.vimrc` or `init.vim`:

```vim
" Use 'en' for English (default) or 'zh' for Chinese
let g:cheatkey_lang = 'zh'
```

## How It Works

`vim-cheatkey` intelligently gathers keybinding information from three distinct sources and merges them into a single, searchable list.

1.  **Built-in Command Cache (`autoload/built_in_cache_xx.txt`)**
    - This is a pre-generated list of common, default Vim commands and mappings, shipped with the plugin.
    - The file corresponding to your `g:cheatkey_lang` setting is loaded. This is how multi-language support is achieved.

2.  **Generated Cache (`~/.cache/vim-cheatkey/generated_cache.txt`)**
    - This file is created or updated when you run `:CheatKeySync`.
    - The plugin scans the output of Vim's `:map` and `:command` to discover all currently active, non-default keybindings from your configuration and other plugins.

3.  **Manual Cache (`~/.cache/vim-cheatkey/manual_cache.txt`)**
    - This file stores the custom keybinding annotations you create with the `:CheatKey` command.

When you run `:CheatKeyPanel`, the plugin reads from these three sources, combines them, and pipes the result into the fzf panel for you to search.

## License

MIT