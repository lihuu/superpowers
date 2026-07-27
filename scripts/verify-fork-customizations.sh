#!/usr/bin/env bash
#
# verify-fork-customizations.sh
#
# 合并 upstream 后一键核对：本 fork 的定制改动是否都还在、是否仍可用。
# 用法：bash scripts/verify-fork-customizations.sh
# 详见 docs/fork-maintenance.md。
#
# 退出码：0 = 全部通过；1 = 有关键件丢失或损坏。

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# 颜色输出（与 install-to-all-agents.sh / register-superpowers-hook.sh 风格一致）
log()  { printf '\033[1;34m[verify]\033[0m %s\n' "$*"; }
ok()   { printf '  \033[32m✓\033[0m %s\n' "$*"; }
bad()  { printf '  \033[31m✗\033[0m %s\n' "$*"; }
warn() { printf '  \033[33m⚠\033[0m %s\n' "$*"; }

FAIL=0

# --- 1. 4 个自定义 skill：SKILL.md 存在 + frontmatter 健全 ---
log "自定义 skill"
for s in fast-subagent-development handoff spec-driven-implementation takeover; do
  f="$REPO_ROOT/skills/$s/SKILL.md"
  if [ ! -f "$f" ]; then
    bad "$s/SKILL.md 丢失"
    FAIL=1
    continue
  fi
  # frontmatter 必须含 name 和 description（Claude Code 自动发现的条件）
  if grep -q '^name:' "$f" && grep -q '^description:' "$f"; then
    ok "$s"
  else
    bad "$s frontmatter 缺 name/description"
    FAIL=1
  fi
done

# --- 2. spec-sections 已废弃（a35f092 改用 companion file 分离） ---
# 历史：4 个自定义 skill 曾共用 skills/brainstorming/spec-sections 脚本做
# Implementation Spec / Acceptance region 提取。a35f092 删除该脚本，改用
# 物理文件分离（design spec 一个文件、companion acceptance file 另一个文件），
# 信息隔离靠独立文件而非脚本切区。此处仅留注释说明，不再断言脚本存在。
log "spec-sections（已废弃）"
if [ -f "$REPO_ROOT/skills/brainstorming/spec-sections" ]; then
  warn "skills/brainstorming/spec-sections 仍存在 — a35f092 应已删除，请确认是否遗留"
else
  ok "spec-sections 脚本已删除（companion file 分离方式生效）"
fi

# --- 3. brainstorming 不再引用 spec-sections（a35f092 后） ---
log "共享 skill 不再依赖 spec-sections"
BS="$REPO_ROOT/skills/brainstorming/SKILL.md"
if [ -f "$BS" ]; then
  n=$(grep -c 'spec-sections' "$BS" 2>/dev/null)
  n=${n:-0}
  if [ "$n" -eq 0 ]; then
    ok "brainstorming 不引用 spec-sections（与 companion file 方式一致）"
  else
    warn "brainstorming 仍引用 spec-sections ($n 处) — a35f092 后应为 0，请确认是否遗留"
  fi
else
  bad "brainstorming/SKILL.md 丢失"; FAIL=1
fi

# --- 4. 其他共享 skill 的关键集成段 ---
log "其他共享 skill 集成段"
WP="$REPO_ROOT/skills/writing-plans/SKILL.md"
if [ -f "$WP" ] && grep -q 'Stage Input: Implementation Only' "$WP"; then ok "writing-plans: Stage Input 段"; else bad "writing-plans: Stage Input 段丢失"; FAIL=1; fi

FB="$REPO_ROOT/skills/finishing-a-development-branch/SKILL.md"
if [ -f "$FB" ] && grep -qi 'Archive Documentation' "$FB"; then ok "finishing-a-development-branch: Step 7 归档段"; else bad "finishing-a-development-branch: 归档段丢失"; FAIL=1; fi

# --- 5. 自定义脚本 ---
log "自定义脚本"
for f in skills/finishing-a-development-branch/archive-docs.sh skills/handoff/scripts/gather-state.sh; do
  if [ -f "$REPO_ROOT/$f" ]; then ok "$f"; else bad "$f 丢失"; FAIL=1; fi
done

# --- 6. 无残留冲突标记 ---
log "冲突标记"
markers=$(grep -rlE '^<<<<<<< |^>>>>>>> ' "$REPO_ROOT/skills/" 2>/dev/null || true)
if [ -z "$markers" ]; then ok "skills/ 无残留冲突标记"; else bad "发现冲突标记: $markers"; FAIL=1; fi

# --- 总结 ---
echo ""
if [ "$FAIL" -eq 0 ]; then
  printf '\033[1;34m[verify]\033[0m \033[32m全部通过\033[0m — fork 定制改动完整。\n'
  exit 0
else
  printf '\033[1;34m[verify]\033[0m \033[31m有缺失\033[0m — 对照 docs/fork-maintenance.md 第 2 节排查，或重新合并冲突解决。\n'
  exit 1
fi
