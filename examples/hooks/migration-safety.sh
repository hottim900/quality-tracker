#!/bin/bash
# migration-safety.sh — PostToolUse hook for migration code safety
#
# ======================================================================
# 這是 Sparkle 專案的 SQLite migration 防護範例。
# 展示如何用 Claude Code PostToolUse hook 自動化品質防線。
#
# 使用方式：
# 1. 將此檔案複製到你的 .claude/hooks/ 目錄
# 2. 在 .claude/settings.json 中設定 PostToolUse hook
# 3. 根據你的專案需求修改檢查規則
#
# 你需要根據自己的技術棧重寫檢查邏輯。
# 此範例展示的 pattern 是：
# - 讀取 hook 輸入（JSON，包含 tool_input.file_path）
# - 只對特定檔案路徑觸發
# - exit 0 = 通過, exit 2 = 阻擋（顯示錯誤訊息）
# ======================================================================
#
# Sparkle 原始用途 — 檢查 server/db/index.ts 的 migration 安全性：
# 1. Block SELECT * FROM items (column order mismatch risk)
# 2. Warn if DROP TABLE items without foreign_keys = OFF
# 3. Warn if setSchemaVersion inside transaction block

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# Only check server/db/index.ts
[[ "$FILE_PATH" == */server/db/index.ts ]] || exit 0

DB_DIR="${CLAUDE_PROJECT_DIR:-$(dirname "$(dirname "$(dirname "$0")")")}"

show_schema() {
  if [ -f "$DB_DIR/data/todo.db" ]; then
    echo "" >&2
    echo "生產 DB 實際 schema (欄位順序以此為準):" >&2
    sqlite3 "$DB_DIR/data/todo.db" ".schema items" 2>/dev/null | head -20 >&2
  fi
}

# --- Check 1: SELECT * FROM items ---
if grep -n 'SELECT \* FROM items' "$FILE_PATH" | grep -qv '^\s*//\|^\s*\*'; then
  echo "❌ 禁止在 migration 中使用 SELECT * FROM items" >&2
  echo "   ALTER TABLE 追加的欄位在表尾，和 CREATE TABLE 定義順序不同。" >&2
  echo "   必須顯式列出所有欄位名。" >&2
  echo "" >&2
  echo "   範例:" >&2
  echo "   INSERT INTO items_new (id, type, title, ...) SELECT id, type, title, ... FROM items;" >&2
  show_schema
  exit 2
fi

# --- Check 2: DROP TABLE items without foreign_keys = OFF ---
if grep -q 'DROP TABLE items' "$FILE_PATH"; then
  if ! grep -q 'foreign_keys\s*=\s*OFF\|foreign_keys=OFF' "$FILE_PATH"; then
    echo "❌ DROP TABLE items 偵測到，但缺少 PRAGMA foreign_keys = OFF" >&2
    echo "   share_tokens 有 FK 引用 items(id)，不關閉 FK 檢查會導致錯誤。" >&2
    echo "   在 DROP TABLE 之前加: sqlite.pragma(\"foreign_keys = OFF\");" >&2
    exit 2
  fi
fi

# --- Check 3: setSchemaVersion inside transaction ---
# Pattern: sqlite.transaction(() => { ... setSchemaVersion ... });
# This is dangerous because if the transaction rolls back, version shouldn't advance
if awk '/sqlite\.transaction\(/,/^\s*\}\);/' "$FILE_PATH" | grep -q 'setSchemaVersion'; then
  echo "❌ setSchemaVersion 出現在 sqlite.transaction() 區塊內" >&2
  echo "   如果 transaction rollback，schema version 不應該被推進。" >&2
  echo "   將 setSchemaVersion 移到 migrate() 呼叫之後（transaction 外面）。" >&2
  exit 2
fi

exit 0
