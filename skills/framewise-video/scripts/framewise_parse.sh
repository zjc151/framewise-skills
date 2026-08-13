#!/bin/sh
# 帧知视频解析 — 提交解析任务
# 用法: framewise_parse.sh "<视频URL>" "<API_KEY>" [--prompt "..."] [--model <id>] [--callback <url>]
# 输出: JSON（含 task_id / status / error 等），失败时非 0 退出
set -u

API_BASE="${FRAMEWISE_API_BASE:-https://www.framewise.cc}"

URL="${1:-}"
API_KEY="${2:-}"
PROMPT=""
MODEL=""
CALLBACK=""

shift 2 2>/dev/null
while [ "$#" -gt 0 ]; do
  case "$1" in
    --prompt)  PROMPT="${2:-}"; shift 2 ;;
    --model)   MODEL="${2:-}";  shift 2 ;;
    --callback) CALLBACK="${2:-}"; shift 2 ;;
    *) shift ;;
  esac
done

if [ -z "$URL" ] || [ -z "$API_KEY" ]; then
  echo '{"error":"缺少参数：需要 视频URL 和 API_KEY"}' >&2
  exit 1
fi

# 构造请求体（用 jq 拼装，若没有 jq 则回退 python3；两者都没有则用固定 JSON）
if command -v jq >/dev/null 2>&1; then
  BODY=$(jq -n \
    --arg url "$URL" \
    --arg prompt "$PROMPT" \
    --arg model "$MODEL" \
    --arg cb "$CALLBACK" \
    '{url:$url, platform:"auto", prompt:$prompt, model:$model, callback_url:$cb}')
else
  BODY=$(cat <<EOF
{"url":$(printf '%s' "$URL" | sed 's/\\/\\\\/g; s/"/\\"/g'),"platform":"auto","prompt":$(printf '%s' "$PROMPT" | sed 's/\\/\\\\/g; s/"/\\"/g'),"model":$(printf '%s' "$MODEL" | sed 's/\\/\\\\/g; s/"/\\"/g'),"callback_url":$(printf '%s' "$CALLBACK" | sed 's/\\/\\\\/g; s/"/\\"/g')}
EOF
)
fi

RESP=$(curl -sS --max-time 30 -X POST "${API_BASE}/api/v1/agent/parse" \
  -H "Authorization: Bearer ${API_KEY}" \
  -H "Content-Type: application/json" \
  -d "$BODY")

# 输出响应（保持 JSON，供下游解析）
printf '%s\n' "$RESP"

# 非 2xx / 无 task_id 视为失败
case "$RESP" in
  *'"task_id"'*) exit 0 ;;
  *) exit 1 ;;
esac
