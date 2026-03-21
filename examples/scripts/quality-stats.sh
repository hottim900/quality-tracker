#!/bin/bash
# quality-stats.sh — 品質追蹤項目統計報告
#
# ======================================================================
# 統計品質追蹤項目的活躍狀態，輸出分類/優先級/狀態統計。
#
# 用法：
#   ./quality-stats.sh [quality-dir]
#
# 預設：quality-dir = quality/
# 需求：bash + grep（零外部依賴）
# ======================================================================

QUALITY_DIR="${1:-quality}"

if [ ! -d "$QUALITY_DIR" ]; then
  echo "錯誤：目錄 $QUALITY_DIR 不存在" >&2
  exit 1
fi

# Categories and their directories/prefixes
CATEGORIES=("Defect:defects:DEF" "Tech Debt:tech-debt:TD" "Feature Gap:feature-gaps:FG" "Test Infra:test-infra:TI")
STATUSES=("Pending" "In Progress" "Blocked-by-Decision" "Done")

echo "品質追蹤統計報告"
echo "產生時間：$(date '+%Y-%m-%d %H:%M:%S')"
echo "來源目錄：$QUALITY_DIR/"
echo ""

# === Category × Status table ===
echo "=== 分類統計 ==="
printf "| %-20s | %4s | %7s | %11s | %7s | %4s |\n" "分類" "合計" "Pending" "In Progress" "Blocked" "Done"
printf "| %-20s | %4s | %7s | %11s | %7s | %4s |\n" "--------------------" "----" "-------" "-----------" "-------" "----"

GRAND_TOTAL=0
for CAT in "${CATEGORIES[@]}"; do
  IFS=':' read -r NAME DIR PREFIX <<< "$CAT"
  CAT_DIR="$QUALITY_DIR/$DIR"

  # Count files (exclude .gitkeep and archive/)
  TOTAL=0
  COUNTS=()
  for STATUS in "${STATUSES[@]}"; do
    COUNT=0
    if [ -d "$CAT_DIR" ]; then
      COUNT=$(find "$CAT_DIR" -maxdepth 1 -name "*.md" 2>/dev/null | xargs grep -l "狀態.*$STATUS" 2>/dev/null | grep -v '/archive/' | wc -l)
    fi
    COUNTS+=("$COUNT")
    TOTAL=$((TOTAL + COUNT))
  done
  GRAND_TOTAL=$((GRAND_TOTAL + TOTAL))

  printf "| %-20s | %4d | %7d | %11d | %7d | %4d |\n" "$NAME" "$TOTAL" "${COUNTS[0]}" "${COUNTS[1]}" "${COUNTS[2]}" "${COUNTS[3]}"
done

printf "| %-20s | %4d |\n" "合計" "$GRAND_TOTAL"
echo ""

# === Priority stats (active items only, exclude Done) ===
echo "=== 優先級統計（活躍項目）==="
for PRIORITY in "Critical" "High" "Medium" "Low"; do
  COUNT=0
  for CAT in "${CATEGORIES[@]}"; do
    IFS=':' read -r _ DIR _ <<< "$CAT"
    CAT_DIR="$QUALITY_DIR/$DIR"
    if [ -d "$CAT_DIR" ]; then
      # Find files with this priority that are NOT Done
      while IFS= read -r F; do
        [[ "$F" == */archive/* ]] && continue
        if grep -q "優先級.*$PRIORITY" "$F" && ! grep -q "狀態.*Done" "$F"; then
          COUNT=$((COUNT + 1))
        fi
      done < <(find "$CAT_DIR" -maxdepth 1 -name "*.md" 2>/dev/null)
    fi
  done
  printf "%-10s %d\n" "$PRIORITY:" "$COUNT"
done
echo ""

# === Critical/High detail ===
echo "=== Critical / High 明細 ==="
FOUND=0
for CAT in "${CATEGORIES[@]}"; do
  IFS=':' read -r _ DIR _ <<< "$CAT"
  CAT_DIR="$QUALITY_DIR/$DIR"
  [ -d "$CAT_DIR" ] || continue
  while IFS= read -r F; do
    [[ "$F" == */archive/* ]] && continue
    if grep -q '優先級.*Critical\|優先級.*High' "$F" && ! grep -q '狀態.*Done' "$F"; then
      ID=$(basename "$F" .md | grep -oE '^(DEF|TD|FG|TI)-[0-9]+')
      PRIORITY=$(grep '優先級' "$F" | head -1 | sed 's/.*優先級[^|]*| *\([^ |]*\).*/\1/')
      STATUS=$(grep '狀態' "$F" | head -1 | sed 's/.*狀態[^|]*| *\([^ |]*\).*/\1/')
      printf "%-10s | %-10s | %s\n" "$ID" "$PRIORITY" "$STATUS"
      FOUND=1
    fi
  done < <(find "$CAT_DIR" -maxdepth 1 -name "*.md" 2>/dev/null)
done
[ "$FOUND" -eq 0 ] && echo "（目前無 Critical/High 活躍項目）"
