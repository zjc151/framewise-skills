---
name: framewise-knowledge
description: 查询帧知知识库——搜索文档、阅读内容、基于视频内容问答。
metadata:
  {
    "openclaw":
      {
        "emoji": "📚",
        "primaryEnv": "FRAMEWISE_API_KEY",
        "homepage": "https://www.framewise.cc/skills",
        "requires": { "bins": ["curl", "sh"] }
      }
  }
---

# 帧知知识库查询（Framewise Knowledge Query）

搜索帧知知识库中的文档，阅读已解析的视频知识内容，或基于视频内容回答问题。

## 何时使用

当用户的意图是以下之一时使用本技能：

- 「我之前解析的那个 XX 视频讲了什么？」——搜索知识库，找到文档后阅读内容并总结
- 「帮我查一下知识库里有没有关于 XX 的内容」——关键词搜索
- 「那个视频里提到的三个核心结论是什么？」——先搜索定位文档，再问答
- 「我存的知识库里，UP主叫什么来着」——搜索或直接查看文档详情

**不要**用于：用户发来一个新视频链接要求解析（那应该用 `framewise-video` 技能提交解析）。

## 前置条件

1. 需要帧知平台 API Key（与 `framewise-video` 技能共用同一个密钥）。从环境变量 `FRAMEWISE_API_KEY` 读取。
2. 若环境变量为空或调用返回 401：
   - 明确告诉用户：「需要配置帧知 API Key。请访问 https://www.framewise.cc/skills 查看配置方法（在账户设置里生成 fw_ 开头的密钥），或在环境变量 FRAMEWISE_API_KEY 或 openclaw.json 的 skills.entries.framewise-knowledge.apiKey 中填入。」
   - 不要继续尝试。

## 工作流程

### 场景 1：搜索知识库

当用户想查找某个主题/关键词的文档时：

```bash
{baseDir}/scripts/framewise_search.sh "<关键词>" "$FRAMEWISE_API_KEY"
```

可选参数：
```bash
# 按标签筛选
{baseDir}/scripts/framewise_search.sh "<关键词>" "$FRAMEWISE_API_KEY" --tag "标签名"

# 翻页
{baseDir}/scripts/framewise_search.sh "<关键词>" "$FRAMEWISE_API_KEY" --page 2
```

脚本输出 JSON（含 items 列表，每项有 id/title/summary/tags/doc_url）。把匹配的文档标题和摘要呈现给用户，让用户选择想看哪篇。

### 场景 2：查看文档详情

当用户想阅读某篇文档的完整内容时（需要先通过搜索拿到 doc_id）：

```bash
{baseDir}/scripts/framewise_doc.sh "<doc_id>" "$FRAMEWISE_API_KEY"
```

脚本输出 JSON（含 content_md 字段，即完整的 Markdown 知识文档正文）。你可以：
- 直接基于 content_md 内容总结回答用户
- content_md 中的图片为完整 HTTPS 链接，若你的模型支持多模态可直接读取图片内容

### 场景 3：基于文档内容问答

当用户对某篇文档有具体问题时（需要先通过搜索拿到 doc_id）：

```bash
{baseDir}/scripts/framewise_qa.sh "<doc_id>" "<问题>" "$FRAMEWISE_API_KEY"
```

脚本输出 JSON（含 answer 字段，即 AI 基于视频 ASR 全文 + 知识文档正文生成的回答）。

**注意**：问答接口限流较严（每用户 5 次/分钟 + 每文档 3 次/分钟），单次对话中连续问答不要超过 3 次。如果问题较泛（如"讲了什么"），优先用场景 2 获取完整内容自行总结，而非反复 QA。

### 典型组合流程

用户：「之前那个关于 Python 装饰器的视频讲了什么？」

1. 搜索：`framewise_search.sh "Python 装饰器" "$FRAMEWISE_API_KEY"` -> 拿到 doc_id
2. 获取详情：`framewise_doc.sh "<doc_id>" "$FRAMEWISE_API_KEY"` -> 拿到完整 content_md
3. 基于 content_md 总结回答用户

用户：「那个视频里说的 functools.wraps 是干嘛的？」

1. 复用上一步的 doc_id
2. 问答：`framewise_qa.sh "<doc_id>" "functools.wraps 是什么作用" "$FRAMEWISE_API_KEY"` -> 拿到精准回答

## 错误处理

- **401**：API Key 无效或未配置 -> 引导用户到 https://www.framewise.cc/skills 配置。
- **429**：限流 -> 告知用户稍后再试，不要连续请求。
- **404（文档不存在）**：doc_id 可能错误或文档已被删除，建议用户重新搜索。
- **搜索结果为空**：建议用户换个关键词，或先通过 `framewise-video` 技能解析视频入库后再查询。
