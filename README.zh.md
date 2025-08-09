# vim-cheatkey

[English Documentation](README.md)

一个 Vim 插件，旨在发现并显示所有可用的快捷键和命令。它通过一个可搜索的 fzf 面板，帮助您快速掌握您的 Vim 环境。

## 功能特性

- **发现映射**: 自动扫描并解析所有当前生效的快捷键映射。
- **发现命令**: 扫描并列出所有可用的用户自定义及插件命令。
- **手动注解**: 使用 `:CheatKey` 命令，为您自己的快捷键注册自定义的描述。
- **多语言支持**: 以您偏好的语言（支持英文和中文）来显示 Vim 内置指令的文档。
- **fzf 集成**: 提供一个快速、直观的模糊搜索面板，让您能即时找到任何快捷键。

## 环境要求

- [fzf](https://github.com/junegunn/fzf): 命令行模糊搜索工具。
- [fzf.vim](https://github.com/junegunn/fzf.vim): fzf 的 Vim 插件。

## 安装

使用您喜欢的插件管理器进行安装。

**vim-plug**:
```vim
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
Plug 'wujiuli/vim-cheatkey'
```

## 使用方法

1.  **`:CheatKeyPanel`**
    - 打开核心的 fzf 面板，它会显示所有已发现和已注册的快捷键。

2.  **`:CheatKeySync`**
    - 扫描您当前的 Vim 环境，找出所有非默认的映射和命令，并更新缓存。每当您安装新插件或更改快捷键配置后，都应运行此命令。

3.  **`:CheatKey "<模式> <键位>" "<描述>"`**
    - 手动注册一个快捷键，并为其添加自定义描述。
    - 示例: `CheatKey "n <leader>f" "查找文件"`

## 配置

### 语言设置

要让插件以您偏好的语言来显示 Vim 内置指令的描述，请将以下这行配置添加到您的 `.vimrc` 或 `init.vim` 文件中：

```vim
" 使用 'en' 代表英文 (默认)，'zh' 代表中文
let g:cheatkey_lang = 'zh'
```

## 工作原理

`vim-cheatkey` 会智能地从三个不同的来源收集快捷键信息，并将它们合并成一个统一的可搜索列表。

1.  **内置指令缓存 (`autoload/built_in_cache_xx.txt`)**
    - 这是一个预先生成好的列表，包含了常见的、默认的 Vim 命令和映射，它作为插件的一部分被分发。
    - 插件会根据您的 `g:cheatkey_lang` 设置来加载对应的文件（`_en` 或 `_zh`）。多语言支持就是通过这种方式实现的。

2.  **自动生成缓存 (`~/.cache/vim-cheatkey/generated_cache.txt`)**
    - 这个文件在您运行 `:CheatKeySync` 时被创建或更新。
    - 插件通过扫描 Vim 的 `:map` 和 `:command` 命令的输出来发现所有当前生效的、非默认的快捷键（来自您的配置以及其他插件）。

3.  **手动添加缓存 (`~/.cache/vim-cheatkey/manual_cache.txt`)**
    - 这个文件用于存储您通过 `:CheatKey` 命令创建的自定义快捷键注解。

当您运行 `:CheatKeyPanel` 时，插件会读取这三个来源的数据，将它们合并，然后传送给 fzf 面板供您搜索。

## 许可证

MIT