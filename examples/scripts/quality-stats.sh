#!/bin/bash
# quality-stats.sh — 品質追蹤項目統計報告（Issue-native 版）
#
# ======================================================================
# 透過 gh/glab CLI 查詢 Issues，統計品質追蹤項目的活躍狀態。
#
# 用法：
#   ./quality-stats.sh --github    # GitHub repo
#   ./quality-stats.sh --gitlab    # GitLab repo
#
# 前置需求：
#   - gh CLI 已認證（GitHub）或 glab CLI 已認證（GitLab）
#   - jq
#   - 網路連線
#
# 限制：單次查詢上限 500 筆 Issue。超過時會顯示警告。
# ======================================================================

set -euo pipefail

# --- 參數解析 ---

PLATFORM=""
case "${1:-}" in
  --github) PLATFORM="github" ;;
  --gitlab) PLATFORM="gitlab" ;;
  *)
    echo "用法：$0 --github | --gitlab" >&2
    exit 1
    ;;
esac

# --- 前置檢查 ---

if ! command -v jq &>/dev/null; then
  echo "❌ 需要 jq" >&2
  exit 1
fi

if [ "$PLATFORM" = "github" ] && ! command -v gh &>/dev/null; then
  echo "❌ 需要 gh CLI" >&2
  exit 1
fi

if [ "$PLATFORM" = "gitlab" ] && ! command -v glab &>/dev/null; then
  echo "❌ 需要 glab CLI" >&2
  exit 1
fi

# --- jq 共用定義 ---

# is_open: 統一 GitHub (open) 和 GitLab (opened/OPEN) 的狀態判斷
JQ_DEFS='def is_open: .state == "open" or .state == "OPEN" or .state == "opened"; def is_closed: .state == "closed" or .state == "CLOSED"; def has_label($l): .labels | map(.name) | any(. == $l);'

# --- 查詢 Issues ---

QUERY_LIMIT=500

fetch_issues() {
  if [ "$PLATFORM" = "github" ]; then
    gh issue list --state all --limit "$QUERY_LIMIT" --json number,title,state,labels \
      | jq '[.[] | select(.labels | map(.name) | any(startswith("type:")))]'
  else
    glab issue list --all --per-page "$QUERY_LIMIT" --output json \
      | jq '[.[] | {number: .iid, title: .title, state: .state, labels: [(.labels // [])[] | {name: .}]}]'
  fi
}

echo "品質追蹤統計報告"
echo "產生時間：$(date '+%Y-%m-%d %H:%M:%S')"
echo "平台：$PLATFORM"
echo ""

ISSUES=$(fetch_issues)

ISSUE_COUNT=$(echo "$ISSUES" | jq 'length')
if [ "$ISSUE_COUNT" -ge "$QUERY_LIMIT" ]; then
  echo "⚠️  查詢結果達到上限 ${QUERY_LIMIT} 筆，統計數字可能不完整。" >&2
  echo ""
fi

# --- 分類統計 ---

TYPES=("defect" "tech-debt" "feature-gap" "test-infra")
TYPE_NAMES=("Defect" "Tech Debt" "Feature Gap" "Test Infra")

echo "=== 分類統計 ==="
printf "| %-20s | %4s | %7s | %11s | %7s | %4s |\n" "分類" "合計" "Pending" "In Progress" "Blocked" "Done"
printf "| %-20s | %4s | %7s | %11s | %7s | %4s |\n" "--------------------" "----" "-------" "-----------" "-------" "----"

GRAND_TOTAL=0
for i in "${!TYPES[@]}"; do
  TYPE="${TYPES[$i]}"
  NAME="${TYPE_NAMES[$i]}"

  TYPE_ISSUES=$(echo "$ISSUES" | jq --arg t "type:$TYPE" '[.[] | select(.labels | map(.name) | any(. == $t))]')

  # Single jq call to compute all 4 counters
  read -r DONE IN_PROGRESS BLOCKED OPEN_TOTAL < <(
    echo "$TYPE_ISSUES" | jq -r "$JQ_DEFS"'
      [
        [.[] | select(is_closed)] | length,
        [.[] | select(is_open and has_label("status:in-progress"))] | length,
        [.[] | select(is_open and has_label("status:blocked-by-decision"))] | length,
        [.[] | select(is_open)] | length
      ] | @tsv'
  )
  PENDING=$((OPEN_TOTAL - IN_PROGRESS - BLOCKED))
  TOTAL=$((OPEN_TOTAL + DONE))
  GRAND_TOTAL=$((GRAND_TOTAL + TOTAL))

  printf "| %-20s | %4d | %7d | %11d | %7d | %4d |\n" "$NAME" "$TOTAL" "$PENDING" "$IN_PROGRESS" "$BLOCKED" "$DONE"
done

printf "| %-20s | %4d |\n" "合計" "$GRAND_TOTAL"
echo ""

# --- 優先級統計（活躍項目）---

echo "=== 優先級統計（活躍項目）==="
for PRIORITY in "critical" "high" "medium" "low"; do
  COUNT=$(echo "$ISSUES" | jq --arg p "priority:$PRIORITY" "$JQ_DEFS"'
    [.[] | select(is_open and has_label($p))] | length')
  DISPLAY_NAME="$(echo "$PRIORITY" | awk '{print toupper(substr($0,1,1)) substr($0,2)}'):"
  printf "%-10s %d\n" "$DISPLAY_NAME" "$COUNT"
done
echo ""

# --- Critical/High 明細 ---

echo "=== Critical / High 明細 ==="
FOUND=0
for PRIORITY in "critical" "high"; do
  ITEMS=$(echo "$ISSUES" | jq -r --arg p "priority:$PRIORITY" "$JQ_DEFS"'
    .[] | select(is_open and has_label($p))
    | "#\(.number) | \(.labels | map(.name) | map(select(startswith("priority:"))) | .[0] // "—") | \(.title)"')
  if [ -n "$ITEMS" ]; then
    echo "$ITEMS"
    FOUND=1
  fi
done
[ "$FOUND" -eq 0 ] && echo "（目前無 Critical/High 活躍項目）"

exit 0
