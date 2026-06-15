#!/usr/bin/env bash
# scan_credentials.sh - 扫描单个 skill 目录中的敏感信息
# 用法: scan_credentials.sh <skill_dir> [allowlist_file]
# 退出码: 0=未发现, 1=发现疑似敏感信息

set -euo pipefail

TARGET_DIR="${1:?用法: scan_credentials.sh <skill_dir> [allowlist_file]}"
ALLOWLIST="${2:-}"

if [[ ! -d "$TARGET_DIR" ]]; then
  echo "目录不存在: $TARGET_DIR" >&2
  exit 2
fi

TARGET_NAME=$(basename "$TARGET_DIR")
FOUND=0

EXCLUDES=(
  --exclude-dir='.git'
  --exclude-dir='node_modules'
  --exclude-dir='__pycache__'
  --exclude-dir='.idea'
  --exclude-dir='.check-and-publish.lock'
  --exclude='*.class'
  --exclude='*.jar'
  --exclude='*.png'
  --exclude='*.jpg'
  --exclude='*.gif'
  --exclude='*.ico'
  --exclude='*.woff'
  --exclude='*.woff2'
  --exclude='*.ttf'
  --exclude='*.eot'
  --exclude='*.map'
  --exclude='*.min.js'
  --exclude='*.min.css'
  --exclude='.hashes.json'
  --exclude='.github-published'
  --exclude='.allowlist'
  --exclude='.DS_Store'
  --exclude='scan_credentials.sh'
)

echo "扫描 skill: $TARGET_NAME"
echo "路径: $TARGET_DIR"
echo ""

# 高危模式
HIT_FILE=$(mktemp)
trap "rm -f $HIT_FILE" EXIT

# API Key / Token / Secret 赋值，要求赋值后存在实际值，避免命中文档中的空模式示例。
grep -rniE '(api[_-]?key|apikey|api[_-]?secret|access[_-]?token|refresh[_-]?token|auth[_-]?token|password|passwd|secret|secret[_-]?key)[[:space:]]*[:=][[:space:]]*["'\"']?[A-Za-z0-9_./+=-]{8,}' \
  "${EXCLUDES[@]}" "$TARGET_DIR" >> "$HIT_FILE" 2>/dev/null || true

# GitHub tokens
grep -rn 'ghp_[A-Za-z0-9]\{36\}' "${EXCLUDES[@]}" "$TARGET_DIR" >> "$HIT_FILE" 2>/dev/null || true
grep -rnE 'gh[opsu]_[A-Za-z0-9]{20,}' "${EXCLUDES[@]}" "$TARGET_DIR" >> "$HIT_FILE" 2>/dev/null || true
grep -rnE 'github_pat_[A-Za-z0-9_]{20,}' "${EXCLUDES[@]}" "$TARGET_DIR" >> "$HIT_FILE" 2>/dev/null || true

# OpenAI and Slack tokens
grep -rnE 'sk-(proj-|svcacct-)?[A-Za-z0-9_-]{20,}' "${EXCLUDES[@]}" "$TARGET_DIR" >> "$HIT_FILE" 2>/dev/null || true
grep -rnE 'xox[baprs]-[A-Za-z0-9-]{10,}' "${EXCLUDES[@]}" "$TARGET_DIR" >> "$HIT_FILE" 2>/dev/null || true

# AWS keys
grep -rn 'AKIA[0-9A-Z]\{16\}' "${EXCLUDES[@]}" "$TARGET_DIR" >> "$HIT_FILE" 2>/dev/null || true
grep -rniE 'aws[_-]?secret[_-]?access[_-]?key[[:space:]]*[:=][[:space:]]*["'\"']?[A-Za-z0-9/+=]{20,}' \
  "${EXCLUDES[@]}" "$TARGET_DIR" >> "$HIT_FILE" 2>/dev/null || true

# Private keys
grep -rnE -- '-----BEGIN ([A-Z0-9 ]+ )?PRIVATE KEY-----' \
  "${EXCLUDES[@]}" "$TARGET_DIR" >> "$HIT_FILE" 2>/dev/null || true

# Connection strings
grep -rniE '(jdbc:[A-Za-z0-9]|mongodb(\+srv)?://[^[:space:]`]+|redis://[^[:space:]`]+|amqp://[^[:space:]`]+)' \
  "${EXCLUDES[@]}" "$TARGET_DIR" >> "$HIT_FILE" 2>/dev/null || true

# 长 Base64 字符串 (100+ chars)
grep -rnE '(^|[^A-Za-z0-9+/])[A-Za-z0-9+/]{100,}={0,2}([^A-Za-z0-9+/]|$)' \
  "${EXCLUDES[@]}" "$TARGET_DIR" >> "$HIT_FILE" 2>/dev/null || true

# 去重并过滤 allowlist
if [[ -s "$HIT_FILE" ]]; then
  SORTED=$(sort -u "$HIT_FILE")
  
  if [[ -n "$ALLOWLIST" && -f "$ALLOWLIST" ]]; then
    # 过滤掉 allowlist 中的行
    FILTERED=$(echo "$SORTED" | grep -vFf "$ALLOWLIST" 2>/dev/null || true)
  else
    FILTERED="$SORTED"
  fi
  
  if [[ -n "$FILTERED" ]]; then
    COUNT=$(echo "$FILTERED" | wc -l | tr -d ' ')
    echo "$FILTERED" | awk -F: '{print $1 ":" $2 ": [内容已隐藏]"}' | sort -u
    echo ""
    echo "发现 $COUNT 处疑似敏感信息"
    FOUND=1
  fi
fi

if [[ $FOUND -eq 0 ]]; then
  echo "通过: $TARGET_NAME 未发现敏感信息"
  exit 0
else
  exit 1
fi
