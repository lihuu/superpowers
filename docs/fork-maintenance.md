# Superpowers Fork — 维护与合并 Runbook

> 本文件是 **fork 专属**（upstream 没有），记录 obra/superpowers 之上本仓库的定制改动、依赖关系、合并 upstream 的标准流程，以及改动如何真正生效。每次合并 upstream 前后对照本文复核。

---

## 1. 这个 fork 是什么

- Fork 自 `obra/superpowers`，基线 v5.1.0（`f2cbfbe`），已合并到 v6.1.1（`d884ae0`）
- 在 upstream 之上维护自己的定制改动；**决定：定制内容留在本 fork，不迁出**
- upstream 远程：`upstream` → `https://github.com/obra/superpowers.git`
- 本仓库远程：`origin` → `https://github.com/lihuu/superpowers.git`，工作分支 `dev`

---

## 2. 定制清单（每次合并后逐一核对存活）

### 2.1 独立新增 skill（4 个 — 低冲突风险，整目录保留即可）

| skill | 作用 | 文件 |
|---|---|---|
| `fast-subagent-development` | 快速实现路径：implementer + 单次最终 review，无逐任务 review | SKILL.md + implementer/final-reviewer/repair-prompt.md |
| `handoff` | 把当前进度/上下文写成 Markdown 移交文件，供下个会话接管 | SKILL.md + scripts/gather-state.sh |
| `spec-driven-implementation` | "Red Zone" 协议：被催促时用轻量 tracker 保可见性 + TDD 纪律 | SKILL.md |
| `takeover` | 从 handoff 文件接管工作，先核对工作区状态再恢复 | SKILL.md |

frontmatter 都健全（`name` + `description`），Claude Code 从 `skills/` 自动发现，无需注册。

### 2.2 新增脚本

| 脚本 | 作用 |
|---|---|
| ~~`skills/brainstorming/spec-sections`~~ | **已删除（a35f092）**：原 Python 脚本做 spec 双区提取，被 companion file 物理分离替代（design spec 与 acceptance 各一个文件） |
| ~~`skills/brainstorming/spec-sections.md`~~ | **已删除（a35f092）**：上述脚本的命令参考文档 |
| `skills/finishing-a-development-branch/archive-docs.sh` | 合并/PR 后把 spec/plan 文档移到 `archive/` 子目录 |
| `skills/handoff/scripts/gather-state.sh` | 收集 git 状态供 handoff 使用 |
| `skills/fast-subagent-development/scripts/` | sdd-workspace / packet-brief / review-package（09e30a3 起自带，不跨 skill 引用） |

### 2.3 对共享 skill 的修改（**高冲突风险，重点核对**）

| skill | 你的改动 | 合并后状态 |
|---|---|---|
| `brainstorming` | ~~spec-sections 双区 spec 体系~~（a35f092 已移除，改用 companion file 分离）；保留 Acceptance Criteria 格式、Verification Protocol、Self-Review 4→9 条 | ✅ companion file 方式保留 |
| `writing-plans` | ~~"Stage Input: Implementation Only" 段 + Self-Review Context isolation + plan 模板 2 字段~~ **7b53d3c 已整体还原成 upstream 原版（zero diff）**，fork spec-sections 集成段被有意移除（acceptance 机制移到独立 acceptance-review skill） | ✅ upstream 原版，无 fork 定制 |
| `finishing-a-development-branch` | 新增 Step 7 归档步骤（`archive-docs.sh`） | ✅ 完整保留 |
| `subagent-driven-development` | "Stage Context Setup"（~~spec-sections 集成~~，现 file-handoff）+ 原 "Independent Acceptance and Repair Loop" | ⚠️ Stage Context Setup 保留；**acceptance/repair loop 被 upstream v6 的 task-reviewer 重构覆盖删除** |
| `executing-plans` / `requesting-code-review` / `receiving-code-review` | ~~spec-sections 集成相关小改~~（a35f092 后相关引用已移除） | ✅ 保留 |

### 2.4 新增测试（11 个）

`tests/claude-code/test-{acceptance-criteria-requirement,document-auto-archive,fast-subagent-development,staged-spec-workflow,subagent-driven-development}.sh`、`tests/handoff/*`、`tests/takeover/*`、`tests/skill-triggering/prompts/takeover.txt`

> 注：`tests/claude-code/test-spec-sections.sh` 随 a35f092 删除 spec-sections 脚本一并移除；`test-staged-spec-workflow.sh` 已接手断言"各 skill 不引用 spec-sections"。

### 2.5 .gitignore

- `.superpowers/` ✅ 保留
- `.antigravitycli/` ⚠️ 合并时丢失过，工作区已手动加回（未提交），每次合并后确认仍在
- `tst` ❌ 合并时丢失，未恢复（如仍需要请补回）

---

## 3. 依赖图（核对一致性）

```
companion file 分离（a35f092 起，替代原 spec-sections 提取）
   design spec 文件 (YYYY-MM-DD-<topic>-design.md)
   companion acceptance 文件 (YYYY-MM-DD-<topic>-acceptance.md)
   ↑
   ├── writing-plans              (7b53d3c 后：upstream 原版，无 fork 集成)
   ├── spec-driven-implementation (Independent Acceptance 读 companion acceptance 文件)
   ├── fast-subagent-development  (final reviewer 读两个文件；implementer 不收 acceptance)
   └── subagent-driven-development(Stage Context Setup file-handoff)

handoff  ↔  takeover              (handoff 产出文件，takeover 消费；gather-state.sh 共用)
```

