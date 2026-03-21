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

> **為什麼要絕對路徑？** Claude Code 可能在 git worktree 中執行，worktree 裡不會有品質系統的參考文件（README.md、defect-taxonomy.md）。
> 使用絕對路徑確保任何 session 都能正確存取。
>
> **範例：**
>
> - Companion repo 模式：`QUALITY_DIR=/home/user/my-project-quality/quality`
> - Collocated 模式：`QUALITY_DIR=/home/user/my-project/quality`

## 快速操作

> 以下指令以 `gh` (GitHub) 為例。GitLab 替換 `gh issue` → `glab issue`。

```bash
# 列出所有活躍 Defect
gh issue list --label "type:defect" --state open

# 列出所有活躍 Tech Debt / Feature Gap / Test Infrastructure
gh issue list --label "type:tech-debt" --state open
gh issue list --label "type:feature-gap" --state open
gh issue list --label "type:test-infra" --state open

# 列出正在處理中的項目
gh issue list --label "status:in-progress" --state open

# 列出 Critical/High 項目
gh issue list --label "priority:critical" --state open
gh issue list --label "priority:high" --state open

# 列出等待決策的項目
gh issue list --label "status:blocked-by-decision" --state open
```

### 建立新項目

依照 [README.md 建立新項目](${QUALITY_DIR}/README.md#建立新項目) 的完整步驟操作。

簡要流程：

1. 判斷類型（[決策樹](${QUALITY_DIR}/README.md#如何判斷分類)）— Defect / Tech Debt / Feature Gap / Test Infrastructure
2. 用對應的 Issue 模板建立 Issue：
   - `gh issue create --template defect.yml`
   - `gh issue create --template tech-debt.yml`
   - `gh issue create --template feature-gap.yml`
   - `gh issue create --template test-infra.yml`
3. 加上 `priority:` label（GitHub 模板自動套用 `type:` label；GitLab 及其他 label 需手動加上）
4. 若 Defect → 在 Issue body 填寫「缺陷子類別」連結搜查手冊

### 修復完成後

> **IMPORTANT:** 嚴格執行 [完成步驟](${QUALITY_DIR}/README.md#完成步驟)，缺任何一步 = 未完成。

完成步驟適用於所有類型（Defect / Tech Debt / Feature Gap / Test Infrastructure）：
1. 關閉 Issue + 填寫完成 comment（Commit/PR、修改摘要、測試結果）
2. 若有相依 Issue（Complements/Blocks）→ 檢查對方 Issue 是否需更新
3. 若 Defect 且為系統性搜查中發現 → 確認搜查結果已記錄於 taxonomy

---

## 搜查手冊

系統性搜查工具，定義已知缺陷類別。每個類別有：

- **定義**：什麼模式構成此類缺陷
- **搜查方式**：可執行的 grep/搜查指令
- **搜查結果**：範圍與命中數、發現、low-risk observations、判定合理

執行搜查時，讀取 `${QUALITY_DIR}/defect-taxonomy.md` 取得每個類別的具體搜查指令。

---

## 行為準則

- **修復 bug 時**：檢查是否有對應的品質追蹤 Issue。若無且是系統性問題 → 建議建立（但由人類決定）。
- **發現新問題時**：記錄到 README「待追蹤發現」段落。**不要主動升級為正式項目**。
- **搜查手冊中發現同類問題時**：記錄到搜查手冊的「搜查結果」中。
- **完成修復後**：嚴格執行「完成步驟」，不要遺漏任何一步。
