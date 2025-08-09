[English Version](README.md)

# vim-cheatkey

一个 Vim 插件，提供两种模式来查看您的快捷键：一个干净、您亲自整理的备忘面板，以及一个强大的模糊搜索探索器。

## 核心问题

Vim 的强大在于其可定制性。然而，我们很容易忘记自己定义的快捷键，或是插件提供的快捷键。`vim-cheatkey` 通过提供两种截然不同的方式来查看您的快捷键，从而解决这个问题。

## 核心功能

1.  **备忘模式**: 一个静态面板，只显示您通过 `:CheatKey` 命令明确记录的快捷键。这是您的个人、无噪音的备忘单。
2.  **探索模式**: 一个由 `fzf.vim` 驱动的交互式模糊搜索窗口，允许您探索和发现当前 Vim 会话中**所有**生效的快捷键，并附带其来源信息。
3.  **简单可靠**: 通过将“精心整理的备忘单”与“功能全面的探索器”分离开来，本插件提供了健壮且可预期的体验。

## 用户接口与命令

### 1. 定义快捷键 (用于备忘面板)

`CheatKey <mode> <keys> <command> "description"`
- **说明**: 手动定义一个快捷键及其描述。这是向备忘面板添加条目的**唯一**方式。
- **示例**: `CheatKey n <leader>s :w<CR> "保存当前文件"`

### 2. 查看备忘面板

`:CheatKeyPanel`
- **说明**: 打开一个干净的面板，只显示您用 `:CheatKey` 定义的快捷键。
- **推荐绑定**: `nmap <silent> <leader>? :CheatKeyPanel<CR>`

### 3. 探索所有快捷键

`:CheatKeyExplore`
- **说明**: 打开一个 FZF 窗口，以模糊搜索的方式浏览**所有**来源（Vim、插件、您的 vimrc）的全部可用快捷键。
- **依赖**: 需要安装 `fzf.vim` 插件。
- **推荐绑定**: `nmap <silent> <leader>h :CheatKeyExplore<CR>`

## 配置

### 1. 安装 (以 `vim-plug` 为例)
```vim
" 探索模式需要 fzf.vim
Plug 'junegunn/fzf.vim'

Plug 'wu9o/vim-cheatkey'
```

### 2. 通用配置
```vim
" (可选) 设置显示语言 (当前无效果，为未来功能保留)。
let g:cheatkey_language = 'zh'
```

## 技术实现思路

- **`:CheatKeyPanel`**: 从一个仅由 `:CheatKey` 命令填充的简单内部注册表中读取数据。
- **`:CheatKeyExplore`**:
  - 调用 Vim 的 `maplist()` 函数获取所有映射。
  - 格式化列表，并附加上来源信息（通过映射的脚本ID派生）。
  - 将格式化后的列表传送给 `fzf#run()` 进行交互式搜索。
