#!/usr/bin/env bash
# scan_all.sh — 扫描所有用户创建的 skill
# 用法: scan_all.sh [skills_root]
# 排除: .system/, android-cli/

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILLS_ROOT="${1:-$HOME/.codex/skills}"
ALLOWLIST="$SCRIPT_DIR/../.allowlist"
SCAN_SCRIPT="$SCRIPT_DIR/scan_credentials.sh"

if [[ ! -d "$SKILLS_ROOT" ]]; then
  echo "❌ Skills 目录不存在: $SKILLS_ROOT" >&2
  exit 2
fi

echo "🛡️  安全扫描：所有用户 Skills"
echo "   目录: $SKILLS_ROOT"
echo "   排除: .system/, android-cli/"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

PASS_COUNT=0
FAIL_COUNT=0
FAIL_SKILLS=()

for skill_dir in "$SKILLS_ROOT"/*/; do
  skill_name=$(basename "$skill_dir")

  # 排除系统 skill 和非个人 skill
  [[ "$skill_name" == ".system" ]] && continue
  [[ "$skill_name" == "android-cli" ]] && continue

  # 跳过非目录
  [[ ! -d "$skill_dir" ]] && continue

  echo ""
  if "$SCAN_SCRIPT" "$skill_dir" "$ALLOWLIST"; then
    ((PASS_COUNT++))
  else
    ((FAIL_COUNT++))
    FAIL_SKILLS+=("$skill_name")
  fi
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 扫描结果汇总"
echo "   通过: $PASS_COUNT"
echo "   告警: $FAIL_COUNT"

if [[ $FAIL_COUNT -gt 0 ]]; then
  echo ""
  echo "⚠️  以下 skill 存在疑似敏感信息，需要确认："
  for s in "${FAIL_SKILLS[@]}"; do
    echo "   - $s"
  done
  echo ""
  echo "请逐一检查上述 skill，确认后将误报添加到: $ALLOWLIST"
  exit 1
else
  echo ""
  echo "✅ 所有 skill 安全扫描通过，可以发布"
  exit 0
fi
