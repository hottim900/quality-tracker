# 缺陷分類學 — .NET Clean Architecture 搜查手冊

> **用途：** 定義 .NET Clean Architecture + EF Core + React 專案的缺陷類別，提供可重複執行的搜查模式。
> 每個類別附帶搜查指令、判定標準、和搜查結果記錄。

> 此範例展示 .NET Clean Architecture + EF Core + React 專案的搜查手冊。基於實際專案的 3 輪系統性搜查經驗，涵蓋 13 個缺陷類別。
>
> **與通用模板的關係：** 通用模板（`quality/defect-taxonomy.md`）提供 6 個技術棧無關的類別（D-SILENT、D-VALID、D-AUTH、D-TYPE、D-PERF、D-EDGE）。本範例針對 .NET 技術棧重新定義了部分同名類別（D-AUTH、D-VALID、D-EDGE）的搜查指令，並新增了 .NET 專屬類別（D-EFC、D-CACHE、D-EXC 等）。使用時建議以本範例取代通用模板中的對應類別，而非疊加使用。

**建立日期：** 2026-03-21
**最後更新：** 2026-03-21

> **工具提示：** 以下搜查指令使用 `grep -rn` 格式撰寫，方便在終端直接執行。若使用 Claude Code，建議改用內建的 Grep tool（基於 ripgrep），語法更簡潔且效能更佳。例如 `grep -rn "pattern" src/ --include="*.cs"` 等效於 Grep tool 的 `pattern: "pattern", path: "src/", glob: "*.cs"`。

### 搜查結果記錄格式

每個類別搜查完畢後，用以下三層結構記錄結果：

1. **發現（建 DEF）** — 確認的缺陷，已建立追蹤項目。格式：`[DEF-NNN](連結) — 描述`
2. **Low-risk observations（不建 DEF）** — 可疑但影響太低，不值得正式追蹤。記錄檔案位置和原因，供未來參考。
3. **審查但判定合理（非缺陷）** — 經審查排除的項目。記錄判定理由，避免下次重複審查。

---

## 分類總覽

| 代號 | 缺陷類別 | 層級 | 已知實例 | 搜查狀態 |
|------|----------|------|----------|----------|
| D-EFC | EF Core 配置與查詢不匹配 | Infrastructure | — | 🔲 未搜查 |
| D-EXC | 異常型別與 HTTP 語意不匹配 | API / Infrastructure | — | 🔲 未搜查 |
| D-CACHE | 前端 Cache Invalidation 缺口 | Frontend | — | 🔲 未搜查 |
| D-AUTH | 授權與 IDOR 缺口 | API / Application | — | 🔲 未搜查 |
| D-QUERY | 查詢語意錯誤 | Infrastructure | — | 🔲 未搜查 |
| D-VALID | 輸入驗證覆蓋缺口 | Application | — | 🔲 未搜查 |
| D-FETYPE | 前端型別安全漏洞 | Frontend | — | 🔲 未搜查 |
| D-TIME | 時間處理不一致 | 全層 | — | 🔲 未搜查 |
| D-EDGE | 邊界條件與資源限制 | 全層 | — | 🔲 未搜查 |
| D-ASYNC | 非同步與並發問題 | Application / Infrastructure | — | 🔲 未搜查 |
| D-DISPOSE | 資源釋放問題 | Infrastructure | — | 🔲 未搜查 |
| D-CONFIG | 配置與硬編碼值 | Infrastructure / API | — | 🔲 未搜查 |
| D-LOG | 日誌安全 | Infrastructure | — | 🔲 未搜查 |

---

## D-EFC: EF Core 配置與查詢不匹配

### 定義

Entity Framework Core 的 DbContext 配置（`OnModelCreating`、`IEntityTypeConfiguration`）與實際查詢行為不一致：

1. **Backing field 與 Navigation 遺漏** — `builder.Ignore()` 或缺少 `HasConversion` 導致屬性未正確持久化。Domain entity 有 collection 屬性但 EF 配置未設 navigation。
2. **查詢遺漏 Include** — `FirstOrDefaultAsync` / `SingleOrDefaultAsync` 查詢未加 `.Include()` 導致相關資料為 null。
3. **Value Conversion 語意錯誤** — `HasConversion<string>()` 用於 enum 但查詢端用數字比對，或序列化格式不一致。

### 搜查方式

