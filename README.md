# docker-typecho

**`ghcr.io/moderras/docker-typecho` 是官方 [`joyqi/typecho`](https://hub.docker.com/r/joyqi/typecho) Apache 镜像的 drop-in 替代**：沿用 [typecho/Dockerfile](https://github.com/typecho/Dockerfile) 的目录结构、环境变量与入口脚本，仅将 PHP 固定为已修补 **PHP2Shell**（CVE-2026-109618 / CVE-2026-109619）的 **`8.2.35-apache`**，并由本仓库 CI 发布到 GHCR。

若你正在使用例如 `joyqi/typecho:1.3.0-php8.2-apache`，只需将镜像名改为下表对应标签，**无需修改**环境变量、卷挂载、端口或已有数据。

## 标签对照（joyqi → GHCR）

| joyqi/typecho | ghcr.io/moderras/docker-typecho | Typecho |
|---------------|----------------------------------|---------|
| `1.3.0-php8.2-apache` | `1.3.0-php8.2-apache` 或 `1.3.0` | 1.3.0 |
| `nightly-php8.2-apache` | `latest` 或 `1.3.0-php8.2-apache`（本仓库不构建 nightly 开发包） | 1.3.0 |
| `1.2.1-php8.2-apache` | `1.2.1-php8.2-apache` 或 `1.2.1` | 1.2.1 |

附加标签（便于追溯）：`1.3.0-php8.2.35`、`1.2.1-php8.2.35`、git commit SHA（1.3.0 为 `<sha>`，1.2.1 为 `1.2.1-<sha>`）。

## 快速开始（与官方 README 一致）

```bash
docker run --name typecho-server \
  -e TYPECHO_SITE_URL=https://your-domain.com \
  -d ghcr.io/moderras/docker-typecho:1.3.0-php8.2-apache
```

```yaml
services:
  typecho:
    image: ghcr.io/moderras/docker-typecho:1.3.0-php8.2-apache
    restart: always
    environment:
      TYPECHO_SITE_URL: https://your-domain.com
    ports:
      - "8080:80"
    volumes:
      - /var/typecho:/app/usr
```

- **工作目录 / 应用路径**：`/app`
- **数据卷**：`/app/usr`（插件、主题、上传等）
- **端口**：`80`（HTTP，TLS 由前置反向代理终结）

### 自动安装示例（SQLite）

与官方镜像相同，通过环境变量在首次启动时运行 `install.php`（CLI）：

```bash
docker run --name typecho-server \
  -e TYPECHO_SITE_URL=http://127.0.0.1:8080 \
  -e TYPECHO_INSTALL=1 \
  -e TYPECHO_DB_ADAPTER=Pdo_SQLite \
  -e TYPECHO_DB_FILE=/app/usr/uploads/typecho.db \
  -v typecho-data:/app/usr \
  -p 8080:80 \
  -d ghcr.io/moderras/docker-typecho:1.3.0-php8.2-apache
```

> SQLite 数据库文件需放在 `www-data` 可写的路径（通常为 `/app/usr/uploads/...`）。若将卷挂载到 `/app/usr`，卷根目录可能为 `root` 所有，与官方镜像行为一致。

## 环境变量（与 [官方文档](https://github.com/typecho/Dockerfile) 一致）

| 名称 | 说明 |
|------|------|
| `TIMEZONE` | 默认 `UTC`，例如 `Asia/Shanghai` |
| `MEMORY_LIMIT` | PHP `memory_limit` |
| `MAX_POST_BODY` | `upload_max_filesize` / `post_max_size` |
| `MAX_EXECUTION_TIME` | 默认 `30`（镜像内 `ENV`，与上游一致） |
| `TYPECHO_INSTALL` | 默认 `0`；设为 `1` 自动执行安装 |
| `TYPECHO_DB_ADAPTER` | 默认 `Pdo_Mysql`；可选 `Pdo_SQLite`、`Pdo_Pgsql` 等 |
| `TYPECHO_DB_HOST` | MySQL/Pg 主机，默认 `localhost` |
| `TYPECHO_DB_PORT` | MySQL `3306` / Pg `5432` |
| `TYPECHO_DB_USER` | MySQL/Pg 用户名 |
| `TYPECHO_DB_PASSWORD` | MySQL/Pg 密码 |
| `TYPECHO_DB_FILE` | SQLite 数据库路径 |
| `TYPECHO_DB_DATABASE` | MySQL/Pg 库名 |
| `TYPECHO_DB_PREFIX` | 默认 `typecho_` |
| `TYPECHO_DB_ENGINE` | MySQL 引擎，默认 `InnoDB` |
| `TYPECHO_DB_CHARSET` | 默认 MySQL `utf8mb4` / Pg `utf8` |
| `TYPECHO_DB_NEXT` | 默认 `none`；`keep` / `force` |
| `TYPECHO_SITE_URL` | **必填**（安装时）站点 URL |
| `TYPECHO_USER_NAME` | 默认 `typecho` |
| `TYPECHO_USER_PASSWORD` | 默认随机 8 位 |
| `TYPECHO_USER_MAIL` | 默认 `admin@localhost.local` |

Typecho 1.3 安装程序还支持（上游 install.php）：`TYPECHO_DB_DSN`、`TYPECHO_DB_SSL_CA`、`TYPECHO_DB_SSL_VERIFY`。

### 可选（本仓库新增，默认关闭）

| 名称 | 说明 |
|------|------|
| `REMOTEIP_TRUSTED_PROXIES` | 逗号分隔的 CIDR；设置后启用 Apache `mod_remoteip` 信任 `X-Forwarded-For`。未设置时与 joyqi 行为相同。Typecho 1.3 已原生识别 `X-Forwarded-Proto`。 |

## 与 joyqi 的差异

| 项目 | joyqi/typecho | 本镜像 |
|------|---------------|--------|
| PHP | 8.2.30（未修补 PHP2Shell） | **8.2.35**（构建时强制版本校验） |
|  registry | Docker Hub | **ghcr.io** |
| 其余 | — | 可选 `REMOTEIP_TRUSTED_PROXIES`；含 `pdo_sqlite`（与当前 joyqi 8.2-apache 模块一致） |

## PHP2Shell

2026-10-21 披露的 PHP2Shell 影响 PHP 5.4–8.5.11，mod_php 风险最高。本镜像固定 **PHP 8.2.35** 并在构建阶段执行 `version_compare` 检查。

## 本地构建

```bash
docker build \
  --build-arg URL=https://github.com/typecho/typecho/releases/download/v1.3.0/typecho.zip \
  -t docker-typecho:local .
```

## 上游与许可

`scripts/` 来自 [typecho/Dockerfile](https://github.com/typecho/Dockerfile)（GPL-2.0），见 [UPSTREAM.md](UPSTREAM.md)。

## License

See [LICENSE](LICENSE)（本仓库 MIT；上游 Docker 脚本为 GPL-2.0）。
