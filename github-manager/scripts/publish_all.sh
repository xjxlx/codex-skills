#!/usr/bin/env bash
# publish_all.sh — 一键发布/更新所有 skill
# 用法: publish_all.sh [skills_root]
# 流程: 安全扫描 → 检测状态 → 发布/更新 → 生成文档

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILLS_ROOT="${1:-$HOME/.codex/skills}"
HASHES_FILE="$SCRIPT_DIR/../.hashes.json"

EXCLUDE=(".system" "android-cli" "github-manager")

echo "🚀 一键发布所有 Skills"
echo "   目录: $SKILLS_ROOT"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# 第一步：安全扫描
echo "━━━ 第一步：安全扫描 ━━━"
if ! "$SCRIPT_DIR/scan_all.sh" "$SKILLS_ROOT"; then
  echo ""
  echo "❌ 安全扫描未通过，请处理敏感信息后重试"
  exit 1
fi
echo ""

# 第二步：逐个处理
echo "━━━ 第二步：发布/更新 ━━━"
echo ""

PUBLISHED=()
UPDATED=()
SKIPPED=()
FAILED=()

for skill_dir in "$SKILLS_ROOT"/*/; do
  skill_name=$(basename "$skill_dir")

  # 排除
  skip=0
  for ex in "${EXCLUDE[@]}"; do
    [[ "$skill_name" == "$ex" ]] && skip=1
  done
  [[ $skip -eq 1 ]] && continue
  [[ ! -d "$skill_dir" ]] && continue
  [[ ! -f "$skill_dir/SKILL.md" ]] && continue

  echo "━━━ $skill_name ━━━"

  # 检查是否已发布
  if [[ -f "$skill_dir/.github-published" ]]; then
    # 已发布，检测变更
    if "$SCRIPT_DIR/detect_changes.sh" "$skill_dir" "$HASHES_FILE" >/dev/null 2>&1; then
      # 有变更，更新
      if "$SCRIPT_DIR/update_skill.sh" "$skill_dir"; then
        UPDATED+=("$skill_name")
      else
        FAILED+=("$skill_name")
      fi
    else
      SKIPPED+=("$skill_name")
    fi
  else
    # 未发布，首次发布
    if "$SCRIPT_DIR/publish_skill.sh" "$skill_dir"; then
      PUBLISHED+=("$skill_name")
    else
      FAILED+=("$skill_name")
    fi
  fi
  echo ""
done

# 第三步：生成文档
echo "━━━ 第三步：生成文档 ━━━"
"$SCRIPT_DIR/generate_catalog.sh" "$SKILLS_ROOT"
echo ""

# 汇总报告
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 发布汇总报告"
echo ""

if [[ ${#PUBLISHED[@]} -gt 0 ]]; then
  echo "📦 首次发布（${#PUBLISHED[@]} 个）："
  for s in "${PUBLISHED[@]}"; do echo "   - $s"; done
fi

if [[ ${#UPDATED[@]} -gt 0 ]]; then
  echo "🔄 更新发布（${#UPDATED[@]} 个）："
  for s in "${UPDATED[@]}"; do echo "   - $s"; done
fi

if [[ ${#SKIPPED[@]} -gt 0 ]]; then
  echo "⏭️  无变更跳过（${#SKIPPED[@]} 个）："
  for s in "${SKIPPED[@]}"; do echo "   - $s"; done
fi

if [[ ${#FAILED[@]} -gt 0 ]]; then
  echo "❌ 发布失败（${#FAILED[@]} 个）："
  for s in "${FAILED[@]}"; do echo "   - $s"; done
fi

TOTAL=$((${#PUBLISHED[@]} + ${#UPDATED[@]} + ${#SKIPPED[@]} + ${#FAILED[@]}))
echo ""
echo "总计: $TOTAL 个 skill 处理完成"

[[ ${#FAILED[@]} -eq 0 ]]
