# Zero-Token Web Provider 修复记录

## 背景

`linuxhsj/openclaw-zero-token` 是在官方 `openclaw/openclaw` 基础上添加了 web provider 功能的 fork，
支持通过浏览器 Cookie/Token 直接调用 Claude、ChatGPT、DeepSeek 等平台，无需 API Key。

本文档记录了维护此 fork 所需的三处修复，以及每次同步上游后的检查流程。

---

## 修复一：Web Provider API 类型未注册到 Config Schema

### 问题现象

启动 Gateway 时报错：

```
Invalid config at .openclaw-upstream-state/openclaw.json:
- models.providers.deepseek-web.api: Invalid option: expected one of "openai-completions"|...
- models.providers.claude-web.api: Invalid option: expected one of "openai-completions"|...
```

### 根本原因

`src/config/types.models.ts` 的 `MODEL_APIS` 数组只包含标准 API 类型，不包含 zero-token fork
新增的 web provider 类型，导致 config 校验失败。

### 修复方法

**文件 1：`src/config/types.models.ts`**

在 `MODEL_APIS` 数组末尾添加：

```ts
// zero-token web providers
"deepseek-web",
"doubao-web",
"claude-web",
"chatgpt-web",
"qwen-web",
"kimi-web",
"gemini-web",
"grok-web",
"glm-web",
"glm-intl-web",
"manus-api",
```

**文件 2：`src/config/schema.base.generated.ts`**

搜索文件中两处 `api` 字段的 `enum` 数组（约在第 1033 行和第 1137 行），同样追加上述类型。

### 验证

```bash
node openclaw.mjs config validate
# 输出 "Config valid" 即为成功
```

---

## 修复二：`webauth` 命令未注册

### 问题现象

运行 `openclaw webauth` 或点击面板 `[2] Authorize AI Models` 时报错：

```
error: unknown command 'webauth'
(Did you mean health?)
```

### 根本原因

`src/cli/program/register.webauth.ts` 存在，但没有在主程序命令注册表中引用。

### 修复方法

**文件 1：`src/cli/program/command-registry.ts`**

在 `coreEntries` 数组中，`status` 条目之前添加：

```ts
{
  commands: [
    {
      name: "webauth",
      description: "Authorize Web AI models (Claude, ChatGPT, DeepSeek, etc.)",
      hasSubcommands: false,
    },
  ],
  register: async ({ program }) => {
    const mod = await import("./register.webauth.js");
    mod.registerWebauthCommand(program);
  },
},
```

**文件 2：`src/cli/program/core-command-descriptors.ts`**

在 `CORE_CLI_COMMAND_DESCRIPTORS` 数组中，`status` 条目之前添加：

```ts
{
  name: "webauth",
  description: "Authorize Web AI models (Claude, ChatGPT, DeepSeek, etc.)",
  hasSubcommands: false,
},
```

---

## 修复三：web-models 插件无法加载

### 问题现象

Gateway 日志中反复出现：

```
[plugins] web-models failed to load from extensions/web-models/index.ts:
Error: Cannot find module 'src/plugin-sdk/root-alias.cjs/web-models'
```

以及调用 web provider 时报错：

```
Error: No API provider registered for api: gemini-web
```

### 根本原因

`extensions/web-models/index.ts` 插件依赖 `openclaw/plugin-sdk/web-models`，
但 `scripts/lib/plugin-sdk-entrypoints.json` 中没有 `web-models` 条目，
导致构建时不生成 `dist/plugin-sdk/web-models.js`，`package.json` 的 exports 也缺少对应路径。

### 修复方法

**文件：`scripts/lib/plugin-sdk-entrypoints.json`**

在数组中添加 `"web-models"`，然后重新构建：

```bash
node scripts/copy-plugin-sdk-root-alias.mjs
node scripts/tsdown-build.mjs
```

### 验证

```bash
# 确认文件存在
ls dist/plugin-sdk/web-models.js

# 确认 package.json exports 有这条
node -e "const p=require('./package.json'); console.log(p.exports['./plugin-sdk/web-models'])"
```

### 注意

`package.json` 是上游每次更新都会修改的文件，合并时容易产生冲突。
**更新脚本已内置自动检测和修复**，如果合并后 `web-models.js` 丢失会自动重建。

---

## 更新后自动检查流程

`[Update]` 按钮脚本已内置以下检查，无需手动操作：

1. `config validate` — 检测修复一是否失效
2. 检查 `package.json` exports 中是否有 `./plugin-sdk/web-models`
3. 检查 `dist/plugin-sdk/web-models.js` 是否存在
4. 如果 2 或 3 失败，自动重新运行 `copy-plugin-sdk-root-alias` + `tsdown-build`

---

## 手动同步上游流程

```bash
git fetch origin
git merge origin/main
# 解决冲突时注意保留以下文件中的修改：
#   src/config/types.models.ts
#   src/config/schema.base.generated.ts
#   src/cli/program/command-registry.ts
#   src/cli/program/core-command-descriptors.ts
#   scripts/lib/plugin-sdk-entrypoints.json

pnpm install
node scripts/copy-plugin-sdk-root-alias.mjs
node scripts/tsdown-build.mjs
node openclaw.mjs config validate
```
