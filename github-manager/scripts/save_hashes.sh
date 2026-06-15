#!/usr/bin/env bash
# save_hashes.sh — 保存 skill 的 hash 到 .hashes.json
# 用法: save_hashes.sh <skill_dir> [hashes_file]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_DIR="${1:?用法: save_hashes.sh <skill_dir> [hashes_file]}"
HASHES_FILE="${2:-$SCRIPT_DIR/../.hashes.json}"

env -u PYTHONINSPECT python3 \
  "$SCRIPT_DIR/_detect_changes.py" save "$SKILL_DIR" "$HASHES_FILE"
