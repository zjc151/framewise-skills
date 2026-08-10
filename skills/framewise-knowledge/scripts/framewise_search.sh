#!/bin/sh
# 帧知知识库 - 搜索文档
# 用法: framewise_search.sh "<关键词>" "<API_KEY>" [--tag "<标签>"] [--page <页码>]
# 输出: JSON（含 items 列表 / total / page / page_size），失败时非 0 退出
set -u

API_BASE="${FRAMEWISE_API_BASE:-https://www.framewise.cc}"

QUERY="${1:-}"
API_KEY="${2:-}"
TAG=""
PAGE="1"

shift 2 2>/dev/null
while [ "$#" -gt 0 ]; do
  case "$1" in
    --tag)   TAG="${2:-}";   shift 2 ;;
    --page)  PAGE="${2:-1}"; shift 2 ;;
    *) shift ;;
  esac
done

if [ -z "$API_KEY" ]; then
  echo '{"error":"缺少参数：需要 API_KEY"}' >&2
  exit 1
fi

# 构造查询参数
QS=""
if [ -n "$QUERY" ]; then
  QS="search=$(printf '%s' "$QUERY" | sed 's/ /%20/g; s/&/%26/g; s/=/%3D/g')"
fi
if [ -n "$TAG" ]; then
  if [ -n "$QS" ]; then QS="${QS}&"; fi
  QS="${QS}tag=$(printf '%s' "$TAG" | sed 's/ /%20/g; s/&/%26/g')"
fi
if [ -n "$QS" ]; then QS="${QS}&"; fi
QS="${QS}page=${PAGE}&page_size=10"

RESP=$(curl -sS --max-time 30 "${API_BASE}/api/v1/openclaw/documents?${QS}" \
  -H "Authorization: Bearer ${API_KEY}")

printf '%s\n' "$RESP"

case "$RESP" in
  *'"items"'*) exit 0 ;;
  *) exit 1 ;;
esac
