# GitHub 发布工作流参考

## 仓库命名规范

- 单独仓库：`codex-skill-{skill-name}`（如 `codex-skill-code-analyzer`）
- 统一仓库：`codex-skills`（所有 skill 在子目录中）

## 首次发布流程

```
1. 安全扫描通过
2. git init（如未初始化）
3. 创建 .gitignore
4. 生成/更新 README.md
5. git add -A && git commit
6. gh repo create --public --source=. --push
7. 写入 .github-published 标记
8. push 成功后计算并保存 hash
```

## 更新发布流程

```
1. 安全扫描通过
2. hash 对比检测变更
3. 有变更：列出变更文件
4. git add -A && git commit（带变更摘要）
5. git push
6. 更新 .github-published 标记
7. push 成功后保存新 hash
```

## 提交信息规范

- 首次发布：`feat: initial release of {skill_name}`
- 更新：`update: {skill_name} (+N new, ~M modified, -D deleted)`
- 修复：`fix: {skill_name} - {description}`

## README.md 结构

```markdown
# {Skill Display Name}

{一句话描述}

## 功能

- 功能点 1
- 功能点 2

## 使用方法

（从 SKILL.md 提取关键信息）

## 依赖

- 其他 skill 依赖
- 系统依赖（如 gh CLI）

## 目录结构

（列出 scripts/, references/, assets/ 等）
```

## 常见问题

**Q: push 被拒绝？**
A: 确认远程仓库地址正确，尝试 `git pull --rebase origin main` 后重新 push。

**Q: 仓库已存在？**
A: 使用 `--repo-name` 参数指定不同的名称，或先删除已有仓库。

**Q: hash 对比总是报变更？**
A: 确认计算与检测使用同一脚本，并排除 `.DS_Store` 等系统文件。
