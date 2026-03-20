---
name: quality
description: Quality tracking system operations guide. Use when fixing bugs, managing defect/tech-debt/feature-gap items, or running code quality audits.
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
> - Companion repo 模式：`QUALITY_DIR=/home/user/my-project-quality/quality`
> - Collocated 模式：`QUALITY_DIR=/home/user/my-project/quality`

## 路徑解析

操作品質檔案時，**一律使用 QUALITY_DIR 的絕對路徑**。

| 檔案 | 路徑 |
|------|------|
| Dashboard | `${QUALITY_DIR}/README.md` |
| 搜查手冊 | `${QUALITY_DIR}/defect-taxonomy.md` |
| 設計筆記 | `${QUALITY_DIR}/quality-system-design-notes.md` |
| Defect 模板 | `${QUALITY_DIR}/TEMPLATE-DEFECT.md` |
| Tech Debt 模板 | `${QUALITY_DIR}/TEMPLATE-TECH-DEBT.md` |
| Feature Gap 模板 | `${QUALITY_DIR}/TEMPLATE-FEATURE-GAP.md` |

---

## 快速操作

### 發現活躍項目

```bash
# 列出所有活躍 Defect
glob ${QUALITY_DIR}/defects/DEF-*.md

# 列出所有活躍 Tech Debt
glob ${QUALITY_DIR}/tech-debt/TD-*.md

# 列出所有活躍 Feature Gap
glob ${QUALITY_DIR}/feature-gaps/FG-*.md

# 搜尋特定狀態的項目
grep '狀態.*Pending' ${QUALITY_DIR}/defects/
grep '狀態.*In Progress' ${QUALITY_DIR}/defects/
```

### 建立新項目

依照 [README.md 建立新項目](${QUALITY_DIR}/README.md#建立新項目) 的完整步驟操作。

簡要流程：
1. 判斷類型（[決策樹](${QUALITY_DIR}/README.md#如何判斷分類)）
2. 決定 ID → `ls` 對應目錄找最大編號 +1
3. 複製模板 → 填寫 metadata
4. 若 Critical/High → 更新 Dashboard
5. 若 Defect → 連結搜查手冊

### 修復完成後

> **IMPORTANT:** 嚴格執行 [完成步驟](${QUALITY_DIR}/README.md#完成步驟)，缺任何一步 = 未完成。

---

## 搜查手冊

系統性搜查工具，定義已知缺陷類別。每個類別有：
- **定義**：什麼模式構成此類缺陷
- **搜查方式**：可執行的 grep/搜查指令
- **判定標準**：如何判斷是否為缺陷
- **已知實例**：連結到 DEF 項目

執行搜查時，讀取 `${QUALITY_DIR}/defect-taxonomy.md` 取得每個類別的具體搜查指令。

---

## 行為準則

- **修復 bug 時**：檢查是否有對應的品質追蹤項目。若無且是系統性問題 → 建議建立（但由人類決定）。
- **發現新問題時**：記錄到 README「待追蹤發現」段落。**不要主動升級為正式項目**。
- **搜查手冊中發現同類問題時**：記錄到搜查手冊的「搜查結果」中。
- **完成修復後**：嚴格執行「完成步驟」，不要遺漏任何一步。
