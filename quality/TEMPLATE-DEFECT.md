# DEF-NNN: [標題]

> **For Claude:** 這是品質管理追蹤項目。依序執行各 Phase，每完成一項勾選驗收標準。完成後更新狀態並填寫完成紀錄。

| 欄位           | 值                                                                                                                 |
| -------------- | ------------------------------------------------------------------------------------------------------------------ |
| **ID**         | DEF-NNN                                                                                                            |
| **類型**       | Defect                                                                                                             |
| **狀態**       | Pending / In Progress / Blocked-by-Decision / Done                                                                 |
| **優先級**     | Critical / High / Medium / Low                                                                                     |
| **嚴重度**     | S1-Critical / S2-Major / S3-Minor / S4-Trivial                                                                     |
| **成本**       | S / M / L / XL                                                                                                     |
| **根因類別**   | Design Defect / Implementation Error / Configuration Omission / Framework Limitation / Missing Test Coverage       |
| **逃逸階段**   | Code Review / Unit Test / Integration Test / E2E Test / Production                                                 |
| **缺陷子類別** | [D-XXX](../defect-taxonomy.md#d-xxx-類別名稱)（例：[D-SILENT](../defect-taxonomy.md#d-silent-靜默失敗與錯誤吞沒)） |
| **相依**       | — / Complements: DEF-xxx / Blocks: DEF-xxx / Blocked-by: DEF-xxx                                                   |
| **關聯**       | 相關程式碼、Issue、文件連結                                                                                        |

---

## 問題

### TL;DR

一段話摘要：問題是什麼、影響什麼、根因是什麼。

### 現狀

詳細描述目前的問題狀況，含程式碼片段。

---

## 受影響檔案

| 檔案                      | 問題         |
| ------------------------- | ------------ |
| `path/to/file.ts` (L行號) | 具體問題描述 |

---

## 待決策項

> 解決方案中需要人類決策的問題。AI 不應自行決定，標記後等人類回覆。
> 所有待決策項解決後刪除此段落，狀態從 Blocked-by-Decision 改回 Pending/In Progress。

（無待決策項時刪除此段落）

---

## 解決方案

### Phase 1: [階段名稱]

**目標：** 此階段要達成什麼

**修改：**

- `path/to/file.ts` — 修改描述

**驗證：**

- 測試命令
- 預期結果

### Phase 2: [階段名稱]（選填）

（大型修復可分多階段）

---

## 驗收標準

- [ ] 檢查項目 1
- [ ] 檢查項目 2
- [ ] 測試通過

---

## 完成步驟

> **IMPORTANT:** 修復完成後，依序執行以下步驟。缺任何一步 = 未完成。
> 詳細定義見 [README.md 完成步驟](../README.md#完成步驟)。

- [ ] 本檔「狀態」改為 Done
- [ ] 填寫下方「完成紀錄」
- [ ] 若本項在 README.md Critical/High 表中 → 移除該行
- [ ] 更新 README.md 統計概覽（活躍項目數、Critical/High 計數）
- [ ] 若「相依」有 Complements/Blocks 項目 → 檢查對方檔案是否需更新

## 完成紀錄

> 完成後填寫

**Commit:** `abc1234` 或 PR 連結
**修改摘要：**

- Phase 1: 簡述實際修改

**測試結果：** X passed, 0 failed
**學習紀錄：**（選填）踩坑經驗
