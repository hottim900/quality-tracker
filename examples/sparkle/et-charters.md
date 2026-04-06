# Sparkle ET Charters — 探索式測試執行範例

> **用途：** 展示 ET session 的結構和內容深度，從 charter 生成到結果記錄。
> 這是一份**示範範例**，基於 Sparkle 的真實架構撰寫，但 session 本身是推演而非實際執行。
> 你的專案應依照此結構執行自己的第一份 charter。

**專案背景：** Sparkle 是一個自架式的 PKM (Personal Knowledge Management) 前端，用 TypeScript/Bun 開發。功能包括筆記的 CRUD、分類管理、標籤系統、匯入匯出、分享連結。後端是 Hono + SQLite，前端是 React + TanStack Router。

---

## Charter 1: D-EDGE 業務規則邊界

### 觸發原因

Sparkle 的 D-EDGE 搜查已完成（2026-03-20）。grep 找到了 schema 層面的問題：

- **DEF-006:** category color 無格式驗證、reorder items 無 max、sort_order 無 max
- **DEF-007:** batch ids 陣列無 max 上限

這些都是 schema 限制的缺口。grep 能找到「z.string() 沒有 .max()」，但找不到業務規則層面的邊界條件。D-EDGE 的 charter seed 指向這個盲區。

### Charter

```
Target: 分類管理 (Category) — 業務規則邊界條件
Task: 探索「最後一個」邊界和跨功能互動：
  - 刪除或重新排序最後一個分類
  - 筆記全部移出某分類後的空分類行為
  - 分類被刪除後，引用該分類的筆記的狀態
  - 匯出操作和分類變更的交互
Timebox: 30 min
Trigger: D-EDGE 搜查完成，grep 已覆蓋 schema 限制但業務規則邊界未測試
```

### Session Report

**日期：** 2026-04-06
**實際耗時：** 30 min（探索 55% / 調查 30% / 記錄 15%）

#### 探索路徑

1. **「最後一個分類」的邊界** — Sparkle 預設有一個 "Uncategorized" 分類。嘗試理解：如果使用者刪除所有自建分類，系統是否有保護機制？如果筆記的分類被刪除，筆記會回到哪裡？

2. **空分類的行為** — 建立分類後不放任何筆記，然後嘗試：匯出（是否匯出空分類？）、排序（空分類在排序中的位置）、API response（空分類的 item_count 是否為 0 而非 null）。

3. **分類重新排序的極端值** — sort_order 欄位的行為：如果手動設定 sort_order 為負數？如果兩個分類有相同的 sort_order？DEF-006 已經指出 sort_order 無 max，但 sort_order 衝突時的行為是業務邏輯層面的問題。

4. **匯出與分類變更的交互** — 匯出進行中（尤其是大量筆記的 JSON 匯出），同時修改分類結構。DEF-023 已經發現匯出有 timestamp 精度問題，但匯出的「一致性快照」問題是更深層的設計問題。

#### 發現

**發現 1: 分類刪除後的筆記歸屬**

刪除一個有筆記的分類時，筆記的 category_id 變成 orphan reference。Sparkle 的 schema 設計中 category 和 note 的關聯是 FK 約束（SQLite FOREIGN KEY），所以刪除分類時 SQLite 會根據 ON DELETE 行為決定處理方式。

如果設定了 `ON DELETE SET NULL`，筆記的 category_id 變成 NULL，在 UI 上顯示為「未分類」。如果設定了 `ON DELETE CASCADE`，筆記會被一起刪除，這在大量筆記的情況下可能是使用者不預期的行為。

這不是 grep 能找到的：關鍵不是 schema 定義本身，而是「使用者刪除一個有 200 筆筆記的分類時，是否得到足夠的警告？刪除後能否復原？」

**發現 2: sort_order 衝突行為**

如果兩個分類的 sort_order 相同（例如透過 API 直接設定），UI 的排序結果是不確定的（取決於 SQLite 的 row 順序）。這對使用者來說是「每次刷新，分類順序可能不同」的體驗。

grep 能找到「sort_order 無 max」（DEF-006），但「sort_order 重複時的行為」是業務邏輯層面的問題。

#### 新 Pattern 發現

- **Orphan FK 檢查：** `grep -rn "ON DELETE" server/migrations/ --include="*.ts"` 可以列出所有 FK 的刪除行為。如果發現有 `ON DELETE CASCADE` 在使用者面向的 entity 上，就是潛在風險。
  - 可 regex 化？ 是
  - False positive < 20%？ 需要驗證，CASCADE 在 junction table 上是合理的
  - 跨專案有用？ 是（任何有 FK 的 ORM 專案）
  - **結論：** 有推廣潛力，但需要更多資料驗證 false positive rate。暫時記錄在 charter seed。

#### 筆記

- 「最後一個」的邊界在 Sparkle 的語境中有兩層：最後一個自建分類（"Uncategorized" 始終存在）和最後一個被引用的分類（筆記指向的分類）
- 匯出一致性（snapshot isolation）是個有趣的方向，但 30 分鐘不夠深入。Sparkle 使用 SQLite WAL mode，理論上單次 read transaction 能得到一致快照，但匯出的 HTTP handler 是否在一個 transaction 內完成全部讀取？這需要更深入的調查
- DEF-023（timestamp 精度）和匯出一致性是不同層次的問題，前者是命名衝突，後者是資料完整性

---

## 執行這個範例的步驟

你的專案要執行第一次 ET session，按照以下步驟：

1. **選擇一個已完成搜查的 D-XXX 類別**（優先選 D-EDGE 或 D-SILENT，命中率高）
2. **讀取該類別的 charter seed**（「What grep can't find」段落）
3. **填入 4T 欄位**：用 charter seed 的 suggested charter 作為起點，依你的專案調整
4. **設定 30 分鐘計時器**
5. **邊探索邊記錄**：不要等 session 結束才記錄，發現疑似問題時立即寫下
6. **Session 結束後整理**：
   - 確認的缺陷 → 建 Issue + `discovery-method:et-session` label
   - 新 pattern → 評估[推廣標準](../../quality/discovery-strategy.md#pattern-推廣標準)
   - Session 紀錄 → 建 Issue 記錄完整 session report

不需要每次都有發現。沒有發現的 session 也是有價值的資訊，見 [et-charter-template.md](../../quality/et-charter-template.md#沒有發現怎麼辦)。

---

## See also

- [defect-taxonomy.md](./defect-taxonomy.md) — Sparkle 的搜查手冊（12 個完成的 D-XXX 類別）
- [quality/discovery-strategy.md](../../quality/discovery-strategy.md) — 雙層模型與方法論
- [quality/et-charter-template.md](../../quality/et-charter-template.md) — Charter 模板與 Quick Start