```bash
# === Backing field 與配置 ===

# 被 Ignore 的屬性 — 檢查是否有應該持久化但被排除的
grep -rn "builder\.Ignore" src/Infrastructure/ --include="*.cs"

# Value Conversion — 確認 enum/complex type 轉換一致性
grep -rn "HasConversion" src/Infrastructure/ --include="*.cs"

# HasField / backing field 配置 — 常見的 DDD 集合封裝
grep -rn "\.HasField\|\.UsePropertyAccessMode" src/Infrastructure/ --include="*.cs"

# === 查詢遺漏 Include ===

# 所有 FirstOrDefaultAsync / SingleOrDefaultAsync — 逐一檢查是否需要 Include
grep -rn "FirstOrDefaultAsync\|SingleOrDefaultAsync\|FindAsync" src/Infrastructure/ --include="*.cs"

# 有 Include chain 的查詢（正面樣本，了解哪些 aggregate 已正確 eager load）
grep -rn "\.Include(" src/Infrastructure/ --include="*.cs"

# === Navigation Property ===

# Domain entity 的 collection 屬性 — 對照 EF 配置是否有對應 HasMany/HasOne
grep -rn "IReadOnlyList\|ICollection\|IEnumerable" src/Domain/ --include="*.cs" | grep -v "using\|namespace"
```

### 判定標準

- `builder.Ignore()` 用在非計算屬性 → **D-EFC 缺陷**
- `FirstOrDefaultAsync` 的 entity 有 navigation property 但查詢無 Include → **D-EFC 缺陷**
- `HasConversion<string>()` 但查詢端用 `== (int)enumValue` → **D-EFC 缺陷**
- `builder.Ignore()` 用在計算屬性或 DTO mapping 中間值 → **合理**
- 查詢後有手動 mapping 且不需要 navigation data → **合理**

**搜查狀態：** 🔲 未搜查

### 搜查結果

**發現：**

（尚未執行搜查）

**Low-risk observations：**

（尚未執行搜查）

**審查但判定合理：**

（尚未執行搜查）

---

## D-EXC: 異常型別與 HTTP 語意不匹配

### 定義

Application / Infrastructure 層使用 `InvalidOperationException` 或 `ArgumentException` 等通用異常回應業務規則違反，導致全域 ExceptionHandler 無法正確映射 HTTP status code：

1. **通用異常濫用** — 資源不存在用 `throw new InvalidOperationException()` 而非 domain-specific 的 `NotFoundException`，導致 client 收到 500 而非 404。
2. **Bare catch 吞沒** — `catch (Exception)` 沒有 `throw` 或 log，異常被靜默吞沒。
3. **HTTP status 語意錯誤** — 驗證失敗回 500 而非 400/422，授權失敗回 500 而非 403。

### 搜查方式

```bash
# === 通用異常濫用 ===

# Infrastructure / Application 層的 InvalidOperationException
grep -rn "throw new InvalidOperationException" src/Application/ src/Infrastructure/ --include="*.cs"

# 同層的其他通用異常
grep -rn "throw new ArgumentException\|throw new ArgumentNullException\|throw new Exception(" src/Application/ src/Infrastructure/ --include="*.cs"

# Domain-specific 異常定義（正面樣本，了解團隊自定義了哪些）
grep -rn "class.*Exception.*:" src/Domain/ src/Application/ --include="*.cs"

# === Bare catch 吞沒 ===

# catch 塊不帶 throw — 潛在靜默吞沒
grep -rn "catch" src/ --include="*.cs" -A 3 | grep -v "throw\|_logger\|Log\.\|return"

# catch (Exception) 不帶型別過濾
grep -rn "catch (Exception)" src/ --include="*.cs"

# === ExceptionHandler 配置 ===

# 全域異常處理器 — 確認映射規則完整
grep -rn "ExceptionHandler\|UseExceptionHandler\|IExceptionHandler" src/Api/ src/Infrastructure/ --include="*.cs"
```

### 判定標準

- Application 層 `throw new InvalidOperationException("not found")` → **D-EXC 缺陷**（應用 NotFoundException）
- `catch (Exception) { }` 空區塊 → **D-EXC 缺陷**
- `catch (Exception) { _logger.LogError(...); throw; }` → **合理**（有日誌 + 重新拋出）
- Controller/Handler 中 `try-catch` 回傳 `StatusCode(500)` 繞過全域 handler → **D-EXC 缺陷**

**搜查狀態：** 🔲 未搜查

### 搜查結果

**發現：**

（尚未執行搜查）

**Low-risk observations：**

（尚未執行搜查）

**審查但判定合理：**

（尚未執行搜查）

---

## D-CACHE: 前端 Cache Invalidation 缺口

### 定義

React 前端使用 TanStack Query 時，`useMutation` 的 `onSuccess` 未正確呼叫 `invalidateQueries`，導致 UI 顯示過期資料：

