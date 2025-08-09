[English Version](README.md)

# vim-cheatkey

一个智能的 Vim 快捷键提示插件。它不仅能让您为快捷键手动添加描述，还能自动发现您环境中的所有快捷键，并利用 AI 为它们生成您指定语言的精准说明。

## 核心问题

Vim 的强大在于其可定制性，但随着配置的增长和插件的增多，我们往往会忘记自己设置的或插件提供的快捷键。`vim-cheatkey` 旨在通过“手动记录”+“智能发现”相结合的方式，彻底解决这一痛点。

## 核心功能

1.  **手动快捷键文档**: 提供 `:CheatKey` 命令，在创建快捷键的同时为其附加一段描述，拥有最高优先级。
2.  **自动发现与同步**: 提供 `:CheatKeySync` 命令，可扫描您整个 Vim 环境以查找所有快捷键。
3.  **两级描述生成机制**:
    *   **本地回退分析器 (默认)**: 一个离线的、基于规则的引擎，能为常见的 Vim 命令和 `<Plug>` 映射提供足够好的描述。无需配置，开箱即用。
    *   **AI 智能描述 (可选)**: 如果您提供了 API 密钥，插件能异步调用大语言模型 (LLM) 为快捷键生成更优秀、感知上下文的描述。
4.  **快捷键面板**: 通过 `:CheatKeyPanel` 命令，弹出一个优雅的窗口，清晰地列出所有快捷键。
5.  **轻量与异步**: AI 同步功能完全异步执行，确保在扫描和请求时不会冻结您的 Vim 编辑器。

## 用户接口与命令

### 1. 定义快捷键 (手动)
`CheatKey <mode> <keys> <command> "description"`

### 2. 同步快捷键 (自动)
`:CheatKeySync`

### 3. 查看快捷键面板
`:CheatKeyPanel`

## 配置

在您的 `.vimrc` 文件中进行如下配置：

### 1. 安装插件 (以 `vim-plug` 为例)
```vim
Plug 'wu9o/vim-cheatkey'
```

### 2. 通用配置
```vim
" (可选) 设置描述的显示语言，默认为 'en' (英语)。
" 这个设置会影响 AI 生成的描述，以及未来插件 UI 和本地分析器的本地化。
" 例如: 'en', 'zh', 'ja', 'es'。
let g:cheatkey_language = 'zh'
```

### 3. AI 服务配置 (可选)

如果您希望使用 AI 描述功能，请进行以下配置。

```vim
" (可选) 设置 AI 服务商，默认为 'gemini'。
let g:cheatkey_ai_provider = 'gemini'

" (可选) 设置使用的模型名称。
let g:cheatkey_model_name = 'gemini-1.5-flash'

" (AI功能必须) 设置一个能获取您 API Key 的 shell 命令。
let g:cheatkey_api_key_command = 'echo $GEMINI_API_KEY'

" (可选) 自定义 Prompt 模板。必须包含 {rhs} 和 {language} 占位符。
let g:cheatkey_prompt_template = '你是一个 Vim 专家。Vim 中的一个快捷键执行以下命令: "{rhs}"。请用 {language}，以不超过15个字的长度，精准地描述这个快捷键的功能。只返回描述文本，不要任何额外的话。'
```

## 技术实现思路

- **`plugin/cheatkey.vim`**: 定义用户命令。
- **`autoload/cheatkey.vim`**:
  - `cheatkey#sync()`: 检查 `g:cheatkey_api_key_command` 是否已配置。
    - **如果配置了**: 调用异步的 AI 分析器。
    - **如果未配置**: 调用本地的、基于规则的分析函数。
  - AI 分析器会使用 `g:cheatkey_language` 的值来格式化它的 Prompt。