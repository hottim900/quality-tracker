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

搜查完成後，檢查該類別是否有 charter seed（「What grep can't find」段落）。如果有，向使用者建議 ET session — 見下方「探索式測試 (ET)」章節。

---

## 探索式測試 (ET)

搜查手冊覆蓋已知的 grep 可搜模式。ET 處理 grep 搜不到的問題：業務邊界、意圖判斷、跨功能互動。

完整方法論見 `${QUALITY_DIR}/discovery-strategy.md`。Charter 模板見 `${QUALITY_DIR}/et-charter-template.md`。

### 何時建議 ET session

完成搜查手冊的掃查後，或遇到以下信號時，建議使用者進行 ET session。檢查 5 個觸發條件：

| # | 觸發條件 | 信號 | 建議的 Charter |
|---|----------|------|----------------|
| 1 | **Post-sweep** | 剛完成某 D-XXX 類別的搜查 | 該類別的 charter seed（「What grep can't find」段落） |
| 2 | **Design defect** | Issue 有 `root-cause:design` label | Target: 該 Issue 涉及的設計決策，Task: 探索同一設計決策影響的其他功能 |
| 3 | **Production escape** | Issue 有 `escape:production` label | Target: 該 Issue 的功能區域，Task: 探索自動化管道漏掉的同類場景 |
| 4 | **New feature** | 使用者上線了新功能但沒有對應的搜查覆蓋 | Target: 新功能，Task: 探索邊界條件和錯誤處理路徑 |
| 5 | **Pattern repeat** | 同區域短期內出現 2+ 個 Issue | Target: 該區域，Task: 探索系統性根因 |

每個 charter 使用 4T 欄位：
- **Target（目標）：** 要探索的系統區域
- **Task（任務）：** 具體要做什麼
- **Timebox（時限）：** 30 min（預設）
- **Trigger（觸發）：** 上表中的哪個條件

### 如何建議

1. 讀取 `${QUALITY_DIR}/defect-taxonomy.md` 中相關 D-XXX 類別的 charter seed
2. 如果該類別沒有 charter seed，建議一般性 ET session：基於類別定義，探索 grep pattern 無法覆蓋的業務邏輯和跨功能互動
3. 用 4T 欄位格式向使用者呈現建議的 charter
4. **使用者決定是否執行和何時執行** — 只建議，不強制

### ET session 完成後

1. 為發現的缺陷建 Issue，**手動加上** `discovery-method:et-session` label（Issue 模板的下拉選單僅記錄在 body 中，不會自動建立 label）
2. 若 session 發現了新的可 grep 化 pattern，評估是否符合推廣標準後加入搜查手冊：
   - 可用 regex 表達？
   - False positive < 20%？
   - 跨專案（同技術棧）有用？
3. 建一個 Session 紀錄 Issue（標題如「ET Session: D-EDGE 業務邊界探索」），session report 作為 Issue body

### 使用者不想要 ET

如果使用者說「跳過 ET」、「只要 grep」、「不需要探索式測試」，尊重這個選擇。只執行搜查手冊的 grep 搜查，不建議 ET session。

> **觀察指標：** 如果品質系統使用 30 天後沒有任何 Issue 帶有 `discovery-method:et-session` label，ET 框架可能需要重新設計或者使用者不需要這個功能。用 `gh issue list --label "discovery-method:et-session"` 檢查。

---

## 行為準則

- **修復 bug 時**：檢查是否有對應的品質追蹤 Issue。若無且是系統性問題 → 建議建立（但由人類決定）。
- **發現新問題時**：記錄到 README「待追蹤發現」段落。**不要主動升級為正式項目**。
- **搜查手冊中發現同類問題時**：記錄到搜查手冊的「搜查結果」中。
- **完成修復後**：嚴格執行「完成步驟」，不要遺漏任何一步。
