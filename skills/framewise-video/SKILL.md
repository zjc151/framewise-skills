---
name: framewise-video
description: 把视频链接解析为结构化知识文档（帧知平台，AI 转写/关键帧/知识沉淀）。
metadata:
  {
    "openclaw":
      {
        "emoji": "🎬",
        "primaryEnv": "FRAMEWISE_API_KEY",
        "homepage": "https://www.framewise.cc/skills",
        "requires": { "bins": ["curl", "sh"] }
      }
  }
---

# 帧知视频解析（Framewise Video Parse）

把抖音 / B 站视频链接解析为一份结构化知识文档（AI 转写、关键帧、术语、复习卡），结果是一个可访问的知识文档链接。

## 何时使用

当用户发来一个**视频链接**（抖音 `v.douyin.com/...`、B 站 `bilibili.com/video/BV...`），且意图是以下之一时使用本技能：

- 「把这个视频解析一下 / 转成知识文档 / 存到我的知识库」
- 「帮我整理这个视频的内容 / 生成学习笔记 / 提取要点」
- 在 IM 里直接转发一个视频链接给机器人

**不要**用于：普通文字提问、非视频链接（网页/图片/音频）、闲聊。

## 前置条件

1. 需要帧知平台 API Key。从环境变量 `FRAMEWISE_API_KEY` 读取。
2. 若环境变量为空或调用返回 401：
   - 明确告诉用户：「需要配置帧知 API Key。请访问 https://www.framewise.cc/skills 查看配置方法（在账户设置里生成 fw_ 开头的密钥），或在环境变量 FRAMEWISE_API_KEY 或 openclaw.json 的 skills.entries.framewise-video.apiKey 中填入。」
   - 不要继续尝试。

## 工作流程

### 第 1 步：确认链接

- 从用户消息中提取视频链接（完整 URL）。
- 支持平台：抖音（v.douyin.com）、B 站（bilibili.com/video）。
- 若无法识别平台或不是视频链接，礼貌告知用户仅支持抖音 / B 站视频链接。

### 第 2 步：提交解析任务

运行（从环境变量取 API Key）：

```bash
{baseDir}/scripts/framewise_parse.sh "<视频URL>" "$FRAMEWISE_API_KEY"
```

可选参数（按需追加）：

```bash
# 指定关注点提示词（让 AI 重点整理某些内容）
{baseDir}/scripts/framewise_parse.sh "<URL>" "$FRAMEWISE_API_KEY" --prompt "重点关注第三部分的操作步骤"

# 指定模型（可选，默认用平台默认模型）
{baseDir}/scripts/framewise_parse.sh "<URL>" "$FRAMEWISE_API_KEY" --model qwen-3.6-flash

# 指定回调地址（可选，见「回调模式」）
{baseDir}/scripts/framewise_parse.sh "<URL>" "$FRAMEWISE_API_KEY" --callback "http://<your-agent-host>:<port>/hooks/agent"
```

脚本输出 JSON，从中读取 `task_id`（形如 `task_xxx`）。若返回错误，把错误信息原样转述给用户。

### 第 3 步：等待并获取结果（两种模式）

#### 模式 A：回调（推荐，若提交时带了 --callback）

- 帧知会在解析完成/失败后主动 POST 结果到 `callback_url`（你的 Agent webhook 端点）。
- 等待回调内容，从中读取 `result_url` 与 `status`。
- 若长时间未收到回调，可回退到模式 B 轮询。

#### 模式 B：轮询（默认，最通用）

循环运行状态查询，**每次间隔至少 60 秒**（接口限流：每用户每任务 1 次/分钟）：

```bash
{baseDir}/scripts/framewise_status.sh "<task_id>" "$FRAMEWISE_API_KEY"
```

- `status == "completed"`：任务完成，读取 `result_url`，继续第 4 步。
- `status == "failed"`：读取 `error_msg`，转述给用户并停止。
- 其他状态（queued/processing）：等待 60 秒后重试。最长等待约 30 分钟，超时告知用户稍后可用 `result_url` 或到网页端查看。

### 第 4 步：返回结果

- 用 `https://www.framewise.cc` 拼上 `result_url` 得到**完整文档链接**（如 `https://www.framewise.cc/documents/doc_xxx`）。
- 回复用户时给出链接 + 一句话说明（如「已生成知识文档，点击查看」）。

## 错误处理

- **401**：API Key 无效或未配置 → 引导用户到 https://www.framewise.cc/skills 配置。
- **429**：限流 → 等待 60 秒重试，不要连续请求。
- **404（任务不存在）**：task_id 可能过期，重新提交。
- **failed + error_msg**：把 error_msg 转述给用户（常见：链接无法下载、视频时长超过账号等级限制、模型不可用）。
