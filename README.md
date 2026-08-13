# FrameWise Skills

帧知 FrameWise 的 AI Agent 技能集合。把帧知的视频解析和知识库查询能力接入你使用的 AI Agent，在对话中直接使用。

> **线上访问**：[https://www.framewise.cc](https://www.framewise.cc) · [接入指南](https://www.framewise.cc/skills)

## 兼容性

本仓库的 Skill 基于 SKILL.md 标准机制，纯 curl 脚本实现，零依赖。兼容所有支持 Skill 机制的 AI Agent，包括但不限于：

- **Claude Code**
- **Codex**
- **OpenClaw**
- **Hermes**
- 其他支持 SKILL.md + shell 脚本的 Agent

## 技能列表

| 技能 | 作用 | 触发场景 |
| --- | --- | --- |
| **framewise-video** 🎬 | 提交视频链接解析为知识文档 | 用户发来抖音/B站视频链接，要求整理/解析/转笔记 |
| **framewise-knowledge** 📚 | 查询知识库、阅读文档内容、基于视频内容问答 | 用户问"之前解析的 XX 视频讲了什么"、搜索知识库、对已解析内容提问 |

两个技能共用同一个 API Key，可按需安装一个或两个。

## 安装方式

### 1. 克隆仓库

```bash
git clone https://github.com/zjc151/framewise-skills.git
```

### 2. 复制所需技能到你的 Agent skills 目录

不同 Agent 的 skills 目录不同：

| Agent | Skills 目录 | 配置方式 |
| --- | --- | --- |
| Claude Code | `~/.claude/skills/` | 环境变量 `FRAMEWISE_API_KEY` |
| Codex | `~/.codex/skills/` | 环境变量 `FRAMEWISE_API_KEY` |
| OpenClaw | `~/.openclaw/skills/` | `openclaw.json` skills.entries |
| Hermes | `~/.hermes/skills/` | 环境变量 `FRAMEWISE_API_KEY` |
| 通用 / 其他 | `~/.<agent>/skills/` | 环境变量 `FRAMEWISE_API_KEY` |

```bash
# 以 Claude Code 为例：
cp -r framewise-skills/skills/framewise-video ~/.claude/skills/
cp -r framewise-skills/skills/framewise-knowledge ~/.claude/skills/
```

### 3. 配置 API Key

#### 方式一：环境变量（通用，推荐）

```bash
export FRAMEWISE_API_KEY="fw_你的密钥"
```

在 [帧知设置页](https://www.framewise.cc/settings) 生成 `fw_` 开头的 API Key。

#### 方式二：openclaw.json（OpenClaw 专用）

编辑 `~/.openclaw/openclaw.json`：

```json
{
  "skills": {
    "entries": {
      "framewise-video": {
        "enabled": true,
        "apiKey": "fw_你的密钥"
      },
      "framewise-knowledge": {
        "enabled": true,
        "apiKey": "fw_你的密钥"
      }
    }
  }
}
```

### 4. 重启 Agent 网关

```bash
# 按你的 Agent 方式重启，例如 OpenClaw:
openclaw gateway restart
```

## 获取 API Key

1. 访问 [https://www.framewise.cc/settings](https://www.framewise.cc/settings)
2. 在「API 密钥」区域点击「生成密钥」
3. 复制 `fw_` 开头的密钥（只显示一次，请妥善保存）
4. 如泄露可到设置页撤销后重新生成

## 依赖的后端接口

### 视频解析（framewise-video）

| 端点 | 方法 | 说明 |
| --- | --- | --- |
| `/api/v1/agent/parse` | POST | 提交解析任务 |
| `/api/v1/agent/tasks/{task_id}` | GET | 查询任务状态 |

### 知识库查询（framewise-knowledge）

| 端点 | 方法 | 说明 |
| --- | --- | --- |
| `/api/v1/agent/documents` | GET | 搜索/列出知识库文档 |
| `/api/v1/agent/documents/{doc_id}` | GET | 获取文档详情（含 Markdown 正文） |
| `/api/v1/agent/documents/{doc_id}/qa` | POST | 基于文档内容问答 |

所有接口均使用 `Authorization: Bearer fw_密钥` 认证。详见 [API 参考文档](docs/api-reference.md)。

## 限流说明

| 端点 | 限制 |
| --- | --- |
| 提交解析 | 无（受并发任务数限制） |
| 任务状态查询 | 每用户每任务 1 次/分钟 |
| 知识库搜索 | 每用户 10 次/分钟 |
| 文档详情 | 每用户 10 次/分钟 |
| 文档问答 | 每用户 5 次/分钟 + 每文档 3 次/分钟 |

Nginx 层另有按 IP 的兜底限流（15 次/分钟 burst=10）。

## 目录结构

```
framewise-skills/
├── README.md                          # 本文件
├── skills/
│   ├── framewise-video/               # 视频解析技能
│   │   ├── SKILL.md
│   │   ├── scripts/
│   │   │   ├── framewise_parse.sh     # 提交解析
│   │   │   └── framewise_status.sh    # 查询状态
│   │   └── .env.example
│   └── framewise-knowledge/           # 知识库查询技能
│       ├── SKILL.md
│       ├── scripts/
│       │   ├── framewise_search.sh    # 搜索知识库
│       │   ├── framewise_doc.sh       # 获取文档详情
│       │   └── framewise_qa.sh        # 文档问答
│       └── .env.example
└── docs/
    └── api-reference.md               # API 参考文档
```

## 常见问题

- **密钥泄露了怎么办？** 到帧知设置页「API 密钥」撤销该密钥，重新生成即可，旧密钥立即失效。
- **两个技能需要两个 API Key 吗？** 不需要，共用同一个。
- **视频解析完怎么自动通知我？** 提交解析时带 `--callback` 参数指向你的 Agent webhook 端点，解析完成后帧知会主动推送结果。
- **知识库查询返回的图片模型能看吗？** 文档详情接口返回的 content_md 中，图片 URL 已替换为完整 HTTPS 链接。多模态模型（如 GPT-4o、Claude、Qwen-VL）可直接拉取图片读取内容；纯文本模型会忽略图片 URL，只看文字。
- **不支持我的 Agent？** 只要你的 Agent 支持 SKILL.md 技能机制和 shell 脚本调用，就可以使用。技能脚本纯 curl 实现，零依赖。
