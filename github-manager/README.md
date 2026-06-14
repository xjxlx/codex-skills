# github-manager

管理个人 Codex Skills 的 GitHub 发布与更新的元技能。

本目录不包含实际代码，github-manager 的完整实现位于 `~/.codex/skills/github-manager/`。

## 功能

- 安全扫描：发布前检测账号/密钥泄露
- 首次发布：创建公开 GitHub 仓库
- 变更检测：SHA256 hash 对比，仅更新有改动的 skill
- 文档生成：自动维护 SKILLS_CATALOG.md
