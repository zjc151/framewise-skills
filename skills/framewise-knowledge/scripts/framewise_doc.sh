#!/bin/sh
# 帧知知识库 - 获取文档详情
# 用法: framewise_doc.sh "<doc_id>" "<API_KEY>"
# 输出: JSON（含 content_md 完整正文 / title / tags / stats 等），失败时非 0 退出
set -u

API_BASE="${FRAMEWISE_API_BASE:-https://www.framewise.cc}"

DOC_ID="${1:-}"
API_KEY="${2:-}"

if [ -z "$DOC_ID" ] || [ -z "$API_KEY" ]; then
  echo '{"error":"缺少参数：需要 doc_id 和 API_KEY"}' >&2
  exit 1
fi

RESP=$(curl -sS --max-time 30 "${API_BASE}/api/v1/openclaw/documents/${DOC_ID}" \
  -H "Authorization: Bearer ${API_KEY}")

printf '%s\n' "$RESP"

case "$RESP" in
  *'"content_md"'*) exit 0 ;;
  *) exit 1 ;;
esac