1. **遺漏 invalidation** — mutation 成功但未 invalidate 相關 query，使用者需手動 refresh 才看到更新。
2. **invalidation 範圍不足** — 只 invalidate 直接相關的 query，遺漏間接受影響的列表 / 統計 query。
3. **Optimistic update 缺 rollback** — 樂觀更新但 mutation 失敗後未還原 cache。

### 搜查方式

```bash
# === 所有 mutation 的 onSuccess ===

# 列出所有 useMutation — 逐一檢查 onSuccess 內的 invalidation
grep -rn "useMutation" frontend/src/ --include="*.ts" --include="*.tsx" -A 10

# 搜查有 useMutation 但沒有 invalidateQueries 的檔案
grep -rn "useMutation" frontend/src/ --include="*.ts" --include="*.tsx" -l | xargs grep -L "invalidateQueries"

# === invalidation 範圍 ===

# 所有 invalidateQueries 呼叫 — 檢查 queryKey 範圍是否足夠
grep -rn "invalidateQueries" frontend/src/ --include="*.ts" --include="*.tsx"

# query key factory 定義（若使用）
grep -rn "queryKey\|Queries\s*=" frontend/src/ --include="*.ts" --include="*.tsx"

# === Optimistic update ===

# 有 setQueryData 但沒有 onError rollback
grep -rn "setQueryData" frontend/src/ --include="*.ts" --include="*.tsx" -l | xargs grep -L "onError"
```

### 判定標準

- `useMutation` 的 `onSuccess` 無 `invalidateQueries` → **D-CACHE 缺陷**
- mutation 修改 entity 但只 invalidate detail query，未 invalidate list query → **D-CACHE 缺陷**
- `setQueryData` 做樂觀更新但 `onError` 沒有 rollback → **D-CACHE 缺陷**
- mutation 後用 `navigate()` 跳頁，目標頁會自動 fetch → **合理**（不需手動 invalidate）
- delete mutation 成功後 `removeQueries` → **合理**

**搜查狀態：** 🔲 未搜查

### 搜查結果

**發現：**

（尚未執行搜查）

**Low-risk observations：**

（尚未執行搜查）

**審查但判定合理：**

（尚未執行搜查）

---

## D-AUTH: 授權與 IDOR 缺口

### 定義

API endpoint 的授權檢查不完整，可能導致越權存取：

1. **IDOR（Insecure Direct Object Reference）** — `[FromRoute] int id` 直接查詢 DB 未驗證資源所有權，導致使用者可存取他人資源。
2. **動作級授權遺漏** — `[HttpPost]` / `[HttpPut]` / `[HttpDelete]` endpoint 缺少資源層級的授權檢查。
3. **Policy 覆蓋不足** — `[Authorize]` 只做認證未做角色/Policy 檢查，或 handler 中未驗證 tenant/project 歸屬。

### 搜查方式

```bash
# === IDOR 檢查 ===

# 從 route 取得 ID 的 handler — 每個都需確認有 ownership 檢查
grep -rn "\[FromRoute\]" src/Api/ --include="*.cs"

# Handler / Command 中直接用 ID 查詢但沒有 ownership filter
grep -rn "FindAsync\|FirstOrDefaultAsync\|GetByIdAsync" src/Application/ src/Infrastructure/ --include="*.cs"

# === 動作級授權 ===

# 所有寫入 endpoint — 確認有 [Authorize] 或 handler 內的 policy 檢查
grep -rn "\[HttpPost\]\|\[HttpPut\]\|\[HttpDelete\]\|\[HttpPatch\]" src/Api/ --include="*.cs"

# 有 [AllowAnonymous] 的地方 — 確認每個都合理
grep -rn "\[AllowAnonymous\]" src/Api/ --include="*.cs"

# === Policy 與 Authorization Handler ===

# 自定義 AuthorizationHandler
grep -rn "IAuthorizationHandler\|AuthorizationHandler" src/ --include="*.cs"

# Policy 定義
grep -rn "AddPolicy\|RequireRole\|RequireClaim" src/ --include="*.cs"

# Handler 中的 tenant/project 歸屬檢查
grep -rn "CurrentUser\|UserId\|TenantId" src/Application/ --include="*.cs"
```

### 判定標準

- `[FromRoute] int id` → `_repo.GetByIdAsync(id)` 無 ownership/tenant filter → **D-AUTH 缺陷**
- `[HttpDelete]` endpoint 無 `[Authorize]` 且 handler 無 policy 檢查 → **D-AUTH 缺陷**
- `[AllowAnonymous]` 在非公開端點（如 health check、login 以外） → **D-AUTH 缺陷**
- 有 global `[Authorize]` filter + handler 內 ownership 檢查 → **合理**
- 資源為公開性質（如共用設定值、不分 tenant 的 enum 列表） → **合理**

