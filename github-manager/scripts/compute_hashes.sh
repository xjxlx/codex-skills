#!/usr/bin/env bash
# compute_hashes.sh - 计算 skill 目录的文件 SHA256 hash
# 用法: compute_hashes.sh <skill_dir>
# 输出: JSON 格式的 hash 映射 {"file": "sha256", ...}

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_DIR="${1:?用法: compute_hashes.sh <skill_dir>}"

if [[ ! -d "$SKILL_DIR" ]]; then
  echo "目录不存在: $SKILL_DIR" >&2
  exit 2
fi
env -u PYTHONINSPECT python3 "$SCRIPT_DIR/_detect_changes.py" compute "$SKILL_DIR"
