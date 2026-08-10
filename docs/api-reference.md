# FrameWise OpenClaw API 参考

所有接口的 Base URL：`https://www.framewise.cc`

认证方式：`Authorization: Bearer fw_你的API密钥`

---

## 视频解析

### POST /api/v1/openclaw/parse

提交视频链接解析任务。

**请求体**：
```json
{
  "url": "https://www.bilibili.com/video/BVxxxxx",
  "platform": "auto",
  "prompt": "重点关注操作步骤（可选）",
  "model": "qwen-3.6-flash",
  "callback_url": "https://你的openclaw地址/hooks/agent"
}
```

**响应**（200）：
```json
{
  "task_id": "task_xxx",
  "status": "queued",
  "result_url": null,
  "summary": null,
  "created_at": "2026-08-01T10:00:00Z"
}
```

### GET /api/v1/openclaw/tasks/{task_id}

查询解析任务状态。限流：每用户每任务 1 次/分钟。

**响应**（200）：
```json
{
  "task_id": "task_xxx",
  "status": "completed",
  "progress": { "stage": 6, "stage_name": "入库完成", "percent": 100 },
  "eta_seconds": null,
  "result_doc_id": "doc_xxx",
  "result_url": "/documents/doc_xxx",
  "error_msg": null,
  "created_at": "2026-08-01T10:00:00Z",
  "completed_at": "2026-08-01T10:04:30Z"
}
```

---

## 知识库查询

### GET /api/v1/openclaw/documents

搜索/列出当前用户的知识库文档。限流：每用户 10 次/分钟。

**查询参数**：
| 参数 | 类型 | 默认 | 说明 |
| --- | --- | --- | --- |
| search | string | null | 搜索关键词（标题+正文+摘要） |
| tag | string | null | 标签筛选 |
| page | int | 1 | 页码（1-100） |
| page_size | int | 10 | 每页条数（1-20） |

**响应**（200）：
```json
{
  "items": [
    {
      "id": "doc_xxx",
      "title": "视频标题",
      "platform": "bilibili",
      "summary": "一句话摘要",
      "tags": ["标签1", "标签2"],
      "duration_sec": 320,
      "created_at": "2026-08-01T10:00:00Z",
      "doc_url": "https://www.framewise.cc/documents/doc_xxx"
    }
  ],
  "total": 42,
  "page": 1,
  "page_size": 10
}
```

### GET /api/v1/openclaw/documents/{doc_id}

获取文档详情（含完整 Markdown 正文）。限流：每用户 10 次/分钟。

**响应**（200）：
```json
{
  "id": "doc_xxx",
  "title": "视频标题",
  "platform": "bilibili",
  "author": "UP主名",
  "summary": "摘要",
  "content_md": "# 完整 Markdown 正文...\n![配图](https://www.framewise.cc/api/v1/files/keyframes/xxx/000.jpg)",
  "content_length": 8500,
  "tags": ["标签1"],
  "stats": { "keyframe_count": 5, "term_count": 8 },
  "duration_sec": 320,
  "created_at": "2026-08-01T10:00:00Z",
  "doc_url": "https://www.framewise.cc/documents/doc_xxx"
}
```

> **图片 URL**：content_md 中的图片路径已替换为完整 HTTPS URL（如 `https://www.framewise.cc/api/v1/files/keyframes/{uuid}/000.jpg`）。多模态模型可直接拉取图片内容；纯文本模型会忽略图片，只看文字。图片 URL 无需认证即可访问。

### POST /api/v1/openclaw/documents/{doc_id}/qa

基于文档内容问答。限流：每用户 5 次/分钟 + 每文档 3 次/分钟。

**请求体**：
```json
{
  "question": "这个视频里提到的核心结论是什么？（限 500 字符）"
}
```

**响应**（200）：
```json
{
  "answer": "根据视频内容，三个核心结论是...",
  "doc_id": "doc_xxx"
}
```

---

## 错误码

| HTTP 状态码 | detail | 说明 |
| --- | --- | --- |
| 401 | Missing Authorization | 未传 API Key |
| 401 | Invalid API Key | API Key 无效 |
| 401 | API Key revoked | API Key 已被撤销 |
| 404 | DOCUMENT_NOT_FOUND | 文档不存在或不属于当前用户 |
| 404 | TASK_NOT_FOUND | 任务不存在 |
| 429 | RATE_LIMITED: ... | 限流，响应头含 Retry-After |
| 400 | INVALID_URL / PLATFORM_NOT_SUPPORTED | 链接无效或不支持的平台 |
| 400 | DURATION_EXCEEDED | 视频时长超过等级限制 |
| 400 | MODEL_NOT_AVAILABLE | 模型不可用 |
| 402 | QUOTA_EXCEEDED | 并发任务数超限 |
