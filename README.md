# quality-tracker

為 AI 輔助開發設計的品質追蹤系統。搭配 [Claude Code](https://docs.anthropic.com/en/docs/claude-code) 使用。

追蹤三種品質項目：**Defect**（非預期 bug）、**Tech Debt**（有意識的妥協）、**Feature Gap**（功能缺口），搭配系統性搜查手冊，讓 AI 能自主發現、記錄、修復品質問題。

---

## 為什麼需要這個？

AI 輔助開發常見的品質問題：

- **改完原始碼忘更新追蹤** — AI 修完 bug 但忘記更新 Dashboard、統計數字、相依項目
- **同類 bug 反覆出現** — 修了一個 bare catch，但不知道同類問題還有 12 處
- **缺乏系統性搜查** — 靠肉眼或記憶找 bug，而非可重複執行的搜查指令

本系統用 **搜查手冊（Defect Taxonomy）** 解決這些問題 — 定義缺陷類別 + 可執行的 grep 指令，讓你（和 AI）能系統性地掃描整個 codebase。

---

## 快速開始

### 1. 從 template 建立你的品質 repo

點選 GitHub 的 **"Use this template"** 按鈕，建立你的 private repo。

### 2. 設定 Claude Code Skill

將 `.claude/skills/quality/` 複製到你的專案，然後編輯 `SKILL.md` 頂部：

```
QUALITY_DIR=/你的品質系統絕對路徑/quality
```

> **為什麼要絕對路徑？** Claude Code 可能在 git worktree 中執行，相對路徑會指向 worktree 而非品質系統。

### 3. 在 CLAUDE.md 加入入口

將 `CLAUDE.md.snippet` 的內容貼進你專案的 `CLAUDE.md`：

```markdown
## 品質管理

品質追蹤系統（Defect / Tech Debt / Feature Gap）在 `quality/README.md`。
**操作前必須載入 `/quality` skill。**

修復 bug 時，檢查是否有對應的品質追蹤項目。
修復後嚴格執行項目檔底部的「完成步驟」。
```

### 4. 跑首次搜查

在 Claude Code 中：

```
/quality
```

然後請 Claude 對你的 codebase 執行搜查手冊中的類別，從 D-SILENT（靜默失敗）開始。

---

## 系統組成

```
quality/
├── README.md                      ← Dashboard：統計、Critical/High 表、分類定義
├── defect-taxonomy.md             ← 搜查手冊：6 個缺陷類別 + 擴充指引
├── quality-system-design-notes.md ← 方法論：設計原則、取捨、AI 效率優化
├── TEMPLATE-DEFECT.md             ← Defect 項目模板
├── TEMPLATE-TECH-DEBT.md          ← Tech Debt 項目模板
├── TEMPLATE-FEATURE-GAP.md        ← Feature Gap 項目模板
├── defects/                       ← DEF-001-xxx.md, DEF-002-xxx.md, ...
├── tech-debt/                     ← TD-001-xxx.md, TD-002-xxx.md, ...
└── feature-gaps/                  ← FG-001-xxx.md, FG-002-xxx.md, ...
```

| 組件          | 說明                                                                         |
| ------------- | ---------------------------------------------------------------------------- |
| **Dashboard** | 統計概覽 + Critical/High 表。只列高優先級項目，其餘用 `glob` 發現。          |
| **模板**      | 三種獨立模板（Defect / Tech Debt / Feature Gap），每種有專屬 metadata 欄位。 |
| **搜查手冊**  | 6 個內建缺陷類別，各附可執行的 grep 搜查指令。可自行擴充。                   |
| **Skill**     | Claude Code 的操作指南，讓 AI 知道如何操作整個系統。                         |

---

## 工作流

```
發現問題
    │
    ▼
判斷分類（決策樹）
    │
    ├─ 有意識的妥協？ → Tech Debt
    ├─ 行為與意圖不符？ → Defect
    └─ 功能設計不完整？ → Feature Gap
    │
    ▼
建立項目（複製模板 → 填 metadata → 更新 Dashboard）
    │
    ▼
修復
    │
    ▼
完成 Checklist（狀態→Done、完成紀錄、更新 Dashboard、更新搜查手冊）
```

---

## 版本控制

品質追蹤資料可能包含安全漏洞的詳細描述，需要考慮隔離。

### 模式 A：Companion Repo（建議）

品質系統作為獨立的 private repo，不在主專案的 git 歷史中。

- 主專案 `.gitignore` 加入 `quality/`（或品質 repo 放在主專案外）
- 品質 repo 獨立 commit + push
- **優點**：資料隔離、主專案 git log 不混雜品質追蹤紀錄
- **適用**：品質資料需要保密的場景

### 模式 B：Collocated

品質目錄直接在主專案 repo 內。

- `quality/` 正常 tracked in git
- **優點**：簡單、一個 repo 管理所有
- **適用**：開源專案、品質資料不需保密的場景

---

## 進階

### 自定義搜查類別

內建 6 個通用類別（D-SILENT、D-VALID、D-AUTH、D-TYPE、D-PERF、D-EDGE），可根據你的技術棧擴充。詳見搜查手冊底部的「[如何新增自定義類別](./quality/defect-taxonomy.md#如何新增自定義類別)」。

### Hook 整合

用 Claude Code 的 PostToolUse hook 自動化品質防線。範例見 [`examples/hooks/`](./examples/hooks/)。

### 方法論

本系統基於 ODC、DORA、Shift-Left Testing 等業界實踐設計。詳見 [`quality/quality-system-design-notes.md`](./quality/quality-system-design-notes.md)。

---

## 來自 Sparkle

本系統在 [Sparkle](https://github.com/user/sparkle) 個人知識管理專案中經過實戰驗證：3 輪系統性搜查、38 項追蹤、12 類缺陷分類。[`examples/sparkle/`](./examples/sparkle/) 包含 Sparkle 的完整搜查手冊（12 個類別 + 搜查結果），展示真實專案的使用方式。

## 授權

MIT
