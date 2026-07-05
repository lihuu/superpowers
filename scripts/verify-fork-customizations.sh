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

# --- 2. spec-sections：存在 + 可执行 + 接口完整（4 个 skill 的共同依赖） ---
log "spec-sections 核心依赖"
SS="$REPO_ROOT/skills/brainstorming/spec-sections"
if [ ! -f "$SS" ]; then
  bad "skills/brainstorming/spec-sections 丢失 — 4 个自定义 skill 都会断"
  FAIL=1
else
  if [ -x "$SS" ]; then ok "可执行"; else bad "不可执行 (chmod +x)"; FAIL=1; fi
  # 接口：必须支持 implementation/acceptance 子命令 + --legacy
  if grep -q '"implementation"' "$SS" && grep -q '"acceptance"' "$SS"; then
    ok "子命令 implementation/acceptance"
  else
    bad "缺少 implementation/acceptance 子命令"
    FAIL=1
  fi
  if grep -q -- '--legacy' "$SS"; then
    ok "--legacy 参数"
  else
    bad "缺少 --legacy 参数"
    FAIL=1
  fi
fi

# spec-sections.md 参考文档
if [ -f "$REPO_ROOT/skills/brainstorming/spec-sections.md" ]; then
  ok "spec-sections.md"
else
  bad "spec-sections.md 丢失"; FAIL=1
fi

# 功能冒烟（软检查：python3 在 PATH 时实际跑一下 --help）
if [ -x "$SS" ] && command -v python3 >/dev/null 2>&1; then
  if python3 "$SS" --help >/dev/null 2>&1; then
    ok "运行正常 (--help 通过)"
  else
    warn "--help 运行异常（可能 python3 环境问题，非致命）"
  fi
fi

# --- 3. brainstorming 集成仍在（引用 spec-sections） ---
log "共享 skill 的 spec-sections 集成"
BS="$REPO_ROOT/skills/brainstorming/SKILL.md"
if [ -f "$BS" ]; then
  n=$(grep -c 'spec-sections' "$BS" 2>/dev/null || echo 0)
  if [ "$n" -gt 0 ]; then ok "brainstorming 引用 spec-sections ($n 处)"; else bad "brainstorming 不再引用 spec-sections"; FAIL=1; fi
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
