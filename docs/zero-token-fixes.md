# Zero-Token Web Provider 修复记录

## 背景

`linuxhsj/openclaw-zero-token` 是在官方 `openclaw/openclaw` 基础上添加了 web provider 功能的 fork，
支持通过浏览器 Cookie/Token 直接调用 Claude、ChatGPT、DeepSeek 等平台，无需 API Key。

每次同步上游代码后，以下两处修复可能需要重新确认。

---

## 修复一：Web Provider API 类型未注册到 Config Schema

### 问题现象

启动 Gateway 时报错：

```
Invalid config at .openclaw-upstream-state/openclaw.json:
- models.providers.deepseek-web.api: Invalid option: expected one of "openai-completions"|...
- models.providers.claude-web.api: Invalid option: expected one of "openai-completions"|...
...（所有 web provider 均报错）
```

### 根本原因

`src/config/types.models.ts` 的 `MODEL_APIS` 数组只包含标准 API 类型，
不包含 zero-token fork 新增的 web provider 类型，导致 config 校验失败。

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

搜索文件中两处 `api` 字段的 `enum` 数组（约在第 1033 行和第 1137 行），
同样追加上述 web provider 类型。

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

`src/cli/program/register.webauth.ts` 文件存在，但没有在主程序命令注册表中引用，
导致 CLI 不认识这个命令。

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

## 更新后检查流程

每次 `git pull` 同步上游后，运行：

```bash
node openclaw.mjs config validate
```

如果报 `Invalid option` 错误，重新应用修复一。
如果 `webauth` 命令消失，重新应用修复二。

---

## 维护建议

将此 repo fork 到自己的 GitHub，把这些修复作为独立 commit 保留。
上游更新时执行：

```bash
git fetch upstream
git merge upstream/main
# 解决冲突时保留本文件中的修改
```
