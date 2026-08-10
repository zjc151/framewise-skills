#!/bin/sh
# 帧知知识库 - 文档问答
# 用法: framewise_qa.sh "<doc_id>" "<问题>" "<API_KEY>"
# 输出: JSON（含 answer 字段），失败时非 0 退出
set -u

API_BASE="${FRAMEWISE_API_BASE:-https://www.framewise.cc}"

DOC_ID="${1:-}"
QUESTION="${2:-}"
API_KEY="${3:-}"

if [ -z "$DOC_ID" ] || [ -z "$QUESTION" ] || [ -z "$API_KEY" ]; then
  echo '{"error":"缺少参数：需要 doc_id、问题 和 API_KEY"}' >&2
  exit 1
fi

# 构造请求体（用 jq 拼装，若没有 jq 则回退 sed 转义）
if command -v jq >/dev/null 2>&1; then
  BODY=$(jq -n --arg q "$QUESTION" '{question:$q}')
else
  ESC_Q=$(printf '%s' "$QUESTION" | sed 's/\\/\\\\/g; s/"/\\"/g')
  BODY="{\"question\":\"${ESC_Q}\"}"
fi

RESP=$(curl -sS --max-time 120 -X POST "${API_BASE}/api/v1/openclaw/documents/${DOC_ID}/qa" \
  -H "Authorization: Bearer ${API_KEY}" \
  -H "Content-Type: application/json" \
  -d "$BODY")

printf '%s\n' "$RESP"

case "$RESP" in
  *'"answer"'*) exit 0 ;;
  *) exit 1 ;;
esac
