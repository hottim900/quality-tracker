# 品質管理追蹤

你的專案的品質管理體系。追蹤缺陷、技術債、功能缺口、測試覆蓋與工具建設，並維護品質防線。

---

## 快速查詢

> 本系統不維護手動統計數字 — 所有狀態由 item 檔案的 metadata 衍生，透過查詢取得即時結果。

| 查詢                 | 指令                                                                                                                                       |
| -------------------- | ------------------------------------------------------------------------------------------------------------------------------------------ |
| 活躍項目             | `grep -Erl '狀態.*(Pending\|In Progress)' defects/ tech-debt/ feature-gaps/ test-infra/`                                                           |
| Critical/High 活躍   | `grep -Erl '優先級.*(Critical\|High)' defects/ tech-debt/ feature-gaps/ test-infra/ \| xargs grep -El '狀態.*(Pending\|In Progress)'` |
| Blocked 項目         | `grep -rl '狀態.*Blocked-by-Decision' defects/ tech-debt/ feature-gaps/ test-infra/`                                                             |
| 搜查進度             | 見 [defect-taxonomy.md 分類總覽](./defect-taxonomy.md#分類總覽)                                                                            |
| 統計報告             | `bash examples/scripts/quality-stats.sh`                                                                                                   |

---

## 分類體系

| 分類             | 定義                         | 處理策略                | 目錄                             |
| ---------------- | ---------------------------- | ----------------------- | -------------------------------- |
| **Defect**       | 非預期的錯誤，寫入時就是錯的 | 立即修復 + 回溯流程漏洞 | [defects/](./defects/)           |
| **Tech Debt**    | 有意識的妥協，先上線再改     | 排優先級，安排容量      | [tech-debt/](./tech-debt/)       |
| **Feature Gap**          | 功能不完整，缺少預期互動         | 放進 backlog            | [feature-gaps/](./feature-gaps/) |
| **Test Infrastructure**  | 測試覆蓋缺口與測試工具建設       | 排優先級，系統性補齊    | [test-infra/](./test-infra/)     |
| **Quality Gate**         | 防止 Defect / Tech Debt / Feature Gap 進入 codebase | 持續投資的基礎設施 | （例如 CI、搜查手冊、hook） |

### 如何判斷分類？

```
這個問題是有意識的妥協嗎？
├── 是 → 妥協的是測試覆蓋或測試工具嗎？
│   ├── 是 → Test Infrastructure（「知道該寫測試，先上線再補」）
│   └── 否 → Tech Debt（「我知道不夠好，先上線」）
└── 否 → 程式碼行為與設計意圖一致嗎？
    ├── 否 → Defect（逃逸缺陷 / 設計缺陷）
    └── 是 → 功能設計完整嗎？
        ├── 否 → 缺少的是測試覆蓋嗎？
        │   ├── 是 → Test Infrastructure（未覆蓋的測試路徑或缺少的測試工具）
        │   └── 否 → Feature Gap（缺少的互動或資訊）
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

#### 升級與降級信號

優先級不是固定的 — 隨情境變化調整。以下為常見信號，非硬性規則：

**升級（例如 Medium → High）：**
- 同類問題重複出現（第二次遇到 = 模式，不再是偶發）
- 外部依賴變化（上游 API 即將 deprecate、安全漏洞公告）
- 影響範圍擴大（原本只影響一個功能，發現波及多處）
- 阻擋其他項目進展

**降級（例如 High → Medium）：**
- 找到有效的 workaround 且已記錄
- 影響範圍確認比預期小（例如只在特定邊界條件觸發）
- 外部壓力消失（deadline 延後、相關功能暫停開發）

> **操作：** 調整優先級時，更新項目檔的優先級欄位並簡述變更原因。

---

## 搜查手冊

定義所有已知缺陷類別和可重複執行的搜查模式：**[defect-taxonomy.md](./defect-taxonomy.md)**

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
| Defect              | `DEF-NNN` | DEF-001 | `DEF-001-short-description.md` |
| Tech Debt           | `TD-NNN`  | TD-001  | `TD-001-short-description.md`  |
| Feature Gap         | `FG-NNN`  | FG-001  | `FG-001-short-description.md`  |
| Test Infrastructure | `TI-NNN`  | TI-001  | `TI-001-short-description.md`  |

---

## 模板

| 類型        | 模板檔案                                             |
| ----------- | ---------------------------------------------------- |
| Defect              | [TEMPLATE-DEFECT.md](./TEMPLATE-DEFECT.md)               |
| Tech Debt           | [TEMPLATE-TECH-DEBT.md](./TEMPLATE-TECH-DEBT.md)         |
| Feature Gap         | [TEMPLATE-FEATURE-GAP.md](./TEMPLATE-FEATURE-GAP.md)     |
| Test Infrastructure | [TEMPLATE-TEST-INFRA.md](./TEMPLATE-TEST-INFRA.md)       |

---

## 建立新項目

1. 用[分類決策樹](#如何判斷分類)判斷類型（Defect / Tech Debt / Feature Gap / Test Infrastructure）
2. 決定下一個 ID — `ls` 對應目錄找最大編號 +1
3. 複製對應模板到目錄，例如：
   - `cp TEMPLATE-DEFECT.md defects/DEF-NNN-short-description.md`
   - `cp TEMPLATE-TEST-INFRA.md test-infra/TI-NNN-short-description.md`
4. 填寫 metadata table 所有欄位（參照上方[定義參考](#定義參考)）
5. 若 Defect，填寫「缺陷子類別」欄位，連結到 [defect-taxonomy.md](./defect-taxonomy.md) 對應段落

---

## 完成步驟

> **IMPORTANT:** 修復完成後，依序執行以下步驟。缺任何一步 = 未完成。

1. 項目檔「狀態」改為 Done，填寫「完成紀錄」（Commit、修改摘要、測試結果）
2. 若「相依」有 Complements/Blocks 項目 → 檢查對方是否需更新
3. 若為 Defect 且在系統性搜查中發現 → 確認搜查結果已記錄於 [defect-taxonomy.md](./defect-taxonomy.md)

---

## 封存（Archival）

Done 項目的下一個生命週期階段。項目留在原目錄不影響系統運作 — `grep -E '狀態.*(Pending|In Progress)'` 可過濾活躍項目。

項目累積過多時（建議閾值：單一目錄超過 30 個 Done 項目），可選擇封存：

1. 在對應目錄建立 `archive/` 子目錄（例如 `defects/archive/`）
2. 將 Done 項目移入：`mv defects/DEF-001-*.md defects/archive/`

### 不建議

- **不要刪除** Done 項目 — 歷史紀錄是學習資產（根因分析、逃逸階段統計）
- **不要過早封存** — 最近完成的項目可能需要回顧，建議至少保留一個月
