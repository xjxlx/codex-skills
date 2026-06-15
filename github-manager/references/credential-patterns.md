# 敏感信息检测模式参考

## 高危模式（必须拦截）

| 模式 | 说明 | 示例 |
|---|---|---|
| `ghp_*` | GitHub Personal Access Token | `ghp_ABCDEF...` |
| `github_pat_*` | GitHub Fine-grained PAT | `github_pat_11ABC...` |
| `AKIA*` | AWS Access Key ID | `AKIA...REDACTED` |
| `-----BEGIN.*PRIVATE KEY` | 私钥文件 | RSA/EC/Ed25519 私钥 |
| `sk-*` | OpenAI API Key | `sk-proj-...` |
| `xox[bps]-*` | Slack Token | `xoxb-...` |

## 中危模式（需要确认）

| 模式 | 说明 |
|---|---|
| `password=` / `secret=` | 硬编码密码或密钥赋值 |
| `token=` / `access_token=` | Token 赋值 |
| `jdbc:` / `mongodb+srv://` | 数据库连接串 |
| 长 Base64 字符串（>100 字符） | 可能是编码后的密钥 |
| 硬编码 IP:端口 | 可能是内网地址 |

## 低危模式（记录但不拦截）

| 模式 | 说明 |
|---|---|
| `api_key` 注释或文档引用 | 可能只是说明文字 |
| 示例代码中的占位符 | `your-api-key-here` |
| 环境变量引用 | `$API_KEY`、`${SECRET}` |

## 误报处理

常见误报场景：
- 文档中描述 API Key 的格式
- 代码中使用环境变量引用（非硬编码）
- 测试用的 mock 数据
- SKILL.md 中的示例说明

将确认的误报添加到 `.allowlist` 文件，格式为匹配的完整行内容。
