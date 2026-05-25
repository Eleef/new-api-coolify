# New API Coolify Deployment

这个目录用于把 [QuantumNous/new-api](https://github.com/QuantumNous/new-api) 作为独立服务部署到 Coolify。当前模板采用官方 Docker 镜像 `calciumion/new-api`，不在 Coolify 上从源码构建，降低构建时间和构建依赖风险。

## 文件

| 文件 | 用途 |
| --- | --- |
| `docker-compose.yaml` | Coolify Docker Compose 部署模板，包含 New API、PostgreSQL、Redis 和持久化卷 |
| `.github/workflows/deploy-coolify.yml` | GitHub `main` 分支 push 后调用 Coolify 部署 API，自动触发重新部署 |
| `coolify.env.example` | 可复制到 Coolify 环境变量面板的非密钥配置和密钥占位符 |
| `scripts/generate-secrets.ps1` | 本地生成随机密钥，仅输出到终端，不写入文件 |
| `scripts/smoke-check.ps1` | 部署后检查首页和 `/api/status` |

## 推荐部署方式

1. 新建一个 GitHub 仓库，例如 `new-api-coolify`，把本目录内容作为仓库根目录提交。当前部署仓库是 `https://github.com/Eleef/new-api-coolify`。
2. 在 Coolify 中创建新资源，选择 GitHub 仓库，Build Pack 选择 **Docker Compose**。
3. Compose 文件路径使用 `docker-compose.yaml`。
4. 域名配置使用 `SERVICE_FQDN_NEWAPI_3000=https://llmapi.1983070.xyz`，或在 Coolify UI 中给 `new-api` 服务绑定域名并指向容器端口 `3000`。
5. 环境变量可从 `coolify.env.example` 复制后修改。生产密钥应放在 Coolify 环境变量或密钥面板，不要提交到 GitHub。
6. 部署完成后访问 `https://llmapi.1983070.xyz/api/status`，确认返回 `success=true`。

如果你不单独建 GitHub 仓库，也可以把本目录作为一个明确的部署根目录使用；Coolify 中要确保项目根目录和 Compose 文件路径指向这里，而不是指向其他服务目录。

## 关键配置

- **公网域名**：`https://llmapi.1983070.xyz`。
- **Cloudflare DNS**：已创建 proxied `A` 记录，origin 指向 Coolify 入口 `192.129.135.37`。
- **应用端口**：New API 监听 `3000`，Coolify 代理也应指向容器端口 `3000`。
- **健康检查**：`GET /api/status`，期望 JSON 中 `success=true`。
- **数据库**：默认使用 PostgreSQL 15，数据保存在 `new_api_postgres` 卷。
- **缓存**：默认启用 Redis 7，数据保存在 `new_api_redis` 卷。
- **应用数据和日志**：`/data` 和 `/app/logs` 分别挂载到 `new_api_data`、`new_api_logs`。
- **会话密钥**：必须设置 `SESSION_SECRET`，模板默认来自 `SERVICE_PASSWORD_SESSION`。
- **Redis 加密密钥**：使用 Redis 时必须设置 `CRYPTO_SECRET`，模板默认来自 `SERVICE_PASSWORD_CRYPTO`。

## Current Deployment

| 项目 | 值 |
| --- | --- |
| Coolify resource | `new-api-llmapi` |
| Coolify UUID | `n7vl5q2hu7m6dns4ry2c4big` |
| Coolify project | `My first project` / `production` |
| Git source | `Eleef/new-api-coolify`, branch `main` |
| Auto deploy | GitHub Actions on `main` push, using `COOLIFY_BASE_URL`, `COOLIFY_TOKEN`, and `COOLIFY_APP_UUID` repository secrets |
| Last verified | `2026-05-25` |
| Verification | `GET /api/status` returns `success=true`; homepage returns `200` |

## 环境变量说明

Coolify 支持 `SERVICE_PASSWORD_*` 这类变量自动生成并持久化随机值。模板使用：

| 变量 | 作用 |
| --- | --- |
| `SERVICE_PASSWORD_POSTGRES` | PostgreSQL 密码 |
| `SERVICE_PASSWORD_REDIS` | Redis 密码 |
| `SERVICE_PASSWORD_SESSION` | New API 会话密钥 |
| `SERVICE_PASSWORD_CRYPTO` | Redis 相关加密密钥 |

如果手动填写这些值，请使用 URL 安全字符，因为 `SQL_DSN` 和 `REDIS_CONN_STRING` 会把密码放进连接字符串。不要使用 `random_string` 作为 `SESSION_SECRET`，New API 会拒绝这个默认值。

## 首次上线检查

在本机 PowerShell 运行：

```powershell
.\scripts\smoke-check.ps1 -BaseUrl "https://llmapi.1983070.xyz"
```

检查项：

- 首页返回 2xx 或 3xx。
- `/api/status` 返回 `success=true`。
- Coolify 中 `new-api`、`postgres`、`redis` 三个容器均为健康状态。
- 首次登录或初始化后立刻修改默认管理员密码；旧初始化路径可能创建 `root / 123456`。
- 进入管理后台后配置合法授权的上游模型渠道，不要把上游 API Key 写进仓库。

## 升级和回滚

- 推送到部署仓库 `main` 分支会自动触发 Coolify 重新部署，并重新拉取 Compose 中声明的镜像。
- 生产环境建议把 `NEW_API_IMAGE` 从 `latest` 固定到已验证的版本标签。
- 升级前先在 Coolify 中确认 PostgreSQL 卷、Redis 卷、`/data` 卷都存在。
- 升级后运行 `scripts/smoke-check.ps1`，再做一次登录和一次真实 API 转发测试。
- 回滚优先改回上一版 `NEW_API_IMAGE` 并重新部署。删除卷、恢复数据库或重建应用属于高风险操作，需要单独确认。

## 合规和许可

New API 使用 AGPLv3 许可证，并面向合法授权的 AI API 网关、组织鉴权、多模型管理、用量统计和私有部署场景。公开提供生成式 AI 服务或 API 转售前，应先确认本地监管、备案、内容安全、实名、日志留存、税务、支付和上游授权要求。
