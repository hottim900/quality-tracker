# 缺陷分類學 — 系統性搜查手冊

> **用途：** 定義已知和潛在的缺陷類別，提供可重複執行的搜查模式，讓開發者能快速找出同類問題。
> 每個類別附帶定義、搜查方式、和搜查結果記錄。

**建立日期：** YYYY-MM-DD <!-- 首次使用時填入 -->
**最後更新：** YYYY-MM-DD <!-- 每次搜查後更新 -->

> 優先級、嚴重度、成本定義見 [README.md](./README.md#定義參考)

### 搜查結果記錄格式

每個類別搜查完畢後，記錄以下內容：

1. **搜查範圍與命中數** — 例如「`server/` + `src/` 全部 `.ts/.tsx`，共 70 個 catch 區塊」。這是下次搜查的**基線**，用於偵測 pattern 是否仍然有效（命中數驟降 = pattern 可能需要更新）。
2. **發現（建 DEF）** — 確認的缺陷，已建立追蹤項目。格式：`[DEF-NNN](連結) — 描述`
3. **Low-risk observations（不建 DEF）** — 可疑但影響太低，不值得正式追蹤。記錄檔案位置和原因，供未來參考。
4. **審查但判定合理（非缺陷）** — 經審查排除的項目。記錄判定理由，避免下次重複審查。

**範例（假想）：**

> **發現：**
>
> - [DEF-001](./defects/DEF-001-example.md) — `src/api.ts` 的 catch 區塊吞沒了 HTTP 錯誤，使用者看不到失敗通知
>
> **Low-risk observations：**
>
> - `src/utils/logger.ts:42` — catch 後只記 console.warn 不記 error，但此路徑為 debug-only 功能，影響極低
>
> **審查但判定合理：**
>
> - `src/health-check.ts` catch → 設定 degraded 狀態並回傳 503，設計如此

> **Claude Code 提示：** 以下各類別的 grep 指令為搜查邏輯的參考寫法。在 Claude Code 中請用內建 Grep 工具執行，`--include` 對應 `glob` 參數。

### 技術棧適配

本手冊的搜查指令以 TypeScript/React 為範例。適配到其他語言時，調整副檔名和搜查模式：

| 技術棧 | `--include` 參數 |
|--------|-----------------|
| TypeScript/React | `*.ts` `*.tsx` |
| .NET / C# | `*.cs` |
| Python | `*.py` |
| Go | `*.go` |
| Java/Kotlin | `*.java` `*.kt` |

完整的技術棧適配範例見 [examples/dotnet/](https://github.com/hottim900/quality-tracker/tree/main/examples/dotnet)（.NET）和 [examples/sparkle/](https://github.com/hottim900/quality-tracker/tree/main/examples/sparkle)（TypeScript/Bun）。

---

## 分類總覽

| 代號     | 缺陷類別             | 層級              | 已知實例       | 搜查狀態 |
| -------- | -------------------- | ----------------- | -------------- | -------- |
| D-SILENT | 靜默失敗與錯誤吞沒   | 全層              | 見搜查結果     | 待搜查   |
| D-VALID  | 輸入驗證缺口         | API               | 見搜查結果     | 待搜查   |
| D-AUTH   | 認證、授權與安全防線 | API / 全層        | 見搜查結果     | 待搜查   |
| D-TYPE   | 型別安全漏洞         | Frontend / Server | 見搜查結果     | 待搜查   |
| D-PERF   | 效能問題             | 全層              | 見搜查結果     | 待搜查   |
| D-EDGE   | 邊界條件與資源限制   | 全層              | 見搜查結果     | 待搜查   |

---

## D-SILENT: 靜默失敗與錯誤吞沒

### 定義

catch 塊中只記錄 log 或完全忽略錯誤，上層不知道操作失敗。包含 API 錯誤未正確傳遞給 UI、錯誤回應未檢查 status、缺少結構化日誌。

### 搜查方式

```bash
# 精準搜查：bare catch（空 catch 或只有註解的 catch）
grep -rn "catch.*{" . --include="*.ts" --include="*.tsx" -A 2 | grep -B 1 "^\s*}"

# 次精準：catch 後沒有 throw/toast/log 的地方
grep -rn "catch" . --include="*.ts" --include="*.tsx" -A 5 | grep -v "throw\|toast\|log\|warn\|error\|reject"

# 廣域搜查（噪音高）：所有 catch — 只在首次全面盤點時用
grep -rn "catch" . --include="*.ts" --include="*.tsx"

# HTTP response 未檢查 status
grep -rn "await fetch" . --include="*.ts" --include="*.tsx" -A 3 | grep -v "\.ok\|\.status\|response\.ok"

# 前端 console.* 應改用結構化 logger 或移除
grep -rn "console\." . --include="*.ts" --include="*.tsx" | grep -v node_modules | grep -v "\.test\."
```

> **搜查策略：** 從精準到廣域。先找 bare catch，再擴展到所有 catch 區塊。

**搜查狀態：** 待搜查

### 搜查結果

（依[記錄格式](#搜查結果記錄格式)填寫：範圍與命中數 → 發現 → Low-risk → 判定合理）

---

## D-VALID: 輸入驗證缺口

### 定義

API endpoint 的驗證 schema 未覆蓋所有輸入欄位，或驗證規則不完整（缺少長度限制、格式檢查等）。

### 搜查方式

```bash
# 列出所有 route handler（依框架調整）
grep -rn "app\.\(get\|post\|put\|patch\|delete\)\|router\.\(get\|post\|put\|patch\|delete\)" . --include="*.ts"

# 列出所有驗證 schema（Zod / Joi / Yup 等）
grep -rn "z\.object\|Joi\.object\|yup\.object" . --include="*.ts"

# 找出缺少 max/min 限制的 string 欄位
grep -rn "z\.string()" . --include="*.ts" | grep -v "max\|min\|length"

# 陣列長度限制
grep -rn "z\.array\|Joi\.array" . --include="*.ts" | grep -v "max\|min"
```

**搜查狀態：** 待搜查

### 搜查結果

（依[記錄格式](#搜查結果記錄格式)填寫：範圍與命中數 → 發現 → Low-risk → 判定合理）

---

## D-AUTH: 認證、授權與安全防線

### 定義

認證驗證遺漏、API 端點未正確保護、公開路由暴露過多資訊、CSP/XSS 防護不完整。

### 搜查方式

```bash
# 所有 API 路由
grep -rn "app\.\(get\|post\|put\|patch\|delete\)\|router\.\(get\|post\|put\|patch\|delete\)" . --include="*.ts"

# 認證中介層
grep -rn "auth\|middleware\|bearerAuth\|Authorization\|jwt\|token" . --include="*.ts"

# dangerouslySetInnerHTML（應為 0）
grep -rn "dangerouslySetInnerHTML\|innerHTML" . --include="*.tsx" --include="*.ts"

# eval / Function constructor（應為 0）
grep -rn "eval(\|new Function(" . --include="*.ts" --include="*.tsx"

# CSP header 定義
grep -rn "Content-Security-Policy" . --include="*.ts"
```

**搜查狀態：** 待搜查

### 搜查結果

（依[記錄格式](#搜查結果記錄格式)填寫：範圍與命中數 → 發現 → Low-risk → 判定合理）

---

## D-TYPE: 型別安全漏洞

### 定義

`as any` 強制轉型、不安全的類型斷言、API 回傳值與前端型別定義不一致。

### 搜查方式

```bash
# any 使用
grep -rn "as any\|: any" . --include="*.ts" --include="*.tsx" | grep -v node_modules | grep -v "\.test\."

# 型別斷言（排除 as const）
grep -rn "as [A-Z]" . --include="*.ts" --include="*.tsx" | grep -v "as const"

# @ts-ignore / @ts-expect-error
grep -rn "@ts-ignore\|@ts-expect-error" . --include="*.ts" --include="*.tsx"
```

**搜查狀態：** 待搜查

### 搜查結果

（依[記錄格式](#搜查結果記錄格式)填寫：範圍與命中數 → 發現 → Low-risk → 判定合理）

---

## D-PERF: 效能問題

### 定義

不必要的 re-render、缺少 memo、N+1 查詢、大量資料未分頁、bundle size 過大。

### 搜查方式

```bash
# 資料庫查詢是否有 LIMIT（依 ORM 調整）
grep -rn "\.findMany\|\.all(\|SELECT" . --include="*.ts" | grep -v "LIMIT\|limit\|take"

# React 元件是否使用 memo（前端專案）
grep -rn "React\.memo\|memo(" . --include="*.tsx"

# useMemo/useCallback 使用（前端專案）
grep -rn "useMemo\|useCallback" . --include="*.tsx"

# 迴圈內的資料庫查詢（N+1 候選）
grep -rn "for.*await\|\.map.*await\|forEach.*await" . --include="*.ts" -A 3
```

**搜查狀態：** 待搜查

### 搜查結果

（依[記錄格式](#搜查結果記錄格式)填寫：範圍與命中數 → 發現 → Low-risk → 判定合理）

---

## D-EDGE: 邊界條件與資源限制

### 定義

未處理的極端輸入：超長字串、空內容、超大陣列、分頁 offset 負數、並發寫入衝突。

### 搜查方式

```bash
# 驗證 schema 的 max/min 限制覆蓋率
grep -rn "z\.string()\|z\.array(" . --include="*.ts" | grep -v "max\|min"

# 分頁參數驗證
grep -rn "offset\|limit\|page\|skip\|take" . --include="*.ts"

# 無上限的查詢
grep -rn "\.findMany\|\.all(" . --include="*.ts" | grep -v "limit\|take\|LIMIT"
```

**搜查狀態：** 待搜查

### 搜查結果

（依[記錄格式](#搜查結果記錄格式)填寫：範圍與命中數 → 發現 → Low-risk → 判定合理）

---

## 搜查執行紀錄

| 日期 | 類別 | 命中數 | 發現/排除 | 備註 |
| ---- | ---- | ------ | --------- | ---- |

---

## 如何新增自定義類別

當你的專案有特定領域的缺陷模式時，可以擴充搜查手冊。

### 步驟

1. 在[分類總覽](#分類總覽)表格新增一行
2. 在本文件新增一個 `## D-XXXX: 類別名稱` 段落
3. 填寫：定義、搜查方式（具體的 grep 指令）、搜查狀態
4. 執行首次搜查，依[記錄格式](#搜查結果記錄格式)記錄結果

### 類別模板

```markdown
## D-XXXX: [類別名稱]

### 定義

描述什麼模式構成此類缺陷。

### 搜查方式

\`\`\`bash

# 搜查指令（盡量從精準到廣域排列）

grep -rn "pattern" . --include="\*.ts"
\`\`\`

**搜查狀態：** 待搜查

### 搜查結果

（依[記錄格式](#搜查結果記錄格式)填寫：範圍與命中數 → 發現 → Low-risk → 判定合理）
```

### 常見擴充方向

- **D-STATE** — 前端狀態管理不一致（React Query invalidation、樂觀更新回滾）
- **D-OFFLINE** — 離線同步與 PWA 問題（Service Worker 快取策略、離線佇列）
- **D-QUERY** — 查詢語意錯誤（SQL 排序不確定、FTS 行為異常、分頁遺漏）
- **D-MIGRATE** — DB Migration 安全性（欄位順序依賴、transaction 管理）
- **D-DEPLOY** — Build/Deploy 一致性（artifact 過期、config drift）
- **D-RACE** — 競態條件與並發問題（double-submit、stale closure、abort race）

完整範例請參考 [examples/sparkle/defect-taxonomy.md](../examples/sparkle/defect-taxonomy.md)，展示 12 個類別在真實專案中的使用方式。
