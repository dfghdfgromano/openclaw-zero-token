/**
 * Web Models Plugin
 *
 * 提供基于浏览器的 Web AI 模型支持
 * 支持 ChatGPT Web, Claude Web, DeepSeek Web 等
 */

import type { OpenClawPluginApi } from "openclaw/plugin-sdk/web-models";
import { emptyPluginConfigSchema, getWebStreamFactory } from "openclaw/plugin-sdk/web-models";

const WEB_PROVIDER_IDS = [
  "chatgpt-web",
  "claude-web",
  "deepseek-web",
  "doubao-web",
  "gemini-web",
  "glm-web",
  "glm-intl-web",
  "grok-web",
  "kimi-web",
  "qwen-web",
  "qwen-cn-web",
  "perplexity-web",
  "xiaomimo-web",
  "manus-api",
] as const;

const webModelsPlugin = {
  id: "web-models",
  name: "Web Models",
  description: "Web-based AI model providers (ChatGPT Web, Claude Web, DeepSeek Web, etc.)",
  configSchema: emptyPluginConfigSchema(),
  register(api: OpenClawPluginApi) {
    for (const providerId of WEB_PROVIDER_IDS) {
      const factory = getWebStreamFactory(providerId);
      if (!factory) {
        continue;
      }

      api.registerProvider({
        id: providerId,
        label: providerId,
        models: {
          baseUrl: "",
          apiKey: "",
          api: providerId as string,
          models: [],
        },
        auth: [],
        // 注册 stream 处理器，让 Gateway 能调用 web provider
        createStreamFn(ctx) {
          const providerConfig = ctx.config?.models?.providers?.[providerId];
          const apiKey = typeof providerConfig?.apiKey === "string" ? providerConfig.apiKey : "";
          return factory(apiKey);
        },
      });
    }
  },
};

export default webModelsPlugin;
