#!/bin/bash
# quality-item-consistency.sh — PostToolUse hook for quality item consistency
#
# ======================================================================
# 檢查品質追蹤項目的一致性：
# - Done 項目不應有未勾選的 checklist（完成步驟或驗收標準）
#
# 使用方式：
# 1. 將此檔案複製到你的 .claude/hooks/ 目錄
# 2. 在 .claude/settings.json 中設定 PostToolUse hook：
#    {
#      "hooks": {
#        "PostToolUse": [
#          {
#            "matcher": "Edit|Write",
#            "command": "bash .claude/hooks/quality-item-consistency.sh"
#          }
#        ]
#      }
#    }
# 3. 將 QUALITY_DIR 改為你的品質系統路徑
#
# Hook pattern 與 migration-safety.sh 相同（JSON stdin、exit 0/2）。
# ======================================================================

QUALITY_DIR="quality"

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# Only check quality item files
[[ "$FILE_PATH" == */"$QUALITY_DIR"/*/DEF-*.md ]] || \
[[ "$FILE_PATH" == */"$QUALITY_DIR"/*/TD-*.md ]] || \
[[ "$FILE_PATH" == */"$QUALITY_DIR"/*/FG-*.md ]] || \
[[ "$FILE_PATH" == */"$QUALITY_DIR"/*/TI-*.md ]] || exit 0

# Skip if file doesn't exist (deleted)
[ -f "$FILE_PATH" ] || exit 0

# Check: Done items should not have unchecked boxes
if grep -q '狀態.*Done' "$FILE_PATH"; then
  UNCHECKED=$(grep -c '^\- \[ \]' "$FILE_PATH" 2>/dev/null || echo 0)
  if [ "$UNCHECKED" -gt 0 ]; then
    echo "❌ 品質項目狀態為 Done，但有 $UNCHECKED 個未勾選的 checklist 項目" >&2
    echo "   檔案：$FILE_PATH" >&2
    echo "" >&2
    echo "   未完成項目：" >&2
    grep -n '^\- \[ \]' "$FILE_PATH" >&2
    echo "" >&2
    echo "   請完成所有 checklist 項目，或將狀態改回 In Progress。" >&2
    exit 2
  fi
fi

exit 0
