#!/bin/bash
# setup-github.sh — 為 GitHub 專案設定品質追蹤模板和 labels
#
# 使用方式：
#   bash integrations/setup-github.sh
#
# 前置需求：gh CLI 已安裝且已認證（gh auth status）、jq
# 此腳本是冪等的 — 重複執行安全無副作用。

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# --- 前置檢查 ---

if ! command -v gh &>/dev/null; then
  echo "❌ 需要 gh CLI。安裝：https://cli.github.com/" >&2
  exit 1
fi

if ! gh auth status &>/dev/null; then
  echo "❌ gh CLI 未認證。請先執行 gh auth login" >&2
  exit 1
fi

if ! command -v jq &>/dev/null; then
  echo "❌ 需要 jq。安裝：https://jqlang.github.io/jq/download/" >&2
  exit 1
fi

# --- 目錄檢查 ---

if [ ! -d ".git" ]; then
  echo "❌ 請從 git repo 根目錄執行此腳本" >&2
  exit 1
fi

# --- 複製模板 ---

echo "📋 複製 Issue 和 PR 模板到 .github/ ..."

mkdir -p .github/ISSUE_TEMPLATE
cp "$SCRIPT_DIR/github/ISSUE_TEMPLATE/"*.yml .github/ISSUE_TEMPLATE/
cp "$SCRIPT_DIR/github/PULL_REQUEST_TEMPLATE.md" .github/

echo "   ✅ 模板已複製到 .github/"

# --- 建立 Labels ---

echo "🏷️  建立品質追蹤 labels ..."

LABELS_FILE="$SCRIPT_DIR/labels.json"
if [ ! -f "$LABELS_FILE" ]; then
  echo "❌ labels.json 不存在：$LABELS_FILE" >&2
  exit 1
fi
if ! jq empty "$LABELS_FILE" 2>/dev/null; then
  echo "❌ labels.json 格式錯誤，無法解析" >&2
  exit 1
fi

PROCESSED=0
FAILED=0

while IFS=$'\t' read -r NAME COLOR DESC; do
  if gh label create "$NAME" --description "$DESC" --color "$COLOR" --force 1>/dev/null; then
    PROCESSED=$((PROCESSED + 1))
  else
    echo "   ⚠️  label '$NAME' 建立失敗" >&2
    FAILED=$((FAILED + 1))
  fi
done < <(jq -r '.[] | [.name, .color, .description] | @tsv' "$LABELS_FILE")

echo "   ✅ $PROCESSED labels 已建立/更新"
if [ "$FAILED" -gt 0 ]; then
  echo "   ⚠️  $FAILED labels 建立失敗，請檢查以上錯誤訊息" >&2
fi

# --- 完成 ---

echo ""
echo "🎉 設定完成！下一步："
echo "   1. 將 .github/ 目錄加入 git 並 commit"
echo "   2. 在 CLAUDE.md 加入品質系統入口（見 CLAUDE.md.snippet）"
echo "   3. 用 /quality skill 開始追蹤"
echo "   4. Companion repo 模式：更新模板中的 quality/ 連結指向品質 repo"
