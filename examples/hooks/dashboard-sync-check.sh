#!/bin/bash
# dashboard-sync-check.sh — PostToolUse hook for dashboard sync reminder
#
# ======================================================================
# 當品質項目的狀態或優先級被修改時，提醒同步更新 Dashboard。
# 這是 advisory hook — 永遠 exit 0，只顯示提醒不阻擋。
#
# 使用方式：
# 1. 將此檔案複製到你的 .claude/hooks/ 目錄
# 2. 在 .claude/settings.json 中設定 PostToolUse hook：
#    {
#      "hooks": {
#        "PostToolUse": [
#          {
#            "matcher": "Edit|Write",
#            "command": "bash .claude/hooks/dashboard-sync-check.sh"
#          }
#        ]
#      }
#    }
# 3. 將 QUALITY_DIR 改為你的品質系統路徑
#
# Advisory hook — 永遠 exit 0，只提醒不阻擋。
# ======================================================================

QUALITY_DIR="quality"

if ! command -v jq &>/dev/null; then
  echo "❌ dashboard-sync-check.sh 需要 jq，但未安裝" >&2
  exit 2
fi

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# Only check quality item files (handle both absolute and relative paths)
[[ "$FILE_PATH" == "$QUALITY_DIR"/*/DEF-*.md || "$FILE_PATH" == */"$QUALITY_DIR"/*/DEF-*.md ]] || \
[[ "$FILE_PATH" == "$QUALITY_DIR"/*/TD-*.md || "$FILE_PATH" == */"$QUALITY_DIR"/*/TD-*.md ]] || \
[[ "$FILE_PATH" == "$QUALITY_DIR"/*/FG-*.md || "$FILE_PATH" == */"$QUALITY_DIR"/*/FG-*.md ]] || \
[[ "$FILE_PATH" == "$QUALITY_DIR"/*/TI-*.md || "$FILE_PATH" == */"$QUALITY_DIR"/*/TI-*.md ]] || exit 0

# Skip if file doesn't exist
[ -f "$FILE_PATH" ] || exit 0

# Check if this item is Critical or High priority
if grep -q '優先級.*Critical\|優先級.*High' "$FILE_PATH"; then
  DASHBOARD="$QUALITY_DIR/README.md"
  ITEM_ID=$(basename "$FILE_PATH" .md | grep -oE '^(DEF|TD|FG|TI)-[0-9]+')

  if [ -n "$ITEM_ID" ] && [ -f "$DASHBOARD" ]; then
    # Remind to check dashboard if this high-priority item changed
    echo "💡 提醒：此項目為 Critical/High 優先級" >&2
    echo "   請確認 $DASHBOARD 的 Critical/High 表是否需要同步更新。" >&2
    echo "   （狀態變更為 Done 時需從表中移除，新增 Critical/High 時需加入）" >&2
  fi
fi

exit 0