**搜查狀態：** 🔲 未搜查

### 搜查結果

**發現：**

（尚未執行搜查）

**Low-risk observations：**

（尚未執行搜查）

**審查但判定合理：**

（尚未執行搜查）

---

## D-QUERY: 查詢語意錯誤

### 定義

EF Core / LINQ 查詢能正確編譯與執行但語意不對：

1. **排序不確定** — `.Take(n)` 無前置 `.OrderBy()`，結果順序由 DB 決定，不同次查詢可能不一致。
2. **字串比對語意** — C# `string.Contains()` 轉為 SQL `LIKE '%x%'`（case-sensitive），但 PostgreSQL 需 `EF.Functions.ILike()` 做 case-insensitive 搜尋。
3. **分頁缺 total count** — `.Skip().Take()` 但未同步查詢總數，前端無法知道是否有下一頁。

### 搜查方式

```bash
# === 排序不確定 ===

# .Take() 前是否有 .OrderBy()
grep -rn "\.Take(" src/Infrastructure/ --include="*.cs" -B 5

# LIMIT 等效語法
grep -rn "\.Skip(" src/Infrastructure/ --include="*.cs" -B 3

# === 字串比對 ===

# string.Contains() 在 LINQ query 中 — 應改用 EF.Functions.ILike()
grep -rn "\.Contains(" src/Infrastructure/ --include="*.cs" | grep -v "using\|List\|Array\|Collection\|Enumerable"

# 正確用法（正面樣本）
grep -rn "EF\.Functions\.ILike\|EF\.Functions\.Like" src/Infrastructure/ --include="*.cs"

# === 分頁完整性 ===

# Skip + Take 搭配 — 確認有 CountAsync
grep -rn "\.Skip(.*\.Take(" src/Infrastructure/ --include="*.cs"

# CountAsync 呼叫（正面樣本）
grep -rn "CountAsync" src/Infrastructure/ --include="*.cs"
```

### 判定標準

- `.Take(n)` 前 5 行內無 `.OrderBy()` / `.OrderByDescending()` → **D-QUERY 缺陷**
- LINQ `x.Name.Contains(keyword)` 在 PostgreSQL 上 → **D-QUERY 缺陷**（case-sensitive 行為不符預期）
- `.Skip().Take()` 無配套 `CountAsync` 且前端有分頁 UI → **D-QUERY 缺陷**
- `.Take(1)` 取唯一結果（等效 FirstOrDefault） → **合理**
- `Contains()` 用在 `List.Contains(id)` 生成 `IN (...)` 子句 → **合理**

**搜查狀態：** 🔲 未搜查

### 搜查結果

**發現：**

（尚未執行搜查）

**Low-risk observations：**

（尚未執行搜查）

**審查但判定合理：**

（尚未執行搜查）

---

## D-VALID: 輸入驗證覆蓋缺口

### 定義

使用 FluentValidation 或 MediatR pipeline 的專案中，Command / Query 的驗證器覆蓋不完整：

1. **Command 無對應 Validator** — `CreateXxxCommand` 存在但無 `CreateXxxCommandValidator`。
2. **驗證規則不完整** — 有 Validator 但未覆蓋所有可寫入欄位（缺 MaxLength、格式檢查等）。
3. **File upload 驗證缺口** — 上傳端點缺少檔案大小、類型、檔名安全性驗證。

### 搜查方式

```bash
# === 覆蓋率比對 ===

# 列出所有 Command（寫入操作）
grep -rn "class.*Command\b" src/Application/ --include="*.cs" | grep -v "Handler\|Validator\|Interface"

# 列出所有 Validator
grep -rn "class.*Validator\b" src/Application/ --include="*.cs"

# 比對：每個 Command 是否有對應 Validator（名稱配對）
# 手動對照上面兩個結果

# === 驗證規則完整性 ===

# Validator 中的規則 — 檢查是否有 MaximumLength / NotEmpty / Must
grep -rn "RuleFor\|MaximumLength\|NotEmpty\|Must(" src/Application/ --include="*.cs"

# Command 的屬性 — 對照 Validator 是否每個 string 屬性都有 MaxLength
grep -rn "public.*string.*{.*get" src/Application/ --include="*.cs" | grep "Command"

# === File upload ===

# 檔案上傳端點
grep -rn "IFormFile\|\[FromForm\]" src/Api/ --include="*.cs"

# 檔案驗證規則
grep -rn "\.Length\|ContentType\|FileName" src/Application/ --include="*.cs" | grep -i "valid\|check\|allow"
```

### 判定標準

