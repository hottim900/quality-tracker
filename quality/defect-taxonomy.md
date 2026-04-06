# 缺陷分類學 — 系統性搜查手冊

> **用途：** 定義已知和潛在的缺陷類別，提供可重複執行的搜查模式，讓開發者能快速找出同類問題。
> 每個類別附帶定義、搜查方式、和搜查結果記錄。

**建立日期：** YYYY-MM-DD <!-- 首次使用時填入 -->
**最後更新：** YYYY-MM-DD <!-- 每次搜查後更新 -->

> 優先級、嚴重度、成本定義見 [README.md](./README.md#定義參考)

### 搜查結果記錄格式

每個類別搜查完畢後，記錄以下內容：

1. **搜查範圍與命中數** — 例如「`server/` + `src/` 全部 `.ts/.tsx`，共 70 個 catch 區塊」。這是下次搜查的**基線**，用於偵測 pattern 是否仍然有效（命中數驟降 = pattern 可能需要更新）。
2. **發現（建 Issue）** — 確認的缺陷，已建立追蹤 Issue。格式：`#N — 描述`（collocated 模式）或 `owner/repo#N — 描述`（companion repo 模式）
3. **Low-risk observations（不建 Issue）** — 可疑但影響太低，不值得正式追蹤。記錄檔案位置和原因，供未來參考。
4. **審查但判定合理（非缺陷）** — 經審查排除的項目。記錄判定理由，避免下次重複審查。

**範例（假想）：**

> **發現：**
>
> - #1 — `src/api.ts` 的 catch 區塊吞沒了 HTTP 錯誤，使用者看不到失敗通知
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

完整的技術棧適配範例見 [examples/dotnet/](../examples/dotnet/)（.NET）和 [examples/sparkle/](../examples/sparkle/)（TypeScript/Bun）。

---

## 分類總覽

| 代號     | 缺陷類別             | 層級              | 搜查狀態 |
| -------- | -------------------- | ----------------- | -------- |
| D-SILENT | 靜默失敗與錯誤吞沒   | 全層              | 待搜查   |
| D-VALID  | 輸入驗證缺口         | API               | 待搜查   |
| D-AUTH   | 認證、授權與安全防線 | API / 全層        | 待搜查   |
| D-TYPE   | 型別安全漏洞         | Frontend / Server | 待搜查   |
| D-PERF   | 效能問題             | 全層              | 待搜查   |
| D-EDGE   | 邊界條件與資源限制   | 全層              | 待搜查   |

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

### What grep can't find (Charter seed)

D-SILENT 的 grep pattern 能偵測 bare catch、缺少 status 檢查、console.* 誤用。它們**搜不到**：

- **錯誤語意是否正確：** catch 裡有 throw，但 throw 的錯誤訊息是否讓上層能做正確的決策？例如：API 回傳 `"Something went wrong"` vs 回傳具體的 error code + context
- **錯誤傳遞鏈斷裂：** 錯誤從 service → controller → frontend 的過程中，有沒有被不當轉換？例如：原始錯誤是 `UNIQUE_VIOLATION` 但使用者看到 `Internal Server Error`
- **靜默成功的假象：** 操作部分失敗但回傳成功。例如：批次匯入 100 筆，3 筆格式錯誤被跳過但 response 說「匯入完成」
- **非同步錯誤遺失：** background job、queue worker、webhook handler 的失敗沒有通知機制

Suggested Charter:
```
Target: 錯誤傳遞鏈 — 從 service 層到使用者面前
Task: 故意觸發每種已知錯誤類型（驗證失敗、權限不足、
  資源不存在、並發衝突），追蹤錯誤訊息從產生到顯示的
  完整路徑，檢查使用者是否得到足夠的資訊做出下一步動作
Timebox: 30 min
Trigger: D-SILENT 搜查完成，grep 已覆蓋 catch 結構
  但錯誤語意和傳遞鏈未驗證
```

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

### What grep can't find (Charter seed)

D-VALID 的 grep pattern 能偵測缺少 max/min 的 schema 欄位和未覆蓋的 route handler。它們**搜不到**：

- **業務語意驗證：** 欄位有格式檢查，但值在業務上合理嗎？例如：結束日期早於開始日期、折扣價高於原價、自己指派自己為審核者
- **跨欄位依賴：** 欄位 A 的合法值取決於欄位 B 的值。例如：付款方式是「信用卡」時需要卡號，但選「銀行轉帳」時不需要
- **狀態轉換驗證：** 某些欄位只在特定狀態下允許修改。例如：已發佈的文章不應允許修改 slug
- **批次操作的驗證一致性：** 單筆 API 有完整驗證，批次 API 是否套用相同規則？

Suggested Charter:
```
Target: API 輸入驗證 — 業務語意層面
Task: 找出所有接受使用者輸入的端點，嘗試提交
  格式正確但業務上不合理的值（日期矛盾、
  自我引用、狀態不允許的修改）
Timebox: 30 min
Trigger: D-VALID 搜查完成，grep 已覆蓋 schema
  格式但業務語意驗證未確認
```

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

### What grep can't find (Charter seed)

D-AUTH 的 grep pattern 能偵測缺少 auth middleware 的路由、dangerouslySetInnerHTML、eval 使用。它們**搜不到**：

- **授權邏輯正確性：** middleware 存在，但邏輯是否正確？例如：使用者 A 能否存取使用者 B 的資源？admin 權限是否能降級？角色變更後舊 session 是否仍有效？
- **間接資訊洩漏：** API 不直接暴露機密，但回傳的錯誤訊息、response time、或 HTTP status code 差異能推測出隱藏資訊（例如：「使用者不存在」vs「密碼錯誤」的差異）
- **權限邊界的組合爆炸：** 兩個單獨合法的操作，組合起來可能繞過權限。例如：修改自己的 email + 重設密碼 = 接管另一個帳號
- **CSP/CORS 的實際效果：** header 設定存在，但是否真正防護了目標攻擊向量？

Suggested Charter:
```
Target: 授權邊界 — 使用者 A 能存取使用者 B 的資源嗎？
Task: 以不同角色登入，嘗試跨使用者存取資源、
  利用 API 直接呼叫繞過 UI 的權限檢查、
  觀察錯誤訊息是否洩漏資訊
Timebox: 30 min
Trigger: D-AUTH 搜查完成，grep 已確認 middleware
  存在但授權邏輯正確性未驗證
```

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

### What grep can't find (Charter seed)

D-TYPE 的 grep pattern 能偵測 `as any`、不安全的型別斷言、`@ts-ignore`。它們**搜不到**：

- **API 契約漂移：** 前後端的型別定義一致，但實際回傳的 JSON 結構在邊界條件下偏離型別。例如：陣列欄位在空時回傳 null 而非 `[]`，optional 欄位在某些路徑完全不存在（undefined vs null）
- **序列化/反序列化的型別損失：** Date 物件變成 string、BigInt 變成 number、enum 變成 magic string。特別是跨 JSON boundary 時
- **泛型約束不足：** 泛型函式接受的型別範圍太廣，在特定使用場景中缺少必要的 property check
- **Runtime 型別與 compile-time 型別不一致：** TypeScript 說是 number，但 HTML input 回傳的是 string

Suggested Charter:
```
Target: API 邊界的型別一致性
Task: 在瀏覽器 DevTools 中觀察實際 API response，
  比對前端型別定義，特別注意 null vs undefined、
  空陣列 vs null、Date 序列化格式
Timebox: 30 min
Trigger: D-TYPE 搜查完成，grep 已覆蓋靜態型別問題
  但 runtime 型別漂移未驗證
```

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

### What grep can't find (Charter seed)

D-PERF 的 grep pattern 能偵測缺少 LIMIT 的查詢、N+1 候選、缺少 memo 的元件。它們**搜不到**：

- **使用者感知效能：** 技術指標正常但使用者體驗慢。例如：API 回應 200ms 但 UI 因為 re-render cascade 需要 2 秒才更新、loading spinner 閃爍（太快結束反而造成視覺干擾）
- **資料量成長後的退化：** 10 筆時快、1000 筆時慢。grep 能找到缺少 LIMIT 的查詢，但找不到「有 LIMIT 但 limit 值太大」或「分頁有但第 100 頁的效能」
- **快取失效策略：** 快取存在但失效頻率太高（每次 mutation 都 invalidate all），或太低（使用者看到過期資料）
- **Cold start vs warm path：** 首次載入、新使用者的體驗 vs 常規使用者的體驗差距

Suggested Charter:
```
Target: 使用者感知效能 — 從點擊到結果顯示
Task: 用 DevTools Performance tab 記錄常見操作
  （列表載入、搜尋、建立、編輯）的實際時間，
  觀察 re-render 次數和 network waterfall，
  模擬大量資料（100+ 筆）的場景
Timebox: 30 min
Trigger: D-PERF 搜查完成，grep 已覆蓋查詢層效能
  但使用者感知效能未測量
```

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

### What grep can't find (Charter seed)

D-EDGE 的 grep pattern 能偵測缺少 max/min 限制的 schema 欄位、分頁參數、無上限查詢。它們**搜不到**：

- **業務規則邊界：** 使用者封存最後一個分類時該怎麼辦？早鳥優惠的截止日期落在閏年 2/29 時？折扣百分比設為 0% 或 100% 時的行為？
- **跨功能資源競爭：** 匯出操作和大量匯入同時進行時會怎樣？兩個並發編輯在 timebox 邊界撞在一起？
- **隱含的數量假設：** UI 設計假設清單有 ~50 筆，但第 1000 筆時分頁、排序、渲染是否正常？搜尋結果為 0 筆時的空狀態處理？
- **時間邊界：** 跨時區操作（使用者在 UTC+8 建立的項目，在 UTC-5 看到的日期）、午夜邊界的 cron job、DST 切換時的排程

Suggested Charter:
```
Target: 業務規則邊界條件 — 「最後一個」和「第一個」的邊界
Task: 探索刪除/封存最後一個 entity、並發操作共享資源、
  隱含數量假設（空集合、超大集合、剛好到限制的集合）
Timebox: 30 min
Trigger: D-EDGE 搜查完成，grep 已覆蓋 schema 限制
  但業務規則邊界未測試
```

### 搜查結果

（依[記錄格式](#搜查結果記錄格式)填寫：範圍與命中數 → 發現 → Low-risk → 判定合理）

---

## 搜查執行紀錄

| 日期 | 類別 | 命中數 | 發現/排除 | 備註 |
| ---- | ---- | ------ | --------- | ---- |

---

## See also

- [discovery-strategy.md](./discovery-strategy.md) — 雙層模型：搜查手冊（本文件）與 ET 如何互饋
- [et-charter-template.md](./et-charter-template.md) — Charter 模板與 Quick Start
- [README.md](./README.md) — 品質管理追蹤總覽
- [examples/sparkle/et-charters.md](../examples/sparkle/et-charters.md) — 真實 ET 執行範例

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

### What grep can't find (Charter seed)

描述此類別的 grep pattern 搜不到的具體問題：
業務規則、跨功能互動、隱含假設等需要人類判斷的盲區。
格式參考現有 D-XXX 類別的 charter seed。

Suggested Charter:
\`\`\`
Target: [探索目標]
Task: [具體要做什麼]
Timebox: 30 min
Trigger: [什麼原因觸發這次 ET]
\`\`\`

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