**核对要点**：a35f092 已删除 `skills/brainstorming/spec-sections` 脚本。合并后确认该脚本**不存在**（存在则为遗留），且上述 4 个 skill 引用的是 design spec / companion acceptance 文件路径而非 spec-sections 提取产物。`tests/claude-code/test-staged-spec-workflow.sh` 已断言各 skill 不引用 spec-sections。

---

## 4. 合并 upstream 的标准流程

```bash
# 1. 拉取
git fetch upstream

# 2. 合并（在 dev 分支）
git merge upstream/main

# 3. 解决冲突（原则见下）
# 4. 用本文件第 2 节清单逐一核对存活
# 5. 跑测试确认 companion file 分离链路正常
bash tests/claude-code/test-staged-spec-workflow.sh
```

### 冲突解决原则

- **你的独立 skill 目录**（2.1）：整目录保留，upstream 不会动
- **共享 skill 的冲突**（2.3）：优先保留你的 companion file 集成段（a35f092 后）；upstream 的新功能择优合并到不冲突的位置
- **被 upstream 删除的文件**：接受删除（upstream 的设计演进，不是误删）。历史案例：`code-quality-reviewer-prompt.md`、`spec-reviewer-prompt.md`（被 `task-reviewer-prompt.md` 替代）、`test-document-review-system.sh`、`run-all.sh`、`run-test.sh`、`skills/brainstorming/spec-sections`（a35f092 改 companion file 分离）

---

## 5. 已知冲突点（v5.1→v6.1 实战经验）

| 冲突点 | upstream 做了什么 | 你的应对 |
|---|---|---|
| `subagent-driven-development` | 两阶段 review（spec-reviewer + code-quality-reviewer）合并成单 `task-reviewer-prompt.md` | 接受 task-reviewer；你的 acceptance/repair loop 已丢，如需要可基于 task-reviewer 重新设计 |
| `brainstorming` / `writing-plans` | upstream 也在演进（加 Global Constraints、Task Right-Sizing 等） | 你的 companion file 集成段（a35f092 后）手动重新合并到 upstream 新版上 |
| 旧 reviewer prompt + 旧 bash 测试 | upstream 用 evals drill 替代 | 接受删除 |

---

## 6. ⚠️ 改动如何真正生效（最容易踩的坑）

**本 fork 没有作为 Claude Code plugin 启用**（`~/.claude/settings.json` 的 `enabledPlugins` 只有 3 个官方 plugin）。直接改 fork 里的 skill **不会**让 Claude Code 加载到新版本。

实际加载路径：

```
本 fork skills/                      ← 你改、你合并 upstream 的地方
   ↓ 手动镜像复制（非 symlink / 非 submodule，内容逐字相同）
lihuu-skills 仓库 skills/superpowers/
   ↓ git push 到 GitHub
   ↓ skills update -g -y  (skills CLI 拉取并递归发现、拍平安装)
~/.agents/skills/<name>/             ← 扁平副本
   ↓ symlink
~/.claude/skills/<name>/SKILL.md     ← Claude Code 真正发现的地方（只扫一层）
```

外加：`lihuu-skills/hooks/superpowers-session-start.sh`（注册在 `~/.claude/settings.json`）注入 `using-superpowers` bootstrap，让模型知道要用 Skill 工具。

### 改完 fork 后必须执行的同步

```bash
# 1. 把 fork 的 skills 镜像到 lihuu-skills
rsync -a --delete skills/ ~/MyFiles/Workspace/research/lihuu-skills/skills/superpowers/
#    （注意：lihuu-skills/skills/superpowers/ 下是扁平 <skill>/ 结构，和 fork 一致）

# 2. 推送 lihuu-skills
cd ~/MyFiles/Workspace/research/lihuu-skills && git add -A && git commit -m "sync superpowers" && git push

# 3. 刷新本机安装
skills update -g -y
```

**不执行同步 → Claude Code 加载的还是旧版本，你以为生效了其实没有。**

### 命名唯一性约束

所有 skill 最终拍平进同一个 `~/.claude/skills/` 命名空间。别在 lihuu-skills 别处放同名 skill，也别同时启用 superpowers plugin（会和 `~/.claude/skills/` 里的同名条目冲突）。

---

## 7. 快速核对脚本

合并后跑一遍，确认关键件都在：

```bash
cd <fork-root>
echo "=== 4 个自定义 skill ==="
for s in fast-subagent-development handoff spec-driven-implementation takeover; do
  test -f skills/$s/SKILL.md && echo "✅ $s" || echo "❌ $s 丢失"
done
echo "=== spec-sections 已删除（a35f092） ==="
test ! -e skills/brainstorming/spec-sections && echo "✅ 已删除" || echo "❌ 仍存在（遗留）"
echo "=== brainstorming 不再引用 spec-sections ==="
n=$(grep -c "spec-sections" skills/brainstorming/SKILL.md 2>/dev/null || echo 0)
[ "$n" -eq 0 ] && echo "✅ 无引用" || echo "⚠️ 仍有 $n 处引用"
echo "=== 归档脚本仍在 ==="
test -f skills/finishing-a-development-branch/archive-docs.sh && echo "✅" || echo "❌"
echo "=== fast-subagent-development 自带 scripts ==="
test -x skills/fast-subagent-development/scripts/sdd-workspace && echo "✅ sdd-workspace" || echo "❌"
echo "=== 无残留冲突标记 ==="
grep -rl '^<<<<<<< \|^>>>>>>> ' skills/ 2>/dev/null || echo "✅ 无冲突标记"
```