- `CreateXxxCommand` 存在但無對應 `CreateXxxCommandValidator` → **D-VALID 缺陷**
- string 屬性無 `MaximumLength` 規則 → **D-VALID 缺陷**（DB 欄位有長度限制時）
- `IFormFile` 端點無檔案大小 / 類型限制 → **D-VALID 缺陷**
- Query（唯讀操作）無 Validator → **合理**（視專案政策，通常 Query 不需嚴格驗證）
- ID 類參數由 DB lookup 保護 → **合理**

**搜查狀態：** 🔲 未搜查

### 搜查結果

**發現：**

（尚未執行搜查）

**Low-risk observations：**

（尚未執行搜查）

**審查但判定合理：**

（尚未執行搜查）

---

## D-FETYPE: 前端型別安全漏洞

### 定義

TypeScript / React 前端的型別安全問題，常見於 API client 自動生成（如 Orval）與手動程式碼的介面處：

1. **型別斷言濫用** — `as any`、`@ts-ignore`、`@ts-expect-error` 繞過型別檢查。
2. **API client 型別不完整** — Orval 生成的型別含 `unknown`，使用端未做型別窄化。
3. **事件處理型別缺漏** — `onChange`、`onSubmit` handler 的 event/value 型別為 `any`。

### 搜查方式

```bash
# === 型別斷言 ===

# as any — 繞過型別檢查（應為 0 或極少量）
grep -rn "as any" frontend/src/ --include="*.ts" --include="*.tsx"

# @ts-ignore / @ts-expect-error — 應有註解說明原因
grep -rn "@ts-ignore\|@ts-expect-error" frontend/src/ --include="*.ts" --include="*.tsx"

# 型別斷言 as unknown as — 雙重斷言，極度可疑
grep -rn "as unknown as" frontend/src/ --include="*.ts" --include="*.tsx"

# === API client 型別 ===

# Orval 生成的 unknown 型別 — 檢查使用端是否有窄化
grep -rn ": unknown\b" frontend/src/ --include="*.ts" | grep -v "node_modules\|\.gen\."

# 手動覆寫 Orval 型別（可能過期）
grep -rn "interface.*Override\|type.*Override" frontend/src/ --include="*.ts"

# === 事件處理 ===

# any 型別的 event handler
grep -rn "e: any\|event: any\|value: any\|data: any" frontend/src/ --include="*.ts" --include="*.tsx"

# React.ChangeEvent 等正確型別（正面樣本）
grep -rn "React\.ChangeEvent\|React\.FormEvent\|ChangeEventHandler" frontend/src/ --include="*.tsx"
```

### 判定標準

- `as any` 無伴隨註解說明 → **D-FETYPE 缺陷**
- Orval 生成的 `unknown` 型別在使用端直接 `as any` 繞過 → **D-FETYPE 缺陷**
- `@ts-ignore` 用於已知 library 型別缺陷且有 issue link → **合理**
- `as const` 或 `as Type`（非 any）的合理斷言 → **合理**

**搜查狀態：** 🔲 未搜查

### 搜查結果

**發現：**

（尚未執行搜查）

**Low-risk observations：**

（尚未執行搜查）

**審查但判定合理：**

（尚未執行搜查）

---

## D-TIME: 時間處理不一致

### 定義

跨層的時間處理不統一，導致時區問題或比較錯誤：

1. **DateTime.Now 誤用** — 使用 `DateTime.Now`（本地時區）而非 `DateTime.UtcNow`，部署在不同時區的伺服器會產生不一致。
2. **DateTime vs DateTimeOffset 混用** — 同一 aggregate 的不同屬性混用兩種型別，DB 儲存與比較語意不一致。
3. **前後端時區不一致** — 後端回傳 UTC，前端顯示未做本地化轉換，或前端送出非 UTC 時間。

### 搜查方式

```bash
# === DateTime.Now 誤用 ===

# DateTime.Now（應改為 DateTime.UtcNow 或透過 ITimeProvider）
grep -rn "DateTime\.Now\b" src/ --include="*.cs" | grep -v "UtcNow\|\.Test\.\|Test/"

# DateTimeOffset.Now（同理，應用 UtcNow）
grep -rn "DateTimeOffset\.Now\b" src/ --include="*.cs" | grep -v "UtcNow"

# === 型別混用 ===

# DateTime 屬性宣告
grep -rn "DateTime\b.*{.*get" src/Domain/ --include="*.cs" | grep -v "Offset\|\/\/"

# DateTimeOffset 屬性宣告
grep -rn "DateTimeOffset.*{.*get" src/Domain/ --include="*.cs"

# 同一 entity 是否混用（需人工對照上面兩個結果）

# === 前端時間處理 ===

# new Date() 不帶參數 — 使用本地時間
grep -rn "new Date()" frontend/src/ --include="*.ts" --include="*.tsx"

# toLocaleDateString / toLocaleTimeString — 確認有正確使用
grep -rn "toLocale\|toISOString\|format(" frontend/src/ --include="*.ts" --include="*.tsx" | grep -i "date\|time"

# === 時間抽象 ===

# ITimeProvider / TimeProvider 注入（正面樣本）
grep -rn "ITimeProvider\|TimeProvider\|IClock" src/ --include="*.cs"
```

