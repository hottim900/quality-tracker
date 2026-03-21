# 品質管理追蹤

你的專案的品質管理體系。追蹤缺陷、技術債、功能缺口，並維護品質防線。

---

## 統計概覽

| 指標                | 數值  |
| ------------------- | ----- |
| 活躍項目            | 0     |
| Critical / High     | 0 / 0 |
| Blocked-by-Decision | 0     |

---

## Critical + High 項目

> **只列 Critical/High。** Medium/Low 項目不列於此 — 用 `glob defects/DEF-*.md` 發現。
> 項目完成後從此表移除，項目檔內的狀態改為 Done。

### Defects

| ID  | 嚴重度 | 描述 |
| --- | ------ | ---- |

### Tech Debt

（目前無 Critical/High Tech Debt）

### Feature Gaps

| ID  | 描述 |
| --- | ---- |

---

## 分類體系

| 分類             | 定義                         | 處理策略                | 目錄                             |
| ---------------- | ---------------------------- | ----------------------- | -------------------------------- |
| **Defect**       | 非預期的錯誤，寫入時就是錯的 | 立即修復 + 回溯流程漏洞 | [defects/](./defects/)           |
| **Tech Debt**    | 有意識的妥協，先上線再改     | 排優先級，安排容量      | [tech-debt/](./tech-debt/)       |
| **Feature Gap**  | 功能不完整，缺少預期互動     | 放進 backlog            | [feature-gaps/](./feature-gaps/) |
| **Quality Gate** | 防止以上三者進入 codebase    | 持續投資的基礎設施      | （例如 CI、搜查手冊、hook）      |

### 如何判斷分類？

```
這個問題是有意識的妥協嗎？
├── 是 → Tech Debt（「我知道不夠好，先上線」）
└── 否 → 程式碼行為與設計意圖一致嗎？
    ├── 否 → Defect（逃逸缺陷 / 設計缺陷）
    └── 是 → 功能設計完整嗎？
        ├── 否 → Feature Gap（缺少的互動或資訊）
        └── 是 → 不需要追蹤
```

---

## 定義參考

### 狀態

| 狀態                    | 定義                                  |
| ----------------------- | ------------------------------------- |
| **Pending**             | 已記錄，等待處理                      |
| **In Progress**         | 正在修復中                            |
| **Blocked-by-Decision** | 解決方案需要人類決策，AI 不應自行推進 |
| **Done**                | 修復完成，已通過驗收                  |

### 優先級（業務緊急度 — 何時修）

| 優先級       | 定義                       | 處理時機              |
| ------------ | -------------------------- | --------------------- |
| **Critical** | 影響生產穩定性或安全性     | 立即處理（同日）      |
| **High**     | 阻礙開發效率或造成頻繁 bug | 下個 Sprint（1-2 週） |
| **Medium**   | 增加維護成本但不影響功能   | 規劃中處理（1 個月）  |
| **Low**      | 改善開發體驗，非必要       | 有空時處理（無 SLA）  |

### 嚴重度（技術影響 — 多嚴重，Defect 專用）

| 嚴重度          | 定義                        | 範例                       |
| --------------- | --------------------------- | -------------------------- |
| **S1-Critical** | 系統不可用或資料遺失        | 寫入操作靜默遺失資料       |
| **S2-Major**    | 功能異常，無合理 workaround | API 回傳錯誤的 status code |
| **S3-Minor**    | 功能異常，有 workaround     | 手動刷新頁面可繞過         |
| **S4-Trivial**  | 外觀/文字問題               | 錯誤訊息措辭不佳           |

### 成本（實作工時）

| 代號   | 範圍          | 說明                 |
| ------ | ------------- | -------------------- |
| **S**  | < 2 小時      | 簡單修復，單一改動   |
| **M**  | 2 小時 ~ 1 天 | 中等複雜度，多個檔案 |
| **L**  | 1 ~ 3 天      | 複雜修復，需要設計   |
| **XL** | > 3 天        | 大型重構，建議分階段 |

### 根因類別（Defect 專用）

| 根因                       | 定義                         |
| -------------------------- | ---------------------------- |
| **Design Defect**          | 架構/設計層面的錯誤決策      |
| **Implementation Error**   | 實作與設計意圖不符           |
| **Configuration Omission** | 配置遺漏（框架、建置工具等） |
| **Framework Limitation**   | 框架已知限制未規避           |
| **Missing Test Coverage**  | 缺少測試導致未發現           |

