#!/bin/bash
# setup-gitlab.sh — 為 GitLab 專案設定品質追蹤模板和 labels
#
# 使用方式：
#   bash integrations/setup-gitlab.sh
#
# 前置需求：glab CLI 已安裝且已認證、jq
# 此腳本可重複執行 — 已存在的 labels 會被跳過。

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# --- 前置檢查 ---

if ! command -v glab &>/dev/null; then
  echo "❌ 需要 glab CLI。安裝：https://gitlab.com/gitlab-org/cli" >&2
  exit 1
fi

if ! glab auth status &>/dev/null; then
  echo "❌ glab CLI 未認證。請先執行 glab auth login" >&2
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

echo "📋 複製 Issue 和 MR 模板到 .gitlab/ ..."

mkdir -p .gitlab/issue_templates
mkdir -p .gitlab/merge_request_templates
cp "$SCRIPT_DIR/gitlab/issue_templates/"*.md .gitlab/issue_templates/
cp "$SCRIPT_DIR/gitlab/merge_request_templates/"*.md .gitlab/merge_request_templates/

echo "   ✅ 模板已複製到 .gitlab/"

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

CREATED=0
SKIPPED=0
FAILED=0

while IFS=$'\t' read -r NAME COLOR DESC; do
  # NOTE: 偵測依賴 glab 錯誤訊息措辭，若 glab 改變措辭需更新
  if ERR=$(glab label create --name "$NAME" --description "$DESC" --color "#$COLOR" 2>&1 1>/dev/null); then
    CREATED=$((CREATED + 1))
  elif echo "$ERR" | grep -qi "already exists"; then
    SKIPPED=$((SKIPPED + 1))
  else
    echo "   ⚠️  label '$NAME' 建立失敗：$ERR" >&2
    FAILED=$((FAILED + 1))
  fi
done < <(jq -r '.[] | [.name, .color, .description] | @tsv' "$LABELS_FILE")

echo "   ✅ $CREATED labels 已建立（$SKIPPED 已存在，跳過）"
if [ "$FAILED" -gt 0 ]; then
  echo "   ⚠️  $FAILED labels 建立失敗，請檢查以上錯誤訊息" >&2
fi

# --- 完成 ---

echo ""
echo "🎉 設定完成！下一步："
echo "   1. 將 .gitlab/ 目錄加入 git 並 commit"
echo "   2. 在 CLAUDE.md 加入品質系統入口（見 CLAUDE.md.snippet）"
echo "   3. 用 /quality skill 開始追蹤"
echo "   4. Companion repo 模式：更新模板中的 quality/ 連結指向品質 repo"
