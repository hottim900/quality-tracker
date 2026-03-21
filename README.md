# quality-tracker

為 AI 輔助開發設計的品質追蹤系統。搭配 [Claude Code](https://docs.anthropic.com/en/docs/claude-code) 使用。

追蹤四種品質項目：**Defect**（非預期 bug）、**Tech Debt**（有意識的妥協）、**Feature Gap**（功能缺口）、**Test Infrastructure**（測試覆蓋與工具建設），搭配系統性搜查手冊，讓 AI 能自主發現、記錄、修復品質問題。

品質項目以 **GitHub Issues / GitLab Issues** 追蹤，透過結構化 label 管理 metadata。核心價值是 **搜查手冊（Defect Taxonomy）** — 可重複執行的 grep 搜查模式。

---

## 為什麼需要這個？

AI 輔助開發常見的品質問題：

- **改完原始碼忘更新追蹤** — AI 修完 bug 但忘記更新追蹤項目狀態、檢查相依項目
- **同類 bug 反覆出現** — 修了一個 bare catch，但不知道同類問題還有 12 處
- **缺乏系統性搜查** — 靠肉眼或記憶找 bug，而非可重複執行的搜查指令

本系統用 **搜查手冊（Defect Taxonomy）** 解決這些問題 — 定義缺陷類別 + 可執行的 grep 指令，讓你（和 AI）能系統性地掃描整個 codebase。

---

## 快速開始

### 1. 從 template 建立你的品質 repo

點選 GitHub 的 **"Use this template"** 按鈕，建立你的 private repo。

### 2. 安裝 Issue/PR 模板和 Labels

根據你的平台執行對應的 setup script：

```bash
# GitHub
bash integrations/setup-github.sh

# GitLab
bash integrations/setup-gitlab.sh
```

> 前置需求：`gh` 或 `glab` CLI 已安裝且已認證，以及 `jq`。

### 3. 設定 Claude Code Skill

將 `.claude/skills/quality/` 複製到你的專案，然後編輯 `SKILL.md` 頂部：

```
QUALITY_DIR=/你的品質系統絕對路徑/quality
```

> **為什麼要絕對路徑？** Claude Code 可能在 git worktree 中執行，相對路徑會指向 worktree 而非品質系統。

### 4. 在 CLAUDE.md 加入入口

將 `CLAUDE.md.snippet` 的內容貼進你專案的 `CLAUDE.md`。

### 5. 跑首次搜查

在 Claude Code 中：

```
/quality
```

然後請 Claude 對你的 codebase 執行搜查手冊中的類別，從 D-SILENT（靜默失敗）開始。

---

## 系統組成

```
quality/
├── README.md                      ← 系統參考：分類定義、Label 參考、查詢指引
├── defect-taxonomy.md             ← 搜查手冊：6 個缺陷類別 + 擴充指引
└── quality-system-design-notes.md ← 方法論：設計原則、取捨、AI 效率優化

integrations/
├── github/                        ← GitHub Issue/PR 模板（YAML forms）
├── gitlab/                        ← GitLab Issue/MR 模板（markdown）
├── labels.json                    ← Label 定義（single source of truth）
├── setup-github.sh                ← GitHub 安裝腳本
└── setup-gitlab.sh                ← GitLab 安裝腳本
```

| 組件          | 說明                                                                         |
| ------------- | ---------------------------------------------------------------------------- |
| **系統參考**  | 分類決策樹、定義參考、Label 參考、完成步驟。                                |
| **Issue 模板**| 四種 Issue 模板（Defect / Tech Debt / Feature Gap / Test Infrastructure），各有專屬 metadata 欄位。 |
| **搜查手冊**  | 6 個內建缺陷類別，各附可執行的 grep 搜查指令。可自行擴充。                   |
| **Skill**     | Claude Code 的操作指南，讓 AI 知道如何操作整個系統。                         |

---

## 工作流

```
發現問題
    │
    ▼
判斷分類（決策樹，依序判斷）
    │
    ├─ 有意識的妥協？
    │   ├─ 測試面？ → Test Infrastructure
    │   └─ 其他？ → Tech Debt
    ├─ 行為與意圖不符？ → Defect
    └─ 功能不完整？
        ├─ 測試覆蓋缺口？ → Test Infrastructure
        └─ 其他？ → Feature Gap
    │
    ▼
建立 Issue（用 Issue 模板 → 加 label）
    │
    ▼
修復 → PR/MR（含缺陷掃查）
    │
    ▼
關閉 Issue（完成 comment → 檢查相依 → 更新 taxonomy）
```

---

## 版本控制

品質追蹤資料可能包含安全漏洞的詳細描述，需要考慮隔離。

### 模式 A：Companion Repo（建議）

品質系統（搜查手冊 + 設計文件）作為獨立的 private repo。品質 Issues 建立在 **project repo**（程式碼所在的 repo），因為 Issue 與程式碼緊密關聯。

- 搜查手冊中的搜查結果用 `owner/project-repo#N` 格式引用 project repo 的 Issue
- **優點**：搜查手冊和方法論獨立版控，可套用到多個專案
- **適用**：品質方法論需要跨專案共用、或搜查手冊需要保密的場景

### 模式 B：Collocated

品質目錄直接在主專案 repo 內。Issues 自然在同一個 repo。

- 搜查結果用 `#N` 格式引用 Issue（自動連結）
- **優點**：簡單、一個 repo 管理所有
- **適用**：開源專案、品質資料不需保密的場景

---

## 進階

### 自定義搜查類別

內建 6 個通用類別（D-SILENT、D-VALID、D-AUTH、D-TYPE、D-PERF、D-EDGE），可根據你的技術棧擴充。詳見搜查手冊底部的「[如何新增自定義類別](./quality/defect-taxonomy.md#如何新增自定義類別)」。

### Hook 整合

用 Claude Code 的 PostToolUse hook 自動化品質防線。範例見 [`examples/hooks/`](./examples/hooks/)：

- **migration-safety.sh** — Migration 程式碼安全檢查（阻擋危險操作）

### 統計腳本

`bash examples/scripts/quality-stats.sh --github` — 透過 `gh`/`glab` CLI 查詢 Issues，輸出各類別/優先級/狀態的統計報告。

> 前置需求：`gh` 或 `glab` CLI 已認證、網路連線。

### 方法論

本系統基於 ODC、DORA、Shift-Left Testing 等業界實踐設計。詳見 [`quality/quality-system-design-notes.md`](./quality/quality-system-design-notes.md)。

---

## 實戰範例

不同技術棧的搜查手冊範例，展示如何將通用方法論適配到具體專案：

- [`examples/sparkle/`](./examples/sparkle/) — **TypeScript / Bun / SQLite**（Sparkle PKM）：3 輪系統性搜查、38 項追蹤、12 類缺陷分類。
- [`examples/dotnet/`](./examples/dotnet/) — **.NET Clean Architecture + EF Core + React**：13 個缺陷類別，涵蓋 EF Core 配置、異常語意、授權 IDOR、前端 cache invalidation 等 .NET 專案常見問題。

> 上述範例使用舊的 `[DEF-NNN](path)` 檔案連結格式。Issue-native 模式下改用 `#N`（collocated）或 `owner/repo#N`（companion repo）格式。

## 授權

MIT
