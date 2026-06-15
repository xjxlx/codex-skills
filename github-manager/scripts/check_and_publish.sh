#!/usr/bin/env bash
# check_and_publish.sh - 检测全部个人 skill，发现变化时自动统一发布
# 用法: check_and_publish.sh [--skills-root dir] [--repo-dir dir] [--repo-name name]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILLS_ROOT="$HOME/.codex/skills"
REPO_DIR="$SCRIPT_DIR/../codex-skills"
REPO_NAME="codex-skills"
HASHES_FILE="$SCRIPT_DIR/../.hashes.json"
EXCLUDE=(".system" "android-cli")

while [[ $# -gt 0 ]]; do
  case "$1" in
    --skills-root) SKILLS_ROOT="${2:?--skills-root 缺少值}"; shift 2 ;;
    --repo-dir) REPO_DIR="${2:?--repo-dir 缺少值}"; shift 2 ;;
    --repo-name) REPO_NAME="${2:?--repo-name 缺少值}"; shift 2 ;;
    *) echo "未知参数: $1" >&2; exit 2 ;;
  esac
done

[[ -d "$SKILLS_ROOT" ]] || { echo "Skills 目录不存在: $SKILLS_ROOT" >&2; exit 2; }

is_excluded() {
  local candidate="$1"
  local excluded
  for excluded in "${EXCLUDE[@]}"; do
    [[ "$candidate" == "$excluded" ]] && return 0
  done
  return 1
}

CHANGED=()
for skill_dir in "$SKILLS_ROOT"/*/; do
  skill_name=$(basename "$skill_dir")
  is_excluded "$skill_name" && continue
  [[ -f "$skill_dir/SKILL.md" ]] || continue

  set +e
  output=$("$SCRIPT_DIR/detect_changes.sh" "$skill_dir" "$HASHES_FILE" 2>&1)
  status=$?
  set -e
  case "$status" in
    0)
      CHANGED+=("$skill_name")
      echo "$output"
      ;;
    1) ;;
    *)
      echo "$output" >&2
      echo "检测失败: $skill_name" >&2
      exit "$status"
      ;;
  esac
done

if [[ ${#CHANGED[@]} -eq 0 ]]; then
  echo "全部个人 skill 均无变化，无需发布。"
  exit 0
fi

echo "检测到 ${#CHANGED[@]} 个 skill 发生变化: ${CHANGED[*]}"
"$SCRIPT_DIR/publish_unified.sh" \
  --skills-root "$SKILLS_ROOT" \
  --repo-dir "$REPO_DIR" \
  --repo-name "$REPO_NAME"
