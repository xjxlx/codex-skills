#!/usr/bin/env python3
import hashlib
import json
import os
import sys
import tempfile
from pathlib import Path


EXCLUDED_PARTS = {
    ".git",
    ".github-published",
    ".hashes.json",
    ".allowlist",
    ".DS_Store",
    "SKILLS_CATALOG.md",
    ".idea",
    "__pycache__",
    "codex-skills",
    "node_modules",
}


def compute_hashes(skill_dir: Path) -> dict[str, str]:
    result = {}
    for path in sorted(skill_dir.rglob("*")):
        if not path.is_file():
            continue
        relative = path.relative_to(skill_dir)
        if any(part in EXCLUDED_PARTS for part in relative.parts):
            continue
        result[str(relative)] = hashlib.sha256(path.read_bytes()).hexdigest()
    return result


def load_state(hashes_file: Path) -> dict:
    if not hashes_file.exists():
        return {}
    with hashes_file.open(encoding="utf-8") as handle:
        data = json.load(handle)
    if not isinstance(data, dict):
        raise ValueError(f"Hash 状态必须是 JSON 对象: {hashes_file}")
    return data


def save_state(hashes_file: Path, data: dict) -> None:
    hashes_file.parent.mkdir(parents=True, exist_ok=True)
    fd, temporary = tempfile.mkstemp(
        dir=hashes_file.parent,
        prefix=f".{hashes_file.name}.",
        text=True,
    )
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as handle:
            json.dump(data, handle, indent=2, ensure_ascii=False, sort_keys=True)
            handle.write("\n")
        os.replace(temporary, hashes_file)
    except Exception:
        Path(temporary).unlink(missing_ok=True)
        raise


def changes_for(current: dict[str, str], saved: dict[str, str]) -> list[str]:
    changes = []
    for name in sorted(current.keys() | saved.keys()):
        if name not in saved:
            changes.append(f"A  {name}")
        elif name not in current:
            changes.append(f"D  {name}")
        elif current[name] != saved[name]:
            changes.append(f"M  {name}")
    return changes


def main() -> int:
    if len(sys.argv) < 3 or sys.argv[1] not in {"compute", "detect", "save"}:
        print(
            "用法: _detect_changes.py <compute|detect|save> <skill_dir> [hashes_file]",
            file=sys.stderr,
        )
        return 2

    command = sys.argv[1]
    skill_dir = Path(sys.argv[2]).expanduser().resolve()
    if not skill_dir.is_dir():
        print(f"目录不存在: {skill_dir}", file=sys.stderr)
        return 2

    current = compute_hashes(skill_dir)
    if command == "compute":
        print(json.dumps(current, indent=2, ensure_ascii=False, sort_keys=True))
        return 0

    hashes_file = (
        Path(sys.argv[3]).expanduser().resolve()
        if len(sys.argv) > 3
        else Path(__file__).resolve().parent.parent / ".hashes.json"
    )
    state = load_state(hashes_file)
    skill_name = skill_dir.name

    if command == "save":
        state[skill_name] = current
        save_state(hashes_file, state)
        print(f"已保存 {skill_name} 的 hash 到 {hashes_file}")
        return 0

    saved = state.get(skill_name, {})
    if not isinstance(saved, dict):
        raise ValueError(f"{skill_name} 的 hash 状态格式错误")
    changes = changes_for(current, saved)
    if not changes:
        print(f"无变更，跳过: {skill_name}")
        return 1

    print(f"检测到变更: {skill_name}")
    print("\n".join(changes))
    return 0


if __name__ == "__main__":
    sys.exit(main())