### 判定標準

- `DateTime.Now` 用在業務邏輯或 DB 寫入 → **D-TIME 缺陷**
- 同一 entity 混用 `DateTime` 和 `DateTimeOffset` → **D-TIME 缺陷**
- `DateTime.Now` 在測試 setup 中 → **合理**（但建議改用 `TimeProvider.System`）
- `new Date()` 用於 UI 顯示「現在時間」 → **合理**
- 使用 `TimeProvider` 抽象 + `DateTime.UtcNow` → **合理**

**搜查狀態：** 🔲 未搜查

### 搜查結果

**發現：**

（尚未執行搜查）

**Low-risk observations：**

（尚未執行搜查）

**審查但判定合理：**

（尚未執行搜查）

---

## D-EDGE: 邊界條件與資源限制

### 定義

未處理的極端輸入或缺少安全護欄：

1. **不安全的集合存取** — `.First()` / `.Single()` 在可能為空的集合上呼叫，未用 `OrDefault` 變體。
2. **分頁驗證缺口** — `pageSize` / `pageNumber` 未限制上下界，可能導致記憶體爆炸或負數 offset。
3. **檔案大小與數量限制** — 上傳端點無檔案大小上限，或批次操作無陣列長度限制。

### 搜查方式

```bash
# === 不安全集合存取 ===

# .First() 不帶 OrDefault — 空集合會拋 InvalidOperationException
grep -rn "\.First()" src/ --include="*.cs" | grep -v "OrDefault\|\.Test\.\|Test/"

# .Single() 不帶 OrDefault — 非預期多筆會拋異常
grep -rn "\.Single()" src/ --include="*.cs" | grep -v "OrDefault\|\.Test\.\|Test/"

# .ElementAt() — 越界存取
grep -rn "\.ElementAt(" src/ --include="*.cs"

# === 分頁驗證 ===

# PageSize / PageNumber 參數 — 確認有上下界限制
grep -rn "PageSize\|PageNumber\|pageSize\|pageNumber" src/ --include="*.cs"

# 分頁的 Validator 規則
grep -rn "PageSize\|PageNumber" src/Application/ --include="*.cs" | grep -i "validator\|RuleFor"

# === 批次操作限制 ===

# List / Array 參數的端點 — 確認有 .Count / .Length 限制
grep -rn "List<\|IEnumerable<\|\[\]" src/Application/ --include="*.cs" | grep "Command\|Request"
```

### 判定標準

- `.First()` 在 production code 的可能為空的查詢結果上 → **D-EDGE 缺陷**
- `PageSize` 無 `GreaterThan(0)` + `LessThanOrEqualTo(maxSize)` → **D-EDGE 缺陷**
- 批次 Command 的 `List<>` 參數無 `.Count` 上限 → **D-EDGE 缺陷**
- `.First()` 在 seed data / migration 中 → **合理**
- `.Single()` 在確定唯一的 lookup（如 by unique key） → **合理**

**搜查狀態：** 🔲 未搜查

### 搜查結果

**發現：**

（尚未執行搜查）

**Low-risk observations：**

（尚未執行搜查）

**審查但判定合理：**

（尚未執行搜查）

---

## D-ASYNC: 非同步與並發問題

### 定義

async/await 使用不當或並發控制缺失：

1. **Fire-and-forget** — `_ = SomeMethodAsync()` 或不 await 的 Task，異常被吞沒。
2. **CancellationToken 未傳遞** — Handler / Service 方法接受 `CancellationToken` 但未傳給下層 DB / HTTP 呼叫。
3. **N+1 非同步迴圈** — `foreach` 迴圈內 `await` 個別項目查詢，應改用批次查詢或 `Task.WhenAll`。

### 搜查方式

