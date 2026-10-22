# docker-typecho

基于官方 **PHP Apache** 镜像构建的 Typecho 容器，面向 Traefik 等反向代理（容器内仅 HTTP 80，由代理终结 TLS）。

| 镜像标签 | Typecho | 说明 |
|----------|---------|------|
| `latest`、`1.3.0`、`1.3.0-php8.2.35` | **1.3.0** | 当前稳定版（推荐） |
| `1.2.1`、`1.2.1-php8.2.35` | **1.2.1** | 旧版主线，便于暂不升级的用户 |

- **PHP**：`8.2.35`（已修复 PHP2Shell / CVE-2026-109618、CVE-2026-109619；构建时校验版本）
- **发布**：`ghcr.io/moderras/docker-typecho`（`linux/amd64`、`linux/arm64`）

> **说明**：本仓库早期版本使用 `abiosoft/caddy:php`（Caddy + PHP-FPM），并从 GitHub `master` 拉取 Typecho。现已改为官方 `php:8.2.35-apache` + 固定 Typecho 版本（构建参数 `TYPECHO_VERSION`）。

Typecho **1.2.1** 与 **1.3.0** 均在 **PHP 8.2.35** 上验证可打开安装页（无致命错误）。1.2.1 官方要求 PHP ≥ 7.2，在 8.2 下可正常运行（可能存在弃用提示，但不影响安装流程）。

## 快速开始

```bash
# Typecho 1.3.0（默认）
docker pull ghcr.io/moderras/docker-typecho:latest

docker run -d \
  --name typecho \
  --restart unless-stopped \
  -p 80:80 \
  -v /path/to/typecho-data:/srv \
  -e TYPECHO_SECURE=1 \
  ghcr.io/moderras/docker-typecho:latest

# Typecho 1.2.1
docker pull ghcr.io/moderras/docker-typecho:1.2.1

docker run -d \
  --name typecho-121 \
  --restart unless-stopped \
  -p 80:80 \
  -v /path/to/typecho-data:/srv \
  -e TYPECHO_SECURE=1 \
  ghcr.io/moderras/docker-typecho:1.2.1
```

站点文件位于卷内 **`/srv/html`**（与旧版 Caddy 镜像挂载 `/srv` 的方式兼容）。首次启动会自动将 Typecho 文件复制到该目录。

### 环境变量

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `TYPECHO_SECURE` | （未设置） | 设为 `1` 时强制 Typecho 使用 `https://` 生成链接（`__TYPECHO_SECURE__`）。未设置时仍可通过代理发来的 `X-Forwarded-Proto: https` 识别 HTTPS。 |
| `REMOTEIP_TRUSTED_PROXIES` | `10.0.0.0/8,172.16.0.0/12,192.168.0.0/16,127.0.0.0/8,::1/128` | `mod_remoteip` 信任的代理 CIDR，逗号或空格分隔。 |
| `APACHE_DOCUMENT_ROOT` | `/srv/html` | 文档根目录，一般无需修改。 |

以下旧版 Caddy 镜像变量 **已不再使用**（TLS 由 Traefik 处理）：`DOMAIN`、`EMAIL`、`ACME_AGREE`。

## Traefik 示例

容器只监听 **80**，请由 Traefik 提供 HTTPS 并转发 `X-Forwarded-Proto` / `X-Forwarded-For`：

```yaml
services:
  typecho:
    image: ghcr.io/moderras/docker-typecho:latest
    volumes:
      - ./data:/srv
    environment:
      TYPECHO_SECURE: "1"
      # 若 Traefik 与容器不在默认私网段，请补充其 IP/CIDR：
      # REMOTEIP_TRUSTED_PROXIES: "10.0.0.0/8,172.16.0.0/12,192.168.0.0/16,172.18.0.0/16"
    labels:
      - traefik.enable=true
      - traefik.http.routers.typecho.rule=Host(`blog.example.com`)
      - traefik.http.routers.typecho.entrypoints=websecure
      - traefik.http.routers.typecho.tls.certresolver=letsencrypt
      - traefik.http.services.typecho.loadbalancer.server.port=80
    networks:
      - web

networks:
  web:
    external: true
```

## PHP2Shell 与安全

2026-10-21 披露的 **PHP2Shell**（CVE-2026-109618 / CVE-2026-109619，CVSS 9.2）影响 PHP 5.4–8.5.11，**mod_php（Apache）风险最高**。两个 Typecho 变体均固定使用已修补的 **PHP 8.2.35**，并在 Docker 构建阶段执行 `version_compare` 检查。

## 本地构建

```bash
# Typecho 1.3.0
docker build --build-arg TYPECHO_VERSION=1.3.0 -t docker-typecho:1.3.0 .

# Typecho 1.2.1
docker build --build-arg TYPECHO_VERSION=1.2.1 -t docker-typecho:1.2.1 .

docker run --rm -p 8080:80 docker-typecho:1.3.0
```

## CI

推送到默认分支、打 tag、手动触发或 **每周一** 定时任务会为 **1.3.0** 与 **1.2.1** 各构建并推送多架构镜像。

| 变体 | 主要标签 |
|------|----------|
| 1.3.0 | `latest`、`1.3.0`、`1.3.0-php8.2.35`、`<git-sha>` |
| 1.2.1 | `1.2.1`、`1.2.1-php8.2.35`、`1.2.1-<git-sha>`（不会覆盖 `latest`） |

## License

See [LICENSE](LICENSE).
