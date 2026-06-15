#!/usr/bin/env bash
# detect_changes.sh - 对比 hash 检测 skill 变更
# 用法: detect_changes.sh <skill_dir> [hashes_file]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_DIR="${1:?用法: detect_changes.sh <skill_dir> [hashes_file]}"
HASHES_FILE="${2:-$SCRIPT_DIR/../.hashes.json}"

if [[ ! -d "$SKILL_DIR" ]]; then
  echo "目录不存在: $SKILL_DIR" >&2
  exit 2
fi

env -u PYTHONINSPECT python3 \
  "$SCRIPT_DIR/_detect_changes.py" detect "$SKILL_DIR" "$HASHES_FILE"