```bash
# === Fire-and-forget ===

# 明確的 fire-and-forget（discard pattern）
grep -rn "_ =" src/ --include="*.cs" | grep -i "async\|task\|await"

# 不帶 await 的 async method call（較高噪音）
grep -rn "Async(" src/ --include="*.cs" | grep -v "await\|return\|Task\|\.Result\|\.Test\."

# === CancellationToken 傳遞 ===

# 接受 CancellationToken 的方法
grep -rn "CancellationToken" src/Application/ src/Infrastructure/ --include="*.cs"

# Async 呼叫未帶 cancellationToken 參數
grep -rn "Async(" src/Application/ src/Infrastructure/ --include="*.cs" | grep -v "cancellationToken\|CancellationToken\|\.Test\."

# === N+1 非同步迴圈 ===

# foreach 內的 await — 潛在 N+1
grep -rn "foreach" src/ --include="*.cs" -A 3 | grep "await"

# for 迴圈內的 await
grep -rn "for\s*(" src/ --include="*.cs" -A 3 | grep "await"

# 正面樣本：批次查詢 / Task.WhenAll
grep -rn "Task\.WhenAll\|WhereIn\|Contains(" src/ --include="*.cs"
```

### 判定標準

- `_ = SomeMethodAsync()` 不帶 try-catch 或 log → **D-ASYNC 缺陷**
- Handler 有 `CancellationToken ct` 參數但 DB call 未帶 `ct` → **D-ASYNC 缺陷**
- `foreach (var item in items) { await _repo.GetAsync(item.Id); }` → **D-ASYNC 缺陷**（N+1）
- `_ = backgroundService.EnqueueAsync()` 有專屬的 error handler → **合理**
- `foreach await` 但每次迭代有副作用需循序執行 → **合理**

**搜查狀態：** 🔲 未搜查

### 搜查結果

**發現：**

（尚未執行搜查）

**Low-risk observations：**

（尚未執行搜查）

**審查但判定合理：**

（尚未執行搜查）

---

## D-DISPOSE: 資源釋放問題

### 定義

IDisposable / IAsyncDisposable 資源未正確釋放：

1. **缺少 using** — `new MemoryStream()` / `new StreamReader()` 未包在 `using` 中，GC 壓力或資源洩漏。
2. **HttpClient 反模式** — 直接 `new HttpClient()` 而非透過 `IHttpClientFactory`，導致 socket exhaustion。
3. **DbContext 生命週期** — 手動 `new DbContext()` 未 dispose，或在 Singleton 中注入 Scoped 的 DbContext。

### 搜查方式

```bash
# === 缺少 using ===

# new MemoryStream() 不帶 using
grep -rn "new MemoryStream(" src/ --include="*.cs" | grep -v "using\|await using"

# new StreamReader / StreamWriter 不帶 using
grep -rn "new StreamReader\|new StreamWriter\|new FileStream" src/ --include="*.cs" | grep -v "using\|await using"

# === HttpClient 反模式 ===

# 直接 new HttpClient()（應用 IHttpClientFactory）
grep -rn "new HttpClient(" src/ --include="*.cs"

# 正面樣本：IHttpClientFactory 使用
grep -rn "IHttpClientFactory\|CreateClient\|AddHttpClient" src/ --include="*.cs"

# === DbContext 生命週期 ===

# 直接 new DbContext（應透過 DI）
grep -rn "new.*DbContext(" src/ --include="*.cs" | grep -v "Test\|Migration\|DesignTime"

# Singleton 中注入 Scoped service
grep -rn "AddSingleton" src/ --include="*.cs" -A 3 | grep "DbContext\|Scoped"
```

### 判定標準

- `new MemoryStream()` 不在 `using` 區塊中且非 return 給呼叫者 → **D-DISPOSE 缺陷**
- `new HttpClient()` 在 application code → **D-DISPOSE 缺陷**
- `new DbContext()` 在非 test / migration 的 production code → **D-DISPOSE 缺陷**
- `new MemoryStream()` 作為回傳值（由呼叫者負責 dispose） → **合理**（需確認呼叫鏈）
- 測試中 `new HttpClient(handler)` 搭配 `MockHttpMessageHandler` → **合理**

**搜查狀態：** 🔲 未搜查

### 搜查結果

**發現：**

（尚未執行搜查）

**Low-risk observations：**

（尚未執行搜查）

**審查但判定合理：**

（尚未執行搜查）

---

## D-CONFIG: 配置與硬編碼值

### 定義

應外部化的配置值被硬編碼在程式碼中：

1. **硬編碼 URL / 端點** — API base URL、bucket name、queue name 寫死在程式碼中。
2. **Magic number** — 重試次數、timeout、分頁大小等數值未提取為 `appsettings.json` 或 `IOptions<T>`。
3. **環境相依邏輯** — `#if DEBUG` 或 `Environment.GetEnvironmentVariable()` 直接使用而非透過 Options pattern。

### 搜查方式

