[English Version](README.md)

# vim-cheatkey

一个智能的 Vim 快捷键提示插件。它不仅能让您为快捷键手动添加描述，还能自动发现您环境中的所有快捷键，并利用 AI 为它们生成您指定语言的精准说明。

## 核心问题

Vim 的强大在于其可定制性，但随着配置的增长和插件的增多，我们往往会忘记自己设置的或插件提供的快捷键。`vim-cheatkey` 旨在通过“手动记录”+“智能发现”相结合的方式，彻底解决这一痛点。

## 核心功能

1.  **手动快捷键文档**: 提供 `:CheatKey` 命令，在创建快捷键的同时为其附加一段描述，拥有最高优先级。
2.  **自动发现与同步**: 提供 `:CheatKeySync` 命令，可扫描您整个 Vim 环境（包括内置、插件、自定义的快捷键），找出所有未被记录的键位。
3.  **AI 智能描述**:
    *   对于自动发现的“孤儿”快捷键，插件能**异步调用**大语言模型（LLM）API，根据其执行的命令智能生成高质量的描述。
    *   **多语言支持**: 能生成您选择的语言的描述（默认为英语）。
    *   **自定义 Prompt**: 允许您定义自己的 Prompt 模板来指导 AI 的输出风格。
    *   支持多种 AI 服务商（如 Google Gemini, OpenAI 等）。
4.  **快捷键面板**: 通过 `:CheatKeyPanel` 命令，弹出一个优雅的窗口，清晰地列出所有已注册和已发现的快捷键及其描述。
5.  **轻量与异步**: 核心同步功能完全异步执行，确保在扫描和请求 AI 时不会冻结您的 Vim 编辑器。

## 用户接口与命令

### 1. 定义快捷键 (手动)

`CheatKey <mode> <keys> <command> "description"`
- **说明**: 手动定义一个快捷键及其描述。这里的描述拥有最高优先级，不会被 AI 覆盖。
- **示例**: `CheatKey n <leader>s :w<CR> "保存当前文件"`

### 2. 同步快捷键 (自动)

`:CheatKeySync`
- **说明**: 异步扫描所有快捷键，并为没有描述的快捷键请求 AI 生成说明。

### 3. 查看快捷键面板

`:CheatKeyPanel`
- **说明**: 打开快捷键备忘面板。
- **推荐绑定**: `nmap <silent> <leader>? :CheatKeyPanel<CR>`

## 配置

在您的 `.vimrc` 文件中进行如下配置：

### 1. 安装插件 (以 `vim-plug` 为例)
```vim
Plug 'wu9o/vim-cheatkey'
```

### 2. AI 服务配置
```vim
" (可选) 设置您希望的语言，默认为 'en' (英语)。
" 支持的语言取决于 AI 模型。例如: 'en', 'zh', 'ja', 'es'。
let g:cheatkey_language = 'zh'

" (可选) 设置 AI 服务商，默认为 'gemini'。
let g:cheatkey_ai_provider = 'gemini'

" (可选) 设置使用的模型名称。
let g:cheatkey_model_name = 'gemini-1.5-flash'

" (必须) 设置一个能获取您 API Key 的 shell 命令。
let g:cheatkey_api_key_command = 'echo $GEMINI_API_KEY'

" (可选) 自定义 Prompt 模板。必须包含 {rhs} 和 {language} 占位符。
let g:cheatkey_prompt_template = '你是一个 Vim 专家。Vim 中的一个快捷键执行以下命令: "{rhs}"。请用 {language}，以不超过15个字的长度，精准地描述这个快捷键的功能。只返回描述文本，不要任何额外的话。'
```

## 技术实现思路

- **`plugin/cheatkey.vim`**:
  - 定义用户命令: `:CheatKey`, `:CheatKeyPanel`, `:CheatKeySync`。
- **`autoload/cheatkey.vim`**:
  - 维护一个快捷键注册表，区分“手动”和“AI生成”两种来源。
  - `cheatkey#register()`: 实现 `:CheatKey` 的手动注册逻辑。
  - `cheatkey#sync()`:
    - 使用 `maplist()` 获取所有映射。
    - 筛选出需要处理的“孤儿”快捷键。
    - 通过 `job_start()` 或 `vim.fn.jobstart()` 异步为每个快捷键构建并执行 `curl` 命令，调用 AI API。Prompt 将从 `g:cheatkey_language` 获取目标语言。
    - 提供回调函数，在 `curl` 执行完毕后，解析返回的 JSON，并将生成的描述更新到注册表中。
  - `cheatkey#show_panel()`: 创建和管理面板窗口，合并展示所有来源的快捷键。

## 未来扩展

- [ ] **分组功能**: 允许用户为快捷键分组（如 `[Git]`, `[文件操作]`），以便在面板中分类展示。
- [ ] **本地 LLM 支持**: 集成对本地运行的 LLM（如 Ollama）的支持。
- [ ] **缓存机制**: 将 AI 生成的结果缓存到本地文件，避免重复请求，加快显示速度。
- [ ] **交互式编辑**: 在面板中直接编辑或完善 AI 生成的描述。