### 逃逸階段（Defect 專用）

| 階段                 | 說明                     |
| -------------------- | ------------------------ |
| **Code Review**      | 初次實作時 review 未捕獲 |
| **Unit Test**        | 單元測試未覆蓋此路徑     |
| **Integration Test** | 整合測試未覆蓋此場景     |
| **E2E Test**         | E2E 測試未覆蓋此場景     |
| **Production**       | 生產環境使用者發現       |

---

## 搜查手冊

定義所有已知缺陷類別和可重複執行的搜查模式：**[defect-taxonomy.md](./defect-taxonomy.md)**

### 搜查進度

> 此表追蹤 [defect-taxonomy.md](./defect-taxonomy.md) 中各缺陷搜查類別的進度（不含 Tech Debt / Feature Gap 等其他分類）。
> 詳細的搜查指令、判定標準與完整結果記錄在 taxonomy 檔案中 — **taxonomy 為 source of truth**，此表為快速總覽。
> 更新搜查結果時，兩處需同步更新。

| 缺陷類別 | 搜查狀態 | 結果摘要 |
| -------- | -------- | -------- |
| D-SILENT — 靜默失敗與錯誤吞沒 | 待搜查 | |
| D-VALID — 輸入驗證缺口 | 待搜查 | |
| D-AUTH — 認證、授權與安全防線 | 待搜查 | |
| D-TYPE — 型別安全漏洞 | 待搜查 | |
| D-PERF — 效能問題 | 待搜查 | |
| D-EDGE — 邊界條件與資源限制 | 待搜查 | |

---

## 待追蹤發現

搜查中發現但尚未建立正式項目的問題。

> **AI 行動指引：** 此段落僅供參考。**不要主動升級為正式項目** — 由人類決定何時建立。
> 若人類要求處理某項，再依「建立新項目」流程操作。

（尚無待追蹤項目）

---

## ID 編碼規則

| 分類        | 前綴      | 範例    | 檔名格式                       |
| ----------- | --------- | ------- | ------------------------------ |
| Defect      | `DEF-NNN` | DEF-001 | `DEF-001-short-description.md` |
| Tech Debt   | `TD-NNN`  | TD-001  | `TD-001-short-description.md`  |
| Feature Gap | `FG-NNN`  | FG-001  | `FG-001-short-description.md`  |

---

## 模板

| 類型        | 模板檔案                                             |
| ----------- | ---------------------------------------------------- |
| Defect      | [TEMPLATE-DEFECT.md](./TEMPLATE-DEFECT.md)           |
| Tech Debt   | [TEMPLATE-TECH-DEBT.md](./TEMPLATE-TECH-DEBT.md)     |
| Feature Gap | [TEMPLATE-FEATURE-GAP.md](./TEMPLATE-FEATURE-GAP.md) |

---

## 建立新項目

1. 用[分類決策樹](#如何判斷分類)判斷類型（Defect / Tech Debt / Feature Gap）
2. 決定下一個 ID — `ls` 對應目錄找最大編號 +1
3. 複製對應模板到目錄：`cp TEMPLATE-DEFECT.md defects/DEF-NNN-short-description.md`
4. 填寫 metadata table 所有欄位（參照上方[定義參考](#定義參考)）
5. 若 Defect，填寫「缺陷子類別」欄位，連結到 [defect-taxonomy.md](./defect-taxonomy.md) 對應段落
6. 若優先級為 Critical 或 High → 加入本檔 [Critical/High 表](#critical--high-項目)
7. 更新[統計概覽](#統計概覽)數字

---

## 完成步驟

> **IMPORTANT:** 修復完成後，依序執行以下步驟。缺任何一步 = 未完成。

1. 項目檔「狀態」改為 Done
2. 填寫項目檔「完成紀錄」（Commit、修改摘要、測試結果）
3. 若本項在 Critical/High 表中 → 移除該行
4. 更新統計概覽（活躍項目數、Critical/High 計數）
5. 若「相依」有 Complements/Blocks 項目 → 檢查對方是否需更新
6. 搜查手冊的「已知實例」加入本項連結（若為 Defect）
