---
name: quality
description: Quality tracking system operations guide. Use when fixing bugs, managing defect/tech-debt/feature-gap/test-infra items, or running code quality audits.
user-invocable: true
---

# 品質管理追蹤系統

## 初始設定（首次使用時修改一次）

將下方 `QUALITY_DIR` 改為你的品質系統**絕對路徑**：

```
QUALITY_DIR=/path/to/your/quality
```

> **為什麼要絕對路徑？** Claude Code 可能在 git worktree 中執行，worktree 裡不會有品質追蹤檔案。
> 使用絕對路徑確保任何 session 都能正確存取。
>
> **範例：**
>
> - Companion repo 模式：`QUALITY_DIR=/home/user/my-project-quality/quality`
> - Collocated 模式：`QUALITY_DIR=/home/user/my-project/quality`

## 快速操作

### 發現活躍項目

```bash
# 列出所有活躍 Defect
glob ${QUALITY_DIR}/defects/DEF-*.md

# 列出所有活躍 Tech Debt
glob ${QUALITY_DIR}/tech-debt/TD-*.md

# 列出所有活躍 Feature Gap
glob ${QUALITY_DIR}/feature-gaps/FG-*.md

# 列出所有活躍 Test Infrastructure
glob ${QUALITY_DIR}/test-infra/TI-*.md

# 搜尋特定狀態的項目（所有目錄）
grep '狀態.*Pending' ${QUALITY_DIR}/defects/ ${QUALITY_DIR}/tech-debt/ ${QUALITY_DIR}/feature-gaps/ ${QUALITY_DIR}/test-infra/
grep '狀態.*In Progress' ${QUALITY_DIR}/defects/ ${QUALITY_DIR}/tech-debt/ ${QUALITY_DIR}/feature-gaps/ ${QUALITY_DIR}/test-infra/
```

### 建立新項目

依照 [README.md 建立新項目](${QUALITY_DIR}/README.md#建立新項目) 的完整步驟操作。

簡要流程：

1. 判斷類型（[決策樹](${QUALITY_DIR}/README.md#如何判斷分類)）— Defect / Tech Debt / Feature Gap / Test Infrastructure
2. 決定 ID → `ls` 對應目錄找最大編號 +1
   - Defect → `ls ${QUALITY_DIR}/defects/`
   - Tech Debt → `ls ${QUALITY_DIR}/tech-debt/`
   - Feature Gap → `ls ${QUALITY_DIR}/feature-gaps/`
   - Test Infrastructure → `ls ${QUALITY_DIR}/test-infra/`
3. 複製對應模板 → 填寫 metadata
4. 若 Defect → 填寫「缺陷子類別」連結搜查手冊

> 填寫「受影響檔案」時，「問題」欄要包含足夠語意描述（函式名、行為），使重構後仍可 grep 定位。

### 修復完成後

> **IMPORTANT:** 嚴格執行 [完成步驟](${QUALITY_DIR}/README.md#完成步驟)，缺任何一步 = 未完成。

完成步驟適用於所有類型（Defect / Tech Debt / Feature Gap / Test Infrastructure）：
1. 項目檔狀態改 Done + 填寫完成紀錄
2. 若「相依」有 Complements/Blocks → 檢查對方是否需更新
3. 若 Defect 且為系統性搜查中發現 → 確認搜查結果已記錄於 taxonomy

---

## 搜查手冊

系統性搜查工具，定義已知缺陷類別。每個類別有：

- **定義**：什麼模式構成此類缺陷，含判定標準
- **搜查方式**：可執行的 grep/搜查指令
- **搜查結果**：範圍與命中數、發現、low-risk observations、判定合理

執行搜查時，讀取 `${QUALITY_DIR}/defect-taxonomy.md` 取得每個類別的具體搜查指令。

---

## 行為準則

- **修復 bug 時**：檢查是否有對應的品質追蹤項目。若無且是系統性問題 → 建議建立（但由人類決定）。
- **發現新問題時**：記錄到 README「待追蹤發現」段落。**不要主動升級為正式項目**。
- **搜查手冊中發現同類問題時**：記錄到搜查手冊的「搜查結果」中。
- **完成修復後**：嚴格執行「完成步驟」，不要遺漏任何一步。
