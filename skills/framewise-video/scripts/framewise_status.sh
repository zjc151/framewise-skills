#!/bin/sh
# 帧知视频解析 — 查询任务状态
# 用法: framewise_status.sh "<task_id>" "<API_KEY>"
# 输出: JSON（含 status / progress / result_url / error_msg 等），失败时非 0 退出
set -u

API_BASE="${FRAMEWISE_API_BASE:-https://www.framewise.cc}"

TASK_ID="${1:-}"
API_KEY="${2:-}"

if [ -z "$TASK_ID" ] || [ -z "$API_KEY" ]; then
  echo '{"error":"缺少参数：需要 task_id 和 API_KEY"}' >&2
  exit 1
fi

RESP=$(curl -sS --max-time 30 "${API_BASE}/api/v1/agent/tasks/${TASK_ID}" \
  -H "Authorization: Bearer ${API_KEY}")

printf '%s\n' "$RESP"

case "$RESP" in
  *'"status"'*) exit 0 ;;
  *) exit 1 ;;
esac