```bash
# === 硬編碼 URL ===

# 寫死的 URL / host
grep -rn "http://\|https://" src/ --include="*.cs" | grep -v "\.Test\.\|Test/\|swagger\|xml\|///\|summary"

# 硬編碼的 bucket / queue / topic 名稱
grep -rn "\"bucket-\|\"queue-\|\"topic-" src/ --include="*.cs"

# === Magic number ===

# 常見 magic number 情境：Timeout、RetryCount、MaxSize
grep -rn "TimeSpan\.From\|new TimeSpan(" src/ --include="*.cs" | grep -v "\.Test\.\|Test/"

# delay / retry 相關硬編碼
grep -rn "Task\.Delay\|\.RetryCount\|maxRetries\|MaxRetry" src/ --include="*.cs"

# === 環境相依邏輯 ===

# 直接讀環境變數（應透過 IConfiguration / IOptions）
grep -rn "Environment\.GetEnvironmentVariable" src/ --include="*.cs" | grep -v "Program\.cs\|Startup\.cs"

# #if DEBUG 條件編譯
grep -rn "#if DEBUG\|#if RELEASE" src/ --include="*.cs"

# 正面樣本：IOptions pattern
grep -rn "IOptions<\|IOptionsMonitor<\|IOptionsSnapshot<" src/ --include="*.cs"
```

### 判定標準

- 程式碼中寫死 `"http://localhost:5000"` 或具體 bucket name → **D-CONFIG 缺陷**
- `TimeSpan.FromSeconds(30)` 硬編碼在 production code 且無註解 → **D-CONFIG 缺陷**
- `Environment.GetEnvironmentVariable` 在非 `Program.cs` 的地方 → **D-CONFIG 缺陷**
- `appsettings.json` 中的預設值 → **合理**
- `TimeSpan.FromSeconds(1)` 在 retry policy 且有 `IOptions` 可覆寫 → **合理**

**搜查狀態：** 🔲 未搜查

### 搜查結果

**發現：**

（尚未執行搜查）

**Low-risk observations：**

（尚未執行搜查）

**審查但判定合理：**

（尚未執行搜查）

---

## D-LOG: 日誌安全

### 定義

日誌或錯誤回應中洩漏不應暴露的資訊：

1. **異常細節洩漏** — `catch (Exception ex) { return ex.Message; }` 或 `ex.StackTrace` 直接回傳給 client，繞過全域 ExceptionHandler 的遮罩。
2. **敏感資料入 log** — `_logger.LogInformation("User {Password}", password)` 或 log 結構化參數包含 PII（email、token、IP）。
3. **SQL / Connection String 洩漏** — EF Core 異常的 inner exception 包含完整 SQL 或 connection string，被回傳至 client。

### 搜查方式

```bash
# === 異常細節洩漏 ===

# ex.Message 直接回傳（繞過全域 handler）
grep -rn "ex\.Message\|ex\.StackTrace" src/Api/ --include="*.cs" | grep -v "_logger\|Log\."

# catch 區塊中直接 return 異常資訊
grep -rn "catch.*Exception" src/Api/ --include="*.cs" -A 5 | grep "return.*ex\.\|StatusCode.*ex\."

# === 敏感資料入 log ===

# 潛在的 PII 在 log 中（需人工審查內容）
grep -rn "_logger\.\|Log\.\(Information\|Warning\|Error\)" src/ --include="*.cs" | grep -i "password\|token\|secret\|email\|creditcard\|ssn"

# 結構化 log 參數 — 大量記錄可能洩漏的欄位
grep -rn "LogInformation\|LogWarning" src/ --include="*.cs" | grep "{.*}" | grep -i "user\|request\|header"

# === 開發模式異常洩漏 ===

# UseDeveloperExceptionPage — 生產環境不應啟用
grep -rn "UseDeveloperExceptionPage" src/ --include="*.cs"

# 確認有環境條件保護
grep -rn "IsDevelopment\|IsProduction" src/ --include="*.cs" -A 2 | grep -i "exception\|error"
```

### 判定標準

- `return Ok(ex.Message)` 或 `return StatusCode(500, ex.ToString())` → **D-LOG 缺陷**
- `_logger.LogInformation("Login {Password}", password)` → **D-LOG 缺陷**
- `UseDeveloperExceptionPage()` 不在 `if (env.IsDevelopment())` 內 → **D-LOG 缺陷**
- `_logger.LogError(ex, "Operation failed for {UserId}", userId)` → **合理**（ID 非敏感、exception 記在 log 不回 client）
- 全域 ExceptionHandler 統一回傳 `ProblemDetails` 不含 ex.Message → **合理**

**搜查狀態：** 🔲 未搜查

### 搜查結果

**發現：**

（尚未執行搜查）

**Low-risk observations：**

（尚未執行搜查）

**審查但判定合理：**

（尚未執行搜查）
