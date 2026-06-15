# {SKILL_DISPLAY_NAME}

{ONE_LINE_DESCRIPTION}

## 功能

- {FEATURE_1}
- {FEATURE_2}
- {FEATURE_3}

## 使用方法

在 Codex 中通过 `$skill-name` 调用本 skill。

### 触发场景

- {TRIGGER_1}
- {TRIGGER_2}

## 依赖

| 依赖 | 说明 |
|---|---|
| {DEP_1} | {DEP_DESC_1} |
| skill-common | 基础规范（中文输出、持续进化） |

## 系统要求

- Codex CLI / Codex Desktop
- {EXTRA_REQUIREMENT}

## 目录结构

```
{skill-name}/
├── SKILL.md           # 主文档
├── README.md          # 本文件
├── agents/            # UI 元数据
│   └── openai.yaml
├── scripts/           # 脚本
│   └── *.sh
├── references/        # 参考文档
│   └── *.md
└── assets/            # 资源文件
    └── *
```

## 许可证

个人使用，仅供学习和参考。
